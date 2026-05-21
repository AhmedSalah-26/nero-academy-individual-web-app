part of 'instructor_announcements_cubit.dart';

enum InstructorAnnouncementsStatus {
  initial,
  loading,
  success,
  error,
  loadingMore
}

class InstructorAnnouncementsState extends Equatable {
  final InstructorAnnouncementsStatus status;
  final List<Map<String, dynamic>> announcements;
  final List<Map<String, dynamic>> courses;
  final String? selectedCourseId;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;
  final InstructorAnnouncementsStatus actionStatus;

  const InstructorAnnouncementsState({
    this.status = InstructorAnnouncementsStatus.initial,
    this.announcements = const [],
    this.courses = const [],
    this.selectedCourseId,
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = true,
    this.actionStatus = InstructorAnnouncementsStatus.initial,
  });

  InstructorAnnouncementsState copyWith({
    InstructorAnnouncementsStatus? status,
    List<Map<String, dynamic>>? announcements,
    List<Map<String, dynamic>>? courses,
    String? selectedCourseId,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    InstructorAnnouncementsStatus? actionStatus,
  }) {
    return InstructorAnnouncementsState(
      status: status ?? this.status,
      announcements: announcements ?? this.announcements,
      courses: courses ?? this.courses,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      actionStatus: actionStatus ?? this.actionStatus,
    );
  }

  @override
  List<Object?> get props => [
        status,
        announcements,
        courses,
        selectedCourseId,
        errorMessage,
        currentPage,
        hasMore,
        actionStatus,
      ];
}
