import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

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

    // Supabase Auth Errors
    if (error is supabase.AuthException) {
      return _handleAuthException(error);
    }

    // Supabase PostgrestException (Database errors)
    if (error is supabase.PostgrestException) {
      return _handlePostgrestException(error);
    }

    // Supabase Storage Errors
    if (error is supabase.StorageException) {
      return ServerFailure(
        error.message,
        code: 'storage_error',
      );
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

  AuthFailure _handleAuthException(supabase.AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return const AuthFailure(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        code: 'invalid_credentials',
      );
    }

    if (message.contains('email already registered') ||
        message.contains('already registered')) {
      return const AuthFailure(
        'البريد الإلكتروني مستخدم بالفعل',
        code: 'email_already_in_use',
      );
    }

    if (message.contains('weak password')) {
      return const AuthFailure(
        'كلمة المرور ضعيفة جداً',
        code: 'weak_password',
      );
    }

    if (message.contains('user not found')) {
      return const AuthFailure(
        'لا يوجد حساب بهذا البريد الإلكتروني',
        code: 'user_not_found',
      );
    }

    if (message.contains('email not confirmed')) {
      return const AuthFailure(
        'يرجى تأكيد بريدك الإلكتروني أولاً',
        code: 'email_not_confirmed',
      );
    }

    if (message.contains('session expired') ||
        message.contains('jwt expired')) {
      return const AuthFailure(
        'انتهت صلاحية الجلسة، سجل دخولك مرة أخرى',
        code: 'session_expired',
      );
    }

    return AuthFailure(error.message, code: 'auth_error');
  }

  ServerFailure _handlePostgrestException(supabase.PostgrestException error) {
    final code = error.code;

    // Foreign Key Violation
    if (code == '23503') {
      return const ServerFailure(
        'لا يمكن حذف هذا العنصر لارتباطه ببيانات أخرى',
        code: 'foreign_key_violation',
      );
    }

    // Unique Violation
    if (code == '23505') {
      return const ServerFailure(
        'هذه البيانات موجودة بالفعل',
        code: 'unique_violation',
      );
    }

    // Not Null Violation
    if (code == '23502') {
      return const ServerFailure(
        'بعض الحقول المطلوبة فارغة',
        code: 'not_null_violation',
      );
    }

    // Check Violation
    if (code == '23514') {
      return const ServerFailure(
        'البيانات المدخلة غير صالحة',
        code: 'check_violation',
      );
    }

    // Permission Denied (RLS)
    if (code == '42501' || error.message.contains('permission denied')) {
      return const ServerFailure(
        'ليس لديك صلاحية لهذا الإجراء',
        code: 'permission_denied',
      );
    }

    // No rows returned (PGRST116)
    if (code == 'PGRST116') {
      return const ServerFailure(
        'لم يتم العثور على البيانات',
        code: 'not_found',
      );
    }

    return ServerFailure(
      error.message,
      code: code ?? 'database_error',
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
