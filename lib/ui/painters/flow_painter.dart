import 'package:flutter/material.dart';
import '../theme.dart';

/// Paints a single pipe tile: a rounded base, pipe arms toward each open side,
/// and a central hub. Lit tiles (carrying lava from the source) glow with the
/// ember ramp; unlit tiles are cool steel.
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
    final center = Offset(w / 2, h / 2);
    final arm = (w < h ? w : h) * 0.5;
    final thick = arm * 0.42;

    // Base tile
    final baseRect = RRect.fromRectAndRadius(
      Offset(w * 0.06, h * 0.06) & Size(w * 0.88, h * 0.88),
      Radius.circular(w * 0.16),
    );
    final basePaint = Paint()
      ..color = isSource
          ? Palette.cool.withValues(alpha: 0.18)
          : isDrain
              ? Palette.gold.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05);
    canvas.drawRRect(baseRect, basePaint);
    canvas.drawRRect(
      baseRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = (lit ? Palette.gold : Colors.white24).withValues(alpha: 0.5),
    );

    // Pipe arms
    final pipeColor = lit ? Palette.ember : const Color(0xFF5A6472);
    final glow = lit ? Palette.emberHot : Colors.transparent;
    final pipePaint = Paint()
      ..color = pipeColor
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final glowPaint = Paint()
      ..color = glow.withValues(alpha: lit ? 0.5 : 0.0)
      ..strokeWidth = thick + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
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
            : (lit ? Palette.gold : const Color(0xFF6B7585));
    canvas.drawCircle(center, thick * 0.62, Paint()..color = hubColor);
    if (isSource || isDrain) {
      canvas.drawCircle(
        center,
        thick * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FlowTilePainter old) =>
      old.mask != mask ||
      old.lit != lit ||
      old.isSource != isSource ||
      old.isDrain != isDrain;
}
