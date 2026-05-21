import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger instance
class AppLogger {
  static final Logger _logger = Logger(
    level: kReleaseMode ? Level.off : Level.debug,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Log info message
  static void i(String message, [dynamic data]) {
    if (kReleaseMode) return;
    if (data != null) {
      _logger.i('$message\n$data');
    } else {
      _logger.i(message);
    }
  }

  /// Log debug message
  static void d(String message, [dynamic data]) {
    if (kReleaseMode) return;
    if (data != null) {
      _logger.d('$message\n$data');
    } else {
      _logger.d(message);
    }
  }

  /// Log warning message
  static void w(String message, [dynamic data]) {
    if (kReleaseMode) return;
    if (data != null) {
      _logger.w('$message\n$data');
    } else {
      _logger.w(message);
    }
  }

  /// Log error message
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log success message (using info with checkmark)
  static void success(String message, [dynamic data]) {
    if (kReleaseMode) return;
    if (data != null) {
      _logger.i('✅ $message\n$data');
    } else {
      _logger.i('✅ $message');
    }
  }

  /// Log step in a process
  static void step(int stepNumber, String description, [dynamic data]) {
    if (kReleaseMode) return;
    if (data != null) {
      _logger.i('📍 Step $stepNumber: $description\n$data');
    } else {
      _logger.i('📍 Step $stepNumber: $description');
    }
  }
}
