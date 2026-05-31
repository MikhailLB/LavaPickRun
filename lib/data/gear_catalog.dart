import 'package:flutter/foundation.dart';

/// Permanent, skill-shaping gear bought with Embers between runs.
///
/// Unlike the previous build's damage-multiplier shop, none of these make the
/// game play itself — they widen the margin for skill (bigger perfect band,
/// slower heat, an extra life, faster recovery). The player still has to land
/// the timing and read the eruptions.
enum GearId {
  steadyHands, // wider perfect band
  heatSink, // slower heat build / faster cooling
  bulwark, // extra stability (lives)
  quickVent, // shorter overheat lockout
  momentumCore, // stronger combo scaling
  emberKnack, // more embers earned
  focusLens, // slows the marker a touch — more reading time
}

@immutable
class GearTier {
  const GearTier({required this.cost, required this.label});
  final int cost;
  final String label;
}

@immutable
class GearDef {
  const GearDef({
    required this.id,
    required this.name,
    required this.glyph,
    required this.blurb,
    required this.tiers,
  });

  final GearId id;
  final String name;
  final String glyph;
  final String blurb;
  final List<GearTier> tiers;

  int get maxTier => tiers.length;
}

class GearCatalog {
  GearCatalog._();

  static int _cost(int base, double growth, int tier) =>
      (base * _pow(growth, tier)).round();

  static double _pow(double b, int e) {
    var r = 1.0;
    for (var i = 0; i < e; i++) {
      r *= b;
    }
    return r;
  }

  static final List<GearDef> all = [
    GearDef(
      id: GearId.steadyHands,
      name: 'Steady Hands',
      glyph: '🤚',
      blurb: 'Widens the perfect band so clean strikes land easier.',
      tiers: List.generate(5, (i) {
        return GearTier(
          cost: _cost(120, 1.9, i),
          label: 'Perfect band +${(i + 1) * 12}%',
        );
      }),
    ),
    GearDef(
      id: GearId.heatSink,
      name: 'Heat Sink',
      glyph: '❄️',
      blurb: 'Strikes add less heat and the core cools faster.',
      tiers: List.generate(5, (i) {
        return GearTier(
          cost: _cost(150, 2.0, i),
          label: 'Heat −${(i + 1) * 9}%, cooling +${(i + 1) * 10}%',
        );
      }),
    ),
    GearDef(
      id: GearId.bulwark,
      name: 'Bulwark',
      glyph: '🛡️',
      blurb: 'Reinforces stability — one extra mistake per run.',
      tiers: List.generate(3, (i) {
        return GearTier(
          cost: _cost(400, 2.6, i),
          label: '+${i + 1} stability',
        );
      }),
    ),
    GearDef(
      id: GearId.quickVent,
      name: 'Quick Vent',
      glyph: '💨',
      blurb: 'Recover from an overheat lockout faster.',
      tiers: List.generate(5, (i) {
        return GearTier(
          cost: _cost(180, 1.85, i),
          label: 'Vent recovery +${(i + 1) * 12}%',
        );
      }),
    ),
    GearDef(
      id: GearId.momentumCore,
      name: 'Momentum Core',
      glyph: '🔥',
      blurb: 'Combos build a stronger ascent multiplier.',
      tiers: List.generate(5, (i) {
        return GearTier(
          cost: _cost(220, 2.0, i),
          label: 'Momentum cap +${(i + 1) * 2}, scaling +${(i + 1) * 8}%',
        );
      }),
    ),
    GearDef(
      id: GearId.emberKnack,
      name: 'Ember Knack',
      glyph: '✨',
      blurb: 'Earn more Embers from every clean strike.',
      tiers: List.generate(5, (i) {
        return GearTier(
          cost: _cost(160, 1.95, i),
          label: 'Embers +${(i + 1) * 15}%',
        );
      }),
    ),
    GearDef(
      id: GearId.focusLens,
      name: 'Focus Lens',
      glyph: '🎯',
      blurb: 'Slows the marker slightly, giving you more time to read it.',
      tiers: List.generate(4, (i) {
        return GearTier(
          cost: _cost(260, 2.1, i),
          label: 'Marker speed −${(i + 1) * 4}%',
        );
      }),
    ),
  ];

  static GearDef byId(GearId id) => all.firstWhere((g) => g.id == id);
}
