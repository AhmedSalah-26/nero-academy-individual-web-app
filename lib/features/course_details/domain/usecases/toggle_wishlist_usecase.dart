import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/course_details_repository.dart';

/// Toggle Wishlist UseCase
class ToggleWishlistUseCase extends UseCaseWithParams<bool, WishlistParams> {
  final CourseDetailsRepository repository;

  ToggleWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(WishlistParams params) {
    return repository.toggleWishlist(params.courseId, params.userId);
  }
}

/// Parameters for ToggleWishlistUseCase
class WishlistParams extends Equatable {
  final String courseId;
  final String userId;

  const WishlistParams({
    required this.courseId,
    required this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}
