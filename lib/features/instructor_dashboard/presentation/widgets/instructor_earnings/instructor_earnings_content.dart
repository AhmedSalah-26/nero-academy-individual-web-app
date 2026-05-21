// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/routing/app_router.dart';
import '../../cubit/instructor_earnings_cubit.dart';
import 'earnings_stats_cards.dart';
import 'earnings_list_widgets.dart';
import 'earnings_breakdown_widget.dart';

/// Instructor Earnings Content — NEW SCHEMA
class InstructorEarningsContent extends StatefulWidget {
  const InstructorEarningsContent({super.key});

  @override
  State<InstructorEarningsContent> createState() =>
      _InstructorEarningsContentState();
}

class _InstructorEarningsContentState extends State<InstructorEarningsContent> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<InstructorEarningsCubit>();
    cubit.loadEarnings(refresh: true);
    cubit.loadWithdrawHistory(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<InstructorEarningsCubit, InstructorEarningsState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            final cubit = context.read<InstructorEarningsCubit>();
            await cubit.loadEarnings();
            await cubit.loadWithdrawHistory();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EarningsStatsCards(
                    state: state, isArabic: isArabic, isDark: isDark),
                const SizedBox(height: 20),
                _buildQuickActions(context, state, isArabic, isDark),
                const SizedBox(height: 24),
                EarningsBreakdownWidget(
                    state: state, isArabic: isArabic, isDark: isDark),
                const SizedBox(height: 24),
                RecentEarningsList(
                    state: state, isArabic: isArabic, isDark: isDark),
                const SizedBox(height: 24),
                WithdrawHistoryList(
                    state: state, isArabic: isArabic, isDark: isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, InstructorEarningsState state,
      bool isArabic, bool isDark) {
    final availableBalance = state.walletSummary.availableBalance;

    return Row(
      children: [
        Expanded(
          child: SolidActionButton(
            icon: Icons.payments_rounded,
            label: isArabic ? 'طلب سحب' : 'Request Withdrawal',
            color: AppColors.success,
            onPressed: availableBalance >= 50
                ? () => _showWithdrawDialog(context, isArabic, availableBalance)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedActionButton(
            icon: Icons.history_rounded,
            label: isArabic ? 'سجل كامل' : 'Full History',
            onPressed: () => AppRouter.goToEarningsHistory(context),
          ),
        ),
      ],
    );
  }

  void _showWithdrawDialog(
      BuildContext context, bool isArabic, double maxAmount) {
    final cubit = context.read<InstructorEarningsCubit>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => _WithdrawRequestDialog(
        isArabic: isArabic,
        maxAmount: maxAmount,
        onSubmit: (amount, method, details) {
          cubit.submitWithdrawRequest(
            amount: amount,
            method: method,
            accountDetails: details,
          );
        },
      ),
    );
  }
}

/// Outlined Action Button
class OutlinedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const OutlinedActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
    );
  }
}

/// Withdraw Request Dialog — NEW SCHEMA
class _WithdrawRequestDialog extends StatefulWidget {
  final bool isArabic;
  final double maxAmount;
  final Function(double amount, String method, Map<String, String> details)
      onSubmit;

  const _WithdrawRequestDialog({
    required this.isArabic,
    required this.maxAmount,
    required this.onSubmit,
  });

  @override
  State<_WithdrawRequestDialog> createState() => _WithdrawRequestDialogState();
}

class _WithdrawRequestDialogState extends State<_WithdrawRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();

  String _selectedMethod = 'instapay';

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isArabic ? 'طلب سحب' : 'Request Withdrawal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.isArabic ? 'المبلغ' : 'Amount',
                  hintText: widget.isArabic
                      ? 'الحد الأقصى: ${widget.maxAmount.toStringAsFixed(0)} ج.م'
                      : 'Max: ${widget.maxAmount.toStringAsFixed(0)} EGP',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.isArabic ? 'مطلوب' : 'Required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return widget.isArabic ? 'مبلغ غير صالح' : 'Invalid amount';
                  }
                  if (amount < 50) {
                    return widget.isArabic
                        ? 'الحد الأدنى 50 ج.م'
                        : 'Minimum is 50 EGP';
                  }
                  if (amount > widget.maxAmount) {
                    return widget.isArabic
                        ? 'المبلغ أكبر من الرصيد المتاح'
                        : 'Amount exceeds available balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment method selection
              Text(
                widget.isArabic ? 'وسيلة الدفع' : 'Payment Method',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'instapay',
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(widget.isArabic ? 'انستاباي' : 'InstaPay'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'wallet',
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(widget.isArabic ? 'محفظة إلكترونية' : 'E-Wallet'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                    _detailsController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Payment details based on selected method
              if (_selectedMethod == 'instapay') ...[
                TextFormField(
                  controller: _detailsController,
                  decoration: InputDecoration(
                    labelText: widget.isArabic
                        ? 'معرف انستاباي (InstaPay ID)'
                        : 'InstaPay ID',
                    hintText: widget.isArabic
                        ? 'أدخل معرف انستاباي'
                        : 'Enter InstaPay ID',
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                    ),
                    border: const OutlineInputBorder(),
                    helperText: widget.isArabic
                        ? 'المعرف الخاص بك في تطبيق انستاباي'
                        : 'Your InstaPay app identifier',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.isArabic ? 'مطلوب' : 'Required';
                    }
                    return null;
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _detailsController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:
                        widget.isArabic ? 'رقم الموبايل' : 'Mobile Number',
                    hintText: widget.isArabic ? '01xxxxxxxxx' : '01xxxxxxxxx',
                    prefixIcon: const Icon(Icons.phone_android),
                    border: const OutlineInputBorder(),
                    helperText: widget.isArabic
                        ? 'رقم المحفظة الإلكترونية'
                        : 'E-Wallet phone number',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.isArabic ? 'مطلوب' : 'Required';
                    }
                    if (!value.startsWith('01') || value.length != 11) {
                      return widget.isArabic
                          ? 'رقم موبايل غير صالح'
                          : 'Invalid mobile number';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.isArabic ? 'طلب السحب' : 'Submit Request',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final details = <String, String>{};

    if (_selectedMethod == 'instapay') {
      details['instapay_id'] = _detailsController.text;
    } else {
      details['phone_number'] = _detailsController.text;
    }

    widget.onSubmit(amount, _selectedMethod, details);
    Navigator.pop(context);
  }
}
