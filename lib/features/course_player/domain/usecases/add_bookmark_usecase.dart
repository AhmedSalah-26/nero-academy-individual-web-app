import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bookmark_entity.dart';
import '../repositories/course_player_repository.dart';

/// Add Bookmark UseCase
class AddBookmarkUseCase
    extends UseCaseWithParams<BookmarkEntity, AddBookmarkParams> {
  final CoursePlayerRepository repository;

  AddBookmarkUseCase(this.repository);

  @override
  Future<Either<Failure, BookmarkEntity>> call(AddBookmarkParams params) {
    return repository.addBookmark(
      lessonId: params.lessonId,
      enrollmentId: params.enrollmentId,
      note: params.note,
    );
  }
}

/// Parameters for AddBookmarkUseCase
class AddBookmarkParams {
  final String lessonId;
  final String enrollmentId;
  final String? note;

  const AddBookmarkParams({
    required this.lessonId,
    required this.enrollmentId,
    this.note,
  });
}
