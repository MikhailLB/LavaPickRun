import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'level_config.dart';
import 'upgrade.dart';
import '../services/save_service.dart';

enum DamageEventType { normal, crit, pyroclasm, curse, apocalypse }

class DamageEvent {
  final Offset position;
  final int damage;
  final DamageEventType type;
  final int id;

  DamageEvent({
    required this.position,
    required this.damage,
    required this.type,
    required this.id,
  });

  bool get isCrit => type == DamageEventType.crit;
}

class GameState extends ChangeNotifier {
  int _coins = 0;
  int _unlockedLevels = 1;
  Map<UpgradeId, int> _upgradeTiers = {};

  int _currentLevelIndex = 0;
  int _currentHp = 0;
  int _maxHp = 0;
  bool _levelComplete = false;

  // ── Active skill states ──────────────────────────────────────────
  bool _frenzyActive = false;
  int _frenzySecondsLeft = 0;
  int _frenzyCooldownLeft = 0;

  bool _goldRushActive = false;
  int _goldRushSecondsLeft = 0;
  int _goldRushCooldownLeft = 0;

  int _apocalypseCooldownLeft = 0;

  // ── Pyroclasm counter ────────────────────────────────────────────
  int _tapCounter = 0;

  // ── Cursed Skull state ───────────────────────────────────────────
  int _skullTapCounter = 0;
  bool _skullCurseActive = false;
  int _skullCurseHitsLeft = 0;

  // ── Timers ───────────────────────────────────────────────────────
  Timer? _autoTapTimer;
  Timer? _frenzyTimer, _frenzyCooldownTimer;
  Timer? _goldRushTimer, _goldRushCooldownTimer;
  Timer? _apocalypseCooldownTimer;

  // ── Damage events (visual only) ──────────────────────────────────
  final List<DamageEvent> _damageEvents = [];
  int _damageEventIdCounter = 0;
  static const int _maxVisualEvents = 10;

  final Random _rng = Random();

  // ── Getters ──────────────────────────────────────────────────────
  int get coins => _coins;
  int get unlockedLevels => _unlockedLevels;
  int get currentHp => _currentHp;
  int get maxHp => _maxHp;
  bool get levelComplete => _levelComplete;
  int get currentLevelIndex => _currentLevelIndex;
  LevelConfig get currentLevel => LevelConfig.levels[_currentLevelIndex];
  List<DamageEvent> get damageEvents => List.unmodifiable(_damageEvents);
  bool get frenzyActive => _frenzyActive;
  int get frenzySecondsLeft => _frenzySecondsLeft;
  int get frenzyCooldownLeft => _frenzyCooldownLeft;
  bool get goldRushActive => _goldRushActive;
  int get goldRushSecondsLeft => _goldRushSecondsLeft;
  int get goldRushCooldownLeft => _goldRushCooldownLeft;
  int get apocalypseCooldownLeft => _apocalypseCooldownLeft;
  bool get skullCurseActive => _skullCurseActive;
  bool get hasCursedSkull => getUpgradeTier(UpgradeId.cursedSkull) > 0;

  int getUpgradeTier(UpgradeId id) => _upgradeTiers[id] ?? 0;

  // ── Damage formula ───────────────────────────────────────────────
  static const double _baseDamage = 15.0;

  double get _damageMultiplier {
    final tier = getUpgradeTier(UpgradeId.damageUp);
    return pow(1.35, tier).toDouble();
  }

  double get _titanMultiplier {
    final tier = getUpgradeTier(UpgradeId.titanGrip);
    return tier == 0 ? 1.0 : pow(2.0, tier).toDouble();
  }

  int get _tapCount {
    final tier = getUpgradeTier(UpgradeId.doubleTap);
    return (tier + 1).clamp(1, 11);
  }

  double get _critChance {
    final tier = getUpgradeTier(UpgradeId.critChance);
    return (tier * 0.05).clamp(0.0, 0.60);
  }

  double get _critMultiplier {
    final tier = getUpgradeTier(UpgradeId.critMultiplier);
    return 1.3 + tier * 0.25;
  }

  double get _frenzyMultiplier {
    if (!_frenzyActive) return 1.0;
    final tier = getUpgradeTier(UpgradeId.tapFrenzy);
    return (2.0 + (tier - 1) * 0.3).clamp(2.0, 6.5);
  }

  double get _autoTapRate {
    final tier = getUpgradeTier(UpgradeId.lavaSurge);
    const rates = [0.0, 0.3, 0.6, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0];
    return rates[tier.clamp(0, rates.length - 1)];
  }

