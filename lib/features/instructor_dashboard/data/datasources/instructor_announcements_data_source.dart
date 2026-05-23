import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';

/// Instructor Announcements Data Source
class InstructorAnnouncementsDataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorAnnouncementsDS';

  InstructorAnnouncementsDataSource(this._apiClient);

  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      final announcements = response['announcements'];
      if (announcements is List) return announcements;
      final courses = response['courses'];
      if (courses is List) return courses;
    }
    return const [];
  }

  /// Get announcements for a course
  Future<List<Map<String, dynamic>>> getAnnouncements({
    required String courseId,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAnnouncements: courseId=$courseId, page=$page');
    try {
      final response = await _apiClient.get(
        '/instructor/announcements?course_id=$courseId&page=$page&limit=$limit',
      );

      final list = _asList(response);
      AppLogger.success('[$_tag] getAnnouncements: ${list.length} items');
      return List<Map<String, dynamic>>.from(list);
    } catch (e, s) {
      AppLogger.e('[$_tag] getAnnouncements error', e, s);
      rethrow;
    }
  }

  /// Get all courses owned by the instructor
  Future<List<Map<String, dynamic>>> getMyCourses() async {
    AppLogger.d('[$_tag] getMyCourses');
    try {
      final response = await _apiClient.get('/instructor/announcements/courses');
      final list = _asList(response);
      AppLogger.success('[$_tag] getMyCourses: ${list.length} courses');
      return List<Map<String, dynamic>>.from(list);
    } catch (e, s) {
      AppLogger.e('[$_tag] getMyCourses error', e, s);
      rethrow;
    }
  }

  /// Create announcement
  Future<bool> createAnnouncement({
    required String courseId,
    required String titleAr,
    String? titleEn,
    String? contentAr,
    String? contentEn,
  }) async {
    AppLogger.d('[$_tag] createAnnouncement: courseId=$courseId');
    try {
      await _apiClient.post(
        '/instructor/announcements',
        body: {
          'course_id': courseId,
          'title_ar': titleAr,
          'title_en': titleEn,
          'content_ar': contentAr,
          'content_en': contentEn,
        },
      );
      AppLogger.success('[$_tag] createAnnouncement success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] createAnnouncement error', e, s);
      rethrow;
    }
  }

  /// Update announcement
  Future<bool> updateAnnouncement(
      String announcementId, Map<String, dynamic> data) async {
    AppLogger.d('[$_tag] updateAnnouncement: $announcementId');
    try {
      await _apiClient.put(
        '/instructor/announcements/$announcementId',
        body: data,
      );
      AppLogger.success('[$_tag] updateAnnouncement success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateAnnouncement error', e, s);
      rethrow;
    }
  }

  /// Delete announcement
  Future<bool> deleteAnnouncement(String announcementId) async {
    AppLogger.d('[$_tag] deleteAnnouncement: $announcementId');
    try {
      await _apiClient.delete('/instructor/announcements/$announcementId');
      AppLogger.success('[$_tag] deleteAnnouncement success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAnnouncement error', e, s);
      rethrow;
    }
  }
}
