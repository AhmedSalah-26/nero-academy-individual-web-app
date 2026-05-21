/// Base Exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Server/API Exception
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// Cache/Local Storage Exception
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Validation Exception
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Not Found Exception
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

/// Auth Exception with factory constructors
class AuthException extends AppException {
  const AuthException(super.message, {super.code});

  factory AuthException.invalidCredentials() {
    return const AuthException(
      'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      code: 'invalid_credentials',
    );
  }

  factory AuthException.emailAlreadyInUse() {
    return const AuthException(
      'البريد الإلكتروني مستخدم بالفعل',
      code: 'email_already_in_use',
    );
  }

  factory AuthException.weakPassword() {
    return const AuthException(
      'كلمة المرور ضعيفة جداً',
      code: 'weak_password',
    );
  }

  factory AuthException.userNotFound() {
    return const AuthException(
      'لا يوجد حساب بهذا البريد الإلكتروني',
      code: 'user_not_found',
    );
  }

  factory AuthException.sessionExpired() {
    return const AuthException(
      'انتهت صلاحية الجلسة، سجل دخولك مرة أخرى',
      code: 'session_expired',
    );
  }

  factory AuthException.userBanned(String? reason, DateTime? until) {
    String message = 'حسابك محظور';
    if (until != null) {
      final remaining = until.difference(DateTime.now());
      if (remaining.inDays > 0) {
        message += ' لمدة ${remaining.inDays} يوم';
      } else if (remaining.inHours > 0) {
        message += ' لمدة ${remaining.inHours} ساعة';
      }
    } else {
      message += ' نهائياً';
    }
    if (reason != null && reason.isNotEmpty) {
      message += '\nالسبب: $reason';
    }
    return AuthException(message, code: 'user_banned');
  }

  factory AuthException.userInactive() {
    return const AuthException(
      'حسابك غير مفعل. تواصل مع الدعم',
      code: 'user_inactive',
    );
  }
}
