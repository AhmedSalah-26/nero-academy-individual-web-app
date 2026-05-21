import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/repositories/portfolio_repository.dart';
import 'portfolio_state.dart';

/// Portfolio Cubit
class PortfolioCubit extends Cubit<PortfolioState> {
  final PortfolioRepository repository;
  String? _currentUserId;

  PortfolioCubit({required this.repository}) : super(PortfolioState.initial());

  String? get currentUserId => _currentUserId;

  /// Load portfolio
  Future<void> loadPortfolio(String userId) async {
    _currentUserId = userId;
    emit(PortfolioState.loading());
    AppLogger.i('📊 [PortfolioCubit] Loading portfolio for: $userId');

    final result = await repository.getPortfolio(userId: userId);

    result.fold(
      (failure) {
        AppLogger.e('[PortfolioCubit] Failed: ${failure.message}');
        emit(PortfolioState.error(failure.message));
      },
      (portfolio) {
        AppLogger.success('[PortfolioCubit] Portfolio loaded');
        emit(PortfolioState.loaded(portfolio));
      },
    );
  }

  /// Change tab
  void changeTab(int index) {
    AppLogger.i('[PortfolioCubit] Tab changed to: $index');
    emit(state.copyWith(selectedTabIndex: index));
  }

  /// Refresh portfolio
  Future<void> refreshPortfolio() async {
    if (_currentUserId == null) return;
    await loadPortfolio(_currentUserId!);
  }
}
