import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/course_entity.dart';
import '../repositories/home_repository.dart';

/// Get Popular Courses UseCase Params
class GetPopularCoursesParams {
  final int limit;
  const GetPopularCoursesParams({this.limit = 10});
}

/// Get Popular Courses UseCase
class GetPopularCoursesUseCase
    implements UseCaseWithParams<List<CourseEntity>, GetPopularCoursesParams> {
  final HomeRepository repository;

  GetPopularCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourseEntity>>> call(
      GetPopularCoursesParams params) {
    return repository.getPopularCourses(limit: params.limit);
  }
}
