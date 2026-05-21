// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_report_model.dart';

/// Report Action Screen - Admin can take action on reports
class ReportActionScreen extends StatefulWidget {
  final AdminReportModel report;
  final VoidCallback? onActionComplete;

  const ReportActionScreen({
    super.key,
    required this.report,
    this.onActionComplete,
  });

  @override
  State<ReportActionScreen> createState() => _ReportActionScreenState();
}

class _ReportActionScreenState extends State<ReportActionScreen> {
  bool _isLoading = false;
  String? _selectedResponse;

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
        return reason;
    }
  }

  List<_ResponseTemplate> _getResponseTemplates(bool isArabic) {
    return [
      _ResponseTemplate(
        id: 'reviewed',
        status: ReportStatusType.reviewed,
        title: isArabic ? 'تم مراجعة بلاغك' : 'Your report has been reviewed',
        body: isArabic
            ? 'شكراً لإبلاغك. تمت مراجعة البلاغ وسيتم اتخاذ الإجراء المناسب.'
            : 'Thank you for your report. It has been reviewed and appropriate action will be taken.',
        icon: Icons.visibility_rounded,
        color: AppColors.info,
      ),
      _ResponseTemplate(
        id: 'resolved',
        status: ReportStatusType.resolved,
        title: isArabic ? 'تم حل بلاغك' : 'Your report has been resolved',
        body: isArabic
            ? 'شكراً لمساعدتنا في تحسين المنصة. تم حل المشكلة المُبلغ عنها.'
            : 'Thank you for helping us improve the platform. The reported issue has been resolved.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
      _ResponseTemplate(
        id: 'content_removed',
        status: ReportStatusType.resolved,
        title: isArabic ? 'تم حل بلاغك' : 'Your report has been resolved',
        body: isArabic
            ? 'تم إزالة المحتوى المخالف. شكراً لإبلاغك.'
            : 'The violating content has been removed. Thank you for your report.',
        icon: Icons.delete_rounded,
        color: AppColors.success,
      ),
      _ResponseTemplate(
        id: 'warning_issued',
        status: ReportStatusType.resolved,
        title: isArabic ? 'تم حل بلاغك' : 'Your report has been resolved',
        body: isArabic
            ? 'تم إرسال تحذير للمستخدم المخالف.'
            : 'A warning has been issued to the violating user.',
        icon: Icons.warning_rounded,
        color: AppColors.warning,
      ),
      _ResponseTemplate(
        id: 'rejected',
        status: ReportStatusType.rejected,
        title: isArabic ? 'تم رفض بلاغك' : 'Your report has been rejected',
        body: isArabic
            ? 'بعد المراجعة، لم نجد انتهاكاً لسياسات المنصة. إذا كان لديك معلومات إضافية، يرجى التواصل مع الدعم.'
            : 'After review, we did not find a violation of our platform policies. If you have additional information, please contact support.',
        icon: Icons.cancel_rounded,
        color: AppColors.error,
      ),
      _ResponseTemplate(
        id: 'no_violation',
        status: ReportStatusType.rejected,
        title: isArabic ? 'تم رفض بلاغك' : 'Your report has been rejected',
        body: isArabic
            ? 'لم نجد انتهاكاً لسياسات المنصة في هذا المحتوى.'
            : 'We did not find a policy violation in this content.',
        icon: Icons.block_rounded,
        color: AppColors.error,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'اتخاذ إجراء' : 'Take Action'),
      ),
      body: Column(
        children: [
          _buildReportInfo(isDark, isArabic),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'اختر الرد:' : 'Select Response:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._getResponseTemplates(isArabic).map((template) =>
                      _buildResponseOption(template, isDark, isArabic)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          child: ElevatedButton(
            onPressed:
                _selectedResponse != null && !_isLoading ? _submitAction : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: AppColors.grey400,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isArabic ? 'تأكيد الإجراء' : 'Confirm Action',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportInfo(bool isDark, bool isArabic) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.report.type == ReportType.course
                    ? Icons.school_rounded
                    : Icons.rate_review_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.report.type == ReportType.course
                        ? (isArabic
                            ? widget.report.courseTitleAr ?? ''
                            : widget.report.courseTitleEn ??
                                widget.report.courseTitleAr ??
                                '')
                        : (isArabic ? 'بلاغ على تعليق' : 'Review Report'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${isArabic ? 'السبب:' : 'Reason:'} ${_getReasonLabel(widget.report.reason, isArabic)}',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.textMutedDark : AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseOption(
      _ResponseTemplate template, bool isDark, bool isArabic) {
    final isSelected = _selectedResponse == template.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedResponse = template.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? template.color.withValues(alpha: 0.1)
              : (isDark ? AppColors.cardDark : AppColors.grey50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? template.color
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              template.icon,
              color: isSelected
                  ? template.color
                  : (isDark ? AppColors.grey400 : AppColors.grey600),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.body,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppColors.textMutedDark : AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Radio<String>(
              value: template.id,
              groupValue: _selectedResponse,
              onChanged: (value) => setState(() => _selectedResponse = value),
              activeColor: template.color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAction() async {
    if (_selectedResponse == null) return;

    final isArabic = context.locale.languageCode == 'ar';
    final template = _getResponseTemplates(isArabic)
        .firstWhere((t) => t.id == _selectedResponse);

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final adminId = supabase.auth.currentUser?.id;

      final tableName = widget.report.type == ReportType.course
          ? 'course_reports'
          : 'review_reports';

      await supabase.from(tableName).update({
        'status': template.status.name,
        'admin_id': adminId,
        'admin_notes': template.body,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.report.id);

      await _sendNotificationToReporter(template, isArabic);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onActionComplete?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تم اتخاذ الإجراء بنجاح' : 'Action taken successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'حدث خطأ أثناء اتخاذ الإجراء' : 'Error taking action',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendNotificationToReporter(
      _ResponseTemplate template, bool isArabic) async {
    try {
      final supabase = Supabase.instance.client;

      final arabicTemplates = _getResponseTemplates(true);
      final englishTemplates = _getResponseTemplates(false);

      final arabicTemplate =
          arabicTemplates.firstWhere((t) => t.id == template.id);
      final englishTemplate =
          englishTemplates.firstWhere((t) => t.id == template.id);

      await supabase.from('notifications').insert({
        'user_id': widget.report.reporterId,
        'type': 'report_update',
        'title_ar': arabicTemplate.title,
        'title_en': englishTemplate.title,
        'body_ar': arabicTemplate.body,
        'body_en': englishTemplate.body,
        'data': {
          'report_id': widget.report.id,
          'report_type': widget.report.type.name,
          'status': template.status.name,
        },
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}

class _ResponseTemplate {
  final String id;
  final ReportStatusType status;
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const _ResponseTemplate({
    required this.id,
    required this.status,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });
}
