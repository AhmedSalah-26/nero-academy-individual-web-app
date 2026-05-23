import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/repositories/instructor_repository.dart';
import '../models/instructor_models.dart';

/// Instructor Stats Data Source - Dashboard statistics and charts
class InstructorStatsDataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorStatsDS';

  InstructorStatsDataSource(this._apiClient);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final nested = response['stats'];
      if (nested is Map<String, dynamic>) return nested;
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      return response;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      final items = response['items'];
      if (items is List) return items;
    }
    return const [];
  }

  /// Get dashboard statistics
  Future<InstructorDashboardStatsModel> getDashboardStats() async {
    AppLogger.d('[$_tag] getDashboardStats');
    try {
      final response = await _apiClient.get('/instructor/stats');
      final stats = InstructorDashboardStatsModel.fromJson(_asMap(response));
      AppLogger.success('[$_tag] getDashboardStats success');
      return stats;
    } catch (e, s) {
      AppLogger.e('[$_tag] getDashboardStats error', e, s);
      rethrow;
    }
  }

  /// Get revenue chart data
  Future<List<ChartDataPoint>> getRevenueChart(
      DateTime start, DateTime end) async {
    AppLogger.d('[$_tag] getRevenueChart: start=$start, end=$end');
    try {
      final response = await _apiClient.get(
        '/instructor/charts/revenue?p_start_date=${start.toIso8601String()}&p_end_date=${end.toIso8601String()}',
      );

      final dataPoints = _asList(response).map((e) {
        return ChartDataPoint(
          label: e['label'] as String? ?? '',
          value: (e['value'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      AppLogger.success('[$_tag] getRevenueChart: ${dataPoints.length} points');
      return dataPoints;
    } catch (e, s) {
      AppLogger.e('[$_tag] getRevenueChart error', e, s);
      return [];
    }
  }

  /// Get enrollments chart data
  Future<List<ChartDataPoint>> getEnrollmentsChart(
      DateTime start, DateTime end) async {
    AppLogger.d('[$_tag] getEnrollmentsChart: start=$start, end=$end');
    try {
      final response = await _apiClient.get(
        '/instructor/charts/enrollments?p_start_date=${start.toIso8601String()}&p_end_date=${end.toIso8601String()}',
      );

      final dataPoints = _asList(response).map((e) {
        return ChartDataPoint(
          label: e['label'] as String? ?? '',
          value: (e['value'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      AppLogger.success(
          '[$_tag] getEnrollmentsChart: ${dataPoints.length} points');
      return dataPoints;
    } catch (e, s) {
      AppLogger.e('[$_tag] getEnrollmentsChart error', e, s);
      return [];
    }
  }
}
