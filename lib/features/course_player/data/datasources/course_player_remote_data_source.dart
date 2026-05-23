import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../models/section_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_progress_model.dart';
import '../models/note_model.dart';
import '../models/bookmark_model.dart';
import '../models/attachment_model.dart';
import '../models/qa_question_model.dart';

/// Course Player Remote Data Source
abstract class CoursePlayerRemoteDataSource {
  Future<List<SectionModel>> getCourseContent({
    required String courseId,
    required String enrollmentId,
  });

  Future<LessonModel> getLesson({required String lessonId});

  Future<List<AttachmentModel>> getLessonAttachments({required String lessonId});

  Future<LessonProgressModel?> getLessonProgress({
    required String lessonId,
    required String enrollmentId,
  });

  Future<List<LessonProgressModel>> getAllLessonProgress({
    required String enrollmentId,
  });

  Future<LessonProgressModel> updateLessonProgress({
    required String lessonId,
    required String enrollmentId,
    required int watchedSeconds,
    required int lastPosition,
  });

  Future<LessonProgressModel> markLessonComplete({
    required String lessonId,
    required String enrollmentId,
  });

  Future<List<NoteModel>> getNotes({
    required String lessonId,
    required String userId,
  });

  Future<List<NoteModel>> getNotesByEnrollment({
    required String lessonId,
    required String enrollmentId,
  });

  Future<NoteModel> addNote({
    required String lessonId,
    required String userId,
    required String content,
    required int timestampSeconds,
  });

  Future<NoteModel> addNoteByEnrollment({
    required String lessonId,
    required String enrollmentId,
    required String content,
    required int timestampSeconds,
  });

  Future<NoteModel> updateNote({
    required String noteId,
    required String content,
  });

  Future<void> deleteNote({required String noteId});

  Future<List<BookmarkModel>> getBookmarks({required String enrollmentId});

  Future<BookmarkModel> addBookmark({
    required String lessonId,
    required String enrollmentId,
    String? note,
  });

  Future<void> deleteBookmark({required String bookmarkId});

  Future<bool> isLessonBookmarked({
    required String lessonId,
    required String enrollmentId,
  });

  // Q&A Methods
  Future<List<QAQuestionModel>> getQuestions({
    required String courseId,
    String? lessonId,
  });

  Future<QAQuestionModel> addQuestion({
    required String courseId,
    required String enrollmentId,
    String? lessonId,
    required String title,
    required String content,
  });

  Future<bool> toggleAnswerUpvote({required String answerId});

  Future<bool> hasUpvotedAnswer({required String answerId});

  // Course Attachments Methods
  Future<List<AttachmentModel>> getCourseAttachments({
    required String courseId,
  });
}

/// Implementation of CoursePlayerRemoteDataSource using REST Client (Laravel)
class CoursePlayerRemoteDataSourceImpl implements CoursePlayerRemoteDataSource {
  final ApiClient _apiClient;
  static const _tag = 'CoursePlayerRemoteDS';

  CoursePlayerRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<SectionModel>> getCourseContent({
    required String courseId,
    required String enrollmentId,
  }) async {
    AppLogger.d('[$_tag] getCourseContent: courseId=$courseId');
    try {
      final response = await _apiClient.get('/courses/$courseId');
      final sectionsRaw = response['sections'] as List? ?? [];
      return sectionsRaw
          .map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCourseContent error', e, s);
      rethrow;
    }
  }

