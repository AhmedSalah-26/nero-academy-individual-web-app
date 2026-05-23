import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/repositories/instructor_repository.dart';
import '../models/instructor_models.dart';

/// Instructor Students Data Source - Student management
class InstructorStudentsDataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorStudentsDS';

  InstructorStudentsDataSource(this._apiClient);

  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      final students = response['students'];
      if (students is List) return students;
    }
    return const [];
  }

  /// Get students enrolled in instructor's courses
  Future<List<InstructorStudentModel>> getStudents({
    String? courseId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getStudents: courseId=$courseId, search=$search');
    try {
      final queryParams = <String>[];
      if (courseId != null) queryParams.add('courseId=$courseId');
      if (search != null) queryParams.add('search=${Uri.encodeComponent(search)}');
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');

      final url = '/instructor/students?${queryParams.join('&')}';
      final response = await _apiClient.get(url);

      final list = _asList(response);
      AppLogger.success('[$_tag] getStudents: ${list.length} students');
      return list.map((e) => InstructorStudentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getStudents error', e, s);
      rethrow;
    }
  }

  /// Get student enrollments
  Future<List<StudentEnrollmentDetail>> getStudentEnrollments(
      String studentId) async {
    AppLogger.d('[$_tag] getStudentEnrollments: studentId=$studentId');
    try {
      final response = await _apiClient.get('/instructor/students/$studentId/enrollments');
      final list = _asList(response);
      AppLogger.success('[$_tag] getStudentEnrollments: ${list.length} enrollments found');
      return list.map((e) => StudentEnrollmentDetail.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getStudentEnrollments error', e, s);
      rethrow;
    }
  }

  /// Get student progress
  Future<List<StudentCourseProgress>> getStudentProgress(
      String studentId) async {
    AppLogger.d('[$_tag] getStudentProgress: studentId=$studentId');
    try {
      final response = await _apiClient.get('/instructor/students/$studentId/progress');
      final list = _asList(response);
      AppLogger.success('[$_tag] getStudentProgress: ${list.length} courses');
      return list.map((e) => StudentCourseProgress.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getStudentProgress error', e, s);
      rethrow;
    }
  }

  /// Send message to student
  Future<bool> sendMessageToStudent(
      String studentId, String subject, String message) async {
    AppLogger.d('[$_tag] sendMessageToStudent: studentId=$studentId');
    try {
      await _apiClient.post(
        '/instructor/students/$studentId/message',
        body: {
          'subject': subject,
          'message': message,
        },
      );
      AppLogger.success('[$_tag] sendMessageToStudent success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] sendMessageToStudent error', e, s);
      rethrow;
    }
  }
}
