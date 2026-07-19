import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback] so call sites read as intent
/// (tap/toggle/success/warning) instead of raw impact levels.
class Haptics {
  Haptics._();

  static void tap() => HapticFeedback.selectionClick();
  static void toggle() => HapticFeedback.lightImpact();
  static void success() => HapticFeedback.mediumImpact();
  static void warning() => HapticFeedback.heavyImpact();
}
