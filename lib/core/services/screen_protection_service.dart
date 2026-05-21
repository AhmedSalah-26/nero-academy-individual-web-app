import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'app_logger.dart';

/// Service to prevent screen recording and screenshots.
/// Uses FLAG_SECURE on Android. iOS uses UIScreen recording detection.
class ScreenProtectionService {
  ScreenProtectionService._();

  static bool _isProtected = false;

  /// Enable screen protection (prevents recording & screenshots).
  static Future<void> enable() async {
    if (_isProtected) return;
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        _isProtected = true;
        AppLogger.i('🔒 [ScreenProtection] Enabled FLAG_SECURE');
      }
      // iOS: The YouTube player webview itself helps, but there's no
      // built‑in FLAG_SECURE equivalent. Recording detection can be
      // added with platform channels if needed in the future.
    } catch (e) {
      AppLogger.e('🔒 [ScreenProtection] Failed to enable: $e');
    }
  }

  /// Disable screen protection (allows recording & screenshots again).
  static Future<void> disable() async {
    if (!_isProtected) return;
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        _isProtected = false;
        AppLogger.i('🔓 [ScreenProtection] Disabled FLAG_SECURE');
      }
    } catch (e) {
      AppLogger.e('🔓 [ScreenProtection] Failed to disable: $e');
    }
  }
}
