import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/coupon_entity.dart';
import '../repositories/cart_repository.dart';

/// Apply Coupon Use Case
class ApplyCouponUseCase
    extends UseCaseWithParams<CouponEntity, ApplyCouponParams> {
  final CartRepository repository;

  ApplyCouponUseCase(this.repository);

  @override
  Future<Either<Failure, CouponEntity>> call(ApplyCouponParams params) {
    return repository.applyCoupon(
      userId: params.userId,
      couponCode: params.couponCode,
    );
  }
}

/// Apply Coupon Parameters
class ApplyCouponParams {
  final String userId;
  final String couponCode;

  const ApplyCouponParams({
    required this.userId,
    required this.couponCode,
  });
}
