import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/search_filter_entity.dart';
import '../repositories/course_search_repository.dart';

/// Search Courses Use Case
class SearchCoursesUseCase
    implements UseCaseWithParams<CourseSearchResult, SearchFilterEntity> {
  final CourseSearchRepository _repository;

  SearchCoursesUseCase(this._repository);

  @override
  Future<Either<Failure, CourseSearchResult>> call(
    SearchFilterEntity params,
  ) async {
    return await _repository.searchCourses(params);
  }
}
