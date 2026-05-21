part of 'instructor_qa_cubit.dart';

enum InstructorQAStatus { initial, loading, loadingMore, success, error }

class InstructorQAState extends Equatable {
  final InstructorQAStatus status;
  final InstructorQAStatus actionStatus;
  final List<InstructorQuestionModel> questions;
  final QAStatus currentStatus;
  final String? currentCourseId;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const InstructorQAState({
    this.status = InstructorQAStatus.initial,
    this.actionStatus = InstructorQAStatus.initial,
    this.questions = const [],
    this.currentStatus = QAStatus.all,
    this.currentCourseId,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == InstructorQAStatus.loading;
  bool get isLoadingMore => status == InstructorQAStatus.loadingMore;
  bool get hasError => status == InstructorQAStatus.error;

  InstructorQAState copyWith({
    InstructorQAStatus? status,
    InstructorQAStatus? actionStatus,
    List<InstructorQuestionModel>? questions,
    QAStatus? currentStatus,
    String? currentCourseId,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InstructorQAState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      questions: questions ?? this.questions,
      currentStatus: currentStatus ?? this.currentStatus,
      currentCourseId: currentCourseId ?? this.currentCourseId,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        questions,
        currentStatus,
        currentCourseId,
        currentPage,
        hasMore,
        errorMessage
      ];
}
