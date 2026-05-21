import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/instructor_commission_model.dart';

/// Admin Commission Data Source — manages instructor commission rates
class AdminCommissionDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminCommissionDS';

  AdminCommissionDataSource(this._client);

  /// Get all instructor commissions via RPC
  Future<List<InstructorCommissionModel>> getInstructorCommissions() async {
    try {
      AppLogger.i('📊 [$_tag] Fetching instructor commissions');

      final response = await _client.rpc('get_instructor_commissions');

      if (response == null) {
        AppLogger.w('📊 [$_tag] No data returned from RPC');
        return [];
      }

      final list = (response as List)
          .map((json) =>
              InstructorCommissionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.success(
          '📊 [$_tag] Fetched ${list.length} instructor commissions');
      return list;
    } catch (e) {
      AppLogger.e('📊 [$_tag] Error fetching commissions: $e');
      // Fallback: fetch from profiles + instructor_profiles
      return _fallbackFetch();
    }
  }

  /// Fallback fetch if RPC doesn't exist yet
  Future<List<InstructorCommissionModel>> _fallbackFetch() async {
    try {
      AppLogger.i('📊 [$_tag] Using fallback fetch');

      final response = await _client
          .from('profiles')
          .select(
              'id, name, email, avatar_url, instructor_profiles!inner(revenue_share, total_courses, total_students, is_verified)')
          .eq('role', 'instructor')
          .order('name', ascending: true);

      return (response as List).map((json) {
        final profile = json as Map<String, dynamic>;
        final instructorProfile =
            profile['instructor_profiles'] as Map<String, dynamic>?;
        final revenueShare =
            (instructorProfile?['revenue_share'] as num?)?.toDouble() ?? 70.0;

        return InstructorCommissionModel(
          instructorId: profile['id'] as String,
          name: profile['name'] as String?,
          email: profile['email'] as String?,
          avatarUrl: profile['avatar_url'] as String?,
          revenueShare: revenueShare,
          commissionRate: 100 - revenueShare,
          totalCourses: instructorProfile?['total_courses'] as int? ?? 0,
          totalStudents: instructorProfile?['total_students'] as int? ?? 0,
          isVerified: instructorProfile?['is_verified'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      AppLogger.e('📊 [$_tag] Fallback fetch also failed: $e');
      rethrow;
    }
  }

  /// Set commission rate for a specific instructor
  Future<bool> setInstructorCommission(
    String instructorId,
    double commissionRate,
  ) async {
    try {
      AppLogger.i(
          '📊 [$_tag] Setting commission for $instructorId to $commissionRate%');

      // Try RPC first
      try {
        final result =
            await _client.rpc('admin_set_instructor_commission', params: {
          'p_instructor_id': instructorId,
          'p_commission_rate': commissionRate,
        });

        if (result != null && result is Map && result['success'] == true) {
          AppLogger.success(
              '📊 [$_tag] Commission set via RPC: $commissionRate%');
          return true;
        }

        if (result != null && result is Map && result['error'] != null) {
          AppLogger.e('📊 [$_tag] RPC error: ${result['error']}');
          throw Exception(result['error']);
        }
      } catch (rpcError) {
        AppLogger.w(
            '📊 [$_tag] RPC not available, using direct update: $rpcError');
      }

      // Fallback: direct update
      final revenueShare = 100 - commissionRate;
      await _client.from('instructor_profiles').update({
        'revenue_share': revenueShare,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('instructor_id', instructorId);

      AppLogger.success(
          '📊 [$_tag] Commission set directly: $commissionRate% (revenue_share: $revenueShare%)');
      return true;
    } catch (e) {
      AppLogger.e('📊 [$_tag] Error setting commission: $e');
      rethrow;
    }
  }

  /// Get single instructor commission
  Future<double> getInstructorCommissionRate(String instructorId) async {
    try {
      final response = await _client
          .from('instructor_profiles')
          .select('revenue_share')
          .eq('instructor_id', instructorId)
          .maybeSingle();

      if (response == null) return 30.0; // default 30% commission

      final revenueShare =
          (response['revenue_share'] as num?)?.toDouble() ?? 70.0;
      return 100 - revenueShare;
    } catch (e) {
      AppLogger.e('📊 [$_tag] Error fetching commission rate: $e');
      return 30.0; // default
    }
  }
}
