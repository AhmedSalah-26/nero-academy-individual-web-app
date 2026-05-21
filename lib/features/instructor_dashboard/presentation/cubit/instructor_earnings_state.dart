part of 'instructor_earnings_cubit.dart';

enum InstructorEarningsStatus { initial, loading, loadingMore, success, error }

class InstructorEarningsState extends Equatable {
  final InstructorEarningsStatus status;
  final InstructorEarningsStatus withdrawStatus;
  final InstructorEarningsStatus actionStatus;
  final List<EarningsTransactionModel> earnings;
  final List<WithdrawRequestModel> withdrawRequests;
  final WalletSummaryModel walletSummary;
  final String? currentCourseId;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  InstructorEarningsState({
    this.status = InstructorEarningsStatus.initial,
    this.withdrawStatus = InstructorEarningsStatus.initial,
    this.actionStatus = InstructorEarningsStatus.initial,
    this.earnings = const [],
    this.withdrawRequests = const [],
    WalletSummaryModel? walletSummary,
    this.currentCourseId,
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  }) : walletSummary = walletSummary ?? WalletSummaryModel.empty;

  bool get isLoading => status == InstructorEarningsStatus.loading;
  bool get isLoadingMore => status == InstructorEarningsStatus.loadingMore;
  bool get hasError => status == InstructorEarningsStatus.error;

  InstructorEarningsState copyWith({
    InstructorEarningsStatus? status,
    InstructorEarningsStatus? withdrawStatus,
    InstructorEarningsStatus? actionStatus,
    List<EarningsTransactionModel>? earnings,
    List<WithdrawRequestModel>? withdrawRequests,
    WalletSummaryModel? walletSummary,
    String? currentCourseId,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return InstructorEarningsState(
      status: status ?? this.status,
      withdrawStatus: withdrawStatus ?? this.withdrawStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      earnings: earnings ?? this.earnings,
      withdrawRequests: withdrawRequests ?? this.withdrawRequests,
      walletSummary: walletSummary ?? this.walletSummary,
      currentCourseId: currentCourseId ?? this.currentCourseId,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        withdrawStatus,
        actionStatus,
        earnings,
        withdrawRequests,
        walletSummary,
        currentCourseId,
        currentPage,
        hasMore,
        errorMessage
      ];
}
