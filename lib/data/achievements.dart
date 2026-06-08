import 'package:flutter/material.dart';

/// Static catalogue of achievements. Unlock state lives in [ProgressStore]
/// keyed by [id]; the engine unlocks ids at the end of a run. The screen only
/// needs the definitions plus the unlocked-id set to render.
@immutable
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String id;
  final String title;
  final String detail;
  final IconData icon;
}

class Achievements {
  Achievements._();

  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'first_summit',
      title: 'First Light',
      detail: 'Reach your first summit.',
      icon: Icons.flag_rounded,
    ),
    AchievementDef(
      id: 'flawless',
      title: 'Untouched',
      detail: 'Summit a peak without a single eruption burn.',
      icon: Icons.shield_moon_rounded,
    ),
    AchievementDef(
      id: 'combo_master',
      title: 'In the Zone',
      detail: 'Build a 14-strike combo in a single run.',
      icon: Icons.bolt_rounded,
    ),
    AchievementDef(
      id: 'perfect_streak_10',
      title: 'Metronome',
      detail: 'Land 10 perfect strikes in a row.',
      icon: Icons.timer_rounded,
    ),
    AchievementDef(
      id: 'triple_star',
      title: 'Three Stars',
      detail: 'Earn all three stars on any level.',
      icon: Icons.star_rounded,
    ),
    AchievementDef(
      id: 'reach_10',
      title: 'Trailblazer',
      detail: 'Clear 10 levels.',
      icon: Icons.terrain_rounded,
    ),
    AchievementDef(
      id: 'reach_25',
      title: 'Halfway to the Top',
      detail: 'Clear 25 levels.',
      icon: Icons.whatshot_rounded,
    ),
    AchievementDef(
      id: 'reach_50',
      title: 'Summit of Summits',
      detail: 'Clear 50 levels.',
      icon: Icons.workspace_premium_rounded,
    ),
    AchievementDef(
      id: 'reach_70',
      title: 'Caldera Conqueror',
      detail: 'Clear all 70 levels.',
      icon: Icons.local_fire_department_rounded,
    ),
    AchievementDef(
      id: 'flow_solver',
      title: 'Pipe Master',
      detail: 'Solve a Lava Flow puzzle level.',
      icon: Icons.water_drop_rounded,
    ),
    AchievementDef(
      id: 'full_gear',
      title: 'Geared Up',
      detail: 'Own at least one tier of every piece of gear.',
      icon: Icons.handyman_rounded,
    ),
    AchievementDef(
      id: 'ember_hoarder',
      title: 'Ember Hoarder',
      detail: 'Earn 10,000 embers in total.',
      icon: Icons.savings_rounded,
    ),
    AchievementDef(
      id: 'veteran',
      title: 'Veteran Climber',
      detail: 'Complete 50 runs.',
      icon: Icons.military_tech_rounded,
    ),
    AchievementDef(
      id: 'sharp_eye',
      title: 'Sharp Eye',
      detail: 'Land 500 perfect strikes across all runs.',
      icon: Icons.center_focus_strong_rounded,
    ),
  ];

  static AchievementDef byId(String id) => all.firstWhere((a) => a.id == id);
}
