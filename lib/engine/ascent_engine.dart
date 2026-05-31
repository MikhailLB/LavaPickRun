import 'dart:math';
import 'package:flutter/foundation.dart';

import '../data/gear_catalog.dart';
import '../data/peaks.dart';
import '../data/progress_store.dart';
import '../feedback/haptics.dart';
import 'models.dart';

/// The beating heart of Ember Ascent.
///
/// One object owns both the meta layer (embers, unlocked peaks, gear) and the
/// live run simulation (timing gauge, heat, eruption director, stability,
/// momentum). The simulation is advanced every frame via [tick]; discrete
/// events (a strike, a state transition, a win/loss) call [notifyListeners] so
/// the lightweight HUD rebuilds, while continuous visuals repaint off the
/// frame ticker instead.
class AscentEngine extends ChangeNotifier {
  AscentEngine();

  final Random _rng = Random();

  // ── Meta state ─────────────────────────────────────────────────────
  int _embers = 0;
  int _highestPeak = 0;
  final Map<GearId, int> _gear = {};

  int get embers => _embers;
  int get highestPeak => _highestPeak;
  int gearTier(GearId id) => _gear[id] ?? 0;
  bool isPeakUnlocked(int index) => index <= _highestPeak;

  // ── Run state ──────────────────────────────────────────────────────
  late Peak _peak;
  Difficulty _difficulty = Difficulty.normal;
  RunPhase _phase = RunPhase.ready;
  HazardState _hazard = HazardState.calm;

  double _ascent = 0;
  double _heat = 0;
  int _stability = 3;
  int _maxStability = 3;
  int _momentum = 0;
  bool _overheated = false;

  double _gaugePhase = 0;
  double _hazardTimer = 0;
  double _stateTimer = 0; // counts down telegraph / eruption / vent

  int _earnedThisRun = 0;
  int _maxCombo = 0;
  int _burns = 0;
  int _starsEarned = 0;
  final List<StrikeFlash> _flashes = [];
  int _flashId = 0;

  Peak get peak => _peak;
  Difficulty get difficulty => _difficulty;
  RunPhase get phase => _phase;
  HazardState get hazard => _hazard;
  double get ascent => _ascent;
  double get heat => _heat;
  int get stability => _stability;
  int get maxStability => _maxStability;
  int get momentum => _momentum;
  bool get overheated => _overheated;
  int get earnedThisRun => _earnedThisRun;
  int get maxCombo => _maxCombo;
  int get burns => _burns;
  int get starsEarned => _starsEarned;
  int get comboGoal => _peak.comboGoal;
  List<StrikeFlash> get flashes => List.unmodifiable(_flashes);

  bool get isClimbing => _phase == RunPhase.climbing;
  bool get isDanger => _hazard == HazardState.erupting;
  bool get isTelegraph => _hazard == HazardState.telegraph;
  bool get isVenting => _hazard == HazardState.venting;

  /// Remaining seconds in the current telegraph / eruption / vent state.
  double get hazardTimeLeft => _stateTimer;

  /// Half-width of the live perfect band in gauge units (for the view).
  double get perfectBandView => _perfectBand;
  double get goodBandView => _peak.goodBand;

  /// Effective telegraph length for the current run (for the view).
  double get telegraphView => _telegraph;

  /// Marker position along the gauge (0 bottom .. 1 top), a triangle sweep.
  double get markerPosition {
    final t = _gaugePhase % 1.0;
    return t < 0.5 ? t * 2.0 : (1.0 - t) * 2.0;
  }

  /// Centre of the timing target (the gauge midpoint).
  static const double targetCenter = 0.5;

  // ── Gear + difficulty derived effective stats ──────────────────────
  double get _focusMul => 1 - gearTier(GearId.focusLens) * 0.04;
  double get _gaugeSpeed =>
      _peak.gaugeSpeed * _difficulty.speedMul * _focusMul;
  double get _telegraph => _peak.telegraph * _difficulty.telegraphMul;
  double get _eruptionWindow => _peak.eruptionWindow;
  double get _gapMin => _peak.eruptionGapMin * _difficulty.gapMul;
  double get _gapMax => _peak.eruptionGapMax * _difficulty.gapMul;

