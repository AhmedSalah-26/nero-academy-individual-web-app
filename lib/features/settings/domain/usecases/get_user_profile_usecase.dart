import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/settings_repository.dart';

/// Get User Profile Use Case
class GetUserProfileUseCase
    implements UseCaseWithParams<UserProfileEntity, GetUserProfileParams> {
  final SettingsRepository repository;

  GetUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(GetUserProfileParams params) {
    return repository.getUserProfile(userId: params.userId);
  }
}

/// Get User Profile Params
class GetUserProfileParams {
  final String userId;

  const GetUserProfileParams({required this.userId});
}
