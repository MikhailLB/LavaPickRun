import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/app_mode.dart';
import '../services/attribution_service.dart';
import '../services/config_service.dart';
import '../services/connectivity_service.dart';
import '../services/notif_service.dart';
import '../services/app_state_service.dart';
import 'main_menu_screen.dart';
import 'onboarding_screen.dart';
import 'no_internet_screen.dart';
import 'push_promo_screen.dart';
import 'content_screen.dart' deferred as content;
import '../services/save_service.dart';

enum _Bar { empty, mid, full }

class GraySplashScreen extends StatefulWidget {
  final AppStateService storage;
  final ConnectivityService connectivity;
  final AttributionService attribution;
  final ConfigService configService;
  final NotifService notifService;

  const GraySplashScreen({
    super.key,
    required this.storage,
    required this.connectivity,
    required this.attribution,
    required this.configService,
    required this.notifService,
  });

  @override
  State<GraySplashScreen> createState() => _GraySplashScreenState();
}

class _GraySplashScreenState extends State<GraySplashScreen> {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  _Bar _bar = _Bar.empty;
  bool _navigated = false;
  Orientation? _currentOrientation;

  @override
  void initState() {
    super.initState();
    // Allow all orientations for splash
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _run();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.of(context).orientation;
    if (o != _currentOrientation) {
      _currentOrientation = o;
      _switchVideo(o);
    }
  }

  Future<void> _switchVideo(Orientation o) async {
    final asset = o == Orientation.landscape
        ? 'assets/Loading/Horizontal_Loading_Screen.mp4'
        : 'assets/Loading/Vertical_Loading_Screen.mp4';

    final old = _videoCtrl;
    final neo = VideoPlayerController.asset(asset);
    try {
      await neo.initialize();
      neo.setLooping(true);
      neo.setVolume(0);
      neo.play();
      if (!mounted) { neo.dispose(); return; }
      setState(() { _videoCtrl = neo; _videoReady = true; });
      old?.dispose();
    } catch (_) {
      neo.dispose();
    }
  }

  Future<void> _run() async {
    widget.notifService.onTokenRefresh = _onTokenRefresh;
    await widget.notifService.init().catchError((_) {});
    _setBar(_Bar.empty);

    final mode = widget.storage.getAppMode();
    switch (mode) {
      case AppMode.online:
        _setBar(_Bar.mid);
        await _handleOnlineMode();
      case AppMode.offline:
        _setBar(_Bar.mid);
        _setBar(_Bar.full);
        await Future.delayed(const Duration(milliseconds: 600));
        _navigateToGame();
      case AppMode.pending:
        await _handleFirstLaunch();
    }
  }

  @override
  void dispose() {
    widget.notifService.onTokenRefresh = null;
    _videoCtrl?.dispose();
    super.dispose();
  }

  void _onTokenRefresh(String token) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.attribution
        .buildRequestBody(locale: locale, pushToken: token);
    widget.configService.fetchRemote(body);
  }

  void _setBar(_Bar b) {
    if (mounted) setState(() => _bar = b);
  }

  Future<void> _handleFirstLaunch() async {
    _setBar(_Bar.empty);
    if (!await widget.connectivity.hasInternet()) {
      if (!mounted) return;
      _navigateToNoInternet(firstLaunch: true);
      return;
    }
    _setBar(_Bar.mid);
    await widget.attribution.init();
    await Future.wait([
      widget.attribution.waitForAttribution(),
      widget.attribution.waitForDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body   = await widget.attribution.buildRequestBody(
      locale: locale, pushToken: widget.notifService.token,
    );
    final resp = await widget.configService.fetchRemote(body);
    if (resp.ok && resp.url != null) {
      await widget.storage.setAppMode(AppMode.online);
      _setBar(_Bar.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToContent(resp.url!);
    } else {
      await widget.storage.setAppMode(AppMode.offline);
      _setBar(_Bar.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToGame();
    }
  }

  Future<void> _handleOnlineMode() async {
    if (!await widget.connectivity.hasInternet()) {
      _setBar(_Bar.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToNoInternet(firstLaunch: false);
      return;
    }
    final pushUrl = await widget.storage.consumePushUrl();
    if (pushUrl != null) {
      _setBar(_Bar.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToContent(pushUrl);
      return;
    }
    final savedUrl = await widget.storage.getSavedUrl();
    await widget.attribution.init();
    await Future.wait([
      widget.attribution.waitForAttribution()
          .timeout(const Duration(seconds: 10), onTimeout: () => {}),
      widget.attribution.waitForDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body   = await widget.attribution.buildRequestBody(
      locale: locale, pushToken: widget.notifService.token,
    );
    final resp = await widget.configService.fetchRemote(body);
    _setBar(_Bar.full);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (resp.ok && resp.url != null) {
      _navigateToContent(resp.url!);
    } else if (savedUrl != null) {
      _navigateToContent(savedUrl);
    } else {
      _navigateToNoInternet(firstLaunch: false);
    }
  }

  Future<void> _navigateToContent(String url) async {
    if (_navigated) return;
    _navigated = true;
    await content.loadLibrary();
    await content.prepareContentEngine();
    if (!mounted) return;

    if (widget.storage.shouldShowNotificationScreen()) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => PushPromoScreen(
          storage: widget.storage,
          notifService: widget.notifService,
          connectivity: widget.connectivity,
          contentUrl: url,
        ),
      ));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => content.ContentScreen(
          url: url,
          storage: widget.storage,
          notifService: widget.notifService,
          connectivity: widget.connectivity,
        ),
      ));
    }
  }

  void _navigateToNoInternet({required bool firstLaunch}) {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => NoInternetScreen(
        retryScreenBuilder: (_) => GraySplashScreen(
          storage: widget.storage,
          connectivity: widget.connectivity,
          attribution: widget.attribution,
          configService: widget.configService,
          notifService: widget.notifService,
        ),
      ),
    ));
  }

  void _navigateToGame() {
    if (_navigated) return;
    _navigated = true;
    // Lock back to portrait for the game
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => FutureBuilder<bool>(
        future: SaveService.isOnboardingDone(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          return snap.data! ? const MainMenuScreen() : const OnboardingScreen();
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final barAsset = switch (_bar) {
      _Bar.empty => 'assets/Loading/Loading_Bar_Empty.webp',
      _Bar.mid   => 'assets/Loading/Loading_Bar_Half.webp',
      _Bar.full  => 'assets/Loading/Loading_Bar_Full.webp',
    };
    final isLandscape = _currentOrientation == Orientation.landscape;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          AnimatedOpacity(
            opacity: _videoReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _videoCtrl != null && _videoReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width:  _videoCtrl!.value.size.width,
                        height: _videoCtrl!.value.size.height,
                        child:  VideoPlayer(_videoCtrl!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_videoReady)
            Positioned(
              left: 0, right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Center(
                child: SizedBox(
                  width: isLandscape ? size.width * 0.28 : size.width * 0.7,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Image.asset(
                      barAsset,
                      key: ValueKey(barAsset),
                      fit: BoxFit.fitWidth,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stack) => const SizedBox(height: 30),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
