import 'package:flutter/material.dart';
import '../theme.dart';

/// Hand-drawn Ember currency mark — a faceted molten droplet.
///
/// Replaces the old coin painter; the silhouette is deliberately different
/// (teardrop gem rather than a round coin) to match the new currency identity.
class EmberIconPainter extends CustomPainter {
  const EmberIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final path = Path()
      ..moveTo(cx, h * 0.04)
      ..cubicTo(w * 0.86, h * 0.30, w * 0.95, h * 0.62, cx, h * 0.96)
      ..cubicTo(w * 0.05, h * 0.62, w * 0.14, h * 0.30, cx, h * 0.04)
      ..close();

    final glow = Paint()
      ..color = Palette.ember.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glow);

    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: Palette.emberRamp,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, body);

    // Inner facet highlight.
    final facet = Path()
      ..moveTo(cx, h * 0.18)
      ..cubicTo(w * 0.66, h * 0.34, w * 0.66, h * 0.56, cx, h * 0.66)
      ..cubicTo(w * 0.40, h * 0.56, w * 0.40, h * 0.34, cx, h * 0.18)
      ..close();
    canvas.drawPath(
      facet,
      Paint()..color = Palette.cream.withValues(alpha: 0.55),
    );

    // Sparkle.
    canvas.drawCircle(
      Offset(cx - w * 0.16, h * 0.30),
      w * 0.05,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(EmberIconPainter oldDelegate) => false;
}

/// Convenience widget wrapper.
class EmberIcon extends StatelessWidget {
  const EmberIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: EmberIconPainter()),
    );
  }
}
