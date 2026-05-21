import 'package:supabase_flutter/supabase_flutter.dart';
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
  final SupabaseClient _client;
  static const _tag = 'ReportsDS';

  ReportsRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Submit a course report
  Future<bool> reportCourse({
    required String courseId,
    required ReportReason reason,
    String? description,
  }) async {
    AppLogger.d(
        '[$_tag] reportCourse: courseId=$courseId, reason=${reason.value}');
    try {
      await _client.from('course_reports').insert({
        'course_id': courseId,
        'user_id': _userId,
        'reason': reason.value,
        'description': description,
        'status': 'pending',
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
      await _client.from('review_reports').insert({
        'review_id': reviewId,
        'user_id': _userId,
        'reason': reason.value,
        'description': description,
        'cached_reviewer_id': reviewerId,
        'cached_review_comment': reviewComment,
        'cached_review_rating': reviewRating,
        'status': 'pending',
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
      final response = await _client
          .from('course_reports')
          .select('id')
          .eq('course_id', courseId)
          .eq('user_id', _userId)
          .eq('status', 'pending')
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      AppLogger.e('[$_tag] hasReportedCourse error', e);
      return false;
    }
  }

  /// Check if user has a pending report for this review
  Future<bool> hasReportedReview(String reviewId) async {
    try {
      final response = await _client
          .from('review_reports')
          .select('id')
          .eq('review_id', reviewId)
          .eq('user_id', _userId)
          .eq('status', 'pending')
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      AppLogger.e('[$_tag] hasReportedReview error', e);
      return false;
    }
  }

  /// Get user's own reports
  Future<List<Map<String, dynamic>>> getMyReports() async {
    try {
      final courseReports = await _client
          .from('course_reports')
          .select('*, course:courses(title_ar, title_en)')
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      final reviewReports = await _client
          .from('review_reports')
          .select('*')
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      // Combine and sort
      final allReports = <Map<String, dynamic>>[];

      for (final r in (courseReports as List)) {
        allReports.add({
          ...Map<String, dynamic>.from(r),
          'type': 'course',
        });
      }

      for (final r in (reviewReports as List)) {
        allReports.add({
          ...Map<String, dynamic>.from(r),
          'type': 'review',
        });
      }

      // Sort by created_at
      allReports.sort((a, b) {
        final aDate = DateTime.parse(a['created_at'] as String);
        final bDate = DateTime.parse(b['created_at'] as String);
        return bDate.compareTo(aDate);
      });

      return allReports;
    } catch (e, s) {
      AppLogger.e('[$_tag] getMyReports error', e, s);
      rethrow;
    }
  }
}
