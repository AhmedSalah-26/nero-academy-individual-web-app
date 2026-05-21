import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';

/// Instructor Announcements Data Source
class InstructorAnnouncementsDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorAnnouncementsDS';

  InstructorAnnouncementsDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get announcements for a course
  Future<List<Map<String, dynamic>>> getAnnouncements({
    required String courseId,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAnnouncements: courseId=$courseId, page=$page');
    try {
      final response = await _client
          .from('course_announcements')
          .select('*, user:profiles(name, avatar_url)')
          .eq('course_id', courseId)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getAnnouncements: ${(response as List).length} items');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, s) {
      AppLogger.e('[$_tag] getAnnouncements error', e, s);
      rethrow;
    }
  }

  /// Get all courses owned by the instructor (for selecting which course to announce to)
  Future<List<Map<String, dynamic>>> getMyCourses() async {
    AppLogger.d('[$_tag] getMyCourses');
    try {
      final response = await _client
          .from('courses')
          .select('id, title_ar, title_en')
          .eq('instructor_id', _userId)
          .eq('is_published', true)
          .order('title_ar');

      AppLogger.success(
          '[$_tag] getMyCourses: ${(response as List).length} courses');
      return List<Map<String, dynamic>>.from(response);
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
      await _client.from('course_announcements').insert({
        'course_id': courseId,
        'user_id': _userId,
        'title_ar': titleAr,
        'title_en': titleEn,
        'content_ar': contentAr,
        'content_en': contentEn,
      });
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
      data['updated_at'] = DateTime.now().toIso8601String();
      await _client
          .from('course_announcements')
          .update(data)
          .eq('id', announcementId)
          .eq('user_id', _userId);
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
      await _client
          .from('course_announcements')
          .delete()
          .eq('id', announcementId)
          .eq('user_id', _userId);
      AppLogger.success('[$_tag] deleteAnnouncement success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAnnouncement error', e, s);
      rethrow;
    }
  }
}
