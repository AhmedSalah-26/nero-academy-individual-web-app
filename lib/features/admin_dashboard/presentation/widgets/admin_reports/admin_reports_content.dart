import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../data/models/admin_report_model.dart';
import '../../cubit/admin_reports_cubit.dart';
import 'report_list_item.dart';

/// Admin Reports Content - Manages course and review reports
class AdminReportsContent extends StatefulWidget {
  const AdminReportsContent({super.key});

  @override
  State<AdminReportsContent> createState() => _AdminReportsContentState();
}

class _AdminReportsContentState extends State<AdminReportsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminReportsCubit>().loadReports();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminReportsCubit>().loadMoreReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocConsumer<AdminReportsCubit, AdminReportsState>(
      listener: (context, state) {
        if (state.actionStatus == AdminReportsStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<AdminReportsCubit>().clearError();
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic),
            Expanded(child: _buildReportsList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminReportsState state,
    bool isArabic,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Row
          _buildStatsRow(state, isArabic),
          const SizedBox(height: 16),
          // Type Tabs
          _buildTypeTabs(context, state, isArabic),
          const SizedBox(height: 12),
          // Status Tabs
          _buildStatusTabs(context, state, isArabic),
          const SizedBox(height: 16),
          // Search Bar
          DashboardSearchBar(
            hintText: 'Search by reporter or reason...',
            hintTextAr: 'بحث بالمبلغ أو السبب...',
            onSearch: (query) {
              context.read<AdminReportsCubit>().search(query);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AdminReportsState state, bool isArabic) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.warning_amber_rounded,
          label: isArabic ? 'غير محلولة' : 'Unresolved',
          count: state.stats.unresolvedCount,
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.pending_actions_rounded,
          label: isArabic ? 'معلقة' : 'Pending',
          count: state.stats.pendingReports,
          color: AppColors.info,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          label: isArabic ? 'محلولة' : 'Resolved',
          count: state.stats.resolvedReports,
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.cancel_rounded,
          label: isArabic ? 'مرفوضة' : 'Rejected',
          count: state.stats.rejectedReports,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTabs(
    BuildContext context,
    AdminReportsState state,
    bool isArabic,
  ) {
    final tabs = [
      DashboardTabItem(
        label: 'All Reports',
        labelAr: 'كل البلاغات',
        icon: Icons.list_rounded,
        badge: state.stats.totalReports.toString(),
      ),
      DashboardTabItem(
        label: 'Course Reports',
        labelAr: 'بلاغات الكورسات',
        icon: Icons.school_rounded,
        badge: state.stats.courseReports.toString(),
      ),
      DashboardTabItem(
        label: 'Review Reports',
        labelAr: 'بلاغات المراجعات',
        icon: Icons.rate_review_rounded,
        badge: state.stats.reviewReports.toString(),
      ),
    ];

    int currentIndex = 0;
    if (state.currentType == ReportType.course) {
      currentIndex = 1;
    } else if (state.currentType == ReportType.review) {
      currentIndex = 2;
    }

    return DashboardTabs(
      tabs: tabs,
      selectedIndex: currentIndex,
      onTabSelected: (index) {
        ReportType? type;
        if (index == 1) type = ReportType.course;
        if (index == 2) type = ReportType.review;
        context.read<AdminReportsCubit>().changeTypeFilter(type);
      },
    );
  }

  Widget _buildStatusTabs(
    BuildContext context,
    AdminReportsState state,
    bool isArabic,
  ) {
    final statusTabs = [
      const DashboardTabItem(
        label: 'All',
        labelAr: 'الكل',
        icon: Icons.all_inclusive_rounded,
      ),
      DashboardTabItem(
        label: 'Pending',
        labelAr: 'معلقة',
        icon: Icons.hourglass_empty_rounded,
        badge: state.stats.pendingReports > 0
            ? state.stats.pendingReports.toString()
            : null,
      ),
      const DashboardTabItem(
        label: 'Reviewed',
        labelAr: 'تمت المراجعة',
        icon: Icons.visibility_rounded,
      ),
      const DashboardTabItem(
        label: 'Resolved',
        labelAr: 'محلولة',
        icon: Icons.check_circle_outline_rounded,
      ),
      const DashboardTabItem(
        label: 'Rejected',
        labelAr: 'مرفوضة',
        icon: Icons.cancel_outlined,
      ),
    ];

    final statusFilters = [
      null,
      ReportStatusType.pending,
      ReportStatusType.reviewed,
      ReportStatusType.resolved,
      ReportStatusType.rejected,
    ];

    final currentIndex = state.currentStatus == null
        ? 0
        : statusFilters.contains(state.currentStatus)
            ? statusFilters.indexOf(state.currentStatus)
            : 0;

    return DashboardTabs(
      tabs: statusTabs,
      selectedIndex: currentIndex,
      onTabSelected: (index) {
        context
            .read<AdminReportsCubit>()
            .changeStatusFilter(statusFilters[index]);
      },
    );
  }

  Widget _buildReportsList(
    BuildContext context,
    AdminReportsState state,
    bool isArabic,
  ) {
    if (state.status == AdminReportsStatus.loading && state.reports.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا يوجد بلاغات' : 'No reports found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'لم يتم العثور على بلاغات تطابق الفلتر المحدد'
                  : 'No reports match the selected filter',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminReportsCubit>().loadReports(
            type: state.currentType,
            status: state.currentStatus,
            search: state.searchQuery,
            refresh: true,
          ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.reports.length +
            (state.status == AdminReportsStatus.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.reports.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final report = state.reports[index];
          return ReportListItem(
            report: report,
            onTap: () => _showReportDetails(context, report),
            onMarkReviewed: report.isPending
                ? () => _markAsReviewed(context, report)
                : null,
            onResolve: !report.isTerminal
                ? () => _showReportDetails(context, report)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: const Row(
            children: [
              LoadingSkeleton(width: 48, height: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: 150),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 200),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 12, width: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDetails(BuildContext context, AdminReportModel report) {
    AppRouter.goToReportDetails(
      context,
      reportId: report.id,
      report: report,
    );
  }

  void _markAsReviewed(BuildContext context, AdminReportModel report) async {
    final success =
        await context.read<AdminReportsCubit>().markAsReviewed(report);
    if (success && context.mounted) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم تحديث حالة البلاغ إلى "تمت المراجعة"'
                : 'Report marked as reviewed',
          ),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }
}
