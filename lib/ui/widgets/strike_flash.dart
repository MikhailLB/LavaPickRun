import 'dart:math';
import 'package:flutter/material.dart';
import '../../engine/models.dart';
import '../theme.dart';

/// Floating, self-animating feedback for a single strike result.
class StrikeFlashView extends StatefulWidget {
  const StrikeFlashView({
    super.key,
    required this.flash,
    required this.onDone,
  });

  final StrikeFlash flash;
  final VoidCallback onDone;

  @override
  State<StrikeFlashView> createState() => _StrikeFlashViewState();
}

class _StrikeFlashViewState extends State<StrikeFlashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final double _dx;

  @override
  void initState() {
    super.initState();
    _dx = (Random(widget.flash.id).nextDouble() - 0.5) * 0.5;
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  ({String text, Color color}) get _style {
    switch (widget.flash.quality) {
      case StrikeQuality.perfect:
        return (text: 'PERFECT', color: Palette.gold);
      case StrikeQuality.good:
        return (text: 'GOOD', color: Palette.cream);
      case StrikeQuality.weak:
        return (text: 'OFF', color: Colors.white60);
      case StrikeQuality.burned:
        return (text: 'BURNED!', color: Palette.danger);
      case StrikeQuality.overheat:
        return (text: 'VENTING', color: Palette.cool);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final opacity = t < 0.15 ? t / 0.15 : (1 - (t - 0.15) / 0.85);
        final rise = -0.12 - t * 0.32;
        final scale = 0.7 + (t < 0.3 ? t / 0.3 : 1.0) * 0.5;
        return Align(
          alignment: Alignment(_dx, rise),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.text,
                      style: AppText.display(26, color: s.color)),
                  if (widget.flash.quality == StrikeQuality.perfect &&
                      widget.flash.momentum > 1)
                    Text('x${widget.flash.momentum} combo',
                        style: AppText.label(12, color: Palette.ember)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
