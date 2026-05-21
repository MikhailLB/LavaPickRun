class LevelConfig {
  final int level;
  final int maxHp;
  final double coinMultiplier;
  final String bgAsset;
  final String volcanoAsset;
  final String name;

  const LevelConfig({
    required this.level,
    required this.maxHp,
    required this.coinMultiplier,
    required this.bgAsset,
    required this.volcanoAsset,
    required this.name,
  });

  // Progression target (full upgrades on each level):
  //   L1 → ~20 min     L4 → ~45 min
  //   L2 → ~25 min     L5 → ~60 min
  //   L3 → ~35 min     L6/L7 → hours
  static const List<LevelConfig> levels = [
    LevelConfig(
      level: 1,
      maxHp: 300000,
      coinMultiplier: 0.06,
      bgAsset: 'assets/Assets/1_bg_asset.webp',
      volcanoAsset: 'assets/Assets/1_volcano_asset.webp',
      name: 'Ember Peak',
    ),
    LevelConfig(
      level: 2,
      maxHp: 2000000,
      coinMultiplier: 0.07,
      bgAsset: 'assets/Assets/2_bg_asset.webp',
      volcanoAsset: 'assets/Assets/2_volcano_asset.webp',
      name: 'Magma Ridge',
    ),
    LevelConfig(
      level: 3,
      maxHp: 15000000,
      coinMultiplier: 0.08,
      bgAsset: 'assets/Assets/3_bg_asset.webp',
      volcanoAsset: 'assets/Assets/3_volcano_asset.webp',
      name: 'Cinder Dome',
    ),
    LevelConfig(
      level: 4,
      maxHp: 100000000,
      coinMultiplier: 0.09,
      bgAsset: 'assets/Assets/4_bg_asset.webp',
      volcanoAsset: 'assets/Assets/4_volcano_asset.webp',
      name: 'Inferno Summit',
    ),
    LevelConfig(
      level: 5,
      maxHp: 700000000,
      coinMultiplier: 0.10,
      bgAsset: 'assets/Assets/5_bg_asset.webp',
      volcanoAsset: 'assets/Assets/5_volcano_asset.webp',
      name: 'Pyroclast Spire',
    ),
    LevelConfig(
      level: 6,
      maxHp: 5000000000,
      coinMultiplier: 0.11,
      bgAsset: 'assets/Assets/6_bg_asset.webp',
      volcanoAsset: 'assets/Assets/6_volcano_asset.webp',
      name: 'Molten Throne',
    ),
    LevelConfig(
      level: 7,
      maxHp: 40000000000,
      coinMultiplier: 0.12,
      bgAsset: 'assets/Assets/7_bg_asset.webp',
      volcanoAsset: 'assets/Assets/7_volcano_asset.webp',
      name: 'Lava Peak',
    ),
  ];
}
