import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/wishlist_item_entity.dart';
import '../repositories/wishlist_repository.dart';

/// Get Wishlist Use Case
class GetWishlistUseCase
    extends UseCaseWithParams<List<WishlistItemEntity>, GetWishlistParams> {
  final WishlistRepository repository;

  GetWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, List<WishlistItemEntity>>> call(
      GetWishlistParams params) {
    return repository.getWishlist(params.userId);
  }
}

/// Get Wishlist Parameters
class GetWishlistParams {
  final String userId;

  const GetWishlistParams({required this.userId});
}
