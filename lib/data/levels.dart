import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';

import '../engine/models.dart';
import 'peaks.dart';

/// What kind of level this is — most are timing ascents, some are Lava Flow
/// pipe puzzles, so the campaign mixes mechanically different challenges.
enum LevelMode { ascent, flow }

/// Extra mechanics that can be layered onto an ascent level. They are
/// introduced one at a time as the campaign progresses, then combined so every
/// level has its own distinct mix.
enum AscentMod {
  vent, // periodic cooling vents you tap to dump heat
  echo, // a perfect strike opens a quick bonus "echo" tap window
  charge, // hold-and-release charged strikes instead of plain taps
  offsetHigh, // target band parks high on the gauge
  offsetLow, // target band parks low on the gauge
  shrink, // the perfect band narrows as you climb
  accel, // the marker speeds up as you climb
  purist, // only perfect strikes advance the climb
  hidden, // the band blinks invisible on a cycle
  doubleErupt, // eruptions come twice as often
  decoy, // a false red band that punishes if you strike it
}

String ascentModLabel(AscentMod m) => switch (m) {
      AscentMod.vent => 'Vents',
      AscentMod.echo => 'Echo',
      AscentMod.charge => 'Charged',
      AscentMod.offsetHigh => 'High Band',
      AscentMod.offsetLow => 'Low Band',
      AscentMod.shrink => 'Shrinking',
      AscentMod.accel => 'Accelerando',
      AscentMod.purist => 'Purist',
      AscentMod.hidden => 'Blackout',
      AscentMod.doubleErupt => 'Double Erupt',
      AscentMod.decoy => 'Decoy',
    };

/// One campaign level. The 50 levels form a single linear ladder (no separate
/// difficulty tabs). Difficulty rises smoothly across the ladder, and new
/// mechanics unlock at fixed milestones with an intro card the first time.
@immutable
class LevelDef {
  const LevelDef({
    required this.index,
    required this.mode,
    required this.artIndex,
    required this.trial,
    required this.mods,
    required this.gaugeSpeed,
    required this.ascentPerPerfect,
    required this.heatPerStrike,
    required this.heatDecay,
    required this.eruptionGapMin,
    required this.eruptionGapMax,
    required this.eruptionWindow,
    required this.telegraph,
    required this.perfectBand,
    required this.goodBand,
    required this.comboGoal,
    this.teaches,
    this.teachHint,
  });

  final int index;
  final LevelMode mode;
  final int artIndex;
  final PeakTrial trial;
  final Set<AscentMod> mods;

  final double gaugeSpeed;
  final double ascentPerPerfect;
  final double heatPerStrike;
  final double heatDecay;
  final double eruptionGapMin;
  final double eruptionGapMax;
  final double eruptionWindow;
  final double telegraph;
  final double perfectBand;
  final double goodBand;
  final int comboGoal;

  /// Name of a newly introduced mechanic on this level (null if nothing new).
  final String? teaches;
  final String? teachHint;

  int get displayNumber => index + 1;
  String get backdrop => Peaks.all[artIndex].backdrop;
  String get sprite => Peaks.all[artIndex].sprite;
  bool get isFlow => mode == LevelMode.flow;

  bool has(AscentMod m) => mods.contains(m);

  /// Build the immutable [Peak] the ascent engine runs on for this level.
  Peak toPeak() => Peak(
        index: index,
        name: 'Level $displayNumber',
        subtitle: Peaks.all[artIndex].name,
        backdrop: backdrop,
        sprite: sprite,
        gaugeSpeed: gaugeSpeed,
        ascentPerPerfect: ascentPerPerfect,
        heatPerStrike: heatPerStrike,
        heatDecay: heatDecay,
        eruptionGapMin: eruptionGapMin,
        eruptionGapMax: eruptionGapMax,
        eruptionWindow: eruptionWindow,
        telegraph: telegraph,
        perfectBand: perfectBand,
        goodBand: goodBand,
        comboGoal: comboGoal,
        trial: trial,
      );
}

class Levels {
  Levels._();

  static const int count = 50;

  static final List<LevelDef> all = _generate();

  static LevelDef byIndex(int i) => all[i.clamp(0, count - 1)];

  // Flow (pipe puzzle) levels interspersed through the ladder.
  static const Set<int> _flowLevels = {4, 9, 17, 25, 33, 41, 48};

  // First-time mechanic introductions (index -> label/hint).
  static const Map<int, List<String>> _teach = {
    0: ['Strike the Band', 'Tap when the marker crosses the gold band.'],
    1: ['High Band', 'The target band parks high on the gauge.'],
    2: ['Drifting Band', 'The gold band glides up and down — track it.'],
    3: ['Ember Gusts', 'Gusts push the marker faster and slower.'],
    4: ['Lava Flow', 'Rotate pipes to connect the source to the drain.'],
    5: ['Shifting Band', 'The band jumps to a new spot — re-aim fast.'],
    6: ['Cooling Vents', 'Tap the VENT when it appears to dump heat.'],
    7: ['Shrinking Band', 'The perfect band narrows as you climb.'],
    8: ['Purist', 'Only perfect strikes advance the climb.'],
    10: ['Blackout Band', 'The band blinks out — strike on rhythm.'],
    11: ['Echo Strike', 'After a perfect, tap again in the echo window.'],
    12: ['Accelerando', 'The marker speeds up the higher you climb.'],
    13: ['Decoy Band', 'A false red band punishes you — hit only the gold.'],
    14: ['Double Eruption', 'Eruptions come twice as often. Stay sharp.'],
    15: ['Charged Strike', 'Hold to charge, release on the band for a big hit.'],
    19: ['Squall', 'A drifting band and gusts at the same time.'],
    32: ['Tempest', 'The band leaps while gusts tear at the marker.'],
  };

