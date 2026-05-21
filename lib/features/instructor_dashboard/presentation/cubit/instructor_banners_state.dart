part of 'instructor_banners_cubit.dart';

enum InstructorBannersStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
  creating,
  updating,
  deleting,
  reordering,
}

class InstructorBannersState extends Equatable {
  final InstructorBannersStatus status;
  final InstructorBannersStatus actionStatus;
  final List<BannerModel> banners;
  final BannerType? currentType;
  final bool? isActiveFilter;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const InstructorBannersState({
    this.status = InstructorBannersStatus.initial,
    this.actionStatus = InstructorBannersStatus.initial,
    this.banners = const [],
    this.currentType,
    this.isActiveFilter,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  InstructorBannersState copyWith({
    InstructorBannersStatus? status,
    InstructorBannersStatus? actionStatus,
    List<BannerModel>? banners,
    BannerType? Function()? currentType,
    bool? isActiveFilter,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InstructorBannersState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      banners: banners ?? this.banners,
      currentType: currentType != null ? currentType() : this.currentType,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        banners,
        currentType,
        isActiveFilter,
        currentPage,
        hasMore,
        errorMessage,
      ];
}
