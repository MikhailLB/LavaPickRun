import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';

class VolcanoWidget extends StatefulWidget {
  final String volcanoAsset;
  final void Function(Offset globalPosition) onTapWithPosition;

  const VolcanoWidget({
    super.key,
    required this.volcanoAsset,
    required this.onTapWithPosition,
  });

  @override
  State<VolcanoWidget> createState() => _VolcanoWidgetState();
}

class _VolcanoWidgetState extends State<VolcanoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _shakeController.forward(from: 0);
    SettingsService.onTap();
    widget.onTapWithPosition(details.globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Listener fires on every pointer-down without gesture arena competition
      onPointerDown: (event) {
        _handleTapDown(
          TapDownDetails(
            globalPosition: event.position,
            localPosition: event.localPosition,
            kind: event.kind,
          ),
        );
      },
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 70),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6D00).withValues(
                      alpha: _isPressed ? 0.9 : 0.45),
                  blurRadius: _isPressed ? 35 : 22,
                  spreadRadius: _isPressed ? 10 : 4,
                ),
                const BoxShadow(
                  color: Color(0x4DFF1744),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              widget.volcanoAsset,
              fit: BoxFit.contain,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 3000.ms,
                color: const Color(0x26FF6D00),
              ),
        ),
      ),
    );
  }
}
