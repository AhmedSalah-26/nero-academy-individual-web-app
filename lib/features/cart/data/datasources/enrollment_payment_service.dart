import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle enrollment payment status reads.
class EnrollmentPaymentService {
  final SupabaseClient supabase;

  EnrollmentPaymentService({required this.supabase});

  /// Paymob confirmation is handled by the Edge Function webhook using the
  /// service role. The mobile client must not call the confirmation RPC.
  Future<bool> confirmPayment({
    required String parentEnrollmentId,
    required String transactionId,
  }) async {
    debugPrint(
      '[EnrollmentPayment] Payment success reported for '
      '$parentEnrollmentId; server webhook will confirm '
      'transaction $transactionId',
    );
    return true;
  }

  /// Get parent enrollment details.
  Future<Map<String, dynamic>?> getParentEnrollment(
    String parentEnrollmentId,
  ) async {
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

  /// Payment failure status is also owned by the backend/webhook path.
  Future<void> markPaymentFailed({
    required String parentEnrollmentId,
    String? errorMessage,
  }) async {
    debugPrint(
      '[EnrollmentPayment] Payment failure reported for '
      '$parentEnrollmentId; backend remains the source of truth. '
      'Error: ${errorMessage ?? 'none'}',
    );
  }
}