  @override
  Future<LessonModel> getLesson({required String lessonId}) async {
    AppLogger.d('[$_tag] getLesson: lessonId=$lessonId');
    try {
      final response = await _apiClient.get('/lessons/$lessonId');
      return LessonModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] getLesson error', e, s);
      rethrow;
    }
  }

  @override
  Future<List<AttachmentModel>> getLessonAttachments({
    required String lessonId,
  }) async {
    AppLogger.d('[$_tag] getLessonAttachments: lessonId=$lessonId');
    try {
      final response = await _apiClient.get('/lessons/$lessonId/attachments');
      final attachmentsRaw = response['data'] as List? ?? [];
      return attachmentsRaw
          .map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getLessonAttachments error', e, s);
      rethrow;
    }
  }

  @override
  Future<List<AttachmentModel>> getCourseAttachments({
    required String courseId,
  }) async {
    AppLogger.d('[$_tag] getCourseAttachments: courseId=$courseId');
    try {
      final response = await _apiClient.get('/courses/$courseId/attachments');
      final attachmentsRaw = response['data'] as List? ?? [];
      return attachmentsRaw
          .map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCourseAttachments error', e, s);
      rethrow;
    }
  }

  @override
  Future<LessonProgressModel?> getLessonProgress({
    required String lessonId,
    required String enrollmentId,
  }) async {
    AppLogger.d('[$_tag] getLessonProgress: lessonId=$lessonId, enrollmentId=$enrollmentId');
    try {
      final response = await _apiClient.get(
        '/enrollments/progress?enrollment_id=$enrollmentId&lesson_id=$lessonId',
      );
      if (response['data'] == null) return null;
      return LessonProgressModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] getLessonProgress error', e, s);
      rethrow;
    }
  }

  @override
  Future<List<LessonProgressModel>> getAllLessonProgress({
    required String enrollmentId,
  }) async {
    AppLogger.d('[$_tag] getAllLessonProgress: enrollmentId=$enrollmentId');
    try {
      final response = await _apiClient.get('/enrollments/$enrollmentId/progress');
      final progressRaw = response['data'] as List? ?? [];
      return progressRaw
          .map((e) => LessonProgressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getAllLessonProgress error', e, s);
      rethrow;
    }
  }

  @override
  Future<LessonProgressModel> updateLessonProgress({
    required String lessonId,
    required String enrollmentId,
    required int watchedSeconds,
    required int lastPosition,
  }) async {
    AppLogger.d('[$_tag] updateLessonProgress: lessonId=$lessonId, watchedSeconds=$watchedSeconds, lastPosition=$lastPosition');
    try {
      final response = await _apiClient.post('/enrollments/progress', body: {
        'lesson_id': lessonId,
        'watch_time': watchedSeconds,
        'last_position': lastPosition,
        'is_completed': false,
      });
      return LessonProgressModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] updateLessonProgress error', e, s);
      rethrow;
    }
  }

  @override
  Future<LessonProgressModel> markLessonComplete({
    required String lessonId,
    required String enrollmentId,
  }) async {
    AppLogger.d('[$_tag] markLessonComplete: lessonId=$lessonId');
    try {
      final response = await _apiClient.post('/enrollments/progress', body: {
        'lesson_id': lessonId,
        'is_completed': true,
      });
      return LessonProgressModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] markLessonComplete error', e, s);
      rethrow;
    }
  }

  @override
  Future<List<NoteModel>> getNotes({
    required String lessonId,
    required String userId,
  }) async {
    AppLogger.d('[$_tag] getNotes: lessonId=$lessonId');
    try {
      final response = await _apiClient.get('/lessons/$lessonId/notes');
      final notesRaw = response['data'] as List? ?? [];
      return notesRaw
          .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getNotes error', e, s);
      rethrow;
    }
  }

  @override
  Future<List<NoteModel>> getNotesByEnrollment({
    required String lessonId,
    required String enrollmentId,
  }) async {
    AppLogger.d('[$_tag] getNotesByEnrollment: lessonId=$lessonId, enrollmentId=$enrollmentId');
    try {
      final response = await _apiClient.get('/enrollments/$enrollmentId/lessons/$lessonId/notes');
      final notesRaw = response['data'] as List? ?? [];
      return notesRaw
          .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getNotesByEnrollment error', e, s);
      rethrow;
    }
  }

  @override
  Future<NoteModel> addNote({
    required String lessonId,
    required String userId,
    required String content,
    required int timestampSeconds,
  }) async {
    AppLogger.d('[$_tag] addNote: lessonId=$lessonId');
    try {
      final response = await _apiClient.post('/notes', body: {
        'lesson_id': lessonId,
        'content': content,
        'timestamp_seconds': timestampSeconds,
      });
      return NoteModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] addNote error', e, s);
      rethrow;
    }
  }

  @override
  Future<NoteModel> addNoteByEnrollment({
    required String lessonId,
    required String enrollmentId,
    required String content,
    required int timestampSeconds,
  }) async {
    AppLogger.d('[$_tag] addNoteByEnrollment: lessonId=$lessonId');
    try {
      final response = await _apiClient.post('/notes', body: {
        'lesson_id': lessonId,
        'content': content,
        'timestamp_seconds': timestampSeconds,
      });
      return NoteModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] addNoteByEnrollment error', e, s);
      rethrow;
    }
  }

  @override
  Future<NoteModel> updateNote({
    required String noteId,
    required String content,
  }) async {
    AppLogger.d('[$_tag] updateNote: noteId=$noteId');
    try {
      final response = await _apiClient.put('/notes/$noteId', body: {
        'content': content,
      });
      return NoteModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] updateNote error', e, s);
      rethrow;
    }
  }

  @override
  Future<void> deleteNote({required String noteId}) async {
    AppLogger.d('[$_tag] deleteNote: noteId=$noteId');
    try {
      await _apiClient.delete('/notes/$noteId');
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteNote error', e, s);
      rethrow;
    }
  }

  @override
  Future<List<BookmarkModel>> getBookmarks({
    required String enrollmentId,
  }) async {
    AppLogger.d('[$_tag] getBookmarks: enrollmentId=$enrollmentId');
    try {
      final response = await _apiClient.get('/enrollments/$enrollmentId/bookmarks');
      final bookmarksRaw = response['data'] as List? ?? [];
      return bookmarksRaw
          .map((e) => BookmarkModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getBookmarks error', e, s);
      rethrow;
    }
  }

  @override
  Future<BookmarkModel> addBookmark({
    required String lessonId,
    required String enrollmentId,
    String? note,
  }) async {
    AppLogger.d('[$_tag] addBookmark: lessonId=$lessonId');
    try {
      final response = await _apiClient.post('/bookmarks', body: {
        'lesson_id': lessonId,
        'enrollment_id': enrollmentId,
        'note': note,
      });
      return BookmarkModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] addBookmark error', e, s);
      rethrow;
    }
  }

  @override
  Future<void> deleteBookmark({required String bookmarkId}) async {
    AppLogger.d('[$_tag] deleteBookmark: bookmarkId=$bookmarkId');
    try {
      await _apiClient.delete('/bookmarks/$bookmarkId');
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteBookmark error', e, s);
      rethrow;
    }
  }

  @override
  Future<bool> isLessonBookmarked({
    required String lessonId,
    required String enrollmentId,
  }) async {
    AppLogger.d('[$_tag] isLessonBookmarked: lessonId=$lessonId');
    try {
      final response = await _apiClient.get(
        '/bookmarks/status?lesson_id=$lessonId&enrollment_id=$enrollmentId',
      );
      return response['bookmarked'] as bool? ?? false;
    } catch (e, s) {
      AppLogger.e('[$_tag] isLessonBookmarked error', e, s);
      return false;
    }
  }

  @override
  Future<List<QAQuestionModel>> getQuestions({
    required String courseId,
    String? lessonId,
  }) async {
    AppLogger.d('[$_tag] getQuestions: courseId=$courseId');
    try {
      final url = lessonId != null
          ? '/courses/$courseId/questions?lesson_id=$lessonId'
          : '/courses/$courseId/questions';
      final response = await _apiClient.get(url);
      final List questionsRaw = response['data'] as List? ?? [];
      return questionsRaw
          .map((e) => QAQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getQuestions error', e, s);
      rethrow;
    }
  }

  @override
  Future<QAQuestionModel> addQuestion({
    required String courseId,
    required String enrollmentId,
    String? lessonId,
    required String title,
    required String content,
  }) async {
    AppLogger.d('[$_tag] addQuestion: courseId=$courseId');
    try {
      final response = await _apiClient.post('/courses/$courseId/questions', body: {
        'lesson_id': lessonId,
        'title': title,
        'content': content,
      });
      return QAQuestionModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.e('[$_tag] addQuestion error', e, s);
      rethrow;
    }
  }

  @override
  Future<bool> toggleAnswerUpvote({required String answerId}) async {
    AppLogger.d('[$_tag] toggleAnswerUpvote: answerId=$answerId');
    try {
      final response = await _apiClient.post('/answers/$answerId/upvote', body: {});
      return response['has_upvoted'] as bool? ?? false;
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleAnswerUpvote error', e, s);
      rethrow;
    }
  }

  @override
  Future<bool> hasUpvotedAnswer({required String answerId}) async {
    AppLogger.d('[$_tag] hasUpvotedAnswer: answerId=$answerId');
    try {
      final response = await _apiClient.get('/answers/$answerId/upvote');
      return response['upvoted'] as bool? ?? false;
    } catch (e, s) {
      AppLogger.e('[$_tag] hasUpvotedAnswer error', e, s);
      return false;
    }
  }
}
