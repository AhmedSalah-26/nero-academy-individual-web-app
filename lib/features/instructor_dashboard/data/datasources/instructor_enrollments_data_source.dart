import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/instructor_entities.dart';
import '../../domain/repositories/instructor_repository.dart';
import '../models/instructor_models.dart';

/// Instructor Enrollments Data Source - Enrollment management
class InstructorEnrollmentsDataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorEnrollmentsDS';

  InstructorEnrollmentsDataSource(this._apiClient);

  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      final enrollments = response['enrollments'];
      if (enrollments is List) return enrollments;
    }
    return const [];
  }

  /// Get enrollments
  Future<List<InstructorEnrollmentModel>> getEnrollments({
    InstructorEnrollmentStatus? status,
    String? courseId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getEnrollments: status=$status, courseId=$courseId');
    try {
      final queryParams = <String>[];
      if (status != null) queryParams.add('status=${status.name}');
      if (courseId != null) queryParams.add('courseId=$courseId');
      if (startDate != null) queryParams.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toIso8601String()}');
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');

      final url = '/instructor/enrollments?${queryParams.join('&')}';
      final response = await _apiClient.get(url);

      final list = _asList(response);
      AppLogger.success('[$_tag] getEnrollments: ${list.length} enrollments');
      return list.map((e) => InstructorEnrollmentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getEnrollments error', e, s);
      rethrow;
    }
  }

  /// Extend enrollment access
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days) async {
    AppLogger.d('[$_tag] extendEnrollmentAccess: $enrollmentId, days=$days');
    try {
      await _apiClient.post(
        '/instructor/enrollments/$enrollmentId/extend',
        body: {'days': days},
      );
      AppLogger.success('[$_tag] extendEnrollmentAccess success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] extendEnrollmentAccess error', e, s);
      rethrow;
    }
  }

  /// Reset enrollment progress
  Future<bool> resetEnrollmentProgress(String enrollmentId) async {
    AppLogger.d('[$_tag] resetEnrollmentProgress: $enrollmentId');
    try {
      await _apiClient.post('/instructor/enrollments/$enrollmentId/reset');
      AppLogger.success('[$_tag] resetEnrollmentProgress success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] resetEnrollmentProgress error', e, s);
      rethrow;
    }
  }

  /// Update enrollment status
  Future<bool> updateEnrollmentStatus(
      String enrollmentId, String status) async {
    AppLogger.d('[$_tag] updateEnrollmentStatus: $enrollmentId, status=$status');
    try {
      await _apiClient.post(
        '/instructor/enrollments/$enrollmentId/status',
        body: {'status': status},
      );
      AppLogger.success('[$_tag] updateEnrollmentStatus success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateEnrollmentStatus error', e, s);
      rethrow;
    }
  }

  /// Mark enrollment as completed
  Future<bool> markAsCompleted(String enrollmentId) async {
    AppLogger.d('[$_tag] markAsCompleted: $enrollmentId');
    try {
      await _apiClient.post('/instructor/enrollments/$enrollmentId/complete');
      AppLogger.success('[$_tag] markAsCompleted success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] markAsCompleted error', e, s);
      rethrow;
    }
  }

  /// Enroll student in a course
  Future<bool> enrollStudent(String studentId, String courseId) async {
    AppLogger.d('[$_tag] enrollStudent: studentId=$studentId, courseId=$courseId');
    try {
      await _apiClient.post(
        '/instructor/enrollments/enroll',
        body: {
          'student_id': studentId,
          'course_id': courseId,
        },
      );
      AppLogger.success('[$_tag] enrollStudent success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] enrollStudent error', e, s);
      rethrow;
    }
  }

  /// Unenroll student from a course
  Future<bool> unenrollStudent(String enrollmentId) async {
    AppLogger.d('[$_tag] unenrollStudent: $enrollmentId');
    try {
      await _apiClient.post('/instructor/enrollments/$enrollmentId/unenroll');
      AppLogger.success('[$_tag] unenrollStudent success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unenrollStudent error', e, s);
      rethrow;
    }
  }

  /// Get available courses for student enrollment
  Future<List<AvailableCourseForEnrollment>> getAvailableCoursesForStudent(
      String studentId) async {
    AppLogger.d('[$_tag] getAvailableCoursesForStudent: $studentId');
    try {
      final response = await _apiClient.get('/instructor/enrollments/available-courses/$studentId');
      final list = _asList(response);
      AppLogger.success('[$_tag] getAvailableCoursesForStudent: ${list.length}');
      return list.map((e) => AvailableCourseForEnrollment.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getAvailableCoursesForStudent error', e, s);
      rethrow;
    }
  }
}
