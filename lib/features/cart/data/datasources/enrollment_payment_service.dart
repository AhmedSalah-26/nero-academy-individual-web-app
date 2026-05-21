import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle enrollment payment confirmation
class EnrollmentPaymentService {
  final SupabaseClient supabase;

  EnrollmentPaymentService({required this.supabase});

  /// Confirm payment for a parent enrollment
  /// This will:
  /// 1. Update parent_enrollment payment_status to 'paid'
  /// 2. Activate all enrollments
  /// 3. Update instructor earnings status
  Future<bool> confirmPayment({
    required String parentEnrollmentId,
    required String transactionId,
  }) async {
    try {
      debugPrint(
          '🔵 [EnrollmentPayment] Confirming payment for: $parentEnrollmentId');
      debugPrint('🔵 [EnrollmentPayment] Transaction ID: $transactionId');

      final response = await supabase.rpc(
        'confirm_enrollment_payment',
        params: {
          'p_parent_enrollment_id': parentEnrollmentId,
          'p_transaction_id': transactionId,
        },
      );

      debugPrint('✅ [EnrollmentPayment] RPC response: $response');
      return response == true;
    } catch (e) {
      debugPrint('❌ [EnrollmentPayment] Error: $e');
      throw Exception('Failed to confirm payment: $e');
    }
  }

  /// Get parent enrollment details
  Future<Map<String, dynamic>?> getParentEnrollment(
      String parentEnrollmentId) async {
    try {
      final response = await supabase
          .from('parent_enrollments')
          .select('*')
          .eq('id', parentEnrollmentId)
          .maybeSingle();

      return response;
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
      await supabase.from('parent_enrollments').update({
        'payment_status': 'failed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', parentEnrollmentId);
    } catch (e) {
      throw Exception('Failed to mark payment as failed: $e');
    }
  }
}
