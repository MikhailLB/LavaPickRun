import 'package:flutter/material.dart';
import '../painters/ember_icon.dart';
import '../theme.dart';

/// Embers counter that gives a little bounce whenever the total changes.
class EmberChip extends StatefulWidget {
  const EmberChip({super.key, required this.amount, this.compact = false});

  final int amount;
  final bool compact;

  static String format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  State<EmberChip> createState() => _EmberChipState();
}

class _EmberChipState extends State<EmberChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.amount;
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didUpdateWidget(EmberChip old) {
    super.didUpdateWidget(old);
    if (widget.amount != _prev) {
      _prev = widget.amount;
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 18.0 : 24.0;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 14,
          vertical: widget.compact ? 5 : 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: Palette.gold.withValues(alpha: 0.65), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.3).animate(
              CurvedAnimation(parent: _bounce, curve: Curves.elasticOut),
            ),
            child: EmberIcon(size: iconSize),
          ),
          const SizedBox(width: 6),
          Text(EmberChip.format(widget.amount),
              style: AppText.title(widget.compact ? 14 : 18,
                  color: Palette.gold)),
        ],
      ),
    );
  }
}
