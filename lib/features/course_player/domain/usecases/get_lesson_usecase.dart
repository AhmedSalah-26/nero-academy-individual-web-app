import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lesson_entity.dart';
import '../repositories/course_player_repository.dart';

/// Get Lesson UseCase
class GetLessonUseCase
    extends UseCaseWithParams<LessonEntity, GetLessonParams> {
  final CoursePlayerRepository repository;

  GetLessonUseCase(this.repository);

  @override
  Future<Either<Failure, LessonEntity>> call(GetLessonParams params) {
    return repository.getLesson(lessonId: params.lessonId);
  }
}

/// Parameters for GetLessonUseCase
class GetLessonParams {
  final String lessonId;

  const GetLessonParams({required this.lessonId});
}