  double get _perfectBand => _peak.perfectBand *
      (1 + gearTier(GearId.steadyHands) * 0.12) *
      _difficulty.perfectMul;
  double get _heatPerStrike => _peak.heatPerStrike *
      (1 - gearTier(GearId.heatSink) * 0.09) *
      _difficulty.heatMul;
  double get _heatDecay =>
      _peak.heatDecay * (1 + gearTier(GearId.heatSink) * 0.10);
  double get _ventDuration =>
      1.7 * (1 - gearTier(GearId.quickVent) * 0.12).clamp(0.4, 1.0);
  int get _momentumCap => 5 + gearTier(GearId.momentumCore) * 2;
  double get _momentumStep =>
      0.12 * (1 + gearTier(GearId.momentumCore) * 0.08);
  double get _emberMult =>
      (1 + gearTier(GearId.emberKnack) * 0.15) * _difficulty.emberMul;

  /// Current ascent multiplier from the live combo.
  double get momentumMultiplier =>
      1 + min(_momentum, _momentumCap) * _momentumStep;

  // ── Boot ───────────────────────────────────────────────────────────
  void hydrate() {
    _embers = ProgressStore.embers;
    _highestPeak = ProgressStore.highestPeak;
    _gear
      ..clear()
      ..addAll(ProgressStore.allGearTiers());
    Feedback.enabled = ProgressStore.hapticsEnabled;
    notifyListeners();
  }

  // ── Run lifecycle ──────────────────────────────────────────────────
  void startRun(int peakIndex, {Difficulty? difficulty}) {
    _peak = Peaks.all[peakIndex.clamp(0, Peaks.count - 1)];
    _difficulty = difficulty ?? _difficulty;
    _phase = RunPhase.ready;
    _hazard = HazardState.calm;
    _ascent = 0;
    _heat = 0;
    _momentum = 0;
    _overheated = false;
    _maxStability = 3 + gearTier(GearId.bulwark);
    _stability = _maxStability;
    _gaugePhase = _rng.nextDouble();
    _hazardTimer = _gapMax + 1.5; // gentle lead-in
    _stateTimer = 0;
    _earnedThisRun = 0;
    _maxCombo = 0;
    _burns = 0;
    _starsEarned = 0;
    _flashes.clear();
    notifyListeners();
  }

  void abandonRun() {
    if (_earnedThisRun > 0) {
      ProgressStore.setEmbers(_embers);
    }
    _phase = RunPhase.ready;
    notifyListeners();
  }

  // ── Per-frame simulation ───────────────────────────────────────────
  void tick(double dt) {
    if (_phase != RunPhase.climbing) {
      // Keep the gauge sweeping on the standby screen for a live feel.
      _gaugePhase += dt * _gaugeSpeed;
      return;
    }

    _gaugePhase += dt * _gaugeSpeed;

    // Heat always bleeds off; venting accelerates it.
    final decay = _heatDecay * (_hazard == HazardState.venting ? 3.4 : 1.0);
    _heat = (_heat - decay * dt).clamp(0.0, 1.0);

    final before = _hazard;
    switch (_hazard) {
      case HazardState.calm:
        _hazardTimer -= dt;
        if (_hazardTimer <= 0) {
          _hazard = HazardState.telegraph;
          _stateTimer = _telegraph;
        }
      case HazardState.telegraph:
        _stateTimer -= dt;
        if (_stateTimer <= 0) {
          _hazard = HazardState.erupting;
          _stateTimer = _eruptionWindow;
          Feedback.hazard();
        }
      case HazardState.erupting:
        _stateTimer -= dt;
        if (_stateTimer <= 0) {
          _hazard = HazardState.calm;
          _scheduleNextEruption();
        }
      case HazardState.venting:
        _stateTimer -= dt;
        if (_stateTimer <= 0) {
          _overheated = false;
          _heat = 0.30;
          _hazard = HazardState.calm;
          _scheduleNextEruption();
        }
    }

    if (before != _hazard) notifyListeners();
  }

  void _scheduleNextEruption() {
    _hazardTimer = _gapMin + _rng.nextDouble() * (_gapMax - _gapMin);
  }

