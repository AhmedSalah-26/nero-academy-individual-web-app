import 'dart:io';

import 'exceptions.dart';
import 'failures.dart';

/// Unified Error Handler - يتعامل مع كل أنواع الأخطاء ويحولها لـ Failure
class ErrorHandler implements Exception {
  late Failure failure;

  ErrorHandler.handle(dynamic error) {
    failure = _handleError(error);
  }

  Failure _handleError(dynamic error) {
    // Network Errors
    if (error is SocketException) {
      return const NetworkFailure('لا يوجد اتصال بالإنترنت');
    }

    // Custom Exceptions
    if (error is ServerException) {
      return ServerFailure(error.message, code: error.code);
    }

    if (error is AuthException) {
      return AuthFailure(error.message, code: error.code);
    }

    if (error is CacheException) {
      return CacheFailure(error.message, code: error.code);
    }

    if (error is ValidationException) {
      return ValidationFailure(error.message, code: error.code);
    }

    // Timeout Errors
    if (error is TimeoutException) {
      return const NetworkFailure(
        'انتهت مهلة الاتصال، حاول مرة أخرى',
        code: 'timeout',
      );
    }

    // Format Exception
    if (error is FormatException) {
      return const ServerFailure(
        'خطأ في تنسيق البيانات',
        code: 'format_error',
      );
    }

    // Generic Error with message
    if (error is Exception) {
      final message = error.toString();
      if (_isNetworkError(message)) {
        return const NetworkFailure('لا يوجد اتصال بالإنترنت');
      }
      return const ServerFailure(
        'حدث خطأ غير متوقع',
        code: 'unknown_error',
      );
    }

    // Default
    return const ServerFailure(
      'حدث خطأ غير متوقع',
      code: 'unknown_error',
    );
  }

  bool _isNetworkError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no address associated') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection reset') ||
        lower.contains('connection timed out') ||
        lower.contains('clientexception');
  }
}

/// Timeout Exception
class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'Connection timeout']);
}
