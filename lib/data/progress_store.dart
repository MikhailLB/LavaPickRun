import 'package:shared_preferences/shared_preferences.dart';
import '../engine/models.dart';
import 'gear_catalog.dart';
import 'peaks.dart';

/// Durable progress + settings.
///
/// Keys are namespaced under `ea.` (Ember Ascent) and intentionally differ from
/// the previous build so a fresh install starts clean and old save blobs are
/// ignored.
class ProgressStore {
  ProgressStore._();

  static const _kEmbers = 'ea.embers';
  static const _kHighestPeak = 'ea.highest_peak';
  static const _kGearPrefix = 'ea.gear.';
  static const _kHaptics = 'ea.haptics';
  static const _kBestPrefix = 'ea.best.';
  static const _kStarPrefix = 'ea.stars.';

  // ── Lifetime stats ──────────────────────────────────────────────────
  static const _kTotalRuns = 'ea.stat.runs';
  static const _kTotalStrikes = 'ea.stat.strikes';
  static const _kPerfectStrikes = 'ea.stat.perfect';
  static const _kGoodStrikes = 'ea.stat.good';
  static const _kWeakStrikes = 'ea.stat.weak';
  static const _kEmbersEarned = 'ea.stat.embers_earned';
  static const _kBestCombo = 'ea.stat.best_combo';
  static const _kSummits = 'ea.stat.summits';

  // ── Achievements / Codex (unlocked id sets) ─────────────────────────
  static const _kAchievements = 'ea.achievements';
  static const _kCodex = 'ea.codex';

  // ── Customization / onboarding ──────────────────────────────────────
  static const _kTheme = 'ea.theme';
  static const _kTutorialSeen = 'ea.tutorial_seen';

