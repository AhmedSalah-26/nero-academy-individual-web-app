import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bookmark_entity.dart';
import '../repositories/course_player_repository.dart';

/// Get Bookmarks UseCase
class GetBookmarksUseCase
    extends UseCaseWithParams<List<BookmarkEntity>, GetBookmarksParams> {
  final CoursePlayerRepository repository;

  GetBookmarksUseCase(this.repository);

  @override
  Future<Either<Failure, List<BookmarkEntity>>> call(
      GetBookmarksParams params) {
    return repository.getBookmarks(enrollmentId: params.enrollmentId);
  }
}

/// Parameters for GetBookmarksUseCase
class GetBookmarksParams {
  final String enrollmentId;

  const GetBookmarksParams({required this.enrollmentId});
}
