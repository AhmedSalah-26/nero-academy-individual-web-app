import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_report_model.dart';
import '../cubit/admin_cubits.dart';
import '../widgets/reports/report_details_widgets.dart';
import '../widgets/reports/report_content_widgets.dart';

/// Report Details Screen - Full screen view for report details
class ReportDetailsScreen extends StatefulWidget {
  final AdminReportModel report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final _responseController = TextEditingController();
  ReportAction _selectedAction = ReportAction.none;
  bool _isProcessing = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل البلاغ' : 'Report Details'),
        actions: [
          ReportStatusBadge(report: widget.report, isArabic: isArabic),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportTypeCard(
                report: widget.report, isArabic: isArabic, isDark: isDark),
            const SizedBox(height: 16),
            ReporterInfoCard(
                report: widget.report, isArabic: isArabic, isDark: isDark),
            const SizedBox(height: 20),
            ReportContentCard(
                report: widget.report, isArabic: isArabic, isDark: isDark),
            if (widget.report.type == ReportType.review)
              ReportedReviewCard(
                  report: widget.report, isArabic: isArabic, isDark: isDark),
            if (widget.report.type == ReportType.course)
              ReportedCourseCard(
                  report: widget.report, isArabic: isArabic, isDark: isDark),
            const SizedBox(height: 20),
            if (!widget.report.isTerminal)
              _buildActionSection(isArabic, isDark),
            if (widget.report.isTerminal)
              ResolutionInfoCard(
                  report: widget.report, isArabic: isArabic, isDark: isDark),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: !widget.report.isTerminal
          ? _buildBottomActions(context, isArabic, isDark)
          : null,
    );
  }

  Widget _buildActionSection(bool isArabic, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'اتخاذ إجراء' : 'Take Action',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'الإجراء المطلوب' : 'Action to take',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  label: isArabic ? 'بدون إجراء' : 'No Action',
                  action: ReportAction.none,
                  icon: Icons.check_rounded,
                ),
                _buildActionChip(
                  label: isArabic ? 'إخفاء المحتوى' : 'Hide Content',
                  action: ReportAction.hideContent,
                  icon: Icons.visibility_off_rounded,
                ),
                _buildActionChip(
                  label: isArabic ? 'تحذير المستخدم' : 'Warn User',
                  action: ReportAction.warnUser,
                  icon: Icons.warning_rounded,
                ),
                _buildActionChip(
                  label: isArabic ? 'حظر المستخدم' : 'Ban User',
                  action: ReportAction.banUser,
                  icon: Icons.block_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'رد الإدارة (اختياري)' : 'Admin Response (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _responseController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isArabic
                    ? 'اكتب رد الإدارة هنا...'
                    : 'Write admin response here...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required ReportAction action,
    required IconData icon,
  }) {
    final isSelected = _selectedAction == action;
    Color color;
    switch (action) {
      case ReportAction.none:
        color = AppColors.success;
      case ReportAction.hideContent:
        color = AppColors.info;
      case ReportAction.warnUser:
        color = AppColors.warning;
      case ReportAction.banUser:
        color = AppColors.error;
    }

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) => setState(() => _selectedAction = action),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.report.isPending)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isProcessing ? null : () => _markReviewed(context),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: Text(isArabic ? 'تمت المراجعة' : 'Mark Reviewed'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (widget.report.isPending) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isProcessing ? null : () => _resolveReport(context, false),
                icon: const Icon(Icons.cancel_rounded, size: 18),
                label: Text(isArabic ? 'رفض' : 'Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isProcessing ? null : () => _resolveReport(context, true),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(isArabic ? 'حل البلاغ' : 'Resolve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markReviewed(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      await context.read<AdminReportsCubit>().markAsReviewed(widget.report);
      if (context.mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _resolveReport(BuildContext context, bool resolve) async {
    setState(() => _isProcessing = true);

    try {
      final dto = ResolveReportDto(
        status: resolve ? ReportStatusType.resolved : ReportStatusType.rejected,
        adminResponse: _responseController.text.trim().isEmpty
            ? null
            : _responseController.text.trim(),
        action: resolve ? _selectedAction : ReportAction.none,
      );

      await context.read<AdminReportsCubit>().resolveReport(widget.report, dto);

      if (context.mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
