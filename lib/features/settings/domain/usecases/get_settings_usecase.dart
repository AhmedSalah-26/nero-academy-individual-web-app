import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

/// Get Settings Use Case
class GetSettingsUseCase
    implements UseCaseWithParams<SettingsEntity, GetSettingsParams> {
  final SettingsRepository repository;

  GetSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, SettingsEntity>> call(GetSettingsParams params) {
    return repository.getSettings(userId: params.userId);
  }
}

/// Get Settings Params
class GetSettingsParams {
  final String userId;

  const GetSettingsParams({required this.userId});
}
