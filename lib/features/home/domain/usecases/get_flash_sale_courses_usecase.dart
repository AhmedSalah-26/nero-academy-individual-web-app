import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/course_entity.dart';
import '../repositories/home_repository.dart';

/// Get Flash Sale Courses UseCase Params
class GetFlashSaleCoursesParams {
  final int limit;
  const GetFlashSaleCoursesParams({this.limit = 10});
}

/// Get Flash Sale Courses UseCase
class GetFlashSaleCoursesUseCase
    implements
        UseCaseWithParams<List<CourseEntity>, GetFlashSaleCoursesParams> {
  final HomeRepository repository;

  GetFlashSaleCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourseEntity>>> call(
      GetFlashSaleCoursesParams params) {
    return repository.getFlashSaleCourses(limit: params.limit);
  }
}
