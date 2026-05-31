import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/peaks.dart';
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
    final hasNext = peak.index + 1 < Peaks.count;

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
                              '${peak.name.toUpperCase()} · ${engine.difficulty.label.toUpperCase()}',
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
                              label: 'NEXT PEAK',
                              icon: Icons.arrow_upward,
                              primary: true,
                              onTap: () => _go(context, engine, peak.index + 1),
                            ),
                          if (won && hasNext) const SizedBox(height: 10),
                          EmberButton(
                            label: won ? 'CLIMB AGAIN' : 'RETRY',
                            icon: Icons.refresh,
                            primary: !(won && hasNext),
                            onTap: () => _go(context, engine, peak.index),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: EmberButton(
                                  label: 'Peaks',
                                  icon: Icons.map_outlined,
                                  compact: true,
                                  onTap: () => Navigator.of(context)
                                      .pushNamedAndRemoveUntil(
                                          Routes.peaks,
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

  void _go(BuildContext context, AscentEngine engine, int peakIndex) {
    engine.startRun(peakIndex, difficulty: engine.difficulty);
    Navigator.of(context)
        .pushReplacementNamed(Routes.ascent, arguments: peakIndex);
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
