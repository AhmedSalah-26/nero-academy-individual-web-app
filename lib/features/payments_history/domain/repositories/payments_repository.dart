import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_entity.dart';

abstract class PaymentsRepository {
  Future<Either<Failure, List<PaymentEntity>>> getUserPayments(String userId);
  Future<Either<Failure, PaymentEntity?>> getPaymentById(String paymentId);
}
