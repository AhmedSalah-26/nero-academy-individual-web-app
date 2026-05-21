import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../data/models/review_report_model.dart';

/// Review Report List Item Widget
class ReviewReportListItem extends StatelessWidget {
  final ReviewReportModel report;
  final Function(ReportStatus, String?)? onUpdateStatus;
  final VoidCallback? onHideReview;

  const ReviewReportListItem({
    super.key,
    required this.report,
    this.onUpdateStatus,
    this.onHideReview,
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
                        '${isArabic ? 'بلاغ من:' : 'Report by:'} ${report.userName}',
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
                        dateFormat.format(report.createdAt),
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
            if (report.cachedReviewComment != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isArabic
                              ? 'التقييم المُبلغ عنه:'
                              : 'Reported Review:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        const Spacer(),
                        if (report.cachedReviewRating != null)
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < report.cachedReviewRating!
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: AppColors.warning,
                              );
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.cachedReviewComment!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (report.status == ReportStatus.pending &&
                (onUpdateStatus != null || onHideReview != null)) ...[
              const SizedBox(height: 12),
              _buildActions(context, isDark, isArabic),
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onHideReview != null && report.reviewId != null)
          TextButton.icon(
            onPressed: onHideReview,
            icon: const Icon(Icons.visibility_off, size: 18),
            label: Text(isArabic ? 'إخفاء التقييم' : 'Hide Review'),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
          ),
        const SizedBox(width: 8),
        if (onUpdateStatus != null) ...[
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
      ],
    );
  }
}
