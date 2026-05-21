part of 'admin_reports_cubit.dart';

/// Status enum for AdminReports operations
enum AdminReportsStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
  resolving,
  updating,
}

/// State class for AdminReports
class AdminReportsState extends Equatable {
  final AdminReportsStatus status;
  final AdminReportsStatus actionStatus;
  final List<AdminReportModel> reports;
  final ReportStatsModel stats;
  final ReportType? currentType;
  final ReportStatusType? currentStatus;
  final String? searchQuery;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;
  final AdminReportModel? selectedReport;

  const AdminReportsState({
    this.status = AdminReportsStatus.initial,
    this.actionStatus = AdminReportsStatus.initial,
    this.reports = const [],
    this.stats = const ReportStatsModel(),
    this.currentType,
    this.currentStatus,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
    this.selectedReport,
  });

  AdminReportsState copyWith({
    AdminReportsStatus? status,
    AdminReportsStatus? actionStatus,
    List<AdminReportModel>? reports,
    ReportStatsModel? stats,
    ReportType? currentType,
    ReportStatusType? currentStatus,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
    AdminReportModel? selectedReport,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return AdminReportsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      reports: reports ?? this.reports,
      stats: stats ?? this.stats,
      currentType: clearType ? null : (currentType ?? this.currentType),
      currentStatus: clearStatus ? null : (currentStatus ?? this.currentStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      selectedReport: selectedReport ?? this.selectedReport,
    );
  }

  /// Get filtered reports based on current filters
  List<AdminReportModel> get filteredReports {
    var filtered = reports;

    if (currentType != null) {
      filtered = filtered.where((r) => r.type == currentType).toList();
    }

    if (currentStatus != null) {
      filtered = filtered.where((r) => r.status == currentStatus).toList();
    }

    return filtered;
  }

  /// Get reports count by type
  int get courseReportsCount =>
      reports.where((r) => r.type == ReportType.course).length;
  int get reviewReportsCount =>
      reports.where((r) => r.type == ReportType.review).length;

  /// Get reports count by status
  int get pendingReportsCount =>
      reports.where((r) => r.status == ReportStatusType.pending).length;
  int get reviewedReportsCount =>
      reports.where((r) => r.status == ReportStatusType.reviewed).length;
  int get resolvedReportsCount =>
      reports.where((r) => r.status == ReportStatusType.resolved).length;
  int get rejectedReportsCount =>
      reports.where((r) => r.status == ReportStatusType.rejected).length;

  /// Get unresolved count (for badge)
  int get unresolvedCount => pendingReportsCount + reviewedReportsCount;

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        reports,
        stats,
        currentType,
        currentStatus,
        searchQuery,
        currentPage,
        hasMore,
        errorMessage,
        selectedReport,
      ];
}
