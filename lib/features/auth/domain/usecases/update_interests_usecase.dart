import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateInterestsUseCase
    implements UseCaseWithParams<UserEntity, List<String>> {
  final AuthRepository repository;

  UpdateInterestsUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(List<String> interests) {
    return repository.updateInterests(interests);
  }
}
