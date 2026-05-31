import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../app/routes.dart';

/// Animated splash/boot screen. Plays the orientation-appropriate loading clip
/// while a four-stage progress bar fills, then hands off to the home screen.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  int _barStage = 0;
  bool _navigating = false;
  bool _disposed = false;
  Orientation? _lastOrientation;
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
    if (_navigating || _disposed) return;
    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      _initVideo(orientation);
    }
  }

  Future<void> _initVideo(Orientation orientation) async {
    final myGen = ++_initGeneration;
    final oldController = _controller;
    _controller = null;
    if (mounted && !_disposed) setState(() => _videoReady = false);

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
    await oldController?.dispose();
  }

  void _startBarProgress() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    if (mounted && !_disposed) setState(() => _barStage = 0);

    _timers.add(Timer(const Duration(milliseconds: 900),
        () => mounted && !_disposed ? setState(() => _barStage = 1) : null));
    _timers.add(Timer(const Duration(milliseconds: 1900),
        () => mounted && !_disposed ? setState(() => _barStage = 2) : null));
    _timers.add(Timer(const Duration(milliseconds: 2900),
        () => mounted && !_disposed ? setState(() => _barStage = 3) : null));
    _timers.add(Timer(const Duration(milliseconds: 3500), () {
      if (!_navigating && !_disposed && mounted) _navigate();
    }));
  }

  void _navigate() {
    _navigating = true;
    _controller?.pause();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.home);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
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
          if (_videoReady &&
              _controller != null &&
              _controller!.value.isInitialized)
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
            const ColoredBox(color: Colors.black),
          if (_videoReady)
            Positioned(
              left: 0,
              right: 0,
              bottom: isLandscape ? 16 : 24,
              child: Center(
                child: _ProgressBar(
                  stage: _barStage,
                  assets: _barAssets,
                  width: isLandscape ? size.width * 0.28 : size.width * 0.72,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar(
      {required this.stage, required this.assets, required this.width});

  final int stage;
  final List<String> assets;
  final double width;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  int _displayed = 0;
  int _next = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.stage;
    _next = widget.stage;
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
  }

  @override
  void didUpdateWidget(_ProgressBar old) {
    super.didUpdateWidget(old);
    if (widget.stage != _next) {
      _next = widget.stage;
      _fade.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _displayed = _next;
            _fade.value = 1.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(widget.assets[_displayed],
              width: widget.width, fit: BoxFit.contain),
          if (_next != _displayed)
            FadeTransition(
              opacity: CurvedAnimation(parent: _fade, curve: Curves.easeInOut),
              child: Image.asset(widget.assets[_next],
                  width: widget.width, fit: BoxFit.contain),
            ),
        ],
      ),
    );
  }
}
