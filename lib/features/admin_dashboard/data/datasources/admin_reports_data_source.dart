import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/admin_report_model.dart';

/// Admin Reports Data Source - Report management
class AdminReportsDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminReportsDS';

  AdminReportsDataSource(this._client);

  /// Get all reports with filtering
  Future<List<AdminReportModel>> getAllReports({
    ReportType? type,
    ReportStatusType? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAllReports: type=$type, status=$status');
    try {
      final List<AdminReportModel> allReports = [];

      if (type == null || type == ReportType.course) {
        final courseReports = await _getCourseReports(
          status: status,
          search: search,
          page: page,
          limit: limit,
        );
        allReports.addAll(courseReports);
      }

      if (type == null || type == ReportType.review) {
        final reviewReports = await _getReviewReports(
          status: status,
          search: search,
          page: page,
          limit: limit,
        );
        allReports.addAll(reviewReports);
      }

      allReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      AppLogger.success('[$_tag] getAllReports: ${allReports.length} reports');
      return allReports;
    } catch (e, s) {
      AppLogger.e('[$_tag] getAllReports error', e, s);
      rethrow;
    }
  }

  Future<List<AdminReportModel>> _getCourseReports({
    ReportStatusType? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    var query = _client.from('course_reports').select(
          '*, course:courses(title_ar, title_en), user:profiles!course_reports_user_id_fkey(name, email, avatar_url), admin:profiles!course_reports_admin_id_fkey(name)',
        );

    if (status != null) {
      query = query.eq('status', status.name);
    }

    if (search != null && search.isNotEmpty) {
      query = query.or('reason.ilike.%$search%,description.ilike.%$search%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return (response as List)
        .map((e) =>
            AdminReportModel.fromCourseReportJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminReportModel>> _getReviewReports({
    ReportStatusType? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    var query = _client.from('review_reports').select(
          '*, user:profiles!review_reports_user_id_fkey(name, email, avatar_url), admin:profiles!review_reports_admin_id_fkey(name)',
        );

    if (status != null) {
      query = query.eq('status', status.name);
    }

    if (search != null && search.isNotEmpty) {
      query = query.or(
          'reason.ilike.%$search%,description.ilike.%$search%,cached_review_comment.ilike.%$search%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return (response as List)
        .map((e) =>
            AdminReportModel.fromReviewReportJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get report by ID
  Future<AdminReportModel> getReportById(String id, ReportType type) async {
    AppLogger.d('[$_tag] getReportById: id=$id, type=$type');
    try {
      if (type == ReportType.course) {
        final response = await _client
            .from('course_reports')
            .select(
                '*, course:courses(title_ar, title_en), user:profiles!course_reports_user_id_fkey(name, email, avatar_url), admin:profiles!course_reports_admin_id_fkey(name)')
            .eq('id', id)
            .single();
        return AdminReportModel.fromCourseReportJson(response);
      } else {
        final response = await _client
            .from('review_reports')
            .select(
                '*, user:profiles!review_reports_user_id_fkey(name, email, avatar_url), admin:profiles!review_reports_admin_id_fkey(name)')
            .eq('id', id)
            .single();
        return AdminReportModel.fromReviewReportJson(response);
      }
    } catch (e, s) {
      AppLogger.e('[$_tag] getReportById error', e, s);
      rethrow;
    }
  }

  /// Resolve report
  Future<AdminReportModel> resolveReport(
    String id,
    ReportType type,
    ResolveReportDto dto,
    String adminId,
  ) async {
    AppLogger.d('[$_tag] resolveReport: id=$id, status=${dto.status}');
    try {
      final tableName =
          type == ReportType.course ? 'course_reports' : 'review_reports';
      final updateData = dto.toUpdateJson(adminId);

      final response = await _client
          .from(tableName)
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      if (dto.action != ReportAction.none &&
          dto.status == ReportStatusType.resolved) {
        await _executeReportAction(id, type, dto.action, response);
      }

      AppLogger.success('[$_tag] resolveReport success');

      if (type == ReportType.course) {
        return AdminReportModel.fromCourseReportJson(response);
      } else {
        return AdminReportModel.fromReviewReportJson(response);
      }
    } catch (e, s) {
      AppLogger.e('[$_tag] resolveReport error', e, s);
      rethrow;
    }
  }

  Future<void> _executeReportAction(
    String reportId,
    ReportType type,
    ReportAction action,
    Map<String, dynamic> reportData,
  ) async {
    try {
      switch (action) {
        case ReportAction.hideContent:
          if (type == ReportType.course) {
            final courseId = reportData['course_id'] as String?;
            if (courseId != null) {
              await _client.from('courses').update({
                'is_suspended': true,
                'suspension_reason': 'Suspended due to report',
              }).eq('id', courseId);
            }
          } else {
            final reviewId = reportData['review_id'] as String?;
            if (reviewId != null) {
              await _client.from('course_reviews').update({
                'is_hidden': true,
              }).eq('id', reviewId);
            }
          }
          break;
        case ReportAction.warnUser:
          AppLogger.w('[$_tag] User warning not implemented yet');
          break;
        case ReportAction.banUser:
          // Implementation for ban user
          break;
        case ReportAction.none:
          break;
      }
    } catch (e, s) {
      AppLogger.e('[$_tag] _executeReportAction error', e, s);
    }
  }

  /// Get report statistics
  Future<ReportStatsModel> getReportStats() async {
    AppLogger.d('[$_tag] getReportStats');
    try {
      final courseReports =
          await _client.from('course_reports').select('status') as List;
      final reviewReports =
          await _client.from('review_reports').select('status') as List;

      int pending = 0, reviewed = 0, resolved = 0, rejected = 0;

      for (final report in [...courseReports, ...reviewReports]) {
        switch (report['status'] as String?) {
          case 'pending':
            pending++;
            break;
          case 'reviewed':
            reviewed++;
            break;
          case 'resolved':
            resolved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return ReportStatsModel(
        totalReports: courseReports.length + reviewReports.length,
        pendingReports: pending,
        reviewedReports: reviewed,
        resolvedReports: resolved,
        rejectedReports: rejected,
        courseReports: courseReports.length,
        reviewReports: reviewReports.length,
      );
    } catch (e, s) {
      AppLogger.e('[$_tag] getReportStats error', e, s);
      rethrow;
    }
  }

  /// Get unresolved reports count
  Future<int> getUnresolvedReportsCount() async {
    try {
      final courseCount = await _client
          .from('course_reports')
          .select('id')
          .inFilter('status', ['pending', 'reviewed']);

      final reviewCount = await _client
          .from('review_reports')
          .select('id')
          .inFilter('status', ['pending', 'reviewed']);

      return (courseCount as List).length + (reviewCount as List).length;
    } catch (e, s) {
      AppLogger.e('[$_tag] getUnresolvedReportsCount error', e, s);
      rethrow;
    }
  }

  /// Update report status (for marking as reviewed)
  Future<AdminReportModel> updateReportStatusAdmin(
    String id,
    ReportType type,
    ReportStatusType status,
    String adminId,
  ) async {
    AppLogger.d('[$_tag] updateReportStatusAdmin: id=$id, status=$status');
    try {
      final tableName =
          type == ReportType.course ? 'course_reports' : 'review_reports';

      final updateData = {
        'status': status.name,
        'admin_id': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
      };

      await _client.from(tableName).update(updateData).eq('id', id);

      // Fetch and return the updated report
      return await getReportById(id, type);
    } catch (e, s) {
      AppLogger.e('[$_tag] updateReportStatusAdmin error', e, s);
      rethrow;
    }
  }
}
