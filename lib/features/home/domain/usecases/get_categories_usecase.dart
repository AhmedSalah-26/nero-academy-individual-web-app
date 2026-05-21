import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/home_repository.dart';

/// Get Categories UseCase
class GetCategoriesUseCase implements UseCase<List<CategoryEntity>> {
  final HomeRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call() {
    return repository.getCategories();
  }
}
