import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_settings.dart';
import '../services/connectivity_service.dart';
import '../services/notif_service.dart';
import '../services/app_state_service.dart';
import 'content_screen.dart' deferred as content;

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
  VideoPlayerController? _ctrl;
  bool _videoReady = false;
  Orientation? _currentOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.of(context).orientation;
    if (o != _currentOrientation) {
      _currentOrientation = o;
      _initVideo(o);
    }
  }

  Future<void> _initVideo(Orientation o) async {
    // Use game loading videos as background since no dedicated nf_screen assets
    final asset = o == Orientation.landscape
        ? 'assets/Loading/Horizontal_Loading_Screen.mp4'
        : 'assets/Loading/Vertical_Loading_Screen.mp4';
    final old = _ctrl;
    final neo = VideoPlayerController.asset(asset);
    try {
      await neo.initialize();
      neo.setLooping(true);
      neo.setVolume(0);
      neo.play();
      if (!mounted) { neo.dispose(); return; }
      setState(() { _ctrl = neo; _videoReady = true; });
      old?.dispose();
    } catch (_) { neo.dispose(); }
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  void _onAccept() async {
    final granted = await widget.notifService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
          AppSettings.notificationRetryDelaySeconds;
      await widget.storage.setNotificationSkipUntil(until);
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
        url: widget.contentUrl, storage: widget.storage,
        notifService: widget.notifService, connectivity: widget.connectivity,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = _currentOrientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_videoReady && _ctrl != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _ctrl!.value.size.width,
                  height: _ctrl!.value.size.height,
                  child: VideoPlayer(_ctrl!),
                ),
              )
            else
              Container(color: const Color(0xFF1A0500)),

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
              Positioned(
                left: 0, right: 0, bottom: size.height * 0.06,
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
  @override State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glow;
  late Animation<double> _glowVal;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _glowVal = Tween<double>(begin: 0.35, end: 0.75)
        .animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _glowVal,
        builder: (_, _) => AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? [const Color(0xFFE6A800), const Color(0xFFCC8800)]
                    : [const Color(0xFFFFCC00), const Color(0xFFFF9900)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9900)
                      .withValues(alpha: _pressed ? 0.2 : _glowVal.value),
                  blurRadius: _pressed ? 8 : 14 + _glowVal.value * 18,
                  spreadRadius: _pressed ? 0 : _glowVal.value * 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: Text('Accept',
              style: TextStyle(
                color: const Color(0xFF1A0A00),
                fontSize: widget.compact ? 16 : 20,
                fontWeight: FontWeight.w800, letterSpacing: 0.5,
              ))),
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
  @override State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.5 : 0.85,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 8),
          child: Center(child: Text('Skip',
            style: TextStyle(
              color: Colors.white, fontSize: widget.compact ? 16 : 22,
              fontWeight: FontWeight.w700, letterSpacing: 0.5,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
            ))),
        ),
      ),
    );
  }
}
