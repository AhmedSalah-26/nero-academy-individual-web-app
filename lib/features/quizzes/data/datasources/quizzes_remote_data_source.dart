import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_attempt_model.dart';

/// Quizzes Remote Data Source - Handles API calls to Laravel backend
abstract class QuizzesRemoteDataSource {
  Future<List<QuizModel>> getCourseQuizzes({required String courseId});
  Future<QuizModel> getQuiz({required String quizId});
  Future<QuizModel?> getQuizByLessonId({required String lessonId});
  Future<List<QuizQuestionModel>> getQuizQuestions({
    required String quizId,
    bool shuffle,
  });
  Future<List<QuizAttemptModel>> getQuizAttempts({
    required String quizId,
    required String enrollmentId,
  });
  Future<QuizAttemptModel> startQuizAttempt({
    required String quizId,
    required String enrollmentId,
  });
  Future<QuizAttemptModel> submitQuiz({
    required String attemptId,
    required Map<String, List<String>> answers,
    required int timeSpentSeconds,
  });
  Future<QuizAttemptModel> getAttemptDetails({required String attemptId});
  Future<int> getRemainingAttempts({
    required String quizId,
    required String enrollmentId,
  });
}

/// Quizzes Remote Data Source Implementation
class QuizzesRemoteDataSourceImpl implements QuizzesRemoteDataSource {
  final ApiClient apiClient;

  QuizzesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<QuizModel>> getCourseQuizzes({required String courseId}) async {
    try {
      final response = await apiClient.get('/courses/$courseId/quizzes');
      final list = response['quizzes'] as List;
      return list.map((q) {
        final count = q['questions_count'] as int? ?? q['total_questions'] as int? ?? 0;
        return QuizModel.fromJson({
          ...q as Map<String, dynamic>,
          'total_questions': count,
        });
      }).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في تحميل اختبارات الكورس: $e');
    }
  }

  @override
  Future<QuizModel> getQuiz({required String quizId}) async {
    try {
      final response = await apiClient.get('/quizzes/$quizId');
      final q = response['quiz'] as Map<String, dynamic>;
      final count = q['questions_count'] as int? ?? q['total_questions'] as int? ?? 0;
      return QuizModel.fromJson({
        ...q,
        'total_questions': count,
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في تحميل بيانات الاختبار: $e');
    }
  }

  @override
  Future<QuizModel?> getQuizByLessonId({required String lessonId}) async {
    try {
      final response = await apiClient.get('/quizzes/lesson/$lessonId');
      if (response == null || response['quiz'] == null) return null;
      final q = response['quiz'] as Map<String, dynamic>;
      final count = q['questions_count'] as int? ?? q['total_questions'] as int? ?? 0;
      return QuizModel.fromJson({
        ...q,
        'total_questions': count,
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في تحميل بيانات الاختبار: $e');
    }
  }

  @override
  Future<List<QuizQuestionModel>> getQuizQuestions({
    required String quizId,
    bool shuffle = false,
  }) async {
    try {
      final response = await apiClient.get('/quizzes/$quizId/questions');
      final list = response['questions'] as List;
      var questions = list
          .map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();

      if (shuffle) {
        questions.shuffle();
      }

      return questions;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في تحميل أسئلة الاختبار: $e');
    }
  }

  @override
  Future<List<QuizAttemptModel>> getQuizAttempts({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      final response = await apiClient.get(
        '/quizzes/$quizId/attempts?enrollment_id=$enrollmentId',
      );
      final list = response['attempts'] as List;
      return list.map((a) => QuizAttemptModel.fromJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في تحميل محاولات الاختبار: $e');
    }
  }

  @override
  Future<QuizAttemptModel> startQuizAttempt({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      final response = await apiClient.post(
        '/quizzes/$quizId/attempt',
        body: {
          'enrollment_id': enrollmentId,
        },
      );
      final attemptId = response['attempt_id'] as String;
      return getAttemptDetails(attemptId: attemptId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في بدء الاختبار: $e');
    }
  }

  @override
  Future<QuizAttemptModel> submitQuiz({
    required String attemptId,
    required Map<String, List<String>> answers,
    required int timeSpentSeconds,
  }) async {
    try {
      final response = await apiClient.post(
        '/quizzes/attempts/$attemptId/submit',
        body: {
          'answers': answers,
          'time_spent': timeSpentSeconds,
        },
      );
      if (response == null || response['success'] != true) {
        throw ServerException(response?['message'] ?? 'فشل في إرسال الاختبار');
      }
      return getAttemptDetails(attemptId: attemptId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في إرسال الاختبار: $e');
    }
  }

  @override
  Future<QuizAttemptModel> getAttemptDetails({
    required String attemptId,
  }) async {
    try {
      final response = await apiClient.get('/quizzes/attempts/$attemptId');
      return QuizAttemptModel.fromJson(response['attempt'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في تحميل تفاصيل المحاولة: $e');
    }
  }

  @override
  Future<int> getRemainingAttempts({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      final quiz = await getQuiz(quizId: quizId);
      if (quiz.maxAttempts == null) return -1; // Unlimited

      final attempts = await getQuizAttempts(
        quizId: quizId,
        enrollmentId: enrollmentId,
      );

      final completedCount = attempts.where((a) => a.completedAt != null).length;
      return quiz.maxAttempts! - completedCount;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في حساب المحاولات المتبقية: $e');
    }
  }
}
