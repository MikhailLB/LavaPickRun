import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class SettingsService {
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';

  static bool soundEnabled = true;
  static bool vibrationEnabled = true;

  static final AudioPlayer _tapPlayer = AudioPlayer();
  static bool _playerReady = false;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool(_soundKey) ?? true;
    vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    await _preloadTapSound();
  }

  static Future<void> _preloadTapSound() async {
    try {
      await _tapPlayer.setReleaseMode(ReleaseMode.stop);
      await _tapPlayer.setVolume(0.6);
      await _tapPlayer.setSource(AssetSource('Sounds/tap.mp3'));
      _playerReady = true;
    } catch (_) {
      _playerReady = false;
    }
  }

  static Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  static Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
  }

  /// Called on every volcano tap
  static void onTap() {
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    if (soundEnabled && _playerReady) {
      // Stop any previous playback and replay from start for rapid taps
      _tapPlayer.stop().then((_) => _tapPlayer.resume());
    }
  }

  static void dispose() {
    _tapPlayer.dispose();
  }
}
