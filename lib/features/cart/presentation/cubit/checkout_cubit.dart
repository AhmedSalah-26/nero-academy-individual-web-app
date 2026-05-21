import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/base/base_state.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/usecases/checkout_usecase.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../../payment/data/services/paymob_service.dart';
import '../../data/datasources/enrollment_payment_service.dart';
import 'checkout_state.dart';

/// Checkout Cubit
class CheckoutCubit extends Cubit<CheckoutState> {
  final CheckoutUseCase checkoutUseCase;
  final CartRepository cartRepository;
  final EnrollmentPaymentService enrollmentPaymentService;

  CheckoutCubit({
    required this.checkoutUseCase,
    required this.cartRepository,
    required this.enrollmentPaymentService,
  }) : super(const CheckoutState());

  String? _currentUserId;
  String? _pendingParentEnrollmentId;

  /// Initialize checkout with cart data
  Future<void> initCheckout(String userId, CartEntity cart) async {
    _currentUserId = userId;
    emit(state.copyWith(
      status: StateStatus.loading,
      cart: cart,
    ));

    // Load saved payment methods
    final result = await cartRepository.getSavedPaymentMethods(userId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: StateStatus.success,
        savedPaymentMethods: [],
      )),
      (methods) {
        // Auto-select default method if available
        final defaultMethod = methods.where((m) => m.isDefault).firstOrNull;
        emit(state.copyWith(
          status: StateStatus.success,
          savedPaymentMethods: methods,
          selectedSavedMethodId: defaultMethod?.id,
        ));
      },
    );
  }

  /// Select payment method type
  void selectPaymentMethod(PaymentMethodType method) {
    emit(state.copyWith(
      selectedPaymentMethod: method,
      clearSavedMethodId: true,
    ));
  }

  /// Select saved payment method
  void selectSavedPaymentMethod(String methodId) {
    emit(state.copyWith(
      selectedPaymentMethod: PaymentMethodType.card,
      selectedSavedMethodId: methodId,
    ));
  }

  /// Process checkout
  Future<void> processCheckout({Map<String, dynamic>? cardDetails}) async {
    if (_currentUserId == null) return;
    emit(state.copyWith(isProcessing: true));

    final result = await checkoutUseCase(
      CheckoutParams(
        userId: _currentUserId!,
        paymentMethod: state.selectedPaymentMethod,
        savedPaymentMethodId: state.selectedSavedMethodId,
        cardDetails: cardDetails,
        couponDiscountTotal: state.cart?.discountAmount ?? 0,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isProcessing: false,
        failure: failure,
      )),
      (order) {
        _pendingParentEnrollmentId = order.id;
        emit(state.copyWith(
          isProcessing: false,
          order: order,
        ));
      },
    );
  }

  /// Get Paymob payment URL for card payment
  Future<String?> getPaymentUrl({
    required double amount,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    if (_pendingParentEnrollmentId == null) {
      debugPrint('❌ [CheckoutCubit] No pending parent enrollment ID');
      return null;
    }

    try {
      debugPrint(
          '🔵 [CheckoutCubit] Getting payment URL for amount: $amount, orderId: $_pendingParentEnrollmentId');

      final paymentUrl = await PaymobService.instance.getPaymentUrl(
        amount: amount,
        orderId: _pendingParentEnrollmentId!,
        currency: 'EGP',
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
      );

      if (paymentUrl != null) {
        debugPrint('✅ [CheckoutCubit] Payment URL generated successfully');
      } else {
        debugPrint('❌ [CheckoutCubit] Failed to generate payment URL');
      }

      return paymentUrl;
    } catch (e) {
      debugPrint('❌ [CheckoutCubit] Error getting payment URL: $e');
      return null;
    }
  }

  /// Get Paymob wallet payment URL
  Future<String?> getWalletPaymentUrl({
    required double amount,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    if (_pendingParentEnrollmentId == null) {
      debugPrint('❌ [CheckoutCubit] No pending parent enrollment ID');
      return null;
    }

    if (customerPhone == null || customerPhone.isEmpty) {
      debugPrint('❌ [CheckoutCubit] Wallet phone number is required');
      return null;
    }

    try {
      debugPrint(
          '🔵 [CheckoutCubit] Getting wallet payment URL for amount: $amount, orderId: $_pendingParentEnrollmentId');

      final paymentUrl = await PaymobService.instance.getWalletPaymentUrl(
        amount: amount,
        orderId: _pendingParentEnrollmentId!,
        walletPhoneNumber: customerPhone,
        currency: 'EGP',
        customerName: customerName,
        customerEmail: customerEmail,
      );

      if (paymentUrl != null) {
        debugPrint('✅ [CheckoutCubit] Wallet payment URL generated successfully');
      } else {
        debugPrint('❌ [CheckoutCubit] Failed to generate wallet payment URL');
      }

      return paymentUrl;
    } catch (e) {
      debugPrint('❌ [CheckoutCubit] Error getting wallet payment URL: $e');
      return null;
    }
  }

  /// Confirm payment after successful Paymob transaction
  Future<bool> confirmPayment(String transactionId) async {
    if (_pendingParentEnrollmentId == null) return false;

    try {
      final success = await enrollmentPaymentService.confirmPayment(
        parentEnrollmentId: _pendingParentEnrollmentId!,
        transactionId: transactionId,
      );

      if (success) {
        // Update order status to completed
        emit(state.copyWith(
          order: state.order?.copyWith(status: OrderStatus.completed),
        ));
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Mark payment as failed
  Future<void> markPaymentFailed() async {
    if (_pendingParentEnrollmentId == null) return;

    try {
      await enrollmentPaymentService.markPaymentFailed(
        parentEnrollmentId: _pendingParentEnrollmentId!,
      );
    } catch (e) {
      // Log error but don't throw
    }
  }

  /// Reset checkout state
  void reset() {
    emit(const CheckoutState());
  }

  /// Stop processing indicator
  void stopProcessing() {
    emit(state.copyWith(isProcessing: false));
  }
}