  // Pyroclasm: every N taps → mega hit
  int get _pyroclasmEvery {
    final tier = getUpgradeTier(UpgradeId.pyroclasm);
    return (30 - (tier - 1) * 1.5).floor().clamp(12, 30);
  }

  int get _pyroclasmMult {
    final tier = getUpgradeTier(UpgradeId.pyroclasm);
    return 15 + (tier - 1) * 10;
  }

  String get autoTapLabel {
    final tier = getUpgradeTier(UpgradeId.lavaSurge);
    if (tier == 0) return '';
    final rate = _autoTapRate;
    return '×${rate % 1 == 0 ? rate.toInt() : rate}';
  }

  // ── Init ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _coins = await SaveService.loadCoins();
    _unlockedLevels = await SaveService.loadUnlockedLevels();
    _upgradeTiers = await SaveService.loadUpgrades();
    notifyListeners();
  }

  void startLevel(int levelIndex) {
    _currentLevelIndex = levelIndex;
    final config = LevelConfig.levels[levelIndex];
    _maxHp = config.maxHp;
    _currentHp = _maxHp;
    _levelComplete = false;
    _tapCounter = 0;
    _damageEvents.clear();
    _stopAutoTap();
    _startAutoTap();
    notifyListeners();
  }

  // ── Tap ──────────────────────────────────────────────────────────
  void onTap(Offset position) {
    if (_levelComplete || _currentHp <= 0) return;
    _applyTap(position, isManual: true);
  }

  void _applyTap(Offset position, {bool isManual = false}) {
    final count = _tapCount;
    final isCrit = _rng.nextDouble() < _critChance;
    final critM = isCrit ? _critMultiplier : 1.0;
    final baseDmg = _baseDamage * _damageMultiplier * _titanMultiplier * _frenzyMultiplier;

    // Skull curse: next 5 taps are ×200
    final skullM = _skullCurseActive ? 200.0 : 1.0;
    if (_skullCurseActive) {
      _skullCurseHitsLeft--;
      if (_skullCurseHitsLeft <= 0) {
        _skullCurseActive = false;
      }
    }

    int totalDmg = 0;
    for (int t = 0; t < count; t++) {
      final v = 0.85 + _rng.nextDouble() * 0.30;
      totalDmg += (baseDmg * v * critM * skullM).round().clamp(1, 999999999999);
    }

    _dealDamage(totalDmg);
    _spawnEvent(position, totalDmg,
        _skullCurseActive || skullM > 1
            ? DamageEventType.curse
            : isCrit
                ? DamageEventType.crit
                : DamageEventType.normal);

    // Tap counter for Pyroclasm + Skull
    if (isManual) {
      _tapCounter++;
      _skullTapCounter++;

      // Pyroclasm trigger
      final pyroTier = getUpgradeTier(UpgradeId.pyroclasm);
      if (pyroTier > 0 && _tapCounter % _pyroclasmEvery == 0) {
        final pyroDmg = (baseDmg * _pyroclasmMult).round().clamp(1, 999999999999);
        _dealDamage(pyroDmg);
        _spawnEvent(position, pyroDmg, DamageEventType.pyroclasm);
      }

      // Skull curse trigger (every 60 manual taps)
      if (hasCursedSkull && _skullTapCounter >= 60) {
        _skullTapCounter = 0;
        _skullCurseActive = true;
        _skullCurseHitsLeft = 5;
      }
    }

    notifyListeners();
  }

  void _dealDamage(int damage) {
    if (_currentHp <= 0) return;
    final config = LevelConfig.levels[_currentLevelIndex];
    final coinMult = _goldRushActive ? config.coinMultiplier * 2.0 : config.coinMultiplier;
    final coins = (damage * coinMult).round();
    _currentHp = (_currentHp - damage).clamp(0, _maxHp);
    _coins += coins;

    if (_currentHp <= 0) {
      _currentHp = 0;
      _levelComplete = true;
      _stopAutoTap();
      final nextLevel = _currentLevelIndex + 2;
      if (nextLevel > _unlockedLevels) {
        _unlockedLevels = nextLevel;
        SaveService.saveUnlockedLevels(_unlockedLevels);
      }
      SaveService.saveCoins(_coins);
    }
  }

  void _spawnEvent(Offset position, int damage, DamageEventType type) {
    if (_damageEvents.length >= _maxVisualEvents) return;
    _damageEvents.add(DamageEvent(
      position: Offset(
        position.dx + (_rng.nextDouble() - 0.5) * 60,
        position.dy + (_rng.nextDouble() - 0.5) * 60,
      ),
      damage: damage,
      type: type,
      id: _damageEventIdCounter++,
    ));
  }

  void removeDamageEvent(int id) {
    _damageEvents.removeWhere((e) => e.id == id);
  }

  // ── Buy upgrade ──────────────────────────────────────────────────
  Future<bool> buyUpgrade(UpgradeId id) async {
    final def = UpgradeDefinition.all.firstWhere((d) => d.id == id);
    final current = getUpgradeTier(id);
    if (current >= def.tiers.length) return false;

    final cost = def.tiers[current].cost;
    if (_coins < cost) return false;

    _coins -= cost;
    _upgradeTiers[id] = current + 1;

    await SaveService.saveCoins(_coins);
    await SaveService.saveUpgrade(id, _upgradeTiers[id]!);

    _stopAutoTap();
    _startAutoTap();

    notifyListeners();
    return true;
  }

  // ── Tap Frenzy ───────────────────────────────────────────────────
  void activateFrenzy() {
    final tier = getUpgradeTier(UpgradeId.tapFrenzy);
    if (tier == 0 || _frenzyActive || _frenzyCooldownLeft > 0) return;

    final duration = 4 + (tier - 1) ~/ 2;
    final cd = (30 - (tier - 1) * 1.5).floor().clamp(12, 30);

    _frenzyActive = true;
    _frenzySecondsLeft = duration;

    _frenzyTimer?.cancel();
    _frenzyTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _frenzySecondsLeft--;
      if (_frenzySecondsLeft <= 0) {
        _frenzyActive = false;
        t.cancel();
        _frenzyCooldownLeft = cd;
        _frenzyCooldownTimer?.cancel();
        _frenzyCooldownTimer = Timer.periodic(const Duration(seconds: 1), (ct) {
          _frenzyCooldownLeft--;
          if (_frenzyCooldownLeft <= 0) { _frenzyCooldownLeft = 0; ct.cancel(); }
          notifyListeners();
        });
      }
      notifyListeners();
    });
    notifyListeners();
  }

  // ── Gold Rush ────────────────────────────────────────────────────
  void activateGoldRush() {
    final tier = getUpgradeTier(UpgradeId.goldRush);
    if (tier == 0 || _goldRushActive || _goldRushCooldownLeft > 0) return;

    final duration = 8 + (tier - 1) * 2;
    final cd = (60 - (tier - 1) * 5).clamp(25, 60);

    _goldRushActive = true;
    _goldRushSecondsLeft = duration;

    _goldRushTimer?.cancel();
    _goldRushTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _goldRushSecondsLeft--;
      if (_goldRushSecondsLeft <= 0) {
        _goldRushActive = false;
        t.cancel();
        _goldRushCooldownLeft = cd;
        _goldRushCooldownTimer?.cancel();
        _goldRushCooldownTimer = Timer.periodic(const Duration(seconds: 1), (ct) {
          _goldRushCooldownLeft--;
          if (_goldRushCooldownLeft <= 0) { _goldRushCooldownLeft = 0; ct.cancel(); }
          notifyListeners();
        });
      }
      notifyListeners();
    });
    notifyListeners();
  }

  // ── Apocalypse ───────────────────────────────────────────────────
  void activateApocalypse() {
    final tier = getUpgradeTier(UpgradeId.apocalypse);
    if (tier == 0 || _apocalypseCooldownLeft > 0) return;

    final pct = (0.05 + (tier - 1) * 0.05).clamp(0.05, 0.25);
    final dmg = (_maxHp * pct).round().clamp(1, 999999999999);
    _dealDamage(dmg);
    // Big central event
    _spawnEvent(const Offset(200, 400), dmg, DamageEventType.apocalypse);

    _apocalypseCooldownLeft = 120;
    _apocalypseCooldownTimer?.cancel();
    _apocalypseCooldownTimer = Timer.periodic(const Duration(seconds: 1), (ct) {
      _apocalypseCooldownLeft--;
      if (_apocalypseCooldownLeft <= 0) { _apocalypseCooldownLeft = 0; ct.cancel(); }
      notifyListeners();
    });
    notifyListeners();
  }

  // ── Auto-tap ─────────────────────────────────────────────────────
  void _startAutoTap() {
    final rate = _autoTapRate;
    if (rate <= 0) return;
    final intervalMs = (1000 / rate).round();
    _autoTapTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!_levelComplete && _currentHp > 0) {
        _applyTap(const Offset(200, 420), isManual: false);
      }
    });
  }

  void _stopAutoTap() {
    _autoTapTimer?.cancel();
    _autoTapTimer = null;
  }

  @override
  void dispose() {
    _stopAutoTap();
    _frenzyTimer?.cancel(); _frenzyCooldownTimer?.cancel();
    _goldRushTimer?.cancel(); _goldRushCooldownTimer?.cancel();
    _apocalypseCooldownTimer?.cancel();
    super.dispose();
  }
}
