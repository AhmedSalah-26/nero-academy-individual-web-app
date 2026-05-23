import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';

part 'instructor_quizzes_state.dart';

/// Instructor Quizzes Cubit - uses ApiClient (Laravel backend)
class InstructorQuizzesCubit extends Cubit<InstructorQuizzesState> {
  final ApiClient _apiClient;
  int _currentPage = 1;
  static const int _pageSize = 20;
  static const _tag = 'InstructorQuizzesCubit';

  InstructorQuizzesCubit(this._apiClient)
      : super(const InstructorQuizzesState());

  /// Load quizzes
  Future<void> loadQuizzes({bool refresh = false}) async {
    AppLogger.i('📝 [$_tag] loadQuizzes: refresh=$refresh');

    if (refresh) {
      _currentPage = 1;
      emit(state.copyWith(
        status: InstructorQuizzesStatus.loading,
        quizzes: [],
        hasMore: true,
      ));
    } else if (state.status == InstructorQuizzesStatus.initial) {
      emit(state.copyWith(status: InstructorQuizzesStatus.loading));
    }

    try {
      AppLogger.d('[$_tag] Loading quizzes for instructor (page=$_currentPage)');

      final url = '/instructor/quizzes?page=$_currentPage&per_page=$_pageSize';
      final response = await _apiClient.get(url);

      final rawList = response is List
          ? response
          : (response['quizzes'] ?? response['data'] ?? []) as List;

      AppLogger.d('[$_tag] Raw quizzes response: ${rawList.length} quizzes');

      final quizzes =
          rawList.map((q) => InstructorQuizModel.fromJson(q as Map<String, dynamic>)).toList();

      AppLogger.success('[$_tag] Loaded ${quizzes.length} quizzes');

      emit(state.copyWith(
        status: InstructorQuizzesStatus.success,
        quizzes: refresh ? quizzes : [...state.quizzes, ...quizzes],
        hasMore: quizzes.length >= _pageSize,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadQuizzes error', e, s);
      emit(state.copyWith(
        status: InstructorQuizzesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more quizzes
  Future<void> loadMoreQuizzes() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    _currentPage++;
    await loadQuizzes();
    emit(state.copyWith(isLoadingMore: false));
  }

  /// Filter by course
  void filterByCourse(String? courseId) {
    emit(state.copyWith(selectedCourseId: courseId));
    loadQuizzes(refresh: true);
  }

  /// Create quiz (course-level)
  Future<bool> createQuiz({
    required String courseId,
    required String titleAr,
    required String titleEn,
    String? descriptionAr,
    String? descriptionEn,
    required int passingScore,
    int? timeLimitMinutes,
    int? maxAttempts,
    bool shuffleQuestions = false,
    bool shuffleAnswers = false,
    bool showCorrectAnswers = true,
  }) async {
    AppLogger.i('📝 [$_tag] createQuiz: courseId=$courseId, title=$titleAr');

    try {
      final body = {
        'course_id': courseId,
        'title_ar': titleAr,
        'title_en': titleEn,
        if (descriptionAr != null) 'description_ar': descriptionAr,
        if (descriptionEn != null) 'description_en': descriptionEn,
        'passing_score': passingScore,
        if (timeLimitMinutes != null) 'time_limit': timeLimitMinutes,
        if (maxAttempts != null) 'max_attempts': maxAttempts,
        'shuffle_questions': shuffleQuestions,
        'shuffle_answers': shuffleAnswers,
        'show_correct_answers': showCorrectAnswers,
      };

      final response = await _apiClient.post('/instructor/quizzes', body: body);
      AppLogger.success('[$_tag] Quiz created: ${response['id']}');
      await loadQuizzes(refresh: true);
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] createQuiz error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Update quiz
  Future<bool> updateQuiz({
    required String quizId,
    String? titleAr,
    String? titleEn,
    String? descriptionAr,
    String? descriptionEn,
    int? passingScore,
    int? timeLimitMinutes,
    int? maxAttempts,
    bool? shuffleQuestions,
    bool? shuffleAnswers,
    bool? showCorrectAnswers,
  }) async {
    AppLogger.i('📝 [$_tag] updateQuiz: quizId=$quizId');

    try {
      final updates = <String, dynamic>{};
      if (titleAr != null) updates['title_ar'] = titleAr;
      if (titleEn != null) updates['title_en'] = titleEn;
      if (descriptionAr != null) updates['description_ar'] = descriptionAr;
      if (descriptionEn != null) updates['description_en'] = descriptionEn;
      if (passingScore != null) updates['passing_score'] = passingScore;
      if (timeLimitMinutes != null) updates['time_limit'] = timeLimitMinutes;
      if (maxAttempts != null) updates['max_attempts'] = maxAttempts;
      if (shuffleQuestions != null) {
        updates['shuffle_questions'] = shuffleQuestions;
      }
      if (shuffleAnswers != null) updates['shuffle_answers'] = shuffleAnswers;
      if (showCorrectAnswers != null) {
        updates['show_correct_answers'] = showCorrectAnswers;
      }

      await _apiClient.put('/instructor/quizzes/$quizId', body: updates);

      AppLogger.success('[$_tag] Quiz updated');
      await loadQuizzes(refresh: true);
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateQuiz error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Delete quiz
  Future<bool> deleteQuiz(String quizId) async {
    AppLogger.i('📝 [$_tag] deleteQuiz: quizId=$quizId');

    try {
      await _apiClient.delete('/instructor/quizzes/$quizId');

      final updatedQuizzes =
          state.quizzes.where((q) => q.id != quizId).toList();
      emit(state.copyWith(quizzes: updatedQuizzes));

      AppLogger.success('[$_tag] Quiz deleted');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteQuiz error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Get quiz questions
  Future<List<QuizQuestionModel>> getQuizQuestions(String quizId) async {
    AppLogger.i('📝 [$_tag] getQuizQuestions: quizId=$quizId');

    try {
      final response = await _apiClient.get('/instructor/quizzes/$quizId/questions');
      final rawList = response is List
          ? response
          : (response['questions'] ?? response['data'] ?? []) as List;

      final questions =
          rawList.map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>)).toList();

      AppLogger.success('[$_tag] Loaded ${questions.length} questions');
      return questions;
    } catch (e, s) {
      AppLogger.e('[$_tag] getQuizQuestions error', e, s);
      return [];
    }
  }

  /// Add question
  Future<bool> addQuestion({
    required String quizId,
    required String questionAr,
    required String questionEn,
    String? imageUrl,
    required String type,
    int points = 1,
    required List<Map<String, dynamic>> options,
    String? correctAnswer,
  }) async {
    AppLogger.i('📝 [$_tag] addQuestion: quizId=$quizId, type=$type');

    try {
      // Generate UUIDs for options that don't have IDs
      const uuid = Uuid();
      final optionsWithIds = options.map((opt) {
        if (opt['id'] == null || (opt['id'] as String).isEmpty) {
          return {...opt, 'id': uuid.v4()};
        }
        return opt;
      }).toList();

      final body = {
        'question_ar': questionAr,
        'question_en': questionEn,
        if (imageUrl != null) 'image_url': imageUrl,
        'question_type': type,
        'points': points,
        'options': optionsWithIds,
        if (correctAnswer != null) 'correct_answer': correctAnswer,
      };

      AppLogger.d('📝 [$_tag] Posting question: $body');
      await _apiClient.post('/instructor/quizzes/$quizId/questions', body: body);

      AppLogger.success('[$_tag] Question added successfully');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] addQuestion error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Update question
  Future<bool> updateQuestion({
    required String questionId,
    String? questionAr,
    String? questionEn,
    String? imageUrl,
    bool removeImage = false,
    String? type,
    int? points,
    List<Map<String, dynamic>>? options,
    String? correctAnswer,
  }) async {
    AppLogger.i('📝 [$_tag] updateQuestion: questionId=$questionId');

    try {
      final updates = <String, dynamic>{};
      if (questionAr != null) updates['question_ar'] = questionAr;
      if (questionEn != null) updates['question_en'] = questionEn;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (removeImage) updates['image_url'] = null;
      if (type != null) updates['question_type'] = type;
      if (points != null) updates['points'] = points;
      if (options != null) {
        // Generate UUIDs for options that don't have IDs
        const uuid = Uuid();
        final optionsWithIds = options.map((opt) {
          if (opt['id'] == null || (opt['id'] as String).isEmpty) {
            return {...opt, 'id': uuid.v4()};
          }
          return opt;
        }).toList();
        updates['options'] = optionsWithIds;
      }
      if (correctAnswer != null) updates['correct_answer'] = correctAnswer;

      if (updates.isNotEmpty) {
        await _apiClient.put('/instructor/quiz-questions/$questionId', body: updates);
      }

      AppLogger.success('[$_tag] Question updated');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateQuestion error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Delete question
  Future<bool> deleteQuestion(String questionId, String quizId) async {
    AppLogger.i('📝 [$_tag] deleteQuestion: questionId=$questionId');

    try {
      await _apiClient.delete('/instructor/quiz-questions/$questionId');

      AppLogger.success('[$_tag] Question deleted');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteQuestion error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Reorder questions
  Future<bool> reorderQuestions(String quizId, List<String> questionIds) async {
    AppLogger.i(
        '📝 [$_tag] reorderQuestions: quizId=$quizId, count=${questionIds.length}');

    try {
      await _apiClient.post('/instructor/quizzes/$quizId/reorder-questions', body: {
        'question_ids': questionIds,
      });

      AppLogger.success('[$_tag] Questions reordered');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reorderQuestions error', e, s);
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Get quiz attempts with student info and answers
  Future<List<Map<String, dynamic>>> getQuizAttempts(String quizId) async {
    AppLogger.i('📝 [$_tag] getQuizAttempts: quizId=$quizId');

    try {
      final response =
          await _apiClient.get('/instructor/quizzes/$quizId/attempts');

      final rawList = response is List
          ? response
          : (response['attempts'] ?? response['data'] ?? []) as List;

      AppLogger.d('[$_tag] Raw attempts: ${rawList.length}');

      // Get quiz questions for answer details
      final questions = await getQuizQuestions(quizId);
      final questionsMap = {for (var q in questions) q.id: q};

      // Process attempts with detailed answers
      final attempts = rawList.map((attempt) {
        final attemptMap = attempt as Map<String, dynamic>;

        // Handle user - could be Map or nested object
        final userData = attemptMap['user'];
        Map<String, dynamic>? user;
        if (userData is Map<String, dynamic>) {
          user = userData;
        } else if (userData is Map) {
          user = Map<String, dynamic>.from(userData);
        } else if (userData is List && userData.isNotEmpty) {
          final firstItem = userData.first;
          if (firstItem is Map<String, dynamic>) {
            user = firstItem;
          } else if (firstItem is Map) {
            user = Map<String, dynamic>.from(firstItem);
          }
        }

        // Calculate time taken
        final timeSpent = attemptMap['time_spent'] as int?;
        int timeTaken;
        if (timeSpent != null && timeSpent > 0) {
          timeTaken = timeSpent;
        } else {
          final startedAt = attemptMap['started_at'] != null
              ? DateTime.tryParse(attemptMap['started_at'].toString())
              : null;
          final completedAt = attemptMap['completed_at'] != null
              ? DateTime.tryParse(attemptMap['completed_at'].toString())
              : null;
          timeTaken = (startedAt != null && completedAt != null)
              ? completedAt.difference(startedAt).inSeconds.abs()
              : 0;
        }

        // Handle answers
        final answersData = attemptMap['answers'];
        final List<Map<String, dynamic>> detailedAnswers = [];

        if (answersData is Map) {
          final answersMap = Map<String, dynamic>.from(answersData);

          for (final entry in answersMap.entries) {
            final questionId = entry.key;
            final answerValue = entry.value;
            final question = questionsMap[questionId];

            List<String> selectedOptionIds = [];
            bool? storedIsCorrect;

            if (answerValue is Map) {
              final answerMap = Map<String, dynamic>.from(answerValue);
              final selectedIds = answerMap['selected_option_ids'];
              if (selectedIds is List) {
                selectedOptionIds =
                    selectedIds.map((e) => e.toString()).toList();
              }
              storedIsCorrect = answerMap['is_correct'] as bool?;
            } else if (answerValue is List) {
              selectedOptionIds = answerValue.map((e) => e.toString()).toList();
            }

            if (question == null) {
              detailedAnswers.add({
                'question_id': questionId,
                'question_text_ar': 'سؤال محذوف',
                'question_text_en': 'Deleted question',
                'options': <Map<String, dynamic>>[],
                'selected_option_id': selectedOptionIds.isNotEmpty
                    ? selectedOptionIds.first
                    : null,
                'selected_option_ids': selectedOptionIds,
                'correct_option_id': '',
                'is_correct': storedIsCorrect ?? false,
                'explanation': null,
              });
              continue;
            }

            final opts = question.options;
            final correctOptionIds = <String>[];
            for (final opt in opts) {
              if (opt.isCorrect) {
                correctOptionIds.add(opt.id);
              }
            }

            bool isCorrect;
            if (storedIsCorrect != null) {
              isCorrect = storedIsCorrect;
            } else {
              final selectedSet = selectedOptionIds.toSet();
              final correctSet = correctOptionIds.toSet();
              isCorrect = selectedSet.isNotEmpty &&
                  selectedSet.length == correctSet.length &&
                  selectedSet.containsAll(correctSet);
            }

            detailedAnswers.add({
              'question_id': questionId,
              'question_text_ar': question.questionAr,
              'question_text_en': question.questionEn,
              'image_url': question.imageUrl,
              'options': opts
                  .map((o) => {
                        'id': o.id,
                        'text_ar': o.textAr,
                        'text_en': o.textEn,
                        'is_correct': o.isCorrect,
                      })
                  .toList(),
              'selected_option_id':
                  selectedOptionIds.isNotEmpty ? selectedOptionIds.first : null,
              'selected_option_ids': selectedOptionIds,
              'correct_option_id':
                  correctOptionIds.isNotEmpty ? correctOptionIds.first : '',
              'correct_option_ids': correctOptionIds,
              'is_correct': isCorrect,
              'explanation': null,
            });
          }
        } else if (answersData is List) {
          for (final ans in answersData) {
            if (ans is! Map) continue;
            final ansMap = Map<String, dynamic>.from(ans);
            final questionId = ansMap['question_id'] as String?;
            final question =
                questionId != null ? questionsMap[questionId] : null;

            if (question == null) {
              detailedAnswers.add({
                'question_id': questionId,
                'question_text_ar': 'سؤال محذوف',
                'question_text_en': 'Deleted question',
                'options': <Map<String, dynamic>>[],
                'selected_option_id': ansMap['selected_option_id'],
                'correct_option_id': '',
                'is_correct': ansMap['is_correct'] ?? false,
                'explanation': null,
              });
              continue;
            }

            final opts = question.options;
            String? correctOptionId;
            for (final opt in opts) {
              if (opt.isCorrect) {
                correctOptionId = opt.id;
                break;
              }
            }

            detailedAnswers.add({
              'question_id': questionId,
              'question_text_ar': question.questionAr,
              'question_text_en': question.questionEn,
              'options': opts
                  .map((o) => {
                        'id': o.id,
                        'text_ar': o.textAr,
                        'text_en': o.textEn,
                        'is_correct': o.isCorrect,
                      })
                  .toList(),
              'selected_option_id': ansMap['selected_option_id'],
              'correct_option_id': correctOptionId ?? '',
              'is_correct': ansMap['is_correct'] ?? false,
              'explanation': null,
            });
          }
        }

        return {
          'id': attemptMap['id'],
          'student_name': user?['name'] ?? 'Unknown',
          'student_email': user?['email'],
          'student_phone': user?['phone'],
          'avatar_url': user?['avatar_url'],
          'score': attemptMap['percentage'] ?? 0,
          'passed': attemptMap['passed'] ?? false,
          'started_at': attemptMap['started_at'],
          'completed_at': attemptMap['completed_at'],
          'time_taken': timeTaken,
          'answers': detailedAnswers,
        };
      }).toList();

      AppLogger.success('[$_tag] Processed ${attempts.length} attempts');
      return attempts;
    } catch (e, s) {
      AppLogger.e('[$_tag] getQuizAttempts error', e, s);
      return [];
    }
  }
}
