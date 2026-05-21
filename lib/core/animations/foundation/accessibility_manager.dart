import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages accessibility preferences and reduce motion settings
class AccessibilityManager {
  static AccessibilityManager? _instance;
  SharedPreferences? _prefs;
  bool _animationsEnabled = true;

  AccessibilityManager._();

  /// Get singleton instance
  static AccessibilityManager get instance {
    _instance ??= AccessibilityManager._();
    return _instance!;
  }

  /// Initialize the manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _animationsEnabled = _prefs?.getBool('animations_enabled') ?? true;
  }

  /// Get from context
  static AccessibilityManager of(BuildContext context) {
    return instance;
  }

  /// Check if reduce motion is enabled (system-wide)
  bool reduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Check if animations are enabled (app-level setting)
  bool get animationsEnabled => _animationsEnabled;

  /// Set animations enabled state
  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    await _prefs?.setBool('animations_enabled', enabled);
  }

  /// Check if animations should play
  /// Takes into account both system and app-level settings
  bool shouldAnimate(BuildContext context) {
    // Check app-level setting first
    if (!_animationsEnabled) return false;

    // Check system reduce motion setting
    if (reduceMotionEnabled(context)) return false;

    return true;
  }

  /// Adjust duration based on accessibility settings
  /// Returns zero duration if animations are disabled
  Duration adjustDuration(BuildContext context, Duration original) {
    if (!shouldAnimate(context)) {
      return Duration.zero;
    }
    return original;
  }

  /// Get simplified duration for reduce motion mode
  /// Returns a shorter duration instead of zero
  Duration getSimplifiedDuration(BuildContext context, Duration original) {
    if (!_animationsEnabled) {
      return Duration.zero;
    }

    if (reduceMotionEnabled(context)) {
      // Reduce duration to 1/3 of original
      return Duration(milliseconds: original.inMilliseconds ~/ 3);
    }

    return original;
  }
}
