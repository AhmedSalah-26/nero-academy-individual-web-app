import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';

/// Service to handle enrollment payment confirmation via Laravel REST API
class EnrollmentPaymentService {
  final ApiClient apiClient;

  EnrollmentPaymentService({required this.apiClient});

  /// Confirm payment for a parent enrollment
  Future<bool> confirmPayment({
    required String parentEnrollmentId,
    required String transactionId,
  }) async {
    try {
      debugPrint(
          '🔵 [EnrollmentPayment] Confirming payment for: $parentEnrollmentId');
      debugPrint('🔵 [EnrollmentPayment] Transaction ID: $transactionId');

      final response = await apiClient.post(
        '/checkout/settle/$parentEnrollmentId',
        body: {
          'transaction_id': transactionId,
        },
      );

      debugPrint('✅ [EnrollmentPayment] Response: $response');
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ [EnrollmentPayment] Error: $e');
      throw Exception('Failed to confirm payment: $e');
    }
  }

  /// Get parent enrollment details
  Future<Map<String, dynamic>?> getParentEnrollment(
      String parentEnrollmentId) async {
    try {
      final response = await apiClient.get('/payments/$parentEnrollmentId');
      return response['payment'] as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get parent enrollment: $e');
    }
  }

  /// Update payment status to failed
  Future<void> markPaymentFailed({
    required String parentEnrollmentId,
    String? errorMessage,
  }) async {
    try {
      await apiClient.post('/checkout/fail/$parentEnrollmentId');
    } catch (e) {
      throw Exception('Failed to mark payment as failed: $e');
    }
  }
}
