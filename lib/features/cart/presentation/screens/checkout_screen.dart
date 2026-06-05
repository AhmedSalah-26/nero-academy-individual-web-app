import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/animations/animations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/back_button.dart';
import '../../../payment/presentation/widgets/payment_webview.dart';
import '../../data/datasources/enrollment_payment_service.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';

/// Checkout Screen - Professional Design
class CheckoutScreen extends StatefulWidget {
  final CartEntity cart;

  const CheckoutScreen({
    super.key,
    required this.cart,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _walletPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCheckout();
  }

  @override
  void dispose() {
    _walletPhoneController.dispose();
    super.dispose();
  }

  void _initCheckout() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && mounted) {
      context.read<CheckoutCubit>().initCheckout(userId, widget.cart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (!mounted) return;

          if (state.hasOrder && state.isOrderSuccessful) {
            // Clear cart after successful payment
            context.read<CartCubit>().clearCart();
            _navigateToSuccess(state.order!.id);
          } else if (state.failure != null) {
            _showError(state.errorMessage ?? 'errors.unknown'.tr());
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // App Bar
              _buildSliverAppBar(isDark),
              // Content
              SliverToBoxAdapter(
                child: _buildContent(state, isDark),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, state) => _buildBottomBar(state, isDark),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: const AppBackButton(),
      title: Text(
        'payment.payment'.tr(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildContent(CheckoutState state, bool isDark) {
    final locale = context.locale.languageCode;
    final cart = state.cart ?? widget.cart;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
          _buildOrderSummaryCard(cart, locale, isDark),
          const SizedBox(height: 16),
          // Payment Methods
          _buildPaymentMethodsSection(state, isDark),
          const SizedBox(height: 16),
          // Security Badge
          _buildSecurityBadge(isDark),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartEntity cart, String locale, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cart.order_total'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      '${cart.currency} ${cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${cart.items.length} ${'cart.courses'.tr()}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Items list - compact
          ...cart.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.getTitle(locale),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          if (cart.items.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+${cart.items.length - 2} ${'cart.courses'.tr()}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(CheckoutState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment.payment_method'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 10),
        // Payment method options
        _buildPaymentMethodOption(
          icon: Icons.credit_card_rounded,
          title: 'payment.card'.tr(),
          isSelected: state.selectedPaymentMethod == PaymentMethodType.card,
          onTap: () => _selectPaymentMethod(PaymentMethodType.card),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildPaymentMethodOption(
          icon: Icons.account_balance_wallet_rounded,
          title: 'payment.wallet'.tr(),
          isSelected: state.selectedPaymentMethod == PaymentMethodType.wallet,
          onTap: () => _selectPaymentMethod(PaymentMethodType.wallet),
          isDark: isDark,
        ),
        // Wallet phone number input (shown when wallet is selected)
        if (state.selectedPaymentMethod == PaymentMethodType.wallet) ...[
          const SizedBox(height: 12),
          _buildWalletPhoneInput(isDark),
        ],
      ],
    );
  }

  Widget _buildWalletPhoneInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رقم المحفظة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _walletPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '01xxxxxxxxx',
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : (isDark ? AppColors.cardDark : AppColors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.grey200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.grey500 : AppColors.grey400),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Icon
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.grey400 : AppColors.grey500),
              ),
              const SizedBox(width: 8),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBadge(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_rounded,
              size: 14,
              color: AppColors.success,
            ),
            const SizedBox(width: 6),
            Text(
              'payment.ssl_secure'.tr(),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(CheckoutState state, bool isDark) {
    final cart = state.cart ?? widget.cart;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: state.isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: state.isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '${'payment.pay'.tr()} ${cart.currency} ${cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  void _selectPaymentMethod(PaymentMethodType method) {
    context.read<CheckoutCubit>().selectPaymentMethod(method);
  }

  void _processPayment() {
    HapticFeedback.mediumImpact();

    final state = context.read<CheckoutCubit>().state;
    final cart = state.cart ?? widget.cart;

    // If free order, process directly
    if (cart.total == 0) {
      context.read<CheckoutCubit>().processCheckout();
      return;
    }

    // For paid orders, show payment method specific flow
    if (state.selectedPaymentMethod == PaymentMethodType.card) {
      _processCardPayment();
    } else if (state.selectedPaymentMethod == PaymentMethodType.wallet) {
      _processWalletPayment();
    } else {
      // Other payment methods
      context.read<CheckoutCubit>().processCheckout();
    }
  }

  Future<void> _processCardPayment() async {
    final cubit = context.read<CheckoutCubit>();

    // First create the order
    await cubit.processCheckout();

    final state = cubit.state;
    if (state.hasOrder && !state.isOrderSuccessful) {
      // Order created with pending status, now get payment URL
      final user = Supabase.instance.client.auth.currentUser;

      // Get user profile data including phone number
      String? phoneNumber = user?.phone;
      String? userName = user?.userMetadata?['full_name'];

      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('phone, name')
            .eq('id', user!.id)
            .maybeSingle();

        if (profile != null) {
          phoneNumber = profile['phone'] as String?;
          userName = profile['name'] as String? ?? userName;
        }
      } catch (e) {
        // Use default values if profile fetch fails
      }

      final paymentUrl = await cubit.getPaymentUrl(
        amount: state.order!.total,
        customerName: userName,
        customerEmail: user?.email,
        customerPhone: phoneNumber,
      );

      if (paymentUrl != null && mounted) {
        // Show payment webview - keep processing state until webview opens
        await _showPaymentWebView(paymentUrl, state.order!.id);
        // Reset processing state after webview is shown
        if (mounted) {
          cubit.stopProcessing();
        }
      } else {
        _showError('فشل في الحصول على رابط الدفع');
      }
    }
  }

  Future<void> _processWalletPayment() async {
    final walletPhone = _walletPhoneController.text.trim();

    // Validate phone number
    if (walletPhone.isEmpty) {
      _showError('من فضلك أدخل رقم المحفظة');
      return;
    }

    if (!RegExp(r'^01[0-9]{9}$').hasMatch(walletPhone)) {
      _showError('رقم المحفظة غير صحيح');
      return;
    }

    final cubit = context.read<CheckoutCubit>();

    // First create the order
    await cubit.processCheckout();

    final state = cubit.state;
    if (state.hasOrder && !state.isOrderSuccessful) {
      // Order created with pending status, now get wallet payment URL
      final user = Supabase.instance.client.auth.currentUser;
      String? userName = user?.userMetadata?['full_name'];

      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', user!.id)
            .maybeSingle();

        if (profile != null) {
          userName = profile['name'] as String? ?? userName;
        }
      } catch (e) {
        // Use default values if profile fetch fails
      }

      final paymentUrl = await cubit.getWalletPaymentUrl(
        amount: state.order!.total,
        customerName: userName,
        customerEmail: user?.email,
        customerPhone: walletPhone,
      );

      if (paymentUrl != null && mounted) {
        if (paymentUrl.startsWith('ERROR:')) {
          _showError(paymentUrl.substring(6));
        } else {
          // Show payment webview for wallet - keep processing state until webview opens
          await _showPaymentWebView(paymentUrl, state.order!.id,
              isWallet: true);
          // Reset processing state after webview is shown
          if (mounted) {
            cubit.stopProcessing();
          }
        }
      } else {
        _showError('فشل في الحصول على رابط الدفع بالمحفظة');
      }
    }
  }

  Future<void> _showPaymentWebView(String paymentUrl, String orderId,
      {bool isWallet = false}) async {
    // Save cubits before navigation to avoid context issues
    final checkoutCubit = context.read<CheckoutCubit>();
    final cartCubit = context.read<CartCubit>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PaymentWebView(
          paymentUrl: paymentUrl,
          isWalletPayment: isWallet,
          onPaymentComplete: (result) async {
            try {
              debugPrint(
                  '🔵 Payment result received: success=${result.success}, txnId=${result.transactionId}');

              if (result.success && result.transactionId != null) {
                // Wait for backend webhook confirmation.
                if (!context.mounted) return;
                final confirmation =
                    await checkoutCubit.confirmPayment(result.transactionId!);

                if (confirmation == PaymentConfirmationStatus.paid &&
                    context.mounted) {
                  // Clear cart and navigate to success
                  cartCubit.clearCart();
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Close webview
                  }
                  _navigateToSuccess(orderId);
                } else if (confirmation == PaymentConfirmationStatus.pending &&
                    context.mounted) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Close webview
                  }
                  _showError('payment.pending_confirmation'.tr());
                } else if (context.mounted) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Close webview
                  }
                  _showError('فشل في تأكيد الدفع');
                }
              } else if (!result.success) {
                // Payment failed
                if (!context.mounted) return;
                await checkoutCubit.markPaymentFailed();
                if (context.mounted) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Close webview
                  }
                  _showError(result.message ?? 'فشل الدفع');
                }
              }
            } catch (e) {
              debugPrint('❌ Error in payment complete handler: $e');
              if (context.mounted) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Close webview
                }
                _showError('حدث خطأ أثناء معالجة الدفع');
              }
            }
          },
          onCancel: () async {
            try {
              // User cancelled payment
              if (!context.mounted) return;
              await checkoutCubit.markPaymentFailed();
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context); // Close webview
              }
            } catch (e) {
              debugPrint('❌ Error in cancel handler: $e');
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
        ),
      ),
    );
  }

  void _navigateToSuccess(String orderId) {
    // Navigate directly to success page
    AppRouter.goToPaymentSuccess(context, orderId);
  }

  void _showError(String message) {
    AnimatedSnackbar.showError(
      context: context,
      message: message,
    );
  }
}
