import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/get_user_payments_usecase.dart';

part 'payments_history_state.dart';

class PaymentsHistoryCubit extends Cubit<PaymentsHistoryState> {
  final GetUserPaymentsUseCase getUserPaymentsUseCase;

  PaymentsHistoryCubit({
    required this.getUserPaymentsUseCase,
  }) : super(PaymentsHistoryInitial());

  Future<void> loadPayments(String userId) async {
    emit(PaymentsHistoryLoading());

    final result = await getUserPaymentsUseCase(userId);

    result.fold(
      (failure) =>
          emit(PaymentsHistoryError(failure.message ?? 'Unknown error')),
      (payments) => emit(PaymentsHistoryLoaded(payments)),
    );
  }

  void filterByStatus(String? status) {
    if (state is PaymentsHistoryLoaded) {
      final currentState = state as PaymentsHistoryLoaded;
      emit(PaymentsHistoryLoaded(
        currentState.payments,
        selectedStatus: status,
      ));
    }
  }
}
