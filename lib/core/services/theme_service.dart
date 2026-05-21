import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Service - Manages dark mode state globally
/// This is the SINGLE SOURCE OF TRUTH for theme across the app
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _darkModeKey = 'app_dark_mode';

  final ValueNotifier<bool> isDarkMode = ValueNotifier(false);

  SharedPreferences? _prefs;

  /// Initialize the theme service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Check for saved preference
    final savedDarkMode = _prefs?.getBool(_darkModeKey);

    if (savedDarkMode != null) {
      // Use saved preference
      isDarkMode.value = savedDarkMode;
    } else {
      // No saved preference - follow system theme and save it
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode.value = brightness == Brightness.dark;
      // Save the initial value
      await _prefs?.setBool(_darkModeKey, isDarkMode.value);
    }
  }

  /// Set dark mode
  Future<void> setDarkMode(bool value) async {
    if (isDarkMode.value == value) return; // No change needed
    isDarkMode.value = value;
    await _prefs?.setBool(_darkModeKey, value);
  }

  /// Get current dark mode value
  bool get currentDarkMode => isDarkMode.value;
}
