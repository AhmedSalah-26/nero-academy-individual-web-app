import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/course_entity.dart';
import '../repositories/home_repository.dart';

/// Get New Courses UseCase Params
class GetNewCoursesParams {
  final int limit;
  const GetNewCoursesParams({this.limit = 10});
}

/// Get New Courses UseCase
class GetNewCoursesUseCase
    implements UseCaseWithParams<List<CourseEntity>, GetNewCoursesParams> {
  final HomeRepository repository;

  GetNewCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourseEntity>>> call(GetNewCoursesParams params) {
    return repository.getNewCourses(limit: params.limit);
  }
}
