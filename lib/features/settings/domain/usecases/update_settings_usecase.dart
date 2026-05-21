import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

/// Update Settings Use Case
class UpdateSettingsUseCase
    implements UseCaseWithParams<SettingsEntity, UpdateSettingsParams> {
  final SettingsRepository repository;

  UpdateSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, SettingsEntity>> call(UpdateSettingsParams params) {
    return repository.updateSettings(
      userId: params.userId,
      languageCode: params.languageCode,
      isDarkMode: params.isDarkMode,
      notificationsEnabled: params.notificationsEnabled,
      videoAutoplay: params.videoAutoplay,
    );
  }
}

/// Update Settings Params
class UpdateSettingsParams {
  final String userId;
  final String? languageCode;
  final bool? isDarkMode;
  final bool? notificationsEnabled;
  final bool? videoAutoplay;

  const UpdateSettingsParams({
    required this.userId,
    this.languageCode,
    this.isDarkMode,
    this.notificationsEnabled,
    this.videoAutoplay,
  });
}
