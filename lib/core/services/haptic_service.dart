import 'package:flutter/services.dart';

/// Haptic Feedback Service
/// Provides consistent haptic feedback across the app
class HapticService {
  HapticService._();

  /// Light impact - for button taps, toggles
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for selections, confirmations
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important actions, errors
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click - for list selections, tab changes
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate - for notifications, alerts
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  /// Success feedback - light impact for positive actions
  static void success() {
    HapticFeedback.lightImpact();
  }

  /// Error feedback - heavy impact for errors
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// Warning feedback - medium impact for warnings
  static void warning() {
    HapticFeedback.mediumImpact();
  }
}
