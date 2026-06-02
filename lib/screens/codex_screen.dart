import 'package:flutter/material.dart';

import '../data/codex.dart';
import '../data/progress_store.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';

/// The Volcano Codex screen — a scrollable collection of real-world volcano
/// entries. Locked entries are blurred placeholders; reaching new summits
/// reveals the next card.
class CodexScreen extends StatelessWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = ProgressStore.unlockedCodex();
    final found = unlocked.length;
    final total = Codex.all.length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/2_bg_asset.webp', darken: 0.66),
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
                          child: Text('VOLCANO CODEX',
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
                        child: Text('$found / $total',
                            style: AppText.title(15, color: Palette.gold)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                  child: Text(
                    'Reach new summits to uncover real volcanoes from around '
                    'the world.',
                    style: AppText.body(12),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: Codex.all.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final entry = Codex.all[i];
                      return _CodexCard(
                        entry: entry,
                        index: i,
                        unlocked: unlocked.contains(entry.id),
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

class _CodexCard extends StatelessWidget {
  const _CodexCard(
      {required this.entry, required this.index, required this.unlocked});

  final CodexEntry entry;
  final int index;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white24, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Entry #${index + 1} — locked',
                  style: AppText.title(15, color: Colors.white38)),
            ),
            Text('Summit ${index + 1}',
                style: AppText.label(10, color: Colors.white38, spacing: 1)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.charcoal, Palette.ink],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.ember.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Palette.emberHot.withValues(alpha: 0.18),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terrain_rounded, color: Palette.gold, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: AppText.title(18)),
                    Text(entry.location,
                        style: AppText.label(10,
                            color: Palette.ember, spacing: 1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: 'Elevation', value: entry.elevation),
              _Chip(label: 'Type', value: entry.type),
              _Chip(label: 'Last eruption', value: entry.lastEruption),
            ],
          ),
          const SizedBox(height: 12),
          Text(entry.fact, style: AppText.body(13)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.ember.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: AppText.label(8, color: Palette.ember, spacing: 1)),
          const SizedBox(height: 2),
          Text(value, style: AppText.label(12, color: Colors.white)),
        ],
      ),
    );
  }
}
