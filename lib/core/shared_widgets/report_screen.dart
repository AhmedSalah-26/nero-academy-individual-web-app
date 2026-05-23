import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/reports_service.dart';
import '../di/injection_container.dart';
import '../network/api_client.dart';

/// Report Screen - Full page replacement for ReportDialog
class ReportScreen extends StatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String? targetTitle;
  final VoidCallback? onReportSubmitted;
  final String? reviewerId;
  final String? reviewComment;
  final int? reviewRating;

  const ReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
    this.onReportSubmitted,
    this.reviewerId,
    this.reviewComment,
    this.reviewRating,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingPending = true;
  bool _hasPendingReport = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPendingReport();
  }

  Future<void> _checkPendingReport() async {
    try {
      final service = ReportsRemoteDataSource(sl<ApiClient>());

      bool hasPending;
      if (widget.targetType == ReportTargetType.course) {
        hasPending = await service.hasReportedCourse(widget.targetId);
      } else {
        hasPending = await service.hasReportedReview(widget.targetId);
      }

      if (mounted) {
        setState(() {
          _hasPendingReport = hasPending;
          _isCheckingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingPending = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      setState(() => _error = context.locale.languageCode == 'ar'
          ? 'الرجاء اختيار سبب البلاغ'
          : 'Please select a reason');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final service = ReportsRemoteDataSource(sl<ApiClient>());

      bool success;
      if (widget.targetType == ReportTargetType.course) {
        success = await service.reportCourse(
          courseId: widget.targetId,
          reason: _selectedReason!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        success = await service.reportReview(
          reviewId: widget.targetId,
          reason: _selectedReason!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          reviewerId: widget.reviewerId,
          reviewComment: widget.reviewComment,
          reviewRating: widget.reviewRating,
        );
      }

      if (success && mounted) {
        widget.onReportSubmitted?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.locale.languageCode == 'ar'
                  ? 'تم إرسال البلاغ بنجاح'
                  : 'Report submitted successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString().contains('duplicate')
            ? (context.locale.languageCode == 'ar'
                ? 'لقد قمت بالإبلاغ عن هذا المحتوى مسبقاً'
                : 'You have already reported this content')
            : (context.locale.languageCode == 'ar'
                ? 'حدث خطأ أثناء إرسال البلاغ'
                : 'Failed to submit report');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.targetType == ReportTargetType.course
              ? (isArabic ? 'الإبلاغ عن الكورس' : 'Report Course')
              : (isArabic ? 'الإبلاغ عن التعليق' : 'Report Review'),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: _isCheckingPending
          ? const Center(child: CircularProgressIndicator())
          : _hasPendingReport
              ? _buildPendingReportView(isDark, isArabic)
              : _buildReportForm(isDark, isArabic),
    );
  }

  Widget _buildPendingReportView(bool isDark, bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 80,
              color: AppColors.warning,
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? 'لديك بلاغ معلق' : 'Pending Report',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'لديك بلاغ معلق على هذا المحتوى. سيتم الرد عليك قريباً.'
                  : 'You have a pending report for this content. We will respond soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 16,
                color: isDark ? AppColors.textMutedDark : AppColors.grey600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isArabic ? 'حسناً' : 'OK',
                  style: const TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportForm(bool isDark, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target info card
          if (widget.targetTitle != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.targetTitle!,
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.white : AppColors.textMainLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Reason selection
          Text(
            isArabic ? 'سبب البلاغ' : 'Reason for Report',
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),

          // Reason chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ReportReason.values.map((reason) {
              final isSelected = _selectedReason == reason;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = reason),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.primaryLight.withValues(alpha: 0.3))
                        : (isDark
                            ? const Color(0xFF424242)
                            : AppColors.grey100),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? const Color(0xFF616161)
                              : AppColors.grey300),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    reason.getLabel(isArabic),
                    style: TextStyle(
                      fontFamily: 'Almarai',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? const Color(0xFFEEEEEE)
                              : AppColors.grey600),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            isArabic
                ? 'تفاصيل إضافية (اختياري)'
                : 'Additional Details (Optional)',
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: 500,
            textDirection:
                isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            decoration: InputDecoration(
              hintText:
                  isArabic ? 'أضف تفاصيل إضافية...' : 'Add more details...',
              hintStyle: TextStyle(
                fontFamily: 'Almarai',
                color: isDark ? AppColors.textMutedDark : AppColors.grey400,
              ),
              filled: true,
              fillColor: isDark ? AppColors.grey800 : AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 14,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),

          // Error message
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.error.withValues(alpha: 0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isArabic ? 'إرسال البلاغ' : 'Submit Report',
                      style: const TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
