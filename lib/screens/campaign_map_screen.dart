import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/levels.dart';
import '../data/progress_store.dart';
import '../engine/ascent_engine.dart';
import '../engine/models.dart';
import '../state/store.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';
import '../ui/widgets/ember_chip.dart';

/// The campaign — a single linear ladder of 70 levels. Level 1 sits at the
/// bottom; progress climbs upward. New mechanics unlock as you ascend.
class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({super.key});

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
  late AscentEngine _engine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _engine = context.read<AscentEngine>();
  }

  void _open(LevelDef def) {
    if (def.isFlow) {
      Navigator.of(context)
          .pushNamed(Routes.flow, arguments: def.index)
          .then((_) => setState(() {}));
      return;
    }
    _engine.startLevel(def);
    Navigator.of(context)
        .pushNamed(Routes.ascent)
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ProgressStore.campaignUnlocked;
    final cleared = ProgressStore.levelsCleared();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/3_bg_asset.webp', darken: 0.64),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CAMPAIGN', style: AppText.display(20)),
                            Text('$cleared / ${Levels.count} cleared',
                                style: AppText.label(10,
                                    color: Palette.ember, spacing: 1.2)),
                          ],
                        ),
                      ),
                      ListenableBuilder(
                        listenable: _engine,
                        builder: (context, _) =>
                            EmberChip(amount: _engine.embers, compact: true),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                    itemCount: Levels.count,
                    itemBuilder: (context, i) {
                      final def = Levels.all[i];
                      final isUnlocked = i <= unlocked;
                      return _LevelRow(
                        def: def,
                        stars: ProgressStore.levelStars(i),
                        unlocked: isUnlocked,
                        onTap: isUnlocked ? () => _open(def) : null,
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

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.def,
    required this.stars,
    required this.unlocked,
    this.onTap,
  });

  final LevelDef def;
  final int stars;
  final bool unlocked;
  final VoidCallback? onTap;

  String get _tag {
    if (def.isFlow) return 'LAVA FLOW PUZZLE';
    final parts = <String>[];
    if (def.trial != PeakTrial.steady) parts.add(def.trial.label);
    for (final m in def.mods) {
      parts.add(ascentModLabel(m));
    }
    if (parts.isEmpty) parts.add('Strike the Band');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        def.isFlow ? Palette.cool : (unlocked ? Palette.ember : Colors.white24);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: unlocked ? 1 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.6),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                          color: accent.withValues(alpha: 0.25), blurRadius: 12),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(def.backdrop, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.45)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.85),
                            border: Border.all(color: Colors.white, width: 1.4),
                          ),
                          child: Text('${def.displayNumber}',
                              style: AppText.title(16, color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                      def.isFlow
                                          ? Icons.water_drop_rounded
                                          : Icons.whatshot_rounded,
                                      size: 11,
                                      color: accent),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(_tag.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.label(9,
                                            color: accent, spacing: 0.8)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              if (unlocked && !def.isFlow)
                                StarRow(stars: stars, size: 14)
                              else if (unlocked && def.isFlow)
                                Text(
                                    stars > 0 ? 'SOLVED' : 'TAP TO SOLVE',
                                    style: AppText.label(10,
                                        color: Palette.cool, spacing: 1))
                              else
                                Row(
                                  children: [
                                    const Icon(Icons.lock,
                                        size: 12, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text('Locked',
                                        style: AppText.label(10,
                                            color: Colors.white54, spacing: 1)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (unlocked)
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.2),
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
