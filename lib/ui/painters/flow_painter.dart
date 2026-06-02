import 'package:flutter/material.dart';
import '../theme.dart';

/// Paints a single pipe tile: a rounded base, thick pipe arms toward each open
/// side, and a central hub. Lit tiles (carrying lava from the source) glow with
/// the ember ramp; unlit tiles are cool steel. The source is marked blue and
/// the drain gold so the goal reads at a glance.
class FlowTilePainter extends CustomPainter {
  FlowTilePainter({
    required this.mask,
    required this.lit,
    required this.isSource,
    required this.isDrain,
  });

  final int mask;
  final bool lit;
  final bool isSource;
  final bool isDrain;

  static const _dxOf = [0.0, 1.0, 0.0, -1.0]; // N,E,S,W unit dir x
  static const _dyOf = [-1.0, 0.0, 1.0, 0.0];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final center = Offset(w / 2, h / 2);
    final arm = (w < h ? w : h) * 0.5;
    final thick = arm * 0.5;

    // Base tile
    final baseRect = RRect.fromRectAndRadius(
      Offset(w * 0.05, h * 0.05) & Size(w * 0.90, h * 0.90),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(
      baseRect,
      Paint()
        ..color = isSource
            ? Palette.cool.withValues(alpha: 0.22)
            : isDrain
                ? Palette.gold.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawRRect(
      baseRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = (lit ? Palette.gold : Colors.white)
            .withValues(alpha: lit ? 0.7 : 0.22),
    );

    // Pipe arms
    final pipeColor = lit ? Palette.ember : const Color(0xFF8893A5);
    final pipePaint = Paint()
      ..color = pipeColor
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final glowPaint = Paint()
      ..color = Palette.emberHot.withValues(alpha: 0.55)
      ..strokeWidth = thick + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..style = PaintingStyle.stroke;

    for (var d = 0; d < 4; d++) {
      if ((mask >> d) & 1 == 0) continue;
      final end = center + Offset(_dxOf[d] * arm, _dyOf[d] * arm);
      if (lit) canvas.drawLine(center, end, glowPaint);
      canvas.drawLine(center, end, pipePaint);
    }

    // Central hub
    final hubColor = isSource
        ? Palette.cool
        : isDrain
            ? Palette.gold
            : (lit ? Palette.gold : const Color(0xFF9AA5B5));
    canvas.drawCircle(center, thick * 0.72, Paint()..color = hubColor);
    if (isSource || isDrain) {
      canvas.drawCircle(
        center,
        thick * 0.72,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Colors.white,
      );
      // A small marker glyph: down-chevron for source (lava in), up for drain.
      final gp = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final s = thick * 0.34;
      if (isSource) {
        canvas.drawLine(center + Offset(-s, -s * 0.4),
            center + Offset(0, s * 0.6), gp);
        canvas.drawLine(center + Offset(s, -s * 0.4),
            center + Offset(0, s * 0.6), gp);
      } else {
        canvas.drawLine(center + Offset(-s, s * 0.4),
            center + Offset(0, -s * 0.6), gp);
        canvas.drawLine(center + Offset(s, s * 0.4),
            center + Offset(0, -s * 0.6), gp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FlowTilePainter old) =>
      old.mask != mask ||
      old.lit != lit ||
      old.isSource != isSource ||
      old.isDrain != isDrain;
}
