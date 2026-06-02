import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../data/peaks.dart';
import '../data/progress_store.dart';
import '../engine/models.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';

/// Lifetime statistics dashboard — a read-only summary of everything the
/// player has accumulated, with a simple accuracy bar.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final perfect = ProgressStore.perfectStrikes;
    final good = ProgressStore.goodStrikes;
    final weak = ProgressStore.weakStrikes;
    final totalStrikes = (perfect + good + weak).clamp(1, 1 << 30);
    final acc = perfect / totalStrikes;

    final unlockedAch = ProgressStore.unlockedAchievements().length;
    final codexFound = ProgressStore.unlockedCodex().length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/6_bg_asset.webp', darken: 0.66),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              Text('STATISTICS', style: AppText.display(20))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // Accuracy panel
                      GlassPanel(
                        glow: true,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STRIKE ACCURACY',
                                style: AppText.label(11,
                                    color: Palette.ember, spacing: 2)),
                            const SizedBox(height: 12),
                            Text('${(acc * 100).toStringAsFixed(1)}%',
                                style: AppText.display(40)),
                            const SizedBox(height: 12),
                            _AccuracyBar(perfect: perfect, good: good, weak: weak),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _Legend(
                                    color: Palette.steady,
                                    label: 'Perfect',
                                    value: perfect),
                                _Legend(
                                    color: Palette.gold,
                                    label: 'Good',
                                    value: good),
                                _Legend(
                                    color: Palette.danger,
                                    label: 'Weak',
                                    value: weak),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Grid of headline numbers
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.7,
                        children: [
                          _StatTile(
                              icon: Icons.replay_rounded,
                              label: 'Total runs',
                              value: '${ProgressStore.totalRuns}'),
                          _StatTile(
                              icon: Icons.flag_rounded,
                              label: 'Summits',
                              value: '${ProgressStore.summits}'),
                          _StatTile(
                              icon: Icons.bolt_rounded,
                              label: 'Best combo',
                              value: '${ProgressStore.bestCombo}'),
                          _StatTile(
                              icon: Icons.touch_app_rounded,
                              label: 'Total strikes',
                              value: '${ProgressStore.totalStrikes}'),
                          _StatTile(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Embers earned',
                              value: '${ProgressStore.embersEarned}'),
                          _StatTile(
                              icon: Icons.star_rounded,
                              label: 'Stars',
                              value:
                                  '${ProgressStore.totalStars()} / ${Peaks.count * 3 * Difficulty.values.length}'),
                          _StatTile(
                              icon: Icons.emoji_events_rounded,
                              label: 'Achievements',
                              value: '$unlockedAch / ${Achievements.all.length}'),
                          _StatTile(
                              icon: Icons.menu_book_rounded,
                              label: 'Codex found',
                              value: '$codexFound'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccuracyBar extends StatelessWidget {
  const _AccuracyBar(
      {required this.perfect, required this.good, required this.weak});

  final int perfect;
  final int good;
  final int weak;

  @override
  Widget build(BuildContext context) {
    final total = (perfect + good + weak).clamp(1, 1 << 30);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            Expanded(
                flex: (perfect / total * 1000).round().clamp(0, 1000),
                child: const ColoredBox(color: Palette.steady)),
            Expanded(
                flex: (good / total * 1000).round().clamp(0, 1000),
                child: const ColoredBox(color: Palette.gold)),
            Expanded(
                flex: (weak / total * 1000).round().clamp(0, 1000),
                child: const ColoredBox(color: Palette.danger)),
            if (perfect + good + weak == 0)
              const Expanded(child: ColoredBox(color: Colors.white12)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label  $value',
            style: AppText.label(11, color: Colors.white70, spacing: 0.5)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.ember.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Palette.gold, size: 20),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.title(18, color: Palette.gold)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: AppText.label(9, color: Palette.ember, spacing: 1)),
        ],
      ),
    );
  }
}
