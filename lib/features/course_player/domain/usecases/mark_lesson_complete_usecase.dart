import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lesson_progress_entity.dart';
import '../repositories/course_player_repository.dart';

/// Mark Lesson Complete UseCase
class MarkLessonCompleteUseCase
    extends UseCaseWithParams<LessonProgressEntity, MarkLessonCompleteParams> {
  final CoursePlayerRepository repository;

  MarkLessonCompleteUseCase(this.repository);

  @override
  Future<Either<Failure, LessonProgressEntity>> call(
      MarkLessonCompleteParams params) {
    return repository.markLessonComplete(
      lessonId: params.lessonId,
      enrollmentId: params.enrollmentId,
    );
  }
}

/// Parameters for MarkLessonCompleteUseCase
class MarkLessonCompleteParams {
  final String lessonId;
  final String enrollmentId;

  const MarkLessonCompleteParams({
    required this.lessonId,
    required this.enrollmentId,
  });
}
