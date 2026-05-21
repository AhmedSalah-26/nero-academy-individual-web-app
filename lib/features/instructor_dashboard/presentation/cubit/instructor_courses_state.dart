part of 'instructor_courses_cubit.dart';

enum InstructorCoursesStatus { initial, loading, loadingMore, success, error }

class InstructorCoursesState extends Equatable {
  final InstructorCoursesStatus status;
  final InstructorCoursesStatus actionStatus;
  final List<InstructorCourseModel> courses;
  final InstructorCourseStatus currentStatus;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const InstructorCoursesState({
    this.status = InstructorCoursesStatus.initial,
    this.actionStatus = InstructorCoursesStatus.initial,
    this.courses = const [],
    this.currentStatus = InstructorCourseStatus.all,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == InstructorCoursesStatus.loading;
  bool get isLoadingMore => status == InstructorCoursesStatus.loadingMore;
  bool get hasError => status == InstructorCoursesStatus.error;

  InstructorCoursesState copyWith({
    InstructorCoursesStatus? status,
    InstructorCoursesStatus? actionStatus,
    List<InstructorCourseModel>? courses,
    InstructorCourseStatus? currentStatus,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InstructorCoursesState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      courses: courses ?? this.courses,
      currentStatus: currentStatus ?? this.currentStatus,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        courses,
        currentStatus,
        currentPage,
        hasMore,
        errorMessage
      ];
}
