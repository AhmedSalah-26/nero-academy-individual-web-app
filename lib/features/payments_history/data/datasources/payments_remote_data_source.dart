import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/payment_model.dart';

abstract class PaymentsRemoteDataSource {
  Future<List<PaymentModel>> getUserPayments(String userId);
  Future<PaymentModel?> getPaymentById(String paymentId);
}

class PaymentsRemoteDataSourceImpl implements PaymentsRemoteDataSource {
  final ApiClient apiClient;

  PaymentsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PaymentModel>> getUserPayments(String userId) async {
    debugPrint('💰 [PaymentsRemote] Getting user payments');
    try {
      final response = await apiClient.get('/payments/history');
      final list = response['payments'] as List;
      return list.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('⚠️ [PaymentsRemote] getUserPayments failed: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    debugPrint('💰 [PaymentsRemote] Getting payment details: $paymentId');
    try {
      final response = await apiClient.get('/payments/$paymentId');
      if (response['payment'] == null) return null;
      return PaymentModel.fromJson(response['payment'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ [PaymentsRemote] getPaymentById failed: $e');
      throw ServerException(e.toString());
    }
  }
}
