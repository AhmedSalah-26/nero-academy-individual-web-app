import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/instructor_earning_model.dart';
import '../models/instructor_balance_model.dart';
import '../models/instructor_payout_model.dart';

/// Instructor Earnings Data Source — NEW SCHEMA
/// Tables: instructor_balance, earnings_transactions, withdraw_requests
class InstructorEarningsDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorEarningsDS';

  InstructorEarningsDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ─────────────────────────────────────────────────────
  // WALLET SUMMARY
  // ─────────────────────────────────────────────────────

  /// Get wallet summary from instructor_balance table
  Future<WalletSummaryModel> getWalletSummary() async {
    AppLogger.d('[$_tag] getWalletSummary: userId=$_userId');
    try {
      final response = await _client
          .from('instructor_balance')
          .select()
          .eq('instructor_id', _userId)
          .maybeSingle();

      if (response == null) {
        AppLogger.w(
            '[$_tag] getWalletSummary: no balance row found, returning empty');
        return WalletSummaryModel.empty;
      }

      final summary = WalletSummaryModel.fromJson(response);
      AppLogger.success(
          '[$_tag] getWalletSummary: available=${summary.availableBalance}, '
          'pending=${summary.pendingBalance}, '
          'totalEarnings=${summary.totalEarnings}, '
          'withdrawn=${summary.totalWithdrawn}');
      return summary;
    } catch (e, s) {
      AppLogger.e('[$_tag] getWalletSummary error', e, s);
      return WalletSummaryModel.empty;
    }
  }

  // ─────────────────────────────────────────────────────
  // EARNINGS TRANSACTIONS
  // ─────────────────────────────────────────────────────

  /// Get earnings transactions (feeds "سجل الأرباح")
  Future<List<EarningsTransactionModel>> getTransactions({
    String? courseId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d(
        '[$_tag] getTransactions: courseId=$courseId, status=$status, page=$page');
    try {
      var query =
          _client.from('earnings_transactions').select().eq('user_id', _userId);

      if (courseId != null) query = query.eq('course_id', courseId);
      if (status != null) query = query.eq('status', status);
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final transactions = (response as List)
          .map((e) =>
              EarningsTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.success(
          '[$_tag] getTransactions: ${transactions.length} transactions');
      return transactions;
    } catch (e, s) {
      AppLogger.e('[$_tag] getTransactions error', e, s);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────
  // WITHDRAW REQUESTS
  // ─────────────────────────────────────────────────────

  /// Get withdraw request history
  Future<List<WithdrawRequestModel>> getWithdrawHistory({
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getWithdrawHistory: page=$page');
    try {
      final response = await _client
          .from('withdraw_requests')
          .select()
          .eq('user_id', _userId)
          .order('requested_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getWithdrawHistory: ${(response as List).length} requests');
      return response.map((e) => WithdrawRequestModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getWithdrawHistory error', e, s);
      rethrow;
    }
  }

  /// Submit a withdraw request
  /// Calls RPC: submit_withdraw_request
  /// Flow:
  ///   IF available_balance >= amount
  ///     - Deduct from available_balance
  ///     - Add to pending_balance
  ///     - Create withdraw_request status=pending
  Future<Map<String, dynamic>> submitWithdrawRequest({
    required double amount,
    required String method,
    required Map<String, String> accountDetails,
  }) async {
    AppLogger.d(
        '[$_tag] submitWithdrawRequest: amount=$amount, method=$method');
    try {
      final response = await _client.rpc('submit_withdraw_request', params: {
        'p_user_id': _userId,
        'p_amount': amount,
        'p_method': method,
        'p_account_details': accountDetails,
      });

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        AppLogger.success(
            '[$_tag] submitWithdrawRequest success: ${result['request_id']}');
        return result;
      } else {
        final error = result['error'] ?? 'Unknown error';
        AppLogger.e('[$_tag] submitWithdrawRequest failed: $error');
        throw Exception(error);
      }
    } catch (e, s) {
      AppLogger.e('[$_tag] submitWithdrawRequest error', e, s);
      rethrow;
    }
  }
}
