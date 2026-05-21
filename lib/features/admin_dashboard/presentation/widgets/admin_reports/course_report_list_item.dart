import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../data/models/course_report_model.dart';

/// Course Report List Item Widget
class CourseReportListItem extends StatelessWidget {
  final CourseReportModel report;
  final Function(ReportStatus, String?)? onUpdateStatus;

  const CourseReportListItem({
    super.key,
    required this.report,
    this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.courseTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isArabic ? 'بواسطة:' : 'By:'} ${report.userName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isDark, isArabic),
              ],
            ),
            const SizedBox(height: 12),
            _buildReasonBadge(isDark, isArabic),
            if (report.description != null) ...[
              const SizedBox(height: 8),
              Text(
                report.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(report.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const Spacer(),
                if (report.status == ReportStatus.pending &&
                    onUpdateStatus != null)
                  _buildActions(context, isDark, isArabic),
              ],
            ),
            if (report.adminResponse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.reply, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.adminResponse!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(report.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        report.status.getLabel(isArabic),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(report.status),
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return AppColors.warning;
      case ReportStatus.reviewed:
        return AppColors.info;
      case ReportStatus.resolved:
        return AppColors.success;
      case ReportStatus.rejected:
        return AppColors.error;
    }
  }

  Widget _buildReasonBadge(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        report.reason,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.error),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark, bool isArabic) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () => onUpdateStatus?.call(ReportStatus.resolved, null),
          icon: const Icon(Icons.check_circle, size: 18),
          label: Text(isArabic ? 'حل' : 'Resolve'),
          style: TextButton.styleFrom(foregroundColor: AppColors.success),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => onUpdateStatus?.call(ReportStatus.rejected, null),
          icon: const Icon(Icons.cancel, size: 18),
          label: Text(isArabic ? 'رفض' : 'Reject'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ],
    );
  }
}
