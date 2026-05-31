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

  static Future<void> wipe() => _p.clear();
}
