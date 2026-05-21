import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/wishlist_item_entity.dart';
import '../repositories/wishlist_repository.dart';

/// Add To Wishlist Use Case
class AddToWishlistUseCase
    extends UseCaseWithParams<WishlistItemEntity, AddToWishlistParams> {
  final WishlistRepository repository;

  AddToWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, WishlistItemEntity>> call(AddToWishlistParams params) {
    return repository.addToWishlist(
      userId: params.userId,
      courseId: params.courseId,
    );
  }
}

/// Add To Wishlist Parameters
class AddToWishlistParams {
  final String userId;
  final String courseId;

  const AddToWishlistParams({
    required this.userId,
    required this.courseId,
  });
}
