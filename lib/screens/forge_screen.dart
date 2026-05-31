import 'package:flutter/material.dart';

import '../data/gear_catalog.dart';
import '../engine/ascent_engine.dart';
import '../state/store.dart';
import '../ui/painters/ember_icon.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';
import '../ui/widgets/ember_chip.dart';

/// The Forge: spend Embers on permanent, skill-shaping gear.
class ForgeScreen extends StatelessWidget {
  const ForgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.read<AscentEngine>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(asset: 'assets/Assets/4_bg_asset.webp', darken: 0.6),
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
                      Expanded(child: Text('THE FORGE', style: AppText.display(22))),
                      ListenableBuilder(
                        listenable: engine,
                        builder: (context, _) =>
                            EmberChip(amount: engine.embers, compact: true),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Text(
                    'Gear sharpens your skill — it never plays for you.',
                    style: AppText.body(12),
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: engine,
                    builder: (context, _) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: GearCatalog.all.length,
                        itemBuilder: (context, i) =>
                            _GearTile(def: GearCatalog.all[i], engine: engine),
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

class _GearTile extends StatelessWidget {
  const _GearTile({required this.def, required this.engine});

  final GearDef def;
  final AscentEngine engine;

  @override
  Widget build(BuildContext context) {
    final tier = engine.gearTier(def.id);
    final maxed = tier >= def.maxTier;
    final next = maxed ? null : def.tiers[tier];
    final affordable = !maxed && engine.canAfford(def.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        accent: maxed ? Palette.gold : Palette.ember.withValues(alpha: 0.6),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Palette.ember.withValues(alpha: 0.5), width: 1.4),
              ),
              child: Text(def.glyph, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(def.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title(15, color: Palette.gold)),
                      ),
                      const SizedBox(width: 6),
                      _TierPips(current: tier, max: def.maxTier),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    maxed ? def.blurb : (next?.label ?? def.blurb),
                    style: AppText.body(11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (maxed)
              _Pill(text: 'MAX', color: Palette.gold)
            else
              _BuyButton(
                cost: next!.cost,
                affordable: affordable,
                onTap: affordable ? () => engine.buyGear(def.id) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton(
      {required this.cost, required this.affordable, this.onTap});

  final int cost;
  final bool affordable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: affordable
              ? const LinearGradient(
                  colors: [Palette.ember, Palette.emberHot])
              : null,
          color: affordable ? null : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: affordable ? Palette.gold : Colors.grey.withValues(alpha: 0.3),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmberIcon(size: 16),
            const SizedBox(width: 4),
            Text(EmberChip.format(cost),
                style: AppText.label(13,
                    color: affordable ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(text, style: AppText.label(12, color: color)),
    );
  }
}

class _TierPips extends StatelessWidget {
  const _TierPips({required this.current, required this.max});
  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < current
                ? Palette.gold
                : Colors.grey.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}
