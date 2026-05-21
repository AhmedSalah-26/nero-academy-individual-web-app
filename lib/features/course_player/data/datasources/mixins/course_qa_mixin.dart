import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/services/app_logger.dart';
import '../../models/qa_question_model.dart';

/// Mixin for Q&A functionality
mixin CoursePlayerQAMixin {
  SupabaseClient get client;

  // Q&A Methods
  Future<List<QAQuestionModel>> getQuestions({
    required String courseId,
    String? lessonId,
  }) async {
    try {
      AppLogger.d('[DataSource] getQuestions: $courseId, lesson: $lessonId');

      final userId = client.auth.currentUser?.id;

      var query = client.from('qa_questions').select('''
            *,
            user:user_id(id, name, avatar_url),
            answers:qa_answers(
              *,
              user:user_id(id, name, avatar_url),
              has_upvoted:qa_answer_upvotes!left(user_id)
            )
          ''').eq('course_id', courseId);

      if (lessonId != null) {
        query = query.eq('lesson_id', lessonId);
      }

      final response = await query.order('created_at', ascending: false);

      // Process the response to add has_upvoted flag for answers only
      final questions = (response as List).map((json) {
        // Process answers to add has_upvoted flag
        final answersRaw = json['answers'] as List?;
        if (answersRaw != null) {
          for (var answer in answersRaw) {
            final answerUpvotes = answer['has_upvoted'] as List?;
            answer['has_upvoted'] =
                answerUpvotes?.any((upvote) => upvote['user_id'] == userId) ??
                    false;
          }
        }

        // Questions don't have upvotes table, so keep hasUpvoted as false
        json['has_upvoted'] = false;
        return QAQuestionModel.fromJson(json);
      }).toList();

      return questions;
    } catch (e) {
      AppLogger.e('[DataSource] Failed to get questions: $e');
      throw ServerException(e.toString());
    }
  }

  Future<QAQuestionModel> addQuestion({
    required String courseId,
    required String enrollmentId,
    String? lessonId,
    required String title,
    required String content,
  }) async {
    try {
      AppLogger.d('[DataSource] addQuestion: $courseId');

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw const ServerException('User not authenticated');
      }

      final response = await client.from('qa_questions').insert({
        'user_id': userId,
        'course_id': courseId,
        'lesson_id': lessonId,
        'title': title,
        'content': content,
      }).select('''
        *,
        user:user_id(id, name, avatar_url),
        answers:qa_answers(
          *,
          user:user_id(id, name, avatar_url)
        )
      ''').single();

      return QAQuestionModel.fromJson(response);
    } catch (e) {
      AppLogger.e('[DataSource] Failed to add question: $e');
      throw ServerException(e.toString());
    }
  }

  Future<bool> hasUpvotedAnswer({required String answerId}) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await client
          .from('qa_answer_upvotes')
          .select('id')
          .eq('answer_id', answerId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.e('[DataSource] Failed to check upvote: $e');
      return false;
    }
  }

  Future<bool> toggleAnswerUpvote({required String answerId}) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw const ServerException('User not authenticated');

      final hasUpvoted = await hasUpvotedAnswer(answerId: answerId);

      if (hasUpvoted) {
        await client
            .from('qa_answer_upvotes')
            .delete()
            .eq('answer_id', answerId)
            .eq('user_id', userId);
        return false;
      } else {
        await client.from('qa_answer_upvotes').insert({
          'answer_id': answerId,
          'user_id': userId,
        });
        return true;
      }
    } catch (e) {
      AppLogger.e('[DataSource] Failed to toggle upvote: $e');
      throw ServerException(e.toString());
    }
  }
}
