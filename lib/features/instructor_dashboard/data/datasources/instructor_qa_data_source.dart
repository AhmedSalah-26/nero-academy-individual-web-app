import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/instructor_entities.dart';
import '../models/instructor_models.dart';

/// Instructor Q&A Data Source - Q&A management
class InstructorQADataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorQADS';

  InstructorQADataSource(this._apiClient);

  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      final questions = response['questions'];
      if (questions is List) return questions;
    }
    return const [];
  }

  /// Get questions
  Future<List<InstructorQuestionModel>> getQuestions({
    QAStatus? status,
    String? courseId,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getQuestions: status=$status, courseId=$courseId');
    try {
      final queryParams = <String>[];
      if (status != null) queryParams.add('status=${status.name}');
      if (courseId != null) queryParams.add('courseId=$courseId');
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');

      final url = '/instructor/qa/questions?${queryParams.join('&')}';
      final response = await _apiClient.get(url);

      final list = _asList(response);
      AppLogger.success('[$_tag] getQuestions: ${list.length} questions');
      return list.map((e) => InstructorQuestionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getQuestions error', e, s);
      rethrow;
    }
  }

  /// Answer question
  Future<bool> answerQuestion(String questionId, String answer) async {
    AppLogger.d('[$_tag] answerQuestion: questionId=$questionId');
    try {
      await _apiClient.post(
        '/instructor/qa/questions/$questionId/answer',
        body: {'answer': answer},
      );
      AppLogger.success('[$_tag] answerQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] answerQuestion error', e, s);
      rethrow;
    }
  }

  /// Update an answer
  Future<bool> updateAnswer(String answerId, String newContent) async {
    AppLogger.d('[$_tag] updateAnswer: answerId=$answerId');
    try {
      await _apiClient.put(
        '/instructor/qa/answers/$answerId',
        body: {'content': newContent},
      );
      AppLogger.success('[$_tag] updateAnswer success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateAnswer error', e, s);
      rethrow;
    }
  }

  /// Delete an answer
  Future<bool> deleteAnswer(String answerId) async {
    AppLogger.d('[$_tag] deleteAnswer: answerId=$answerId');
    try {
      await _apiClient.delete('/instructor/qa/answers/$answerId');
      AppLogger.success('[$_tag] deleteAnswer success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAnswer error', e, s);
      rethrow;
    }
  }

  /// Hide a question (instructor moderation)
  Future<bool> hideQuestion(String questionId) async {
    AppLogger.d('[$_tag] hideQuestion: $questionId');
    try {
      await _apiClient.post('/instructor/qa/questions/$questionId/hide');
      AppLogger.success('[$_tag] hideQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] hideQuestion error', e, s);
      rethrow;
    }
  }

  /// Pin a question
  Future<bool> pinQuestion(String questionId, bool isPinned) async {
    AppLogger.d('[$_tag] pinQuestion: $questionId, isPinned=$isPinned');
    try {
      await _apiClient.post(
        '/instructor/qa/questions/$questionId/pin',
        body: {'isPinned': isPinned},
      );
      AppLogger.success('[$_tag] pinQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] pinQuestion error', e, s);
      rethrow;
    }
  }
}
