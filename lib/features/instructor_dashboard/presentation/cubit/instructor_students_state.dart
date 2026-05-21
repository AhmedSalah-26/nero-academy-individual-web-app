part of 'instructor_students_cubit.dart';

enum InstructorStudentsStatus { initial, loading, loadingMore, success, error }

class InstructorStudentsState extends Equatable {
  final InstructorStudentsStatus status;
  final List<InstructorStudentModel> students;
  final String? currentCourseId;
  final String? searchQuery;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const InstructorStudentsState({
    this.status = InstructorStudentsStatus.initial,
    this.students = const [],
    this.currentCourseId,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == InstructorStudentsStatus.loading;
  bool get isLoadingMore => status == InstructorStudentsStatus.loadingMore;
  bool get hasError => status == InstructorStudentsStatus.error;

  InstructorStudentsState copyWith({
    InstructorStudentsStatus? status,
    List<InstructorStudentModel>? students,
    String? currentCourseId,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InstructorStudentsState(
      status: status ?? this.status,
      students: students ?? this.students,
      currentCourseId: currentCourseId ?? this.currentCourseId,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        students,
        currentCourseId,
        searchQuery,
        currentPage,
        hasMore,
        errorMessage
      ];
}
