import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../data/progress_store.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';

/// Grid of every achievement with locked / unlocked state, plus a progress
/// header. Pure read from [ProgressStore].
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = ProgressStore.unlockedAchievements();
    final total = Achievements.all.length;
    final done = Achievements.all.where((a) => unlocked.contains(a.id)).length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/5_bg_asset.webp', darken: 0.62),
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
                          child: Text('ACHIEVEMENTS',
                              style: AppText.display(20))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Palette.gold.withValues(alpha: 0.5)),
                        ),
                        child: Text('$done / $total',
                            style: AppText.title(15, color: Palette.gold)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: Achievements.all.length,
                    itemBuilder: (context, i) {
                      final a = Achievements.all[i];
                      return _AchievementCard(
                        def: a,
                        unlocked: unlocked.contains(a.id),
                      );
                    },
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

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.def, required this.unlocked});

  final AchievementDef def;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final accent = unlocked ? Palette.gold : Colors.white24;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: unlocked
              ? [Palette.charcoal, Palette.ink]
              : [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.35),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.4),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: Palette.emberHot.withValues(alpha: 0.25),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Icon(def.icon,
                    color: unlocked ? Palette.gold : Colors.white30, size: 22),
              ),
              const Spacer(),
              Icon(
                unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                size: 18,
                color: unlocked ? Palette.steady : Colors.white24,
              ),
            ],
          ),
          const Spacer(),
          Text(def.title,
              style: AppText.title(15,
                  color: unlocked ? Palette.gold : Colors.white54)),
          const SizedBox(height: 4),
          Text(def.detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(11,
                  color: unlocked ? null : Colors.white38)),
        ],
      ),
    );
  }
}
