import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/course_player_repository.dart';

/// Delete Bookmark UseCase
class DeleteBookmarkUseCase
    extends UseCaseWithParams<void, DeleteBookmarkParams> {
  final CoursePlayerRepository repository;

  DeleteBookmarkUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBookmarkParams params) {
    return repository.deleteBookmark(bookmarkId: params.bookmarkId);
  }
}

/// Parameters for DeleteBookmarkUseCase
class DeleteBookmarkParams {
  final String bookmarkId;

  const DeleteBookmarkParams({required this.bookmarkId});
}
