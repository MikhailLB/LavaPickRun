import 'dart:math';
import 'package:flutter/foundation.dart';

import '../data/codex.dart';
import '../data/gear_catalog.dart';
import '../data/levels.dart';
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
  LevelDef? _level;
  Difficulty _difficulty = Difficulty.normal;
  RunPhase _phase = RunPhase.ready;
  HazardState _hazard = HazardState.calm;

  // ── Mechanic mod state (vent / echo / charge) ──────────────────────
  bool _ventActive = false;
  double _ventTimer = 0;
  double _ventCd = 0;
  bool _echoPending = false;
  double _echoTimer = 0;
  bool _charging = false;
  double _charge = 0;

  double _ascent = 0;
  double _heat = 0;
  int _stability = 3;
  int _maxStability = 3;
  int _momentum = 0;
  bool _overheated = false;

  double _gaugePhase = 0;
  double _hazardTimer = 0;
  double _stateTimer = 0; // counts down telegraph / eruption / vent

  // ── Trial (per-peak gameplay twist) live state ─────────────────────
  double _bandCenter = 0.5; // live centre of the target band (0..1)
  double _bandTarget = 0.5; // where a shifting band is easing toward
  double _trialPhase = 0; // drives drift oscillation
  double _gustPhase = 0; // drives gust speed waves
  double _shiftTimer = 0; // countdown to the next band jump

  int _earnedThisRun = 0;
  int _maxCombo = 0;
  int _burns = 0;
  int _starsEarned = 0;

  // Per-run strike tally (folded into lifetime stats at the end of a run).
  int _perfectCount = 0;
  int _goodCount = 0;
  int _weakCount = 0;
  int _perfectStreak = 0;
  int _bestStreak = 0;

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
  int get perfectCount => _perfectCount;
  int get goodCount => _goodCount;
  int get weakCount => _weakCount;
  int get bestStreakThisRun => _bestStreak;
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

  /// Live centre of the timing target. Most peaks keep it at 0.5, but trial
  /// peaks drift, gust or jump it around — this is what the view and the
  /// strike judge both read.
  double get bandCenter => _bandCenter;

  /// Static fallback centre (kept for reference / non-trial use).
  static const double targetCenter = 0.5;

  PeakTrial get trial => _peak.trial;
  bool get hasTrial => _peak.trial != PeakTrial.steady;
  String get trialLabel => _peak.trial.label;
  String get trialHint => _peak.trial.hint;

  // ── Level / mechanic accessors ─────────────────────────────────────
  LevelDef? get level => _level;
  int get currentLevelIndex => _level?.index ?? 0;
  bool _hasMod(AscentMod m) => _level?.has(m) ?? false;
  bool get usesCharge => _hasMod(AscentMod.charge);
  bool get hasVent => _hasMod(AscentMod.vent);
  bool get hasEcho => _hasMod(AscentMod.echo);
  bool get ventActive => _ventActive;
  bool get charging => _charging;
  double get chargeLevel => _charge;
  bool get echoPending => _echoPending;

  // ── Gear + difficulty derived effective stats ──────────────────────
  double get _focusMul => 1 - gearTier(GearId.focusLens) * 0.04;
  double get _gaugeSpeed =>
      _peak.gaugeSpeed * _difficulty.speedMul * _focusMul;

  /// Gauge speed including the live gust wave on gusty peaks.
  double get _liveGaugeSpeed {
    if (!_peak.trial.gusts) return _gaugeSpeed;
    return _gaugeSpeed * (1 + 0.45 * sin(_gustPhase * 2.0));
  }
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
    Feedback.soundEnabled = ProgressStore.soundEnabled;
    notifyListeners();
  }

  // ── Run lifecycle ──────────────────────────────────────────────────
  /// Legacy entry (peak + difficulty). Kept for compatibility.
  void startRun(int peakIndex, {Difficulty? difficulty}) {
    _level = null;
    _peak = Peaks.all[peakIndex.clamp(0, Peaks.count - 1)];
    _difficulty = difficulty ?? _difficulty;
    _resetRun();
    notifyListeners();
  }

  /// Campaign entry — runs a single ladder level.
  void startLevel(LevelDef def) {
    _level = def;
    _peak = def.toPeak();
    _difficulty = Difficulty.normal;
    _resetRun();
    notifyListeners();
  }

  void _resetRun() {
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
    _bandCenter = 0.5;
    _bandTarget = 0.5;
    _trialPhase = 0;
    _gustPhase = 0;
    _shiftTimer = 2.0;
    _ventActive = false;
    _ventTimer = 0;
    _ventCd = 4.0;
    _echoPending = false;
    _echoTimer = 0;
    _charging = false;
    _charge = 0;
    _earnedThisRun = 0;
    _maxCombo = 0;
    _burns = 0;
    _starsEarned = 0;
    _perfectCount = 0;
    _goodCount = 0;
    _weakCount = 0;
    _perfectStreak = 0;
    _bestStreak = 0;
    _flashes.clear();
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

    _advanceTrial(dt);
    _advanceMods(dt);
    _gaugePhase += dt * _liveGaugeSpeed;

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

  /// Moves the live target band according to the peak's trial.
  void _advanceTrial(double dt) {
    final t = _peak.trial;
    if (t.gusts) _gustPhase += dt;
    if (t.drifts) {
      _trialPhase += dt * 0.9;
      _bandCenter = (0.5 + sin(_trialPhase) * 0.26).clamp(0.18, 0.82);
    }
    if (t.shifts) {
      _shiftTimer -= dt;
      if (_shiftTimer <= 0) {
        _bandTarget = 0.28 + _rng.nextDouble() * 0.44;
        _shiftTimer = 1.8 + _rng.nextDouble() * 0.8;
        Feedback.weak();
      }
      _bandCenter += (_bandTarget - _bandCenter) * (1 - exp(-6 * dt));
    }
    if (!t.drifts && !t.shifts) _bandCenter = 0.5;
  }

  /// Advances the per-level mechanic mods each frame.
  void _advanceMods(double dt) {
    if (_hasMod(AscentMod.vent)) {
      if (_ventActive) {
        _ventTimer -= dt;
        if (_ventTimer <= 0) {
          _ventActive = false;
          _ventCd = 3.0;
          notifyListeners();
        }
      } else {
        _ventCd -= dt;
        if (_ventCd <= 0 && _heat > 0.5) {
          _ventActive = true;
          _ventTimer = 2.8;
          Feedback.weak();
          notifyListeners();
        }
      }
    }
    if (_echoPending) {
      _echoTimer -= dt;
      if (_echoTimer <= 0) {
        _echoPending = false;
        notifyListeners();
      }
    }
    if (_charging) {
      _charge = (_charge + dt / 0.8).clamp(0.0, 1.0);
    }
  }

  /// Tap a cooling vent to dump heat (vent levels only).
  void tapVent() {
    if (!_ventActive) return;
    _heat = (_heat * 0.3).clamp(0.0, 1.0);
    _ventActive = false;
    _ventCd = 2.5;
    final r = (3 * _emberMult).round();
    _embers += r;
    _earnedThisRun += r;
    ProgressStore.setEmbers(_embers);
    Feedback.milestone();
    notifyListeners();
  }

  // ── Charged strike input (charge levels) ───────────────────────────
  void beginCharge() {
    if (_phase == RunPhase.ready) {
      _phase = RunPhase.climbing;
      _scheduleNextEruption();
      Feedback.good();
    }
    if (_phase != RunPhase.climbing) return;
    if (_overheated || _hazard == HazardState.erupting) return;
    _charging = true;
    _charge = 0;
    notifyListeners();
  }

  void releaseCharge() {
    if (!_charging) {
      // A quick tap with no real hold still counts as a normal strike.
      strike();
      return;
    }
    _charging = false;
    final mul = 1.0 + _charge;
    _charge = 0;
    if (_phase != RunPhase.climbing) return;
    if (_overheated) {
      _emit(StrikeQuality.overheat, 0, 0);
      Feedback.weak();
      notifyListeners();
      return;
    }
    if (_hazard == HazardState.erupting) {
      _burnStrike();
      return;
    }
    _evaluateStrike(chargeMul: mul);
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
      _burnStrike();
      return;
    }

    // Echo bonus window (echo levels): a quick second tap after a perfect.
    if (_echoPending) {
      _echoBonus();
      return;
    }

    _evaluateStrike();
  }

  void _burnStrike() {
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
  }

  void _echoBonus() {
    _echoPending = false;
    final r = (3 * _emberMult).round();
    _embers += r;
    _earnedThisRun += r;
    ProgressStore.setEmbers(_embers);
    _emit(StrikeQuality.good, 0, r);
    Feedback.good();
    notifyListeners();
  }

  void _evaluateStrike({double chargeMul = 1.0}) {
    // Evaluate timing accuracy against the live (possibly moving) band.
    final d = (markerPosition - _bandCenter).abs();
    final StrikeQuality quality;
    final double base;
    if (d <= _perfectBand) {
      quality = StrikeQuality.perfect;
      base = _peak.ascentPerPerfect;
      _momentum++;
      if (_momentum > _maxCombo) _maxCombo = _momentum;
      _perfectCount++;
      _perfectStreak++;
      if (_perfectStreak > _bestStreak) _bestStreak = _perfectStreak;
      if (_hasMod(AscentMod.echo)) {
        _echoPending = true;
        _echoTimer = 0.55;
      }
    } else if (d <= _peak.goodBand) {
      quality = StrikeQuality.good;
      base = _peak.ascentPerPerfect * 0.45;
      _goodCount++;
      _perfectStreak = 0;
      // momentum preserved but not advanced
    } else {
      quality = StrikeQuality.weak;
      base = _peak.ascentPerPerfect * 0.12;
      _weakCount++;
      _perfectStreak = 0;
      _momentum = 0;
    }

    final gain = base * momentumMultiplier * chargeMul;
    _ascent = (_ascent + gain).clamp(0.0, 1.0);

    _heat = (_heat + _heatPerStrike).clamp(0.0, 1.0);
    if (_heat >= 1.0) {
      _overheat();
    }

    final reward = (_emberReward(quality) * chargeMul).round();
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

    final lvl = _level;
    final bonus =
        ((30 + (lvl?.index ?? _peak.index) * 6) * _emberMult).round();
    _embers += bonus;
    _earnedThisRun += bonus;
    ProgressStore.setEmbers(_embers);
    if (lvl != null) {
      ProgressStore.setLevelStars(lvl.index, stars);
      ProgressStore.unlockCampaignLevel(lvl.index + 1);
    } else {
      ProgressStore.setBestAscent(_peak.index, 100);
      ProgressStore.setStars(_peak.index, _difficulty, stars);
      final next = _peak.index + 1;
      if (next > _highestPeak && next < Peaks.count) {
        _highestPeak = next;
        ProgressStore.setHighestPeak(next);
      }
    }
    Feedback.summit();
    _persistRunOutcome(summited: true);
    notifyListeners();
  }

  void _collapse() {
    _phase = RunPhase.collapsed;
    ProgressStore.setEmbers(_embers);
    ProgressStore.setBestAscent(_peak.index, (_ascent * 100).round());
    _persistRunOutcome(summited: false);
    notifyListeners();
  }

  /// Folds the run into lifetime stats, unlocks the peak's codex card on a
  /// summit, then evaluates achievements. Fire-and-forget — never blocks the UI.
  Future<void> _persistRunOutcome({required bool summited}) async {
    await ProgressStore.recordRun(
      perfect: _perfectCount,
      good: _goodCount,
      weak: _weakCount,
      embersEarned: _earnedThisRun,
      bestCombo: _maxCombo,
      summited: summited,
    );
    if (summited) {
      final idx =
          (ProgressStore.summits - 1).clamp(0, Codex.all.length - 1);
      await ProgressStore.unlockCodex(Codex.all[idx].id);
    }
    _newlyUnlocked = await _evaluateAchievements(flawless: summited && _burns == 0);
    if (_newlyUnlocked.isNotEmpty) notifyListeners();
  }

  List<String> _newlyUnlocked = const [];
  List<String> takeNewlyUnlocked() {
    final v = _newlyUnlocked;
    _newlyUnlocked = const [];
    return v;
  }

  Future<List<String>> _evaluateAchievements({required bool flawless}) async {
    final newly = <String>[];
    Future<void> chk(String id, bool cond) async {
      if (cond && await ProgressStore.unlockAchievement(id)) newly.add(id);
    }

    final allGear = GearCatalog.all.every((g) => gearTier(g.id) > 0);
    var anyTriple = false;
    for (var i = 0; i < Levels.count; i++) {
      if (ProgressStore.levelStars(i) >= 3) anyTriple = true;
    }
    final flowSolved = Levels.all
        .where((l) => l.isFlow)
        .any((l) => ProgressStore.isLevelCleared(l.index));
    final cleared = ProgressStore.levelsCleared();

    await chk('first_summit', ProgressStore.summits >= 1);
    await chk('reach_10', cleared >= 10);
    await chk('reach_25', cleared >= 25);
    await chk('reach_50', cleared >= 50);
    await chk('flawless', flawless);
    await chk('combo_master', ProgressStore.bestCombo >= 14);
    await chk('perfect_streak_10', _bestStreak >= 10);
    await chk('full_gear', allGear);
    await chk('ember_hoarder', ProgressStore.embersEarned >= 10000);
    await chk('triple_star', anyTriple);
    await chk('flow_solver', flowSolved);
    await chk('veteran', ProgressStore.totalRuns >= 50);
    await chk('sharp_eye', ProgressStore.perfectStrikes >= 500);
    return newly;
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

  void setSound(bool value) {
    Feedback.soundEnabled = value;
    ProgressStore.setSound(value);
    notifyListeners();
  }

  bool get soundEnabled => Feedback.soundEnabled;
}
