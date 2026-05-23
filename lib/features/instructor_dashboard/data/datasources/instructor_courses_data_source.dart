import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/instructor_entities.dart';
import '../models/instructor_models.dart';

/// Instructor Courses Data Source - Course management
class InstructorCoursesDataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorCoursesDS';

  InstructorCoursesDataSource(this._apiClient);

  List<dynamic> _extractCourses(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final courses = response['courses'];
      if (courses is List) return courses;
      final data = response['data'];
      if (data is List) return data;
    }
    return const [];
  }

  /// Get my courses
  Future<List<InstructorCourseModel>> getMyCourses({
    InstructorCourseStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getMyCourses: status=$status, page=$page');
    try {
      final statusVal = status?.name ?? 'all';
      final response = await _apiClient.get(
        '/instructor/courses?status=$statusVal&page=$page&limit=$limit',
      );

      final list = _extractCourses(response);
      AppLogger.success('[$_tag] getMyCourses: ${list.length} courses');
      return list.map((e) => InstructorCourseModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getMyCourses error', e, s);
      rethrow;
    }
  }

  /// Publish course
  Future<bool> publishCourse(String courseId) async {
    AppLogger.d('[$_tag] publishCourse: $courseId');
    try {
      await _apiClient.post('/instructor/courses/$courseId/publish');
      AppLogger.success('[$_tag] publishCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] publishCourse error', e, s);
      rethrow;
    }
  }

  /// Unpublish course
  Future<bool> unpublishCourse(String courseId) async {
    AppLogger.d('[$_tag] unpublishCourse: $courseId');
    try {
      await _apiClient.post('/instructor/courses/$courseId/unpublish');
      AppLogger.success('[$_tag] unpublishCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unpublishCourse error', e, s);
      rethrow;
    }
  }

  /// Delete course (only if not published or has no enrollments)
  Future<bool> deleteCourse(String courseId) async {
    AppLogger.d('[$_tag] deleteCourse: $courseId');
    try {
      await _apiClient.delete('/instructor/courses/$courseId');
      AppLogger.success('[$_tag] deleteCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteCourse error', e, s);
      rethrow;
    }
  }
}
