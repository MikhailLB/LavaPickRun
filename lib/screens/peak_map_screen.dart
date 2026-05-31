import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/peaks.dart';
import '../data/progress_store.dart';
import '../engine/ascent_engine.dart';
import '../engine/models.dart';
import '../state/store.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';
import '../ui/widgets/ember_chip.dart';

/// Level select, redesigned as a vertical climbing trail. Peaks rise from the
/// base (bottom) to the summit (top), connected by a glowing route, with a
/// difficulty selector that re-skins the whole trail and its star records.
class PeakMapScreen extends StatefulWidget {
  const PeakMapScreen({super.key});

  @override
  State<PeakMapScreen> createState() => _PeakMapScreenState();
}

class _PeakMapScreenState extends State<PeakMapScreen> {
  late AscentEngine _engine;
  Difficulty _selected = Difficulty.normal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _engine = context.read<AscentEngine>();
    // Default to the hardest tier the player has unlocked.
    for (final d in Difficulty.values) {
      if (ProgressStore.difficultyUnlocked(d)) _selected = d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ProgressStore.difficultyUnlocked(_selected);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/3_bg_asset.webp', darken: 0.62),
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
                      Expanded(child: Text('THE ROUTE', style: AppText.display(20))),
                      ListenableBuilder(
                        listenable: _engine,
                        builder: (context, _) =>
                            EmberChip(amount: _engine.embers, compact: true),
                      ),
                    ],
                  ),
                ),
                _DifficultyBar(
                  selected: _selected,
                  onSelect: (d) {
                    if (ProgressStore.difficultyUnlocked(d)) {
                      setState(() => _selected = d);
                    }
                  },
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _engine,
                    builder: (context, _) {
                      return Stack(
                        children: [
                          ListView.builder(
                            // reverse: base of the mountain at the bottom.
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
                            itemCount: Peaks.count,
                            itemBuilder: (context, i) {
                              final peak = Peaks.all[i];
                              final isUnlocked =
                                  unlocked && _engine.isPeakUnlocked(i);
                              return _TrailNode(
                                peak: peak,
                                leftSide: i.isEven,
                                stars: ProgressStore.stars(i, _selected),
                                unlocked: isUnlocked,
                                isSummit: i == Peaks.count - 1,
                                onTap: isUnlocked
                                    ? () {
                                        _engine.startRun(i,
                                            difficulty: _selected);
                                        Navigator.of(context).pushNamed(
                                            Routes.ascent,
                                            arguments: i);
                                      }
                                    : null,
                              );
                            },
                          ),
                          if (!unlocked)
                            Positioned(
                              left: 24,
                              right: 24,
                              bottom: 24,
                              child: _LockedBanner(difficulty: _selected),
                            ),
                        ],
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

class _DifficultyBar extends StatelessWidget {
  const _DifficultyBar({required this.selected, required this.onSelect});

  final Difficulty selected;
  final ValueChanged<Difficulty> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final d in Difficulty.values) ...[
            Expanded(
              child: _DiffTab(
                difficulty: d,
                selected: d == selected,
                unlocked: ProgressStore.difficultyUnlocked(d),
                onTap: () => onSelect(d),
              ),
            ),
            if (d != Difficulty.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _DiffTab extends StatelessWidget {
  const _DiffTab({
    required this.difficulty,
    required this.selected,
    required this.unlocked,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool selected;
  final bool unlocked;
  final VoidCallback onTap;

  Color get _accent => switch (difficulty) {
        Difficulty.normal => Palette.ember,
        Difficulty.hard => Palette.emberHot,
        Difficulty.inferno => Palette.danger,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.6)])
              : null,
          color: selected ? null : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Palette.gold : _accent.withValues(alpha: 0.45),
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(Icons.lock,
                    size: 12, color: Colors.white.withValues(alpha: 0.7)),
              ),
            Text(
              difficulty.short,
              style: AppText.label(11,
                  color: selected ? Colors.white : Colors.white70, spacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({required this.difficulty});
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final prev =
        difficulty == Difficulty.inferno ? 'Hard' : 'Normal';
    return GlassPanel(
      glow: true,
      accent: Palette.danger,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Palette.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Clear every peak on $prev to unlock ${difficulty.label}.',
              style: AppText.body(13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailNode extends StatelessWidget {
  const _TrailNode({
    required this.peak,
    required this.leftSide,
    required this.stars,
    required this.unlocked,
    required this.isSummit,
    this.onTap,
  });

  final Peak peak;
  final bool leftSide;
  final int stars;
  final bool unlocked;
  final bool isSummit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Stack(
        children: [
          // Route spine.
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Palette.ember.withValues(alpha: unlocked ? 0.7 : 0.2),
                    Palette.emberHot.withValues(alpha: unlocked ? 0.5 : 0.15),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: leftSide ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.62,
              child: _NodeCard(
                peak: peak,
                stars: stars,
                unlocked: unlocked,
                isSummit: isSummit,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.peak,
    required this.stars,
    required this.unlocked,
    required this.isSummit,
    this.onTap,
  });

  final Peak peak;
  final int stars;
  final bool unlocked;
  final bool isSummit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unlocked
                ? (isSummit ? Palette.gold : Palette.ember)
                : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: (isSummit ? Palette.gold : Palette.emberHot)
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(peak.backdrop, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: Image.asset(peak.sprite, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isSummit)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.flag,
                                      size: 12, color: Palette.gold),
                                ),
                              Text('PEAK ${peak.displayNumber}',
                                  style: AppText.label(9,
                                      color: Palette.ember, spacing: 1.2)),
                            ],
                          ),
                          Text(peak.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title(14)),
                          const SizedBox(height: 4),
                          if (unlocked)
                            StarRow(stars: stars, size: 15)
                          else
                            Row(
                              children: [
                                Icon(Icons.lock,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Text('Locked',
                                    style: AppText.label(10,
                                        color: Colors.white60, spacing: 1)),
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
                          color: Palette.emberHot.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Palette.gold, width: 1.4),
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
    );
  }
}
