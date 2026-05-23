import '../network/api_client.dart';
import '../../../../core/services/app_logger.dart';

/// Report Type Enum
enum ReportTargetType {
  course,
  review,
}

/// Report Reason Enum
enum ReportReason {
  inappropriate('inappropriate'),
  spam('spam'),
  misleading('misleading'),
  copyright('copyright'),
  harassment('harassment'),
  other('other');

  final String value;
  const ReportReason(this.value);

  String getLabel(bool isArabic) {
    switch (this) {
      case ReportReason.inappropriate:
        return isArabic ? 'محتوى غير لائق' : 'Inappropriate Content';
      case ReportReason.spam:
        return isArabic ? 'محتوى مزعج / سبام' : 'Spam';
      case ReportReason.misleading:
        return isArabic ? 'معلومات مضللة' : 'Misleading Information';
      case ReportReason.copyright:
        return isArabic ? 'انتهاك حقوق الملكية' : 'Copyright Violation';
      case ReportReason.harassment:
        return isArabic ? 'تحرش أو إساءة' : 'Harassment';
      case ReportReason.other:
        return isArabic ? 'أخرى' : 'Other';
    }
  }
}

/// Reports Remote Data Source
class ReportsRemoteDataSource {
  final ApiClient _apiClient;
  static const _tag = 'ReportsDS';

  ReportsRemoteDataSource(this._apiClient);

  /// Submit a course report
  Future<bool> reportCourse({
    required String courseId,
    required ReportReason reason,
    String? description,
  }) async {
    AppLogger.d(
        '[$_tag] reportCourse: courseId=$courseId, reason=${reason.value}');
    try {
      await _apiClient.post('/reports/course', body: {
        'course_id': courseId,
        'reason': reason.value,
        'description': description,
      });

      AppLogger.success('[$_tag] Course report submitted successfully');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reportCourse error', e, s);
      rethrow;
    }
  }

  /// Submit a review report
  Future<bool> reportReview({
    required String reviewId,
    required ReportReason reason,
    String? description,
    // Cached review data in case review is deleted
    String? reviewerId,
    String? reviewComment,
    int? reviewRating,
  }) async {
    AppLogger.d(
        '[$_tag] reportReview: reviewId=$reviewId, reason=${reason.value}');
    try {
      await _apiClient.post('/reports/review', body: {
        'review_id': reviewId,
        'reason': reason.value,
        'description': description,
        'reviewer_id': reviewerId,
        'review_comment': reviewComment,
        'review_rating': reviewRating,
      });

      AppLogger.success('[$_tag] Review report submitted successfully');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reportReview error', e, s);
      rethrow;
    }
  }

  /// Check if user has a pending report for this course
  Future<bool> hasReportedCourse(String courseId) async {
    try {
      final response = await _apiClient.get('/reports/course/$courseId/status');
      return response['reported'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('[$_tag] hasReportedCourse error', e);
      return false;
    }
  }

  /// Check if user has a pending report for this review
  Future<bool> hasReportedReview(String reviewId) async {
    try {
      final response = await _apiClient.get('/reports/review/$reviewId/status');
      return response['reported'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('[$_tag] hasReportedReview error', e);
      return false;
    }
  }

  /// Get user's own reports
  Future<List<Map<String, dynamic>>> getMyReports() async {
    try {
      final response = await _apiClient.get('/reports/my');
      final reportsList = response['reports'] as List;
      return reportsList.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getMyReports error', e, s);
      rethrow;
    }
  }
}
