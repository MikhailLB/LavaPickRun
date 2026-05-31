import 'package:flutter/foundation.dart';

/// How clean a single strike landed against the moving timing band.
enum StrikeQuality {
  perfect,
  good,
  weak,
  burned, // struck during an eruption window
  overheat, // struck while the core was overheated / venting
}

/// Lifecycle of a single ascent attempt.
enum RunPhase {
  ready, // pre-run countdown / standby
  climbing,
  summit, // reached the top
  collapsed, // ran out of stability
}

/// The transient danger state of the volcano during a run.
enum HazardState {
  calm,
  telegraph, // warning shown, do NOT strike soon
  erupting, // active danger window, striking is punished
  venting, // forced cool-down after an overheat
}

/// Difficulty tiers. Each peak can be climbed on all three; harder tiers spin
/// the gauge faster, send eruptions sooner with shorter warnings, build heat
/// quicker and shrink the perfect band — but pay far more Embers. Hard unlocks
/// once every peak is cleared on Normal, Inferno once every peak is cleared on
/// Hard. This roughly triples the long-tail content over the same art.
enum Difficulty { normal, hard, inferno }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.normal => 'Normal',
        Difficulty.hard => 'Hard',
        Difficulty.inferno => 'Inferno',
      };

  String get short => switch (this) {
        Difficulty.normal => 'NORM',
        Difficulty.hard => 'HARD',
        Difficulty.inferno => 'INFERNO',
      };

  double get speedMul => switch (this) {
        Difficulty.normal => 1.0,
        Difficulty.hard => 1.18,
        Difficulty.inferno => 1.40,
      };

  double get gapMul => switch (this) {
        Difficulty.normal => 1.0,
        Difficulty.hard => 0.80,
        Difficulty.inferno => 0.62,
      };

  double get telegraphMul => switch (this) {
        Difficulty.normal => 1.0,
        Difficulty.hard => 0.85,
        Difficulty.inferno => 0.70,
      };

  double get heatMul => switch (this) {
        Difficulty.normal => 1.0,
        Difficulty.hard => 1.10,
        Difficulty.inferno => 1.22,
      };

  double get perfectMul => switch (this) {
        Difficulty.normal => 1.0,
        Difficulty.hard => 0.88,
        Difficulty.inferno => 0.78,
      };

  double get emberMul => switch (this) {
        Difficulty.normal => 1.0,
        Difficulty.hard => 1.7,
        Difficulty.inferno => 2.6,
      };
}

/// Immutable definition of one of the seven peaks.
@immutable
class Peak {
  const Peak({
    required this.index,
    required this.name,
    required this.subtitle,
    required this.backdrop,
    required this.sprite,
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
  });

  final int index;
  final String name;
  final String subtitle;
  final String backdrop;
  final String sprite;

  /// Full sweeps of the timing marker per second.
  final double gaugeSpeed;

  /// Ascent fraction (0..1) granted by a flawless strike before momentum.
  final double ascentPerPerfect;

  final double heatPerStrike;
  final double heatDecay; // per second

  final double eruptionGapMin; // seconds
  final double eruptionGapMax;
  final double eruptionWindow; // seconds the danger window stays open
  final double telegraph; // seconds of warning before the window opens

  /// Half-width of the perfect / good zones in gauge units (0..0.5).
  final double perfectBand;
  final double goodBand;

  /// Max combo needed during a run to earn the third star.
  final int comboGoal;

  int get displayNumber => index + 1;
}

/// Result payload emitted after every strike, consumed by the view layer for
/// floating feedback.
@immutable
class StrikeFlash {
  const StrikeFlash({
    required this.id,
    required this.quality,
    required this.ascentGain,
    required this.emberGain,
    required this.momentum,
  });

  final int id;
  final StrikeQuality quality;
  final double ascentGain;
  final int emberGain;
  final int momentum;
}
