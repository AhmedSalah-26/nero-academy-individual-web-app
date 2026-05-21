import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/extensions/datetime_extensions.dart';
import '../../../data/models/admin_report_model.dart';

/// Report List Item Widget
class ReportListItem extends StatelessWidget {
  final AdminReportModel report;
  final VoidCallback? onTap;
  final VoidCallback? onMarkReviewed;
  final VoidCallback? onResolve;

  const ReportListItem({
    super.key,
    required this.report,
    this.onTap,
    this.onMarkReviewed,
    this.onResolve,
  });

  String _getReasonLabel(String reason, bool isArabic) {
    switch (reason.toLowerCase()) {
      case 'inappropriate':
        return isArabic ? 'محتوى غير لائق' : 'Inappropriate Content';
      case 'spam':
        return isArabic ? 'محتوى مزعج / سبام' : 'Spam';
      case 'misleading':
        return isArabic ? 'معلومات مضللة' : 'Misleading Information';
      case 'copyright':
        return isArabic ? 'انتهاك حقوق الملكية' : 'Copyright Violation';
      case 'harassment':
        return isArabic ? 'تحرش أو إساءة' : 'Harassment';
      case 'other':
        return isArabic ? 'أخرى' : 'Other';
      default:
        return reason; // Return original if not found
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(isDark),
          width: report.isPending ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isArabic, isDark),
                const SizedBox(height: 12),
                _buildContent(context, isArabic, isDark),
                const SizedBox(height: 12),
                _buildFooter(context, isArabic, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(bool isDark) {
    if (report.isPending) {
      return AppColors.warning.withValues(alpha: 0.5);
    }
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  Widget _buildHeader(BuildContext context, bool isArabic, bool isDark) {
    return Row(
      children: [
        _buildTypeIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTypeLabel(isArabic),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                report.reporterName ?? report.reporterEmail ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(isArabic),
      ],
    );
  }

  Widget _buildTypeIcon() {
    final isReview = report.type == ReportType.review;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (isReview ? AppColors.info : AppColors.warning)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isReview ? Icons.rate_review_rounded : Icons.school_rounded,
        color: isReview ? AppColors.info : AppColors.warning,
        size: 22,
      ),
    );
  }

  String _getTypeLabel(bool isArabic) {
    if (report.type == ReportType.review) {
      return isArabic ? 'بلاغ مراجعة' : 'Review Report';
    }
    return isArabic ? 'بلاغ كورس' : 'Course Report';
  }

  Widget _buildStatusBadge(bool isArabic) {
    Color color;
    String label;
    IconData icon;

    switch (report.status) {
      case ReportStatusType.pending:
        color = AppColors.warning;
        label = isArabic ? 'معلق' : 'Pending';
        icon = Icons.hourglass_empty_rounded;
        break;
      case ReportStatusType.reviewed:
        color = AppColors.info;
        label = isArabic ? 'تمت المراجعة' : 'Reviewed';
        icon = Icons.visibility_rounded;
        break;
      case ReportStatusType.resolved:
        color = AppColors.success;
        label = isArabic ? 'محلول' : 'Resolved';
        icon = Icons.check_circle_rounded;
        break;
      case ReportStatusType.rejected:
        color = AppColors.error;
        label = isArabic ? 'مرفوض' : 'Rejected';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isArabic, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reason
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.report_problem_rounded,
              size: 16,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getReasonLabel(report.reason, isArabic),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // Description (if exists)
        if (report.description != null && report.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            report.description!,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Course/Review info
        if (report.type == ReportType.course &&
            report.courseTitleAr != null) ...[
          const SizedBox(height: 8),
          _buildInfoChip(
            icon: Icons.school_outlined,
            label: isArabic
                ? report.courseTitleAr!
                : (report.courseTitleEn ?? report.courseTitleAr!),
            isDark: isDark,
          ),
        ],
        if (report.type == ReportType.review &&
            report.cachedReviewComment != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (report.cachedReviewRating != null)
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < report.cachedReviewRating!
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: AppColors.warning,
                            );
                          }),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        report.cachedReviewComment!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]!.withValues(alpha: 0.5)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isArabic, bool isDark) {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 14,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          report.createdAt.timeAgo,
          style: TextStyle(
            fontSize: 12,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        // Quick Actions
        if (onMarkReviewed != null && report.isPending)
          _buildQuickAction(
            icon: Icons.visibility_rounded,
            label: isArabic ? 'مراجعة' : 'Review',
            color: AppColors.info,
            onTap: onMarkReviewed!,
          ),
        if (onResolve != null && !report.isTerminal) ...[
          const SizedBox(width: 8),
          _buildQuickAction(
            icon: Icons.gavel_rounded,
            label: isArabic ? 'حل' : 'Resolve',
            color: AppColors.success,
            onTap: onResolve!,
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
