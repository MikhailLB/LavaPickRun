import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class VolcanoTap {
  static const String _key = 'ea_resume_dest';

  /// Returns and clears the URL stored by SceneDelegate on cold-start tap.
  /// On iOS scene-based apps, tapping a killed-app notification routes through
  /// SceneDelegate before Dart code is alive. SceneDelegate writes the URL to
  /// UserDefaults under `flutter.ea_resume_dest`; the `flutter.` prefix lets
  /// SharedPreferences read it transparently.
  static Future<String?> consumeTapUrl() async {
    if (!Platform.isIOS) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) return null;
      await prefs.remove(_key);
      return raw.trim();
    } catch (_) {
      return null;
    }
  }
}
