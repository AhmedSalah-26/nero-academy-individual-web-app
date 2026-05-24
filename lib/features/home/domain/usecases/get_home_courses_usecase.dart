import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/home_courses_entity.dart';
import '../repositories/home_repository.dart';

class GetHomeCoursesParams {
  final int limit;
  const GetHomeCoursesParams({this.limit = 10});
}

class GetHomeCoursesUseCase
    implements UseCaseWithParams<HomeCoursesEntity, GetHomeCoursesParams> {
  final HomeRepository repository;

  GetHomeCoursesUseCase(this.repository);

  @override
  Future<Either<Failure, HomeCoursesEntity>> call(GetHomeCoursesParams params) {
    return repository.getHomeCourses(limit: params.limit);
  }
}
