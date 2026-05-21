import 'package:equatable/equatable.dart';

/// Base Failure class - كل الأخطاء ترث منه
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server/API Errors
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Authentication Errors
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Cache/Local Storage Errors
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Validation Errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Network/Connection Errors
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Not Found Errors
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Permission/Authorization Errors
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}
