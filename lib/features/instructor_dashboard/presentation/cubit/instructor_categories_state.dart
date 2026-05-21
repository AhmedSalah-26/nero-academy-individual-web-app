part of 'instructor_categories_cubit.dart';

enum InstructorCategoriesStatus { initial, loading, success, error }

class InstructorCategoriesState extends Equatable {
  final InstructorCategoriesStatus status;
  final InstructorCategoriesStatus actionStatus;
  final List<CategoryModel> categories;
  final bool? isActiveFilter;
  final String? errorMessage;

  const InstructorCategoriesState({
    this.status = InstructorCategoriesStatus.initial,
    this.actionStatus = InstructorCategoriesStatus.initial,
    this.categories = const [],
    this.isActiveFilter,
    this.errorMessage,
  });

  bool get isLoading => status == InstructorCategoriesStatus.loading;
  bool get hasError => status == InstructorCategoriesStatus.error;

  List<CategoryModel> get activeCategories =>
      categories.where((c) => c.isActive).toList();

  List<CategoryModel> get inactiveCategories =>
      categories.where((c) => !c.isActive).toList();

  InstructorCategoriesState copyWith({
    InstructorCategoriesStatus? status,
    InstructorCategoriesStatus? actionStatus,
    List<CategoryModel>? categories,
    bool? isActiveFilter,
    String? errorMessage,
  }) {
    return InstructorCategoriesState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      categories: categories ?? this.categories,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        categories,
        isActiveFilter,
        errorMessage,
      ];
}
