import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/models/forum_models.dart';
import '../../domain/entities/forum_entities.dart';
import 'forums_list_state.dart';

/// Forums List Cubit - loads conversations for the current user
class ForumsListCubit extends Cubit<ForumsListState> {
  final ApiClient _apiClient;
  static const _tag = 'ForumsListCubit';

  ForumsListCubit(this._apiClient) : super(const ForumsListState());

  /// Load conversations list
  Future<void> loadConversations({
    String? search,
    String? typeFilter,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: ForumsListStatus.loading,
        conversations: [],
        hasMore: false,
        searchQuery: search,
        typeFilter: typeFilter,
        clearTypeFilter: typeFilter == null,
      ));
    } else {
      emit(state.copyWith(status: ForumsListStatus.loading));
    }

    try {
      // Check profile from API token/auth
      final isInstructor = await _isInstructorUser();
      final instructorCourses = isInstructor
          ? await _fetchInstructorForumCourses()
          : const <InstructorForumCourse>[];

      final conversations = await _fetchConversations(
        typeFilter: typeFilter,
        search: search,
      );

      emit(state.copyWith(
        status: ForumsListStatus.success,
        conversations: conversations,
        isInstructor: isInstructor,
        instructorCourses: instructorCourses,
        hasMore: false,
        clearTogglingCourseId: true,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadConversations error', e, s);
      emit(state.copyWith(
        status: ForumsListStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Set type filter and reload
  void setTypeFilter(String? typeFilter) {
    loadConversations(
      search: state.searchQuery,
      typeFilter: typeFilter,
      refresh: true,
    );
  }

  Future<void> toggleCourseGroup({
    required String courseId,
    required bool enabled,
  }) async {
    emit(state.copyWith(togglingCourseId: courseId));

    try {
      if (enabled) {
        // Create course conversation via API
        await _apiClient.post('/chat/conversations', body: {
          'type': 'course_forum',
          'course_id': courseId,
          'participant_ids': [],
        });
      } else {
        // We'd need a dedicated endpoint; for now skip silently
        AppLogger.w('[$_tag] toggleCourseGroup: Disable not yet supported via REST');
      }
    } catch (e, s) {
      AppLogger.e('[$_tag] toggleCourseGroup error', e, s);
    }

    await loadConversations(
      search: state.searchQuery,
      typeFilter: state.typeFilter,
      refresh: true,
    );
  }

  /// Fetch conversations using REST API
  Future<List<Conversation>> _fetchConversations({
    String? typeFilter,
    String? search,
  }) async {
    AppLogger.d('[$_tag] _fetchConversations: type=$typeFilter, search=$search');

    final url = typeFilter != null
        ? '/chat/conversations?type=$typeFilter'
        : '/chat/conversations';

    final response = await _apiClient.get(url);
    final conversationsRaw = response['conversations'] as List? ?? [];

    var results = conversationsRaw.map((r) {
      return ConversationModel.fromJson(r as Map<String, dynamic>);
    }).toList();

    // Client-side search filtering
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      results = results.where((c) {
        final title = c.displayTitle.toLowerCase();
        return title.contains(searchLower);
      }).toList();
    }

    AppLogger.success(
        '[$_tag] _fetchConversations: ${results.length} conversations');
    return results;
  }

  Future<bool> _isInstructorUser() async {
    try {
      final response = await _apiClient.get('/auth/profile');
      final role = response['role'] as String?;
      return role == 'instructor' || role == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<List<InstructorForumCourse>> _fetchInstructorForumCourses() async {
    try {
      final response = await _apiClient.get('/instructor/courses');
      final coursesRaw = response is List
          ? response
          : (response['courses'] ?? response['data'] ?? []) as List;

      if (coursesRaw.isEmpty) return const [];

      // Get conversations to determine which courses have groups
      final convResponse = await _apiClient.get('/chat/conversations?type=course_forum');
      final convRaw = convResponse['conversations'] as List? ?? [];
      final groupedCourseIds = convRaw
          .map((c) => c['course_id'] as String?)
          .where((id) => id != null)
          .map((id) => id!)
          .toSet();

      return coursesRaw.map((c) {
        final courseId = c['id'] as String;
        return InstructorForumCourse(
          id: courseId,
          titleAr: c['title_ar'] as String? ?? '',
          titleEn: c['title_en'] as String? ?? '',
          hasGroup: groupedCourseIds.contains(courseId),
        );
      }).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] fetchInstructorForumCourses error', e, s);
      return const [];
    }
  }
}
