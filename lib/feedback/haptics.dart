import 'package:flutter/services.dart';

/// Tactile feedback layer.
///
/// The original build leaned on the `audioplayers` package to ping a sound on
/// every tap. Ember Ascent drops that dependency entirely and communicates
/// strike quality through the device's haptic engine instead, which keeps the
/// binary lean and avoids an audio plugin we do not otherwise need.
class Feedback {
  Feedback._();

  static bool enabled = true;

  static void perfect() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void good() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  static void weak() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  static void hazard() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  static void milestone() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }
}
