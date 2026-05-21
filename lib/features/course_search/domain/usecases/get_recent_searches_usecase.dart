import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/course_search_repository.dart';

/// Get Recent Searches Use Case
class GetRecentSearchesUseCase implements UseCase<List<String>> {
  final CourseSearchRepository _repository;

  GetRecentSearchesUseCase(this._repository);

  @override
  Future<Either<Failure, List<String>>> call() async {
    return await _repository.getRecentSearches();
  }
}
