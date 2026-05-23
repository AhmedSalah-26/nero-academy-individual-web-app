import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../models/instructor_earning_model.dart';
import '../models/instructor_balance_model.dart';
import '../models/instructor_payout_model.dart';

/// Instructor Earnings Data Source — reads from instructor_earnings
class InstructorEarningsDataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorEarningsDS';

  InstructorEarningsDataSource(this._apiClient);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      final transactions = response['transactions'];
      if (transactions is List) return transactions;
      final history = response['history'];
      if (history is List) return history;
    }
    return const [];
  }

  // ─────────────────────────────────────────────────────
  // WALLET SUMMARY
  // ─────────────────────────────────────────────────────

  /// Get wallet summary
  Future<WalletSummaryModel> getWalletSummary() async {
    AppLogger.d('[$_tag] getWalletSummary');
    try {
      final response = await _apiClient.get('/instructor/wallet/summary');
      AppLogger.success('[$_tag] getWalletSummary success');
      return WalletSummaryModel.fromJson(_asMap(response));
    } catch (e, s) {
      AppLogger.e('[$_tag] getWalletSummary error', e, s);
      return WalletSummaryModel.empty;
    }
  }

  // ─────────────────────────────────────────────────────
  // EARNINGS TRANSACTIONS
  // ─────────────────────────────────────────────────────

  /// Get earnings from instructor_earnings
  Future<List<EarningsTransactionModel>> getTransactions({
    String? courseId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getTransactions: courseId=$courseId, status=$status, page=$page');
    try {
      final queryParams = <String>[];
      if (courseId != null) queryParams.add('courseId=$courseId');
      if (status != null) queryParams.add('status=$status');
      if (startDate != null) queryParams.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toIso8601String()}');
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');

      final url = '/instructor/wallet/transactions?${queryParams.join('&')}';
      final response = await _apiClient.get(url);

      final list = _asList(response);
      AppLogger.success('[$_tag] getTransactions: ${list.length} transactions');
      return list.map((e) => EarningsTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
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
      final response = await _apiClient.get('/instructor/wallet/withdraw-history?page=$page&limit=$limit');
      final list = _asList(response);
      AppLogger.success('[$_tag] getWithdrawHistory: ${list.length} requests');
      return list.map((e) => WithdrawRequestModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getWithdrawHistory error', e, s);
      rethrow;
    }
  }

  /// Submit a withdraw request
  Future<Map<String, dynamic>> submitWithdrawRequest({
    required double amount,
    required String method,
    required Map<String, String> accountDetails,
  }) async {
    AppLogger.d('[$_tag] submitWithdrawRequest: amount=$amount, method=$method');
    try {
      final response = await _apiClient.post('/instructor/wallet/withdraw', body: {
        'p_amount': amount,
        'p_method': method,
        'p_account_details': accountDetails,
      });

      final result = _asMap(response);

      if (result['success'] == true) {
        AppLogger.success('[$_tag] submitWithdrawRequest success: ${result['request_id']}');
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
