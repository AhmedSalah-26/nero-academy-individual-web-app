import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/repositories/instructor_repository.dart';

/// Instructor Course Editor Data Source - Course editor methods
class InstructorCourseEditorDataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorCourseEditorDS';

  InstructorCourseEditorDataSource(this._apiClient);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      final items = response['items'];
      if (items is List) return items;
    }
    return const [];
  }

  /// Get categories for course editor
  Future<List<CategoryOption>> getCategories() async {
    AppLogger.d('[$_tag] getCategories');
    try {
      final response = await _apiClient.get('/instructor/categories');
      final list = _asList(response);
      AppLogger.success('[$_tag] getCategories: ${list.length} categories');
      return list.map((c) {
        return CategoryOption(
          id: c['id'] as String,
          nameAr: c['name_ar'] as String? ?? '',
          nameEn: c['name_en'] as String? ?? '',
        );
      }).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCategories error', e, s);
      rethrow;
    }
  }

  /// Get course details for editing
  Future<CourseDetails?> getCourseForEdit(String courseId) async {
    AppLogger.d('[$_tag] getCourseForEdit: $courseId');
    try {
      final response = _asMap(await _apiClient.get('/instructor/courses/$courseId/edit'));
      final courseData = (response['course'] as Map<String, dynamic>?) ?? response;
      
      final sections = (courseData['sections'] as List? ?? []).map((s) {
        final lessons = (s['lessons'] as List? ?? []).map((l) {
          return LessonDto(
            id: l['id'] as String?,
            titleAr: l['title_ar'] as String? ?? '',
            titleEn: l['title_en'] as String? ?? '',
            type: l['type'] as String? ?? 'video',
            order: l['sort_order'] as int? ?? 0,
            durationMinutes: ((l['video_duration'] as int? ?? 0) / 60).round(),
            isFree: l['is_preview'] as bool? ?? false,
            isPublished: l['is_published'] as bool? ?? true,
            videoUrl: l['video_url'] as String?,
            articleContent: l['article_content_ar'] as String?,
            fileUrl: l['file_url'] as String?,
            fileName: l['file_name'] as String?,
            fileSize: l['file_size'] as int?,
            fileType: l['file_type'] as String?,
          );
        }).toList();

        return SectionDto(
          id: s['id'] as String?,
          titleAr: s['title_ar'] as String? ?? '',
          titleEn: s['title_en'] as String? ?? '',
          order: s['sort_order'] as int? ?? 0,
          isPublished: s['is_published'] as bool? ?? true,
          lessons: lessons,
        );
      }).toList();

      AppLogger.success('[$_tag] getCourseForEdit: ${sections.length} sections');
      return CourseDetails(
        id: courseData['id'] as String,
        titleAr: courseData['title_ar'] as String? ?? '',
        titleEn: courseData['title_en'] as String? ?? '',
        subtitleAr: courseData['subtitle_ar'] as String?,
        subtitleEn: courseData['subtitle_en'] as String?,
        descriptionAr: courseData['description_ar'] as String?,
        descriptionEn: courseData['description_en'] as String?,
        thumbnailUrl: courseData['thumbnail_url'] as String?,
        previewVideoUrl: courseData['preview_video_url'] as String?,
        categoryId: courseData['category_id'] as String?,
        level: courseData['level'] as String? ?? 'beginner',
        price: (courseData['price'] as num?)?.toDouble() ?? 0,
        discountPrice: (courseData['discount_price'] as num?)?.toDouble(),
        currency: courseData['currency'] as String? ?? 'EGP',
        isPublished: courseData['is_published'] as bool? ?? false,
        badge: courseData['badge'] as String?,
        isFlashSale: courseData['is_flash_sale'] as bool? ?? false,
        flashSaleStart: courseData['flash_sale_start'] != null
            ? DateTime.parse(courseData['flash_sale_start'] as String)
            : null,
        flashSaleEnd: courseData['flash_sale_end'] != null
            ? DateTime.parse(courseData['flash_sale_end'] as String)
            : null,
        sections: sections,
      );
    } catch (e, s) {
      AppLogger.e('[$_tag] getCourseForEdit error', e, s);
      rethrow;
    }
  }

  /// Create new course
  Future<String> createCourse(CourseCreateDto dto) async {
    AppLogger.d('[$_tag] createCourse: ${dto.titleAr}');
    try {
      final response = _asMap(await _apiClient.post('/courses', body: dto.toJson()));
      final course = (response['course'] as Map<String, dynamic>?) ?? response;
      AppLogger.success('[$_tag] createCourse success: ${course['id']}');
      return course['id'] as String;
    } catch (e, s) {
      AppLogger.e('[$_tag] createCourse error', e, s);
      rethrow;
    }
  }

  /// Update course
  Future<bool> updateCourse(String courseId, CourseUpdateDto dto) async {
    AppLogger.d('[$_tag] updateCourse: $courseId');
    try {
      await _apiClient.put('/instructor/courses/$courseId', body: dto.toJson());
      AppLogger.success('[$_tag] updateCourse success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateCourse error', e, s);
      rethrow;
    }
  }

  /// Save sections and lessons using Bulk Upsert
  Future<bool> saveSectionsAndLessons(
      String courseId, List<SectionDto> sections) async {
    AppLogger.d('[$_tag] saveSectionsAndLessons: courseId=$courseId');
    try {
      await _apiClient.post(
        '/instructor/courses/$courseId/structure',
        body: {'sections': sections.map((s) => s.toJson()).toList()},
      );
      AppLogger.success('[$_tag] saveSectionsAndLessons success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] saveSectionsAndLessons error', e, s);
      rethrow;
    }
  }

  /// Create a single section
  Future<String> createSection(String courseId, SectionCreateDto dto) async {
    AppLogger.d('[$_tag] createSection: courseId=$courseId');
    try {
      final response = await _apiClient.post(
        '/courses/$courseId/sections',
        body: dto.toJson(),
      );
      final section = response['section'] as Map<String, dynamic>;
      AppLogger.success('[$_tag] createSection success: ${section['id']}');
      return section['id'] as String;
    } catch (e, s) {
      AppLogger.e('[$_tag] createSection error', e, s);
      rethrow;
    }
  }

  /// Update a single section
  Future<bool> updateSection(String sectionId, SectionUpdateDto dto) async {
    AppLogger.d('[$_tag] updateSection: sectionId=$sectionId');
    try {
      await _apiClient.put(
        '/instructor/sections/$sectionId',
        body: dto.toJson(),
      );
      AppLogger.success('[$_tag] updateSection success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateSection error', e, s);
      rethrow;
    }
  }

  /// Delete a single section
  Future<bool> deleteSection(String sectionId) async {
    AppLogger.d('[$_tag] deleteSection: sectionId=$sectionId');
    try {
      await _apiClient.delete('/instructor/sections/$sectionId');
      AppLogger.success('[$_tag] deleteSection success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteSection error', e, s);
      rethrow;
    }
  }

  /// Reorder sections
  Future<bool> reorderSections(String courseId, List<String> sectionIds) async {
    AppLogger.d('[$_tag] reorderSections: courseId=$courseId');
    try {
      await _apiClient.post(
        '/instructor/courses/$courseId/sections/reorder',
        body: {'section_ids': sectionIds},
      );
      AppLogger.success('[$_tag] reorderSections success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reorderSections error', e, s);
      rethrow;
    }
  }

  /// Create a single lesson
  Future<String> createLesson(
      String sectionId, String courseId, LessonCreateDto dto) async {
    AppLogger.d('[$_tag] createLesson: sectionId=$sectionId');
    try {
      final response = await _apiClient.post(
        '/sections/$sectionId/lessons',
        body: dto.toJson(),
      );
      final lesson = response['lesson'] as Map<String, dynamic>;
      AppLogger.success('[$_tag] createLesson success: ${lesson['id']}');
      return lesson['id'] as String;
    } catch (e, s) {
      AppLogger.e('[$_tag] createLesson error', e, s);
      rethrow;
    }
  }

  /// Update a single lesson
  Future<bool> updateLesson(String lessonId, LessonUpdateDto dto) async {
    AppLogger.d('[$_tag] updateLesson: lessonId=$lessonId');
    try {
      await _apiClient.put(
        '/instructor/lessons/$lessonId',
        body: dto.toJson(),
      );
      AppLogger.success('[$_tag] updateLesson success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateLesson error', e, s);
      rethrow;
    }
  }

  /// Delete a single lesson
  Future<bool> deleteLesson(String lessonId) async {
    AppLogger.d('[$_tag] deleteLesson: lessonId=$lessonId');
    try {
      await _apiClient.delete('/instructor/lessons/$lessonId');
      AppLogger.success('[$_tag] deleteLesson success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteLesson error', e, s);
      rethrow;
    }
  }

  /// Reorder lessons within a section
  Future<bool> reorderLessons(String sectionId, List<String> lessonIds) async {
    AppLogger.d('[$_tag] reorderLessons: sectionId=$sectionId');
    try {
      await _apiClient.post(
        '/instructor/sections/$sectionId/lessons/reorder',
        body: {'lesson_ids': lessonIds},
      );
      AppLogger.success('[$_tag] reorderLessons success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] reorderLessons error', e, s);
      rethrow;
    }
  }

  /// Add course attachment
  Future<String> addCourseAttachment({
    required String courseId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int fileSize,
    required int sortOrder,
  }) async {
    AppLogger.d('[$_tag] addCourseAttachment: courseId=$courseId, fileName=$fileName');
    try {
      final response = await _apiClient.post(
        '/instructor/courses/$courseId/attachments',
        body: {
          'file_name': fileName,
          'file_url': fileUrl,
          'file_type': fileType,
          'file_size': fileSize,
          'sort_order': sortOrder,
        },
      );
      AppLogger.success('[$_tag] addCourseAttachment success');
      return response['id'] as String;
    } catch (e, s) {
      AppLogger.e('[$_tag] addCourseAttachment error', e, s);
      rethrow;
    }
  }

  /// Delete all course attachments
  Future<bool> deleteAllCourseAttachments(String courseId) async {
    AppLogger.d('[$_tag] deleteAllCourseAttachments: courseId=$courseId');
    try {
      await _apiClient.delete('/instructor/courses/$courseId/attachments');
      AppLogger.success('[$_tag] deleteAllCourseAttachments success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAllCourseAttachments error', e, s);
      rethrow;
    }
  }

  /// Get all course attachments
  Future<List<AttachmentDto>> getCourseAttachments(String courseId) async {
    AppLogger.d('[$_tag] getCourseAttachments: courseId=$courseId');
    try {
      final response = await _apiClient.get('/instructor/courses/$courseId/attachments');
      final list = _asList(response);
      AppLogger.success('[$_tag] getCourseAttachments: ${list.length} attachments');
      return list.map((a) {
        return AttachmentDto(
          id: a['id'] as String?,
          fileName: a['file_name'] as String? ?? '',
          fileUrl: a['file_url'] as String? ?? '',
          fileType: a['file_type'] as String? ?? '',
          fileSize: a['file_size'] as int? ?? 0,
          sortOrder: a['sort_order'] as int? ?? 0,
        );
      }).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getCourseAttachments error', e, s);
      rethrow;
    }
  }

  /// Toggle section published status
  Future<bool> toggleSectionPublished(String sectionId) async {
    AppLogger.d('[$_tag] toggleSectionPublished: sectionId=$sectionId');
    try {
      final response = await _apiClient.post('/instructor/sections/$sectionId/toggle-published');
      return response['is_published'] as bool? ?? false;
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleSectionPublished error', e, s);
      rethrow;
    }
  }

  /// Schedule section publishing
  Future<void> scheduleSectionPublish(
    String sectionId, {
    DateTime? publishAt,
    DateTime? unpublishAt,
  }) async {
    AppLogger.d('[$_tag] scheduleSectionPublish: sectionId=$sectionId');
    try {
      await _apiClient.post(
        '/instructor/sections/$sectionId/schedule-publish',
        body: {
          'p_publish_at': publishAt?.toIso8601String(),
          'p_unpublish_at': unpublishAt?.toIso8601String(),
        },
      );
      AppLogger.success('[$_tag] scheduleSectionPublish success');
    } catch (e, s) {
      AppLogger.e('[$_tag] scheduleSectionPublish error', e, s);
      rethrow;
    }
  }

  /// Toggle lesson published status
  Future<bool> toggleLessonPublished(String lessonId) async {
    AppLogger.d('[$_tag] toggleLessonPublished: lessonId=$lessonId');
    try {
      final response = await _apiClient.post('/instructor/lessons/$lessonId/toggle-published');
      return response['is_published'] as bool? ?? false;
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleLessonPublished error', e, s);
      rethrow;
    }
  }

  /// Schedule lesson publishing
  Future<void> scheduleLessonPublish(
    String lessonId, {
    DateTime? publishAt,
    DateTime? unpublishAt,
  }) async {
    AppLogger.d('[$_tag] scheduleLessonPublish: lessonId=$lessonId');
    try {
      await _apiClient.post(
        '/instructor/lessons/$lessonId/schedule-publish',
        body: {
          'p_publish_at': publishAt?.toIso8601String(),
          'p_unpublish_at': unpublishAt?.toIso8601String(),
        },
      );
      AppLogger.success('[$_tag] scheduleLessonPublish success');
    } catch (e, s) {
      AppLogger.e('[$_tag] scheduleLessonPublish error', e, s);
      rethrow;
    }
  }
}
