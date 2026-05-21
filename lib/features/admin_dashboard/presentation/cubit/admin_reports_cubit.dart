import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/admin_reports_data_source.dart';
import '../../data/models/admin_report_model.dart';

part 'admin_reports_state.dart';

/// Admin Reports Cubit - Manages report operations for admin dashboard
class AdminReportsCubit extends Cubit<AdminReportsState> {
  final AdminReportsDataSource _dataSource;

  AdminReportsCubit(this._dataSource) : super(const AdminReportsState());

  String get _currentAdminId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  /// Load reports with optional filters
  Future<void> loadReports({
    ReportType? type,
    ReportStatusType? status,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminReportsStatus.loading,
        reports: [],
        currentPage: 1,
        hasMore: true,
        clearType: type == null,
        clearStatus: status == null,
      ));
    } else {
      emit(state.copyWith(status: AdminReportsStatus.loading));
    }

    try {
      final reports = await _dataSource.getAllReports(
        type: type,
        status: status,
        search: search,
        page: 1,
      );

      // Also load stats
      final stats = await _dataSource.getReportStats();

      emit(state.copyWith(
        status: AdminReportsStatus.success,
        reports: reports,
        stats: stats,
        currentType: type,
        currentStatus: status,
        searchQuery: search,
        currentPage: 1,
        hasMore: reports.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReportsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more reports (pagination)
  Future<void> loadMoreReports() async {
    if (!state.hasMore || state.status == AdminReportsStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: AdminReportsStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final reports = await _dataSource.getAllReports(
        type: state.currentType,
        status: state.currentStatus,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        status: AdminReportsStatus.success,
        reports: [...state.reports, ...reports],
        currentPage: nextPage,
        hasMore: reports.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReportsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Get report by ID
  Future<AdminReportModel?> getReportById(String id, ReportType type) async {
    try {
      final report = await _dataSource.getReportById(id, type);
      emit(state.copyWith(selectedReport: report));
      return report;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  /// Mark report as reviewed
  Future<bool> markAsReviewed(AdminReportModel report) async {
    if (!report.canTransitionTo(ReportStatusType.reviewed)) {
      emit(state.copyWith(
        actionStatus: AdminReportsStatus.error,
        errorMessage:
            'Cannot transition from ${report.status.name} to reviewed',
      ));
      return false;
    }

    emit(state.copyWith(actionStatus: AdminReportsStatus.updating));
    try {
      final updatedReport = await _dataSource.updateReportStatusAdmin(
        report.id,
        report.type,
        ReportStatusType.reviewed,
        _currentAdminId,
      );

      // Update local state
      final updatedReports = state.reports.map((r) {
        if (r.id == report.id) {
          return updatedReport;
        }
        return r;
      }).toList();

      // Update stats
      final stats = await _dataSource.getReportStats();

      emit(state.copyWith(
        actionStatus: AdminReportsStatus.success,
        reports: updatedReports,
        stats: stats,
        selectedReport: updatedReport,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminReportsStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Resolve report
  Future<bool> resolveReport(
    AdminReportModel report,
    ResolveReportDto dto,
  ) async {
    if (!report.canTransitionTo(dto.status)) {
      emit(state.copyWith(
        actionStatus: AdminReportsStatus.error,
        errorMessage:
            'Invalid status transition from ${report.status.name} to ${dto.status.name}',
      ));
      return false;
    }

    emit(state.copyWith(actionStatus: AdminReportsStatus.resolving));
    try {
      final updatedReport = await _dataSource.resolveReport(
        report.id,
        report.type,
        dto,
        _currentAdminId,
      );

      // Update local state
      final updatedReports = state.reports.map((r) {
        if (r.id == report.id) {
          return updatedReport;
        }
        return r;
      }).toList();

      // Update stats
      final stats = await _dataSource.getReportStats();

      emit(state.copyWith(
        actionStatus: AdminReportsStatus.success,
        reports: updatedReports,
        stats: stats,
        selectedReport: updatedReport,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminReportsStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Reject report (shorthand for resolveReport with rejected status)
  Future<bool> rejectReport(AdminReportModel report, {String? response}) async {
    return resolveReport(
      report,
      ResolveReportDto(
        status: ReportStatusType.rejected,
        adminResponse: response,
      ),
    );
  }

  /// Change type filter
  void changeTypeFilter(ReportType? type) {
    if (type != state.currentType) {
      loadReports(
        type: type,
        status: state.currentStatus,
        search: state.searchQuery,
        refresh: true,
      );
    }
  }

  /// Change status filter
  void changeStatusFilter(ReportStatusType? status) {
    if (status != state.currentStatus) {
      loadReports(
        type: state.currentType,
        status: status,
        search: state.searchQuery,
        refresh: true,
      );
    }
  }

  /// Search reports
  void search(String query) {
    loadReports(
      type: state.currentType,
      status: state.currentStatus,
      search: query.isEmpty ? null : query,
      refresh: true,
    );
  }

  /// Refresh stats only
  Future<void> refreshStats() async {
    try {
      final stats = await _dataSource.getReportStats();
      emit(state.copyWith(stats: stats));
    } catch (e) {
      // Silently fail - stats refresh is not critical
    }
  }

  /// Get unresolved count (for badge)
  Future<int> getUnresolvedCount() async {
    try {
      return await _dataSource.getUnresolvedReportsCount();
    } catch (e) {
      return state.unresolvedCount;
    }
  }

  /// Clear selected report
  void clearSelectedReport() {
    emit(AdminReportsState(
      status: state.status,
      actionStatus: state.actionStatus,
      reports: state.reports,
      stats: state.stats,
      currentType: state.currentType,
      currentStatus: state.currentStatus,
      searchQuery: state.searchQuery,
      currentPage: state.currentPage,
      hasMore: state.hasMore,
      errorMessage: state.errorMessage,
      selectedReport: null,
    ));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
