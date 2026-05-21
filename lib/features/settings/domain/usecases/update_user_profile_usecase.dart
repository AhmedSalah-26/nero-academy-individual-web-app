import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/settings_repository.dart';

/// Update User Profile Use Case
class UpdateUserProfileUseCase
    implements UseCaseWithParams<UserProfileEntity, UpdateUserProfileParams> {
  final SettingsRepository repository;

  UpdateUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(
      UpdateUserProfileParams params) {
    return repository.updateUserProfile(
      userId: params.userId,
      name: params.name,
      phone: params.phone,
      avatarUrl: params.avatarUrl,
      interests: params.interests,
    );
  }
}

/// Update User Profile Params
class UpdateUserProfileParams {
  final String userId;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final List<String>? interests;

  const UpdateUserProfileParams({
    required this.userId,
    this.name,
    this.phone,
    this.avatarUrl,
    this.interests,
  });
}
