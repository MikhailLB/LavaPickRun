import 'package:flutter/services.dart';

/// Tactile + audible feedback layer.
///
/// Haptics communicate strike quality through the device's vibration engine.
/// A lightweight sound channel is layered on top using the platform's built-in
/// system sounds (no audio plugin / asset pipeline required), so the game has
/// audible feedback while keeping the binary lean. Both channels are
/// independently toggleable from Settings.
class Feedback {
  Feedback._();

  static bool enabled = true; // haptics
  static bool soundEnabled = true;

  static void _click() {
    if (soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  static void _alert() {
    if (soundEnabled) SystemSound.play(SystemSoundType.alert);
  }

  static void perfect() {
    if (enabled) HapticFeedback.mediumImpact();
    _click();
  }

  static void good() {
    if (enabled) HapticFeedback.lightImpact();
    _click();
  }

  static void weak() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void hazard() {
    if (enabled) HapticFeedback.heavyImpact();
    _alert();
  }

  static void milestone() {
    if (enabled) HapticFeedback.mediumImpact();
    _click();
  }

  /// Win fanfare — a short double cue.
  static void summit() {
    if (enabled) HapticFeedback.heavyImpact();
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
      Future.delayed(const Duration(milliseconds: 120),
          () => SystemSound.play(SystemSoundType.click));
    }
  }
}
