import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../models/enrollment_model.dart';
import '../models/learning_progress_model.dart';

/// My Learning Remote Data Source - Abstract Contract
abstract class MyLearningRemoteDataSource {
  Future<List<EnrollmentModel>> getEnrollments({
    required String userId,
    EnrollmentStatus? status,
    int page = 1,
    int limit = 20,
  });

  Future<EnrollmentModel?> getContinueLearning(String userId);

  Future<EnrollmentModel> getEnrollmentById(String enrollmentId);

  Future<LearningProgressModel> updateLessonProgress({
    required String enrollmentId,
    required String lessonId,
    required int watchedSeconds,
    bool isCompleted = false,
  });

  Future<LearningProgressModel?> getLessonProgress({
    required String enrollmentId,
    required String lessonId,
  });

  Future<EnrollmentModel> markCourseCompleted(String enrollmentId);

  Future<List<EnrollmentModel>> getRecommendedCourses({
    required String userId,
    int limit = 5,
  });
}

/// My Learning Remote Data Source Implementation using Laravel REST APIs
class MyLearningRemoteDataSourceImpl implements MyLearningRemoteDataSource {
  final ApiClient apiClient;

  MyLearningRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<EnrollmentModel>> getEnrollments({
    required String userId,
    EnrollmentStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.get('/enrollments');
      final list = response['enrollments'] as List;
      final enrollments = list.map((json) => EnrollmentModel.fromJson(json)).toList();

      if (status != null) {
        return enrollments.where((e) => e.status == status).toList();
      }

      // Implement simple pagination
      final startIndex = (page - 1) * limit;
      if (startIndex >= enrollments.length) return [];
      final endIndex = page * limit;
      return enrollments.sublist(
        startIndex,
        endIndex > enrollments.length ? enrollments.length : endIndex,
      );
    } catch (e) {
      debugPrint('⚠️ [MyLearningRemote] getEnrollments failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<EnrollmentModel?> getContinueLearning(String userId) async {
    try {
      final enrollments = await getEnrollments(userId: userId);
      final active = enrollments.where((e) => e.status == EnrollmentStatus.active && e.progressPercentage > 0).toList();
      if (active.isEmpty) return null;
      active.sort((a, b) {
        if (a.lastAccessedAt == null && b.lastAccessedAt == null) return 0;
        if (a.lastAccessedAt == null) return 1;
        if (b.lastAccessedAt == null) return -1;
        return b.lastAccessedAt!.compareTo(a.lastAccessedAt!);
      });
      return active.first;
    } catch (e) {
      debugPrint('⚠️ [MyLearningRemote] getContinueLearning failed: $e');
      return null;
    }
  }

  @override
  Future<EnrollmentModel> getEnrollmentById(String enrollmentId) async {
    try {
      final response = await apiClient.get('/enrollments');
      final list = response['enrollments'] as List;
      final match = list.firstWhere(
        (json) => json['id'] == enrollmentId,
        orElse: () => throw const ServerException('Enrollment not found'),
      );
      return EnrollmentModel.fromJson(match);
    } catch (e) {
      debugPrint('⚠️ [MyLearningRemote] getEnrollmentById failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LearningProgressModel> updateLessonProgress({
    required String enrollmentId,
    required String lessonId,
    required int watchedSeconds,
    bool isCompleted = false,
  }) async {
    try {
      final response = await apiClient.post(
        '/enrollments/progress',
        body: {
          'lesson_id': lessonId,
          'watch_time': watchedSeconds,
          'last_position': watchedSeconds,
          'is_completed': isCompleted,
        },
      );
      return LearningProgressModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ [MyLearningRemote] updateLessonProgress failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LearningProgressModel?> getLessonProgress({
    required String enrollmentId,
    required String lessonId,
  }) async {
    try {
      final response = await apiClient.get(
        '/enrollments/progress?enrollment_id=$enrollmentId&lesson_id=$lessonId',
      );
      if (response['data'] == null) return null;
      return LearningProgressModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ [MyLearningRemote] getLessonProgress failed: $e');
      return null;
    }
  }

  @override
  Future<EnrollmentModel> markCourseCompleted(String enrollmentId) async {
    try {
      final response = await apiClient.post('/enrollments/$enrollmentId/complete');
      return EnrollmentModel.fromJson(response['enrollment'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ [MyLearningRemote] markCourseCompleted failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<EnrollmentModel>> getRecommendedCourses({
    required String userId,
    int limit = 5,
  }) async {
    return [];
  }
}