  // ── Lava Flow (second mechanic) ─────────────────────────────────────
  static const _kFlowLevel = 'ea.flow.level';
  static const _kFlowBest = 'ea.flow.best_moves.';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('ProgressStore.init() must be awaited before use.');
    }
    return p;
  }

  // ── Currency ───────────────────────────────────────────────────────
  static int get embers => _p.getInt(_kEmbers) ?? 0;
  static Future<void> setEmbers(int value) =>
      _p.setInt(_kEmbers, value < 0 ? 0 : value);

  // ── Peak unlocking (index of highest reachable peak) ────────────────
  static int get highestPeak => _p.getInt(_kHighestPeak) ?? 0;
  static Future<void> setHighestPeak(int index) {
    if (index <= highestPeak) return Future.value();
    return _p.setInt(_kHighestPeak, index);
  }

  /// Best ascent fraction (0..100) reached on a given peak — used for the map.
  static int bestAscent(int peakIndex) =>
      _p.getInt('$_kBestPrefix$peakIndex') ?? 0;
  static Future<void> setBestAscent(int peakIndex, int percent) {
    if (percent <= bestAscent(peakIndex)) return Future.value();
    return _p.setInt('$_kBestPrefix$peakIndex', percent.clamp(0, 100));
  }

  // ── Stars (per peak, per difficulty) ────────────────────────────────
  static int stars(int peakIndex, Difficulty d) =>
      _p.getInt('$_kStarPrefix$peakIndex.${d.index}') ?? 0;

  static Future<void> setStars(int peakIndex, Difficulty d, int value) {
    final key = '$_kStarPrefix$peakIndex.${d.index}';
    final current = _p.getInt(key) ?? 0;
    if (value <= current) return Future.value();
    return _p.setInt(key, value.clamp(0, 3));
  }

  static int totalStars() {
    var sum = 0;
    for (var p = 0; p < Peaks.count; p++) {
      for (final d in Difficulty.values) {
        sum += stars(p, d);
      }
    }
    return sum;
  }

  static int peaksClearedOn(Difficulty d) {
    var n = 0;
    for (var p = 0; p < Peaks.count; p++) {
      if (stars(p, d) > 0) n++;
    }
    return n;
  }

  static bool difficultyUnlocked(Difficulty d) {
    switch (d) {
      case Difficulty.normal:
        return true;
      case Difficulty.hard:
        return peaksClearedOn(Difficulty.normal) >= Peaks.count;
      case Difficulty.inferno:
        return peaksClearedOn(Difficulty.hard) >= Peaks.count;
    }
  }

  // ── Gear tiers ──────────────────────────────────────────────────────
  static int gearTier(GearId id) => _p.getInt('$_kGearPrefix${id.name}') ?? 0;
  static Future<void> setGearTier(GearId id, int tier) =>
      _p.setInt('$_kGearPrefix${id.name}', tier);

  static Map<GearId, int> allGearTiers() {
    return {for (final g in GearCatalog.all) g.id: gearTier(g.id)};
  }

  // ── Settings ────────────────────────────────────────────────────────
  static bool get hapticsEnabled => _p.getBool(_kHaptics) ?? true;
  static Future<void> setHaptics(bool value) => _p.setBool(_kHaptics, value);

  static bool get soundEnabled => _p.getBool('ea.sound') ?? true;
  static Future<void> setSound(bool value) => _p.setBool('ea.sound', value);

  // ── Lifetime stats ──────────────────────────────────────────────────
  static int get totalRuns => _p.getInt(_kTotalRuns) ?? 0;
  static int get totalStrikes => _p.getInt(_kTotalStrikes) ?? 0;
  static int get perfectStrikes => _p.getInt(_kPerfectStrikes) ?? 0;
  static int get goodStrikes => _p.getInt(_kGoodStrikes) ?? 0;
  static int get weakStrikes => _p.getInt(_kWeakStrikes) ?? 0;
  static int get embersEarned => _p.getInt(_kEmbersEarned) ?? 0;
  static int get bestCombo => _p.getInt(_kBestCombo) ?? 0;
  static int get summits => _p.getInt(_kSummits) ?? 0;

  /// Folds the per-run tally into the lifetime counters in one call.
  static Future<void> recordRun({
    required int perfect,
    required int good,
    required int weak,
    required int embersEarned,
    required int bestCombo,
    required bool summited,
  }) async {
    await _p.setInt(_kTotalRuns, totalRuns + 1);
    await _p.setInt(_kPerfectStrikes, perfectStrikes + perfect);
    await _p.setInt(_kGoodStrikes, goodStrikes + good);
    await _p.setInt(_kWeakStrikes, weakStrikes + weak);
    await _p.setInt(_kTotalStrikes, totalStrikes + perfect + good + weak);
    await _p.setInt(_kEmbersEarned, ProgressStore.embersEarned + embersEarned);
    if (bestCombo > ProgressStore.bestCombo) {
      await _p.setInt(_kBestCombo, bestCombo);
    }
    if (summited) await _p.setInt(_kSummits, summits + 1);
  }

  // ── Achievements ────────────────────────────────────────────────────
  static Set<String> unlockedAchievements() =>
      (_p.getStringList(_kAchievements) ?? const []).toSet();

  static bool isAchievementUnlocked(String id) =>
      unlockedAchievements().contains(id);

  /// Unlocks an achievement; returns true only the first time.
  static Future<bool> unlockAchievement(String id) async {
    final set = unlockedAchievements();
    if (set.contains(id)) return false;
    set.add(id);
    await _p.setStringList(_kAchievements, set.toList());
    return true;
  }

  // ── Codex ───────────────────────────────────────────────────────────
  static Set<String> unlockedCodex() =>
      (_p.getStringList(_kCodex) ?? const []).toSet();

  static bool isCodexUnlocked(String id) => unlockedCodex().contains(id);

  static Future<void> unlockCodex(String id) async {
    final set = unlockedCodex();
    if (set.add(id)) {
      await _p.setStringList(_kCodex, set.toList());
    }
  }

  // ── Theme / customization ───────────────────────────────────────────
  static String get themeId => _p.getString(_kTheme) ?? 'ember';
  static Future<void> setThemeId(String id) => _p.setString(_kTheme, id);

  // ── Onboarding ──────────────────────────────────────────────────────
  static bool get tutorialSeen => _p.getBool(_kTutorialSeen) ?? false;
  static Future<void> setTutorialSeen() => _p.setBool(_kTutorialSeen, true);

  // ── Lava Flow ───────────────────────────────────────────────────────
  static int get flowLevel => _p.getInt(_kFlowLevel) ?? 0;
  static Future<void> setFlowLevel(int level) {
    if (level <= flowLevel) return Future.value();
    return _p.setInt(_kFlowLevel, level);
  }

  static int flowBestMoves(int level) => _p.getInt('$_kFlowBest$level') ?? 0;
  static Future<void> setFlowBestMoves(int level, int moves) {
    final cur = flowBestMoves(level);
    if (cur != 0 && moves >= cur) return Future.value();
    return _p.setInt('$_kFlowBest$level', moves);
  }

  static Future<void> wipe() => _p.clear();
}
