import 'package:flutter/material.dart';
import '../config/app_settings.dart';
import '../services/connectivity_service.dart';
import '../services/notif_service.dart';
import '../services/app_state_service.dart';
import 'content_screen.dart' deferred as content;

// Background assets — orientation-aware
// Portrait:  assets/Notifications/Vertical_Notifications_Screen.webp
// Landscape: assets/Notifications/Horizontal_Notifications_Screen.webp

class PushPromoScreen extends StatefulWidget {
  final AppStateService storage;
  final NotifService notifService;
  final ConnectivityService connectivity;
  final String contentUrl;

  const PushPromoScreen({
    super.key,
    required this.storage,
    required this.notifService,
    required this.connectivity,
    required this.contentUrl,
  });

  @override
  State<PushPromoScreen> createState() => _PushPromoScreenState();
}

class _PushPromoScreenState extends State<PushPromoScreen> {
  void _onAccept() async {
    final granted = await widget.notifService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      // Count this denial. After 2 denials Android permanently blocks the
      // system dialog, so shouldShowNotificationScreen() will return false.
      await widget.storage.incrementNotifDenied();
      // Also set the 3-day skip timer for the first denial
      if (widget.storage.getNotifDeniedCount() < 2) {
        final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
            AppSettings.notificationRetryDelaySeconds;
        await widget.storage.setNotificationSkipUntil(until);
      }
    }
    _goToContent();
  }

  void _onSkip() async {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        AppSettings.notificationRetryDelaySeconds;
    await widget.storage.setNotificationSkipUntil(until);
    if (!mounted) return;
    _goToContent();
  }

  Future<void> _goToContent() async {
    await content.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => content.ContentScreen(
        url: widget.contentUrl,
        storage: widget.storage,
        notifService: widget.notifService,
        connectivity: widget.connectivity,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Use project-specific custom background screens
    final bgAsset = isLandscape
        ? 'assets/Notifications/Horizontal_Notifications_Screen.webp'
        : 'assets/Notifications/Vertical_Notifications_Screen.webp';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen custom background image
            Image.asset(
              bgAsset,
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
            ),

            // Buttons — portrait: full width at bottom
            if (!isLandscape)
              Positioned(
                left: size.width * 0.08,
                right: size.width * 0.08,
                bottom: size.height * 0.07,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _AcceptButton(onTap: _onAccept),
                  const SizedBox(height: 18),
                  _SkipButton(onTap: _onSkip),
                ]),
              )
            else
              // Landscape: narrower, near bottom center
              Positioned(
                left: 0,
                right: 0,
                bottom: size.height * 0.06,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: size.width * 0.32,
                    child: _AcceptButton(onTap: _onAccept, compact: true),
                  ),
                  const SizedBox(height: 8),
                  _SkipButton(onTap: _onSkip, compact: true),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _AcceptButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _AcceptButton({required this.onTap, this.compact = false});
  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glow;
  late Animation<double> _glowVal;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _glowVal = Tween<double>(begin: 0.35, end: 0.75)
        .animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _glowVal,
        builder: (_, child) => AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(vertical: widget.compact ? 12 : 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? [const Color(0xFFE6A800), const Color(0xFFCC8800)]
                    : [const Color(0xFFFFCC00), const Color(0xFFFF9900)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9900).withValues(
                      alpha: _pressed ? 0.2 : _glowVal.value),
                  blurRadius: _pressed ? 8 : 14 + _glowVal.value * 18,
                  spreadRadius: _pressed ? 0 : _glowVal.value * 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Accept',
                style: TextStyle(
                  color: const Color(0xFF1A0A00),
                  fontSize: widget.compact ? 16 : 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _SkipButton({required this.onTap, this.compact = false});
  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.5 : 0.85,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding:
              EdgeInsets.symmetric(vertical: widget.compact ? 4 : 8),
          child: Center(
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 16 : 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                shadows: const [
                  Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
