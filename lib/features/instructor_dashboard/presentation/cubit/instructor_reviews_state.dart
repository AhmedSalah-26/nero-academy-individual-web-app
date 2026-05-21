part of 'instructor_reviews_cubit.dart';

enum InstructorReviewsStatus { initial, loading, loadingMore, success, error }

class InstructorReviewsState extends Equatable {
  final InstructorReviewsStatus status;
  final List<InstructorReviewModel> reviews;
  final String? currentCourseId;
  final int? currentMinRating;
  final int? currentMaxRating;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const InstructorReviewsState({
    this.status = InstructorReviewsStatus.initial,
    this.reviews = const [],
    this.currentCourseId,
    this.currentMinRating,
    this.currentMaxRating,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get isLoading => status == InstructorReviewsStatus.loading;
  bool get isLoadingMore => status == InstructorReviewsStatus.loadingMore;
  bool get hasError => status == InstructorReviewsStatus.error;

  InstructorReviewsState copyWith({
    InstructorReviewsStatus? status,
    List<InstructorReviewModel>? reviews,
    String? currentCourseId,
    int? currentMinRating,
    int? currentMaxRating,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InstructorReviewsState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      currentCourseId: currentCourseId ?? this.currentCourseId,
      currentMinRating: currentMinRating ?? this.currentMinRating,
      currentMaxRating: currentMaxRating ?? this.currentMaxRating,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        reviews,
        currentCourseId,
        currentMinRating,
        currentMaxRating,
        currentPage,
        hasMore,
        errorMessage
      ];
}
