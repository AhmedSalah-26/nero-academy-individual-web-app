import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/search_filter_entity.dart';
import '../repositories/course_search_repository.dart';

/// Get Categories Use Case
class GetCategoriesUseCase implements UseCase<List<CategoryEntity>> {
  final CourseSearchRepository _repository;

  GetCategoriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call() async {
    return await _repository.getCategories();
  }
}
