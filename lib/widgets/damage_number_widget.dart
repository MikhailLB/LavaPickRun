import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';

class DamageNumberWidget extends StatefulWidget {
  final DamageEvent event;
  final VoidCallback onComplete;

  const DamageNumberWidget({
    super.key,
    required this.event,
    required this.onComplete,
  });

  @override
  State<DamageNumberWidget> createState() => _DamageNumberWidgetState();
}

class _DamageNumberWidgetState extends State<DamageNumberWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnim, _xAnim, _opacityAnim, _scaleAnim;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    final isBig = widget.event.type != DamageEventType.normal;
    final angle = (_rng.nextDouble() - 0.5) * pi * 0.8;
    final dist = 80.0 + _rng.nextDouble() * 60;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isBig ? 1100 : 750),
    );

    _xAnim = Tween<double>(begin: 0, end: sin(angle) * dist).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _yAnim = Tween<double>(begin: 0, end: -(cos(angle).abs() * dist + 40)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 0.1),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 0.6),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 0.3),
    ]).animate(_controller);
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: isBig ? 0.4 : 0.3, end: isBig ? 1.5 : 1.1), weight: 0.2),
      TweenSequenceItem(tween: Tween(begin: isBig ? 1.5 : 1.1, end: isBig ? 1.2 : 0.9), weight: 0.8),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(int dmg) {
    if (dmg >= 1000000000) return '${(dmg / 1000000000).toStringAsFixed(1)}B';
    if (dmg >= 1000000) return '${(dmg / 1000000).toStringAsFixed(1)}M';
    if (dmg >= 1000) return '${(dmg / 1000).toStringAsFixed(1)}K';
    return dmg.toString();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.event.type;
    final isBig = type != DamageEventType.normal;

    String? label;
    List<Color> colors;
    switch (type) {
      case DamageEventType.crit:
        label = 'CRIT!';
        colors = const [Color(0xFFFF6D00), Color(0xFFFFD700), Color(0xFFFFFFFF)];
      case DamageEventType.pyroclasm:
        label = '🌊 PYROCLASM';
        colors = const [Color(0xFFFF1744), Color(0xFFFF6D00), Color(0xFFFFD700)];
      case DamageEventType.curse:
        label = '💀 CURSED';
        colors = const [Color(0xFF9C27B0), Color(0xFFE040FB), Color(0xFFFFFFFF)];
      case DamageEventType.apocalypse:
        label = '☄️ APOCALYPSE';
        colors = const [Color(0xFFB71C1C), Color(0xFFFF3D00), Color(0xFFFFFFFF)];
      case DamageEventType.normal:
        colors = const [Color(0xFFFFD700), Color(0xFFFFF176), Color(0xFFFFD700)];
    }

    final fontSize = isBig ? 28.0 : 22.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Positioned(
        left: widget.event.position.dx + _xAnim.value - 50,
        top: widget.event.position.dy + _yAnim.value - 20,
        child: Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: colors.last,
                        letterSpacing: 1.5,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                  Stack(
                    children: [
                      Text(
                        _fmt(widget.event.damage),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = isBig ? 4 : 3
                            ..color = Colors.black.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        _fmt(widget.event.damage),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: colors,
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ).createShader(
                              Rect.fromLTWH(0, 0, 220, fontSize + 8),
                            ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
