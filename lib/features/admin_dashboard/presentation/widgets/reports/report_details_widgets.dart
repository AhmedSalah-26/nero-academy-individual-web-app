import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/extensions/datetime_extensions.dart';
import '../../../../../core/shared_widgets/user_avatar.dart';
import '../../../data/models/admin_report_model.dart';

/// Helper to get status color
Color getReportStatusColor(ReportStatusType status) {
  switch (status) {
    case ReportStatusType.pending:
      return AppColors.warning;
    case ReportStatusType.reviewed:
      return AppColors.info;
    case ReportStatusType.resolved:
      return AppColors.success;
    case ReportStatusType.rejected:
      return AppColors.error;
  }
}

/// Report Type Card
class ReportTypeCard extends StatelessWidget {
  final AdminReportModel report;
  final bool isArabic;
  final bool isDark;

  const ReportTypeCard(
      {super.key,
      required this.report,
      required this.isArabic,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = getReportStatusColor(report.status);
    final icon = report.type == ReportType.review
        ? Icons.rate_review_rounded
        : Icons.school_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.type == ReportType.review
                      ? (isArabic ? 'بلاغ مراجعة' : 'Review Report')
                      : (isArabic ? 'بلاغ كورس' : 'Course Report'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isArabic ? 'رقم البلاغ: ' : 'Report ID: '}${report.id.substring(0, 8)}...',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Report Status Badge
class ReportStatusBadge extends StatelessWidget {
  final AdminReportModel report;
  final bool isArabic;

  const ReportStatusBadge(
      {super.key, required this.report, required this.isArabic});

  String get _label {
    switch (report.status) {
      case ReportStatusType.pending:
        return isArabic ? 'معلق' : 'Pending';
      case ReportStatusType.reviewed:
        return isArabic ? 'تمت المراجعة' : 'Reviewed';
      case ReportStatusType.resolved:
        return isArabic ? 'محلول' : 'Resolved';
      case ReportStatusType.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getReportStatusColor(report.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16)),
      child: Text(_label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Reporter Info Card
class ReporterInfoCard extends StatelessWidget {
  final AdminReportModel report;
  final bool isArabic;
  final bool isDark;

  const ReporterInfoCard(
      {super.key,
      required this.report,
      required this.isArabic,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'معلومات المُبلِّغ' : 'Reporter Information',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                UserAvatar(
                    imageUrl: report.reporterAvatar,
                    name: report.reporterName ?? 'U',
                    size: AvatarSize.xl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.reporterName ?? 'Unknown',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight)),
                      if (report.reporterEmail != null) ...[
                        const SizedBox(height: 4),
                        Text(report.reporterEmail!,
                            style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(report.createdAt.timeAgo,
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
