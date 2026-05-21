import 'package:equatable/equatable.dart';
import '../../domain/entities/portfolio_entity.dart';
import '../../domain/entities/portfolio_item_entity.dart';

/// Portfolio State
class PortfolioState extends Equatable {
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final PortfolioEntity? portfolio;
  final int selectedTabIndex;
  final bool isDownloading;

  const PortfolioState({
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.portfolio,
    this.selectedTabIndex = 0,
    this.isDownloading = false,
  });

  /// Initial state
  factory PortfolioState.initial() => const PortfolioState();

  /// Loading state
  factory PortfolioState.loading() => const PortfolioState(isLoading: true);

  /// Loaded state
  factory PortfolioState.loaded(PortfolioEntity portfolio) =>
      PortfolioState(portfolio: portfolio);

  /// Error state
  factory PortfolioState.error(String message) =>
      PortfolioState(isError: true, errorMessage: message);

  /// Copy with
  PortfolioState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    PortfolioEntity? portfolio,
    int? selectedTabIndex,
    bool? isDownloading,
  }) {
    return PortfolioState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      portfolio: portfolio ?? this.portfolio,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }

  /// Getters
  PortfolioStatsEntity get stats =>
      portfolio?.stats ?? const PortfolioStatsEntity();
  List<PortfolioItemEntity> get completedCourses =>
      portfolio?.completedCourses ?? [];
  List<PortfolioAchievementEntity> get achievements =>
      portfolio?.achievements ?? [];

  bool get hasData => portfolio != null;
  bool get hasCompletedCourses => completedCourses.isNotEmpty;
  bool get hasAchievements => achievements.isNotEmpty;

  @override
  List<Object?> get props => [
        isLoading,
        isError,
        errorMessage,
        portfolio,
        selectedTabIndex,
        isDownloading,
      ];
}
