import 'package:flutter/material.dart';

import 'progress_store.dart';

/// A selectable accent skin. Changing it re-tints the home hero glow, headers
/// and primary accents that listen to [appSkin].
@immutable
class AppSkin {
  const AppSkin({
    required this.id,
    required this.name,
    required this.accent,
    required this.glow,
  });

  final String id;
  final String name;
  final Color accent;
  final Color glow;
}

class Skins {
  Skins._();

  static const List<AppSkin> all = [
    AppSkin(
      id: 'ember',
      name: 'Ember',
      accent: Color(0xFFFF6D00),
      glow: Color(0xFFFF3D00),
    ),
    AppSkin(
      id: 'ash',
      name: 'Ashen',
      accent: Color(0xFF9E9E9E),
      glow: Color(0xFF607D8B),
    ),
    AppSkin(
      id: 'sulfur',
      name: 'Sulfur',
      accent: Color(0xFFFFD54A),
      glow: Color(0xFFFFA000),
    ),
    AppSkin(
      id: 'obsidian',
      name: 'Obsidian',
      accent: Color(0xFF7E57C2),
      glow: Color(0xFF4527A0),
    ),
    AppSkin(
      id: 'glacier',
      name: 'Glacier',
      accent: Color(0xFF4FC3F7),
      glow: Color(0xFF0277BD),
    ),
    AppSkin(
      id: 'verdant',
      name: 'Verdant',
      accent: Color(0xFF66BB6A),
      glow: Color(0xFF2E7D32),
    ),
  ];

  static AppSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}

/// Global, listenable current skin. Initialised from [ProgressStore] at boot.
final ValueNotifier<AppSkin> appSkin =
    ValueNotifier<AppSkin>(Skins.byId('ember'));

void initSkin() {
  appSkin.value = Skins.byId(ProgressStore.themeId);
}

Future<void> selectSkin(String id) async {
  await ProgressStore.setThemeId(id);
  appSkin.value = Skins.byId(id);
}
