import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lesson_progress_entity.dart';
import '../repositories/course_player_repository.dart';

/// Update Lesson Progress UseCase
class UpdateLessonProgressUseCase extends UseCaseWithParams<
    LessonProgressEntity, UpdateLessonProgressParams> {
  final CoursePlayerRepository repository;

  UpdateLessonProgressUseCase(this.repository);

  @override
  Future<Either<Failure, LessonProgressEntity>> call(
      UpdateLessonProgressParams params) {
    return repository.updateLessonProgress(
      lessonId: params.lessonId,
      enrollmentId: params.enrollmentId,
      watchedSeconds: params.watchedSeconds,
      lastPosition: params.lastPosition,
    );
  }
}

/// Parameters for UpdateLessonProgressUseCase
class UpdateLessonProgressParams {
  final String lessonId;
  final String enrollmentId;
  final int watchedSeconds;
  final int lastPosition;

  const UpdateLessonProgressParams({
    required this.lessonId,
    required this.enrollmentId,
    required this.watchedSeconds,
    required this.lastPosition,
  });
}
