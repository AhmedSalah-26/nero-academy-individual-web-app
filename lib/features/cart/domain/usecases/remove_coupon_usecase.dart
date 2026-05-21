import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Remove Coupon Use Case
class RemoveCouponUseCase extends UseCaseWithParams<void, RemoveCouponParams> {
  final CartRepository repository;

  RemoveCouponUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveCouponParams params) {
    return repository.removeCoupon(params.userId);
  }
}

/// Remove Coupon Parameters
class RemoveCouponParams {
  final String userId;

  const RemoveCouponParams({required this.userId});
}
