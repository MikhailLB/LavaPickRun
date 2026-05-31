import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cfg/magma_config.dart';
import '../core/ember_relay.dart';
import '../core/thermal_probe.dart';
import '../core/crater_vault.dart';
import 'lava_browser.dart';

class BellPrompt extends StatefulWidget {
  final CraterVault vault;
  final EmberRelay pulse;
  final ThermalProbe probe;
  final String destination;
  final bool coldStartPush;
  final Future<void> Function(String token)? onTokenReady;

  const BellPrompt({
    super.key,
    required this.vault,
    required this.pulse,
    required this.probe,
    required this.destination,
    this.coldStartPush = false,
    this.onTokenReady,
  });

  @override
  State<BellPrompt> createState() => _BellPromptState();
}

class _BellPromptState extends State<BellPrompt>
    with TickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _shimmer;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _shimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200),
    )..repeat();
    _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final granted = await widget.pulse.askConsent();
      if (granted) {
        final token = await widget.pulse.refreshTokenAfterConsent();
        if (token != null && token.isNotEmpty) {
          await widget.onTokenReady?.call(token);
        }
      } else {
        await _setCooldown();
      }
      _openBrowser();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    await _setCooldown();
    _openBrowser();
  }

  Future<void> _setCooldown() async {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        MagmaConfig.pushCooldownSeconds;
    await widget.vault.writePushCooldown(until);
  }

  void _openBrowser() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => LavaBrowser(
        destination: widget.destination,
        vault: widget.vault,
        pulse: widget.pulse,
        probe: widget.probe,
        coldStartPush: widget.coldStartPush,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final landscape = mq.size.width > mq.size.height;
    final bgAsset = landscape
        ? 'assets/Notifications/Horizontal_Notifications_Screen.png'
        : 'assets/Notifications/Vertical_Notifications_Screen.png';
    final btnW = landscape
        ? (mq.size.width * 0.30).clamp(220.0, 360.0)
        : mq.size.width * 0.76;
    final bottomGap = mq.size.height * (landscape ? 0.05 : 0.07);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(bgAsset, fit: BoxFit.cover),
            SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: 0, right: 0, bottom: bottomGap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AllowButton(
                          width: btnW,
                          busy: _busy,
                          shimmer: _shimmer,
                          glow: _glow,
                          onTap: _accept,
                          compact: landscape,
                        ),
                        SizedBox(height: mq.size.height * 0.022),
                        _PassButton(onTap: _skip, compact: landscape),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllowButton extends StatefulWidget {
  final double width;
  final bool busy;
  final bool compact;
  final AnimationController shimmer;
  final AnimationController glow;
  final VoidCallback onTap;
  const _AllowButton({
    required this.width, required this.busy, required this.shimmer,
    required this.glow, required this.onTap, this.compact = false,
  });
  @override
  State<_AllowButton> createState() => _AllowButtonState();
}

class _AllowButtonState extends State<_AllowButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 100),
  );
  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.compact ? 16.0 : 20.0;
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); _press.forward(); },
      onTapUp: (_) { setState(() => _pressed = false); _press.reverse(); widget.onTap(); },
      onTapCancel: () { setState(() => _pressed = false); _press.reverse(); },
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, widget.glow]),
        builder: (_, _) => Transform.scale(
          scale: 1.0 - 0.04 * _press.value,
          child: Container(
            width: widget.width,
            padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? [const Color(0xFFE05500), const Color(0xFFBB2200)]
                    : [const Color(0xFFFF6D00), const Color(0xFFDD3300)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4400)
                      .withValues(alpha: _pressed ? 0.2 : 0.25 + 0.25 * widget.glow.value),
                  blurRadius: _pressed ? 6 : 14 + widget.glow.value * 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.busy
                  ? SizedBox(
                      width: fontSize + 4, height: fontSize + 4,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF1A0500),
                      ),
                    )
                  : Text('Accept',
                      style: TextStyle(
                        color: const Color(0xFF1A0500),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      )),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _PassButton({required this.onTap, this.compact = false});
  @override
  State<_PassButton> createState() => _PassButtonState();
}

class _PassButtonState extends State<_PassButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.45 : 0.82,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 8),
          child: Text('Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 16 : 22,
                fontWeight: FontWeight.w700,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
              )),
        ),
      ),
    );
  }
}
