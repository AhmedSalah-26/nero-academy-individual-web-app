import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCaseWithParams<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      name: params.name,
      role: params.role,
      phone: params.phone,
      headline: params.headline,
      bio: params.bio,
      expertise: params.expertise,
      avatarBytes: params.avatarBytes,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final String? phone;
  final String? headline;
  final String? bio;
  final List<String>? expertise;
  final Uint8List? avatarBytes;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    this.role = UserRole.student,
    this.phone,
    this.headline,
    this.bio,
    this.expertise,
    this.avatarBytes,
  });
}
