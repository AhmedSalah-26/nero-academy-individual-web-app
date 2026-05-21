import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark }

class ThemeState {
  final AppThemeMode themeMode;
  final ThemeData themeData;

  const ThemeState({
    required this.themeMode,
    required this.themeData,
  });

  ThemeState copyWith({
    AppThemeMode? themeMode,
    ThemeData? themeData,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeData: themeData ?? this.themeData,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'app_theme_mode';

  ThemeCubit()
      : super(ThemeState(
          themeMode: AppThemeMode.light,
          themeData: _buildLightTheme(),
        )) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'light';
    final themeMode =
        themeString == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
    _applyTheme(themeMode);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _themeKey, mode == AppThemeMode.dark ? 'dark' : 'light');
    _applyTheme(mode);
  }

  void _applyTheme(AppThemeMode mode) {
    final themeData =
        mode == AppThemeMode.dark ? _buildDarkTheme() : _buildLightTheme();
    emit(ThemeState(themeMode: mode, themeData: themeData));
  }

  static ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFF8B4513);
    const secondaryColor = Color(0xFFB5651D);

    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Almarai',
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF5C4033),
        outline: Color(0xFFD3D3D3),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF5C4033),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      dividerColor: const Color(0xFFE0E0E0),
      textTheme: _buildTextTheme(Brightness.light),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: secondaryColor.withValues(alpha: 0.4),
        selectionHandleColor: primaryColor,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.light),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF5C4033)),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF696969),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFFB5651D);
    const secondaryColor = Color(0xFFD4894A);
    const surfaceColor = Color(0xFF1E1E1E);
    const cardColor = Color(0xFF2D2D2D);
    const textColor = Color(0xFFF5F5F5); // Lighter text for better visibility

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Almarai',
      primaryColor: primaryColor,
      scaffoldBackgroundColor: surfaceColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        onSurface: textColor,
        outline: Color(0xFF5A5A5A),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF4A4A4A), width: 1),
        ),
      ),
      dividerColor: const Color(0xFF4A4A4A),
      textTheme: _buildTextTheme(Brightness.dark),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: secondaryColor.withValues(alpha: 0.4),
        selectionHandleColor: primaryColor,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.dark),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: textColor),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFFB0B0B0),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? const Color(0xFF5C4033)
        : const Color(0xFFF5F5F5); // Lighter text for dark mode

    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Almarai', color: color),
      displayMedium: TextStyle(fontFamily: 'Almarai', color: color),
      displaySmall: TextStyle(fontFamily: 'Almarai', color: color),
      headlineLarge: TextStyle(fontFamily: 'Almarai', color: color),
      headlineMedium: TextStyle(fontFamily: 'Almarai', color: color),
      headlineSmall: TextStyle(fontFamily: 'Almarai', color: color),
      titleLarge: TextStyle(fontFamily: 'Almarai', color: color),
      titleMedium: TextStyle(fontFamily: 'Almarai', color: color),
      titleSmall: TextStyle(fontFamily: 'Almarai', color: color),
      bodyLarge: TextStyle(fontFamily: 'Almarai', color: color),
      bodyMedium: TextStyle(fontFamily: 'Almarai', color: color),
      bodySmall: TextStyle(fontFamily: 'Almarai', color: color),
      labelLarge: TextStyle(fontFamily: 'Almarai', color: color),
      labelMedium: TextStyle(fontFamily: 'Almarai', color: color),
      labelSmall: TextStyle(fontFamily: 'Almarai', color: color),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
      Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primaryColor =
        isLight ? const Color(0xFF8B4513) : const Color(0xFFB5651D);
    final borderColor =
        isLight ? const Color(0xFFB5651D) : const Color(0xFF4A4A4A);
    final hintColor =
        isLight ? const Color(0xFFA9A9A9) : const Color(0xFF757575);

    return InputDecorationTheme(
      labelStyle: TextStyle(
        color: primaryColor,
        fontFamily: 'Almarai',
      ),
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontFamily: 'Almarai',
      ),
      hintStyle: TextStyle(
        color: hintColor,
        fontFamily: 'Almarai',
      ),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontFamily: 'Almarai',
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
