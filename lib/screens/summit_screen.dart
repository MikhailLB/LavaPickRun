import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/levels.dart';
import '../engine/ascent_engine.dart';
import '../engine/models.dart';
import '../state/store.dart';
import '../ui/painters/ember_icon.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';
import '../ui/widgets/ember_chip.dart';

/// Outcome screen shown after a run, for both a summit and a collapse.
class SummitScreen extends StatefulWidget {
  const SummitScreen({super.key});

  @override
  State<SummitScreen> createState() => _SummitScreenState();
}

class _SummitScreenState extends State<SummitScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.read<AscentEngine>();
    final peak = engine.peak;
    final won = engine.phase == RunPhase.summit;
    final levelIndex = engine.currentLevelIndex;
    final hasNext = levelIndex + 1 < Levels.count;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          BackdropLayer(asset: peak.backdrop, darken: 0.55),
          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _in, curve: Curves.easeOutBack),
                child: FadeTransition(
                  opacity: _in,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: GlassPanel(
                      glow: true,
                      accent: won ? Palette.gold : Palette.emberDeep,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            won ? Icons.emoji_events : Icons.whatshot,
                            size: 56,
                            color: won ? Palette.gold : Palette.danger,
                          ),
                          const SizedBox(height: 10),
                          Text(won ? 'SUMMIT!' : 'COLLAPSE',
                              style: AppText.display(34)),
                          const SizedBox(height: 4),
                          Text(
                              'LEVEL ${levelIndex + 1} · ${peak.subtitle.toUpperCase()}',
                              textAlign: TextAlign.center,
                              style: AppText.label(12,
                                  color: Palette.ember, spacing: 2)),
                          const SizedBox(height: 16),
                          if (won) ...[
                            ScaleTransition(
                              scale: CurvedAnimation(
                                  parent: _in, curve: Curves.elasticOut),
                              child: StarRow(stars: engine.starsEarned, size: 42),
                            ),
                            const SizedBox(height: 8),
                            _ObjectiveLine(
                              done: true,
                              text: 'Reach the summit',
                            ),
                            _ObjectiveLine(
                              done: engine.burns == 0,
                              text: 'No eruption burns',
                            ),
                            _ObjectiveLine(
                              done: engine.maxCombo >= engine.comboGoal,
                              text:
                                  'Reach a ${engine.comboGoal} combo (best ${engine.maxCombo})',
                            ),
                            const SizedBox(height: 14),
                          ] else ...[
                            const SizedBox(height: 4),
                            _ResultRow(
                              label: 'Ascent reached',
                              value: '${(engine.ascent * 100).round()}%',
                            ),
                            const SizedBox(height: 10),
                          ],
                          _RunBreakdown(engine: engine),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Palette.gold.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                EmberIcon(size: 26),
                                const SizedBox(width: 10),
                                Text('+${EmberChip.format(engine.earnedThisRun)}',
                                    style: AppText.display(24)),
                                const SizedBox(width: 6),
                                Text('embers',
                                    style: AppText.label(12,
                                        color: Colors.white70)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (won && hasNext)
                            EmberButton(
                              label: 'NEXT LEVEL',
                              icon: Icons.arrow_upward,
                              primary: true,
                              onTap: () => _go(context, engine, levelIndex + 1),
                            ),
                          if (won && hasNext) const SizedBox(height: 10),
                          EmberButton(
                            label: won ? 'PLAY AGAIN' : 'RETRY',
                            icon: Icons.refresh,
                            primary: !(won && hasNext),
                            onTap: () => _go(context, engine, levelIndex),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: EmberButton(
                                  label: 'Levels',
                                  icon: Icons.map_outlined,
                                  compact: true,
                                  onTap: () => Navigator.of(context)
                                      .pushNamedAndRemoveUntil(
                                          Routes.campaign,
                                          (r) => r.settings.name == Routes.home),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: EmberButton(
                                  label: 'Forge',
                                  icon: Icons.handyman,
                                  compact: true,
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(Routes.forge),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, AscentEngine engine, int levelIndex) {
    engine.startLevel(Levels.byIndex(levelIndex));
    Navigator.of(context).pushReplacementNamed(Routes.ascent);
  }
}

class _RunBreakdown extends StatelessWidget {
  const _RunBreakdown({required this.engine});
  final AscentEngine engine;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String value, Color color) => Column(
          children: [
            Text(value, style: AppText.title(16, color: color)),
            Text(label,
                style: AppText.label(8, color: Colors.white60, spacing: 1)),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.ember.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          chip('PERFECT', '${engine.perfectCount}', Palette.steady),
          chip('GOOD', '${engine.goodCount}', Palette.gold),
          chip('WEAK', '${engine.weakCount}', Palette.danger),
          chip('STREAK', '${engine.bestStreakThisRun}', Palette.cream),
        ],
      ),
    );
  }
}

class _ObjectiveLine extends StatelessWidget {
  const _ObjectiveLine({required this.done, required this.text});
  final bool done;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: done ? Palette.steady : Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: AppText.body(12,
                    color: done ? Colors.white : Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.body(14)),
        Text(value, style: AppText.title(18, color: Palette.gold)),
      ],
    );
  }
}
