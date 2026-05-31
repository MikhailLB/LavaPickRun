import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../engine/ascent_engine.dart';
import '../../engine/models.dart';
import '../theme.dart';

/// Draws the live, per-frame gameplay overlay: the ascent track (left), the
/// timing gauge (right) and the eruption danger ring around the volcano.
///
/// It repaints off a frame [Listenable] so it stays at display refresh rate
/// without rebuilding any widgets — replacing the old animation package.
class GameCanvasPainter extends CustomPainter {
  GameCanvasPainter({
    required this.engine,
    required this.clock,
  }) : super(repaint: clock);

  final AscentEngine engine;

  /// Monotonic elapsed seconds, advanced by the screen's frame ticker. Used to
  /// derive an ambient "breathing" pulse without a separate animation package.
  final ValueListenable<double> clock;

  double get pulse => (sin(clock.value * 2.4) + 1) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    _paintHazardRing(canvas, size);
    _paintAscentTrack(canvas, size);
    _paintGauge(canvas, size);
  }

  // ── Eruption danger ring around the centre volcano ─────────────────
  void _paintHazardRing(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = min(size.width, size.height) * 0.34;

    double intensity;
    Color color;
    switch (engine.hazard) {
      case HazardState.telegraph:
        final p = engine.telegraphView <= 0
            ? 1.0
            : (1 - engine.hazardTimeLeft / engine.telegraphView)
                .clamp(0.0, 1.0);
        intensity = 0.25 + p * 0.4 + pulse * 0.1;
        color = Color.lerp(Palette.gold, Palette.danger, p)!;
      case HazardState.erupting:
        intensity = 0.85 + pulse * 0.15;
        color = Palette.danger;
      case HazardState.venting:
        intensity = 0.5 + pulse * 0.2;
        color = Palette.cool;
      case HazardState.calm:
        return;
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 + intensity * 7
      ..color = color.withValues(alpha: intensity.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, ring);

    if (engine.hazard == HazardState.erupting) {
      final wash = Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.danger.withValues(alpha: 0.0),
            Palette.danger.withValues(alpha: 0.28 + pulse * 0.1),
          ],
          stops: const [0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6));
      canvas.drawCircle(center, radius * 1.6, wash);
    }
  }

  // ── Left vertical ascent track ─────────────────────────────────────
  void _paintAscentTrack(Canvas canvas, Size size) {
    const margin = 26.0;
    final x = margin;
    final top = size.height * 0.20;
    final bottom = size.height * 0.80;
    const width = 12.0;

    final trackRect = RRect.fromLTRBR(
      x - width / 2, top, x + width / 2, bottom, const Radius.circular(8));
    canvas.drawRRect(
      trackRect,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawRRect(
      trackRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Palette.ember.withValues(alpha: 0.4),
    );

    // Checkpoint marks at the quarter heights.
    for (final c in const [0.25, 0.5, 0.75]) {
      final cy = lerpDouble(bottom, top, c)!;
      final reached = engine.ascent >= c;
      canvas.drawLine(
        Offset(x - width / 2 - 4, cy),
        Offset(x + width / 2 + 4, cy),
        Paint()
          ..color = (reached ? Palette.gold : Palette.cream)
              .withValues(alpha: reached ? 0.9 : 0.3)
          ..strokeWidth = 2,
      );
    }

    final fillTop = lerpDouble(bottom, top, engine.ascent)!;
    if (engine.ascent > 0.001) {
      final fillRect = RRect.fromLTRBR(
        x - width / 2, fillTop, x + width / 2, bottom,
        const Radius.circular(8));
      canvas.drawRRect(
        fillRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Palette.emberHot, Palette.ember, Palette.gold],
          ).createShader(Rect.fromLTRB(x - 6, top, x + 6, bottom)),
      );
      canvas.drawCircle(
        Offset(x, fillTop),
        6 + pulse * 2,
        Paint()
          ..color = Palette.gold.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  // ── Right vertical timing gauge ────────────────────────────────────
  void _paintGauge(Canvas canvas, Size size) {
    final x = size.width - 30.0;
    final top = size.height * 0.18;
    final bottom = size.height * 0.82;
    const width = 16.0;

    final danger = engine.isDanger || engine.isTelegraph;
    final venting = engine.isVenting;
    final railColor = venting
        ? Palette.cool
        : danger
            ? Palette.danger
            : Palette.ember;

    // Rail.
    final rail = RRect.fromLTRBR(
      x - width / 2, top, x + width / 2, bottom, const Radius.circular(10));
    canvas.drawRRect(rail, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawRRect(
      rail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = railColor.withValues(alpha: 0.6),
    );

    double posToY(double pos) => lerpDouble(bottom, top, pos)!;

    // Good band.
    final goodTop = posToY(
        (AscentEngine.targetCenter + engine.goodBandView).clamp(0.0, 1.0));
    final goodBottom = posToY(
        (AscentEngine.targetCenter - engine.goodBandView).clamp(0.0, 1.0));
    canvas.drawRRect(
      RRect.fromLTRBR(
        x - width / 2, goodTop, x + width / 2, goodBottom,
        const Radius.circular(8)),
      Paint()..color = Palette.ember.withValues(alpha: 0.22),
    );

    // Perfect band.
    final perfTop = posToY(
        (AscentEngine.targetCenter + engine.perfectBandView).clamp(0.0, 1.0));
    final perfBottom = posToY(
        (AscentEngine.targetCenter - engine.perfectBandView).clamp(0.0, 1.0));
    canvas.drawRRect(
      RRect.fromLTRBR(
        x - width / 2, perfTop, x + width / 2, perfBottom,
        const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.gold, Palette.cream, Palette.gold],
        ).createShader(Rect.fromLTRB(x - 8, perfTop, x + 8, perfBottom))
        ..color = Palette.gold.withValues(alpha: danger ? 0.4 : 0.9),
    );

    // Marker.
    final my = posToY(engine.markerPosition);
    final markerColor = venting
        ? Palette.cool
        : danger
            ? Palette.danger
            : Palette.cream;
    final marker = Path()
      ..moveTo(x - width / 2 - 12, my)
      ..lineTo(x - width / 2 - 2, my - 8)
      ..lineTo(x - width / 2 - 2, my + 8)
      ..close();
    canvas.drawPath(
      marker,
      Paint()
        ..color = markerColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );
    canvas.drawLine(
      Offset(x - width / 2, my),
      Offset(x + width / 2, my),
      Paint()
        ..color = markerColor.withValues(alpha: 0.9)
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(GameCanvasPainter oldDelegate) => false;
}