  // ── Player input ───────────────────────────────────────────────────
  void strike() {
    // First tap arms the run.
    if (_phase == RunPhase.ready) {
      _phase = RunPhase.climbing;
      _scheduleNextEruption();
      Feedback.good();
      notifyListeners();
      return;
    }
    if (_phase != RunPhase.climbing) return;

    // Locked out while the core vents.
    if (_overheated) {
      _emit(StrikeQuality.overheat, 0, 0);
      Feedback.weak();
      notifyListeners();
      return;
    }

    // Striking inside an eruption window burns the climber.
    if (_hazard == HazardState.erupting) {
      _stability -= 1;
      _momentum = 0;
      _burns++;
      _heat = (_heat + 0.22).clamp(0.0, 1.0);
      _emit(StrikeQuality.burned, 0, 0);
      Feedback.hazard();
      if (_stability <= 0) {
        _collapse();
      } else {
        notifyListeners();
      }
      return;
    }

    // Evaluate timing accuracy.
    final d = (markerPosition - targetCenter).abs();
    final StrikeQuality quality;
    final double base;
    if (d <= _perfectBand) {
      quality = StrikeQuality.perfect;
      base = _peak.ascentPerPerfect;
      _momentum++;
      if (_momentum > _maxCombo) _maxCombo = _momentum;
    } else if (d <= _peak.goodBand) {
      quality = StrikeQuality.good;
      base = _peak.ascentPerPerfect * 0.45;
      // momentum preserved but not advanced
    } else {
      quality = StrikeQuality.weak;
      base = _peak.ascentPerPerfect * 0.12;
      _momentum = 0;
    }

    final gain = base * momentumMultiplier;
    _ascent = (_ascent + gain).clamp(0.0, 1.0);

    _heat = (_heat + _heatPerStrike).clamp(0.0, 1.0);
    if (_heat >= 1.0) {
      _overheat();
    }

    final reward = _emberReward(quality);
    if (reward > 0) {
      _embers += reward;
      _earnedThisRun += reward;
    }

    _emit(quality, gain, reward);
    switch (quality) {
      case StrikeQuality.perfect:
        Feedback.perfect();
      case StrikeQuality.good:
        Feedback.good();
      default:
        Feedback.weak();
    }

    if (_ascent >= 1.0) {
      _summit();
    } else {
      notifyListeners();
    }
  }

  void _overheat() {
    _overheated = true;
    _momentum = 0;
    _hazard = HazardState.venting;
    _stateTimer = _ventDuration;
  }

  int _emberReward(StrikeQuality q) {
    final base = switch (q) {
      StrikeQuality.perfect => 4 + min(_momentum, _momentumCap),
      StrikeQuality.good => 2,
      _ => 0,
    };
    return (base * _emberMult).round();
  }

  void _emit(StrikeQuality quality, double ascentGain, int emberGain) {
    if (_flashes.length >= 8) _flashes.removeAt(0);
    _flashes.add(StrikeFlash(
      id: _flashId++,
      quality: quality,
      ascentGain: ascentGain,
      emberGain: emberGain,
      momentum: _momentum,
    ));
  }

  void clearFlash(int id) {
    _flashes.removeWhere((f) => f.id == id);
  }

  void _summit() {
    _phase = RunPhase.summit;

    // Stars: clear (1) + flawless against eruptions (no burns) + combo goal.
    var stars = 1;
    if (_burns == 0) stars++;
    if (_maxCombo >= _peak.comboGoal) stars++;
    _starsEarned = stars;

    final bonus = ((30 + _peak.index * 15) * _emberMult).round();
    _embers += bonus;
    _earnedThisRun += bonus;
    ProgressStore.setEmbers(_embers);
    ProgressStore.setBestAscent(_peak.index, 100);
    ProgressStore.setStars(_peak.index, _difficulty, stars);
    final next = _peak.index + 1;
    if (next > _highestPeak && next < Peaks.count) {
      _highestPeak = next;
      ProgressStore.setHighestPeak(next);
    }
    notifyListeners();
  }

  void _collapse() {
    _phase = RunPhase.collapsed;
    ProgressStore.setEmbers(_embers);
    ProgressStore.setBestAscent(_peak.index, (_ascent * 100).round());
    notifyListeners();
  }

  // ── Gear shop ──────────────────────────────────────────────────────
  bool canAfford(GearId id) {
    final def = GearCatalog.byId(id);
    final tier = gearTier(id);
    if (tier >= def.maxTier) return false;
    return _embers >= def.tiers[tier].cost;
  }

  bool buyGear(GearId id) {
    final def = GearCatalog.byId(id);
    final tier = gearTier(id);
    if (tier >= def.maxTier) return false;
    final cost = def.tiers[tier].cost;
    if (_embers < cost) return false;
    _embers -= cost;
    _gear[id] = tier + 1;
    ProgressStore.setEmbers(_embers);
    ProgressStore.setGearTier(id, _gear[id]!);
    Feedback.milestone();
    notifyListeners();
    return true;
  }

  // ── Settings ───────────────────────────────────────────────────────
  void setHaptics(bool value) {
    Feedback.enabled = value;
    ProgressStore.setHaptics(value);
    notifyListeners();
  }

  bool get hapticsEnabled => Feedback.enabled;
}