  // Hand-authored early ladder so variety hits from the very start, then a
  // rotating combo table keeps every later level distinct.
  static const Map<int, PeakTrial> _earlyTrial = {
    0: PeakTrial.steady,
    1: PeakTrial.steady,
    2: PeakTrial.drift,
    3: PeakTrial.gust,
    5: PeakTrial.shift,
    6: PeakTrial.gust,
    7: PeakTrial.drift,
    8: PeakTrial.shift,
    10: PeakTrial.drift,
    11: PeakTrial.gust,
    12: PeakTrial.shift,
    13: PeakTrial.squall,
    14: PeakTrial.gust,
    15: PeakTrial.drift,
  };

  static const Map<int, Set<AscentMod>> _earlyMods = {
    0: <AscentMod>{},
    1: {AscentMod.offsetHigh},
    2: <AscentMod>{},
    3: <AscentMod>{},
    5: <AscentMod>{},
    6: {AscentMod.vent},
    7: {AscentMod.shrink},
    8: {AscentMod.purist},
    10: {AscentMod.hidden},
    11: {AscentMod.echo},
    12: {AscentMod.accel},
    13: {AscentMod.decoy},
    14: {AscentMod.doubleErupt, AscentMod.vent},
    15: {AscentMod.charge},
  };

  static const List<PeakTrial> _trialCycle = [
    PeakTrial.drift,
    PeakTrial.gust,
    PeakTrial.shift,
    PeakTrial.squall,
    PeakTrial.tempest,
  ];

  // Distinct combos for the later ladder; each adjacent level differs.
  static const List<Set<AscentMod>> _comboPool = [
    {AscentMod.shrink},
    {AscentMod.accel, AscentMod.vent},
    {AscentMod.purist},
    {AscentMod.hidden},
    {AscentMod.decoy},
    {AscentMod.doubleErupt, AscentMod.echo},
    {AscentMod.offsetHigh, AscentMod.shrink},
    {AscentMod.offsetLow, AscentMod.accel},
    {AscentMod.hidden, AscentMod.vent},
    {AscentMod.decoy, AscentMod.charge},
    {AscentMod.purist, AscentMod.doubleErupt},
    {AscentMod.shrink, AscentMod.echo},
    {AscentMod.accel, AscentMod.decoy},
    {AscentMod.offsetHigh, AscentMod.hidden},
    {AscentMod.offsetLow, AscentMod.doubleErupt, AscentMod.vent},
    {AscentMod.purist, AscentMod.hidden},
    {AscentMod.charge, AscentMod.shrink},
    {AscentMod.decoy, AscentMod.doubleErupt},
  ];

  static PeakTrial _trialFor(int i) =>
      _earlyTrial[i] ?? _trialCycle[i % _trialCycle.length];

  static Set<AscentMod> _modsFor(int i) =>
      _earlyMods[i] ?? _comboPool[i % _comboPool.length];

  static List<LevelDef> _generate() {
    final out = <LevelDef>[];
    for (var i = 0; i < count; i++) {
      final t = i / (count - 1); // 0..1 difficulty progress
      final isFlow = _flowLevels.contains(i);
      final teach = _teach[i];
      out.add(LevelDef(
        index: i,
        mode: isFlow ? LevelMode.flow : LevelMode.ascent,
        artIndex: i % Peaks.count,
        trial: isFlow ? PeakTrial.steady : _trialFor(i),
        mods: isFlow ? const <AscentMod>{} : _modsFor(i),
        gaugeSpeed: lerpDouble(0.42, 1.05, t)!,
        ascentPerPerfect: lerpDouble(0.046, 0.014, t)!,
        heatPerStrike: lerpDouble(0.080, 0.150, t)!,
        heatDecay: lerpDouble(0.26, 0.20, t)!,
        eruptionGapMin: lerpDouble(7.5, 4.0, t)!,
        eruptionGapMax: lerpDouble(11.5, 6.0, t)!,
        eruptionWindow: lerpDouble(1.0, 1.32, t)!,
        telegraph: lerpDouble(1.12, 0.70, t)!,
        perfectBand: lerpDouble(0.098, 0.050, t)!,
        goodBand: lerpDouble(0.225, 0.150, t)!,
        comboGoal: lerpDouble(6, 16, t)!.round(),
        teaches: teach?[0],
        teachHint: teach?[1],
      ));
    }
    return out;
  }
}
