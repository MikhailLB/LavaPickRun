import 'dart:math';

enum UpgradeId {
  // Core perks (always unlocked)
  damageUp,
  doubleTap,
  critChance,
  critMultiplier,
  tapFrenzy,
  lavaSurge,
  // Level-locked perks
  goldRush,    // Level 2
  pyroclasm,   // Level 3
  titanGrip,   // Level 5
  apocalypse,  // Level 7
  // Easter egg
  cursedSkull, // Any level, single purchase
}

class UpgradeTier {
  final int cost;
  final String description;

  const UpgradeTier({required this.cost, required this.description});
}

class UpgradeDefinition {
  final UpgradeId id;
  final String name;
  final String icon;
  final List<UpgradeTier> tiers;
  final int requiredLevel; // 1 = always visible
  final bool isEasterEgg;
  final bool isActive; // active skill vs passive

  const UpgradeDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.tiers,
    this.requiredLevel = 1,
    this.isEasterEgg = false,
    this.isActive = false,
  });

  static int _cost(int base, double mult, int tier) =>
      (base * pow(mult, tier)).round();

  // ── 20 tiers, cost = base × mult^tier ─────────────────────────────
  static List<UpgradeTier> _damageUpTiers() {
    return List.generate(20, (i) {
      final cost = _cost(1000, 2.8, i);
      final mult = pow(1.35, i + 1);
      final dmg = (15 * mult).round();
      return UpgradeTier(
        cost: cost,
        description: 'Damage ×${mult.toStringAsFixed(1)}  →  $dmg',
      );
    });
  }

  static List<UpgradeTier> _multiStrikeTiers() {
    return List.generate(10, (i) {
      final cost = _cost(3000, 3.5, i);
      final hits = i + 2;
      return UpgradeTier(
        cost: cost,
        description: '$hits hits per tap',
      );
    });
  }

  static List<UpgradeTier> _critChanceTiers() {
    return List.generate(12, (i) {
      final cost = _cost(500, 2.8, i);
      final pct = (i + 1) * 5;
      return UpgradeTier(
        cost: cost,
        description: '$pct% crit chance',
      );
    });
  }

  static List<UpgradeTier> _critPowerTiers() {
    return List.generate(15, (i) {
      final cost = _cost(2000, 2.8, i);
      final mult = 1.3 + i * 0.25;
      return UpgradeTier(
        cost: cost,
        description: 'Crits deal ×${mult.toStringAsFixed(2)}',
      );
    });
  }

  static List<UpgradeTier> _tapFrenzyTiers() {
    return List.generate(12, (i) {
      final cost = _cost(5000, 3.0, i);
      final duration = 4 + (i ~/ 2);
      final dmgMult = (2.0 + i * 0.3).toStringAsFixed(1);
      final cd = 30 - (i * 1.5).floor().clamp(0, 18);
      return UpgradeTier(
        cost: cost,
        description: '${duration}s burst ×$dmgMult dmg  (${cd}s cd)',
      );
    });
  }

  static List<UpgradeTier> _lavaSurgeTiers() {
    return List.generate(10, (i) {
      final cost = _cost(2000, 3.2, i);
      const rates = [0.3, 0.6, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0];
      return UpgradeTier(
        cost: cost,
        description: 'Auto-tap ${rates[i]}/sec',
      );
    });
  }

  // ── Level 2: Gold Rush (active) ─────────────────────────────────
  static List<UpgradeTier> _goldRushTiers() {
    return List.generate(8, (i) {
      final cost = _cost(5000, 4.0, i);
      final duration = 8 + i * 2;
      final cd = (60 - i * 5).clamp(25, 60);
      return UpgradeTier(
        cost: cost,
        description: '${duration}s ×2 coins  (${cd}s cd)',
      );
    });
  }

  // ── Level 3: Pyroclasm (passive) ─────────────────────────────────
  // Every N taps → mega hit ×M
  static List<UpgradeTier> _pyroclasmTiers() {
    return List.generate(10, (i) {
      final cost = _cost(20000, 4.0, i);
      final every = (30 - i * 1.5).floor().clamp(12, 30);
      final mult = 15 + i * 10;
      return UpgradeTier(
        cost: cost,
        description: 'Every $every taps → ×$mult PYROCLASM hit',
      );
    });
  }

  // ── Level 5: Titan's Grip (passive) ────────────────────────────
  // ×2 base damage per tier, very expensive
  static List<UpgradeTier> _titanGripTiers() {
    return List.generate(8, (i) {
      final cost = _cost(500000, 5.0, i);
      final mult = pow(2, i + 1).toInt();
      return UpgradeTier(
        cost: cost,
        description: 'All damage ×$mult permanently',
      );
    });
  }

  // ── Level 7: Apocalypse (active) ───────────────────────────────
  // Instantly deal X% of boss max HP as damage
  static List<UpgradeTier> _apocalypseTiers() {
    return List.generate(5, (i) {
      final cost = _cost(10000000, 4.0, i);
      final pct = 5 + i * 5;
      return UpgradeTier(
        cost: cost,
        description: 'Deal $pct% of boss HP instantly (120s cd)',
      );
    });
  }

  // ── Easter egg: Cursed Skull ────────────────────────────────────
  static List<UpgradeTier> _cursedSkullTiers() {
    return [
      const UpgradeTier(
        cost: 5000000,
        description: 'Every 60 taps → 5 CURSED strikes at ×200 dmg',
      ),
    ];
  }

  // ── Master list ─────────────────────────────────────────────────
  static late final List<UpgradeDefinition> all;

  static void init() {
    all = [
      UpgradeDefinition(
        id: UpgradeId.damageUp,
        name: 'Damage Up',
        icon: '⚡',
        tiers: _damageUpTiers(),
      ),
      UpgradeDefinition(
        id: UpgradeId.doubleTap,
        name: 'Multi-Strike',
        icon: '✌️',
        tiers: _multiStrikeTiers(),
      ),
      UpgradeDefinition(
        id: UpgradeId.critChance,
        name: 'Crit Chance',
        icon: '🎯',
        tiers: _critChanceTiers(),
      ),
      UpgradeDefinition(
        id: UpgradeId.critMultiplier,
        name: 'Crit Power',
        icon: '💥',
        tiers: _critPowerTiers(),
      ),
      UpgradeDefinition(
        id: UpgradeId.tapFrenzy,
        name: 'Tap Frenzy',
        icon: '🔥',
        tiers: _tapFrenzyTiers(),
        isActive: true,
      ),
      UpgradeDefinition(
        id: UpgradeId.lavaSurge,
        name: 'Lava Surge',
        icon: '🌋',
        tiers: _lavaSurgeTiers(),
      ),
      UpgradeDefinition(
        id: UpgradeId.goldRush,
        name: 'Gold Rush',
        icon: '🪙',
        tiers: _goldRushTiers(),
        requiredLevel: 2,
        isActive: true,
      ),
      UpgradeDefinition(
        id: UpgradeId.pyroclasm,
        name: 'Pyroclasm',
        icon: '🌊',
        tiers: _pyroclasmTiers(),
        requiredLevel: 3,
      ),
      UpgradeDefinition(
        id: UpgradeId.titanGrip,
        name: "Titan's Grip",
        icon: '👊',
        tiers: _titanGripTiers(),
        requiredLevel: 5,
      ),
      UpgradeDefinition(
        id: UpgradeId.apocalypse,
        name: 'APOCALYPSE',
        icon: '☄️',
        tiers: _apocalypseTiers(),
        requiredLevel: 7,
        isActive: true,
      ),
      UpgradeDefinition(
        id: UpgradeId.cursedSkull,
        name: 'Cursed Skull',
        icon: '💀',
        tiers: _cursedSkullTiers(),
        isEasterEgg: true,
      ),
    ];
  }
}
