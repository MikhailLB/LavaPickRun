import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  int _barStage = 0;
  bool _navigating = false;
  bool _disposed = false;
  Orientation? _lastOrientation;

  // Track which controller is "current" to avoid races
  int _initGeneration = 0;

  static const List<String> _barAssets = [
    'assets/Loading/Loading_Bar_Empty.webp',
    'assets/Loading/Loading_Bar_Half.webp',
    'assets/Loading/Loading_Bar_Almost.webp',
    'assets/Loading/Loading_Bar_Full.webp',
  ];

  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Do not reinitialize if we're already navigating away
    if (_navigating || _disposed) return;
    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      _initVideo(orientation);
    }
  }

  Future<void> _initVideo(Orientation orientation) async {
    final myGen = ++_initGeneration;

    // Snapshot and null out the old controller before async work
    final oldController = _controller;
    _controller = null;

    if (mounted && !_disposed) {
      setState(() => _videoReady = false);
    }

    final asset = orientation == Orientation.portrait
        ? 'assets/Loading/Vertical_Loading_Screen.mp4'
        : 'assets/Loading/Horizontal_Loading_Screen.mp4';

    final controller = VideoPlayerController.asset(asset);

    try {
      await controller.initialize();
    } catch (_) {
      controller.dispose();
      return;
    }

    // Stale check — a newer init started after us
    if (myGen != _initGeneration || _navigating || _disposed) {
      controller.dispose();
      await oldController?.dispose();
      return;
    }

    controller.setLooping(true);
    controller.setVolume(0);
    await controller.play();

    _controller = controller;

    if (mounted && !_disposed && myGen == _initGeneration) {
      setState(() => _videoReady = true);
      _startBarProgress();
    }

    // Safe to dispose the old one now that the new one is playing
    await oldController?.dispose();
  }

  void _startBarProgress() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();

    if (mounted && !_disposed) setState(() => _barStage = 0);

    _timers.add(Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_disposed) setState(() => _barStage = 1);
    }));
    _timers.add(Timer(const Duration(milliseconds: 1900), () {
      if (mounted && !_disposed) setState(() => _barStage = 2);
    }));
    _timers.add(Timer(const Duration(milliseconds: 2900), () {
      if (mounted && !_disposed) setState(() => _barStage = 3);
    }));
    _timers.add(Timer(const Duration(milliseconds: 3500), () {
      if (!_navigating && !_disposed && mounted) {
        _navigate();
      }
    }));
  }

  void _navigate() {
    _navigating = true;
    // Stop and pause video before leaving to prevent the error flash
    _controller?.pause();
    // Restore portrait lock before pushing so the route transition is clean
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Small delay lets the orientation settle before the route change
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/menu');
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    // Pause first to avoid error-state flash during disposal
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final size = MediaQuery.of(context).size;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video background — only render when ready to avoid the error widget
          if (_videoReady && _controller != null && _controller!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            Container(color: Colors.black),

          // Loading bar — portrait: 24px from bottom; landscape: 16px, narrower
          if (_videoReady)
            Positioned(
              left: 0,
              right: 0,
              bottom: isLandscape ? 16 : 24,
              child: Center(
                child: _AnimatedLoadingBar(
                  stage: _barStage,
                  assets: _barAssets,
                  width: isLandscape
                      ? size.width * 0.28
                      : size.width * 0.72,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedLoadingBar extends StatefulWidget {
  final int stage;
  final List<String> assets;
  final double width;

  const _AnimatedLoadingBar({
    required this.stage,
    required this.assets,
    required this.width,
  });

  @override
  State<_AnimatedLoadingBar> createState() => _AnimatedLoadingBarState();
}

class _AnimatedLoadingBarState extends State<_AnimatedLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fade;
  int _displayedStage = 0;
  int _nextStage = 0;

  @override
  void initState() {
    super.initState();
    _displayedStage = widget.stage;
    _nextStage = widget.stage;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_AnimatedLoadingBar old) {
    super.didUpdateWidget(old);
    if (widget.stage != _nextStage) {
      _nextStage = widget.stage;
      _fadeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _displayedStage = _nextStage;
            _fadeController.value = 1.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            widget.assets[_displayedStage],
            width: widget.width,
            fit: BoxFit.contain,
          ),
          if (_nextStage != _displayedStage)
            AnimatedBuilder(
              animation: _fade,
              builder: (context, child) => Opacity(
                opacity: _fade.value,
                child: Image.asset(
                  widget.assets[_nextStage],
                  width: widget.width,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
