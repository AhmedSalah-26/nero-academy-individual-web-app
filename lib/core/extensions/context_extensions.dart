import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// BuildContext extension methods
extension ContextExtensions on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Get keyboard height
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => keyboardHeight > 0;

  /// Get current theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Check if dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Check if RTL
  bool get isRtl => locale.languageCode == 'ar';

  /// Get current locale
  Locale get currentLocale => locale;

  /// Show snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// Pop navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Check if can pop
  bool get canPop => Navigator.of(this).canPop();
}
