part of 'payments_history_cubit.dart';

abstract class PaymentsHistoryState extends Equatable {
  const PaymentsHistoryState();

  @override
  List<Object?> get props => [];
}

class PaymentsHistoryInitial extends PaymentsHistoryState {}

class PaymentsHistoryLoading extends PaymentsHistoryState {}

class PaymentsHistoryLoaded extends PaymentsHistoryState {
  final List<PaymentEntity> payments;
  final String? selectedStatus;

  const PaymentsHistoryLoaded(
    this.payments, {
    this.selectedStatus,
  });

  List<PaymentEntity> get filteredPayments {
    if (selectedStatus == null || selectedStatus == 'all') {
      return payments;
    }
    return payments.where((p) => p.paymentStatus == selectedStatus).toList();
  }

  @override
  List<Object?> get props => [payments, selectedStatus];
}

class PaymentsHistoryError extends PaymentsHistoryState {
  final String message;

  const PaymentsHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
