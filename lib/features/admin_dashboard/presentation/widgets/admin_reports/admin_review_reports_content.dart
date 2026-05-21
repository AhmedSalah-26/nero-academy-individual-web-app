import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../data/models/admin_report_model.dart';
import '../../cubit/admin_reports_cubit.dart';
import 'report_list_item.dart';

/// Admin Review Reports Content
class AdminReviewReportsContent extends StatefulWidget {
  const AdminReviewReportsContent({super.key});

  @override
  State<AdminReviewReportsContent> createState() =>
      _AdminReviewReportsContentState();
}

class _AdminReviewReportsContentState extends State<AdminReviewReportsContent> {
  @override
  void initState() {
    super.initState();
    context.read<AdminReportsCubit>().loadReports(type: ReportType.review);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<AdminReportsCubit, AdminReportsState>(
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
      BuildContext context, AdminReportsState state, bool isArabic) {
    final tabs = [
      const DashboardTabItem(label: 'All', labelAr: 'الكل'),
      const DashboardTabItem(label: 'Pending', labelAr: 'قيد الانتظار'),
      const DashboardTabItem(label: 'Reviewed', labelAr: 'تمت المراجعة'),
      const DashboardTabItem(label: 'Resolved', labelAr: 'تم الحل'),
      const DashboardTabItem(label: 'Rejected', labelAr: 'مرفوض'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: DashboardTabs(
        tabs: tabs,
        selectedIndex: _getTabIndex(state.currentStatus),
        onTabSelected: (index) {
          context
              .read<AdminReportsCubit>()
              .changeStatusFilter(_getStatusFromIndex(index));
        },
      ),
    );
  }

  int _getTabIndex(ReportStatusType? status) {
    if (status == null) return 0;
    switch (status) {
      case ReportStatusType.pending:
        return 1;
      case ReportStatusType.reviewed:
        return 2;
      case ReportStatusType.resolved:
        return 3;
      case ReportStatusType.rejected:
        return 4;
    }
  }

  ReportStatusType? _getStatusFromIndex(int index) {
    switch (index) {
      case 0:
        return null; // All
      case 1:
        return ReportStatusType.pending;
      case 2:
        return ReportStatusType.reviewed;
      case 3:
        return ReportStatusType.resolved;
      case 4:
        return ReportStatusType.rejected;
      default:
        return null;
    }
  }

  Widget _buildReportsList(
      BuildContext context, AdminReportsState state, bool isArabic) {
    final isLoading = state.status == AdminReportsStatus.loading;
    // Filter to show only review reports
    final reviewReports =
        state.reports.where((r) => r.type == ReportType.review).toList();

    if (isLoading && reviewReports.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (reviewReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد بلاغات' : 'No reports found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminReportsCubit>().loadReports(
            type: ReportType.review,
            status: state.currentStatus,
            refresh: true,
          ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: reviewReports.length,
        itemBuilder: (context, index) {
          final report = reviewReports[index];
          return ReportListItem(
            report: report,
            onTap: () => _showReportDetails(context, report, isArabic),
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
          child: const LoadingSkeleton(width: double.infinity, height: 150),
        );
      },
    );
  }

  void _showReportDetails(
      BuildContext context, AdminReportModel report, bool isArabic) {
    AppRouter.goToReportAction(
      context,
      reportId: report.id,
      report: report,
      onActionComplete: () {
        context.read<AdminReportsCubit>().loadReports(
              type: ReportType.review,
              refresh: true,
            );
      },
    );
  }
}
