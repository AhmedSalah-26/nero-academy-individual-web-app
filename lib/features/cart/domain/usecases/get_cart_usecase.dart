import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

/// Get Cart Use Case
class GetCartUseCase extends UseCaseWithParams<CartEntity, GetCartParams> {
  final CartRepository repository;

  GetCartUseCase(this.repository);

  @override
  Future<Either<Failure, CartEntity>> call(GetCartParams params) {
    return repository.getCart(params.userId);
  }
}

/// Get Cart Parameters
class GetCartParams {
  final String userId;

  const GetCartParams({required this.userId});
}
