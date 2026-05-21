import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_entity.dart';
import '../repositories/payments_repository.dart';

class GetUserPaymentsUseCase {
  final PaymentsRepository repository;

  GetUserPaymentsUseCase(this.repository);

  Future<Either<Failure, List<PaymentEntity>>> call(String userId) async {
    return await repository.getUserPayments(userId);
  }
}
