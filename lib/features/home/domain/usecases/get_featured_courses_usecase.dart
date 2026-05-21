import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/course_entity.dart';
import '../repositories/home_repository.dart';

/// Get Featured Courses UseCase Params
class GetFeaturedCoursesParams {
  final int limit;
  const GetFeaturedCoursesParams({this.limit = 10});
}

/// Get Featured Courses UseCase
class GetFeaturedCoursesUseCase
    implements UseCaseWithParams<List<CourseEntity>, GetFeaturedCoursesParams> {
  final HomeRepository repository;

  GetFeaturedCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourseEntity>>> call(
      GetFeaturedCoursesParams params) {
    return repository.getFeaturedCourses(limit: params.limit);
  }
}
