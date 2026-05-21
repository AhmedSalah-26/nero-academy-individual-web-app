import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/enrollment_entity.dart';
import '../repositories/my_learning_repository.dart';

/// Get Continue Learning Use Case
class GetContinueLearningUseCase
    extends UseCaseWithParams<EnrollmentEntity?, String> {
  final MyLearningRepository repository;

  GetContinueLearningUseCase(this.repository);

  @override
  Future<Either<Failure, EnrollmentEntity?>> call(String userId) {
    return repository.getContinueLearning(userId);
  }
}
