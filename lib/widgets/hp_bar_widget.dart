import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HpBarWidget extends StatelessWidget {
  final int currentHp;
  final int maxHp;

  const HpBarWidget({super.key, required this.currentHp, required this.maxHp});

  String _formatHp(int hp) {
    if (hp >= 1000000) return '${(hp / 1000000).toStringAsFixed(1)}M';
    if (hp >= 1000) return '${(hp / 1000).toStringAsFixed(1)}K';
    return hp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0.0;

    final barColor = ratio > 0.5
        ? Color.lerp(const Color(0xFFFF8C00), const Color(0xFF4CAF50), (ratio - 0.5) * 2)!
        : Color.lerp(const Color(0xFFFF1744), const Color(0xFFFF8C00), ratio * 2)!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_formatHp(currentHp)} / ${_formatHp(maxHp)}',
              style: GoogleFonts.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
                shadows: [
                  const Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: Colors.black.withValues(alpha: 0.5),
            border: Border.all(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.5),
            child: Stack(
              children: [
                // Background track
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.grey.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
                // Fill bar
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          barColor.withValues(alpha: 0.7),
                          barColor,
                          barColor.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Shine overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
