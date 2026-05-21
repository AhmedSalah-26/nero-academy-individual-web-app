import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/extensions/datetime_extensions.dart';
import '../../../data/models/admin_report_model.dart';
import 'report_details_widgets.dart';

/// Report Content Card
class ReportContentCard extends StatelessWidget {
  final AdminReportModel report;
  final bool isArabic;
  final bool isDark;

  const ReportContentCard(
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
            Text(isArabic ? 'تفاصيل البلاغ' : 'Report Details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)),
            const SizedBox(height: 12),
            Text(isArabic ? 'سبب البلاغ' : 'Report Reason',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report_problem_rounded,
                      size: 20, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(report.reason,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight)),
                  ),
                ],
              ),
            ),
            if (report.description != null &&
                report.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(isArabic ? 'تفاصيل إضافية' : 'Additional Details',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]!.withValues(alpha: 0.5)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                ),
                child: Text(report.description!,
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Review Content Card
class ReportedReviewCard extends StatelessWidget {
  final AdminReportModel report;
  final bool isArabic;
  final bool isDark;

  const ReportedReviewCard(
      {super.key,
      required this.report,
      required this.isArabic,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (report.cachedReviewComment == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isArabic ? 'المراجعة المُبلَّغ عنها' : 'Reported Review',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]!.withValues(alpha: 0.5)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (report.cachedReviewerName != null) ...[
                      Text(report.cachedReviewerName!,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight)),
                      const SizedBox(width: 12),
                    ],
                    if (report.cachedReviewRating != null)
                      Row(
                          children: List.generate(
                              5,
                              (i) => Icon(
                                  i < report.cachedReviewRating!
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 18,
                                  color: AppColors.warning))),
                  ]),
                  const SizedBox(height: 12),
                  Text(report.cachedReviewComment!,
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reported Course Card
class ReportedCourseCard extends StatelessWidget {
  final AdminReportModel report;
  final bool isArabic;
  final bool isDark;

  const ReportedCourseCard(
      {super.key,
      required this.report,
      required this.isArabic,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (report.courseTitleAr == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isArabic ? 'الكورس المُبلَّغ عنه' : 'Reported Course',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]!.withValues(alpha: 0.5)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.school_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      isArabic
                          ? report.courseTitleAr!
                          : (report.courseTitleEn ?? report.courseTitleAr!),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolution Info Card
class ResolutionInfoCard extends StatelessWidget {
  final AdminReportModel report;
  final bool isArabic;
  final bool isDark;

  const ResolutionInfoCard(
      {super.key,
      required this.report,
      required this.isArabic,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = getReportStatusColor(report.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isArabic ? 'معلومات الحل' : 'Resolution Info',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.adminName != null)
                    Row(children: [
                      const Icon(Icons.admin_panel_settings_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                          '${isArabic ? 'بواسطة: ' : 'By: '}${report.adminName}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight)),
                    ]),
                  if (report.resolvedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(report.resolvedAt!.timeAgo,
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary)),
                    ]),
                  ],
                  if (report.adminResponse != null &&
                      report.adminResponse!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(isArabic ? 'رد الإدارة:' : 'Admin Response:',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight)),
                    const SizedBox(height: 6),
                    Text(report.adminResponse!,
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
