import 'package:flutter/material.dart';
import '../../engine/ascent_engine.dart';
import '../theme.dart';

/// Horizontal heat meter. Repaints off the frame ticker so the fill tracks the
/// simulation smoothly without rebuilding widgets.
class HeatBar extends StatelessWidget {
  const HeatBar({super.key, required this.engine, required this.frame});

  final AscentEngine engine;
  final Listenable frame;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: CustomPaint(
        painter: _HeatPainter(engine: engine, repaint: frame),
        size: Size.infinite,
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({required this.engine, required Listenable repaint})
      : super(repaint: repaint);

  final AscentEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromLTRBR(0, 0, size.width, size.height, radius);

    canvas.drawRRect(track, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = (engine.overheated ? Palette.cool : Palette.ember)
            .withValues(alpha: 0.55),
    );

    final heat = engine.heat.clamp(0.0, 1.0);
    if (heat > 0.001) {
      final fillW = size.width * heat;
      final hot = heat > 0.8;
      final colors = engine.overheated
          ? const [Palette.cool, Color(0xFF80D8FF)]
          : hot
              ? const [Palette.emberHot, Palette.danger]
              : const [Palette.gold, Palette.ember];
      canvas.drawRRect(
        RRect.fromLTRBR(0, 0, fillW, size.height, radius),
        Paint()
          ..shader = LinearGradient(colors: colors)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    // Overheat threshold tick.
    final tickX = size.width * 0.92;
    canvas.drawLine(
      Offset(tickX, 1),
      Offset(tickX, size.height - 1),
      Paint()
        ..color = Palette.cream.withValues(alpha: 0.6)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_HeatPainter oldDelegate) => false;
}
