import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/shared_widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';

/// Payment Success Screen
class PaymentSuccessScreen extends StatefulWidget {
  final String orderId;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Success illustration
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildSuccessIllustration(isDark),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'payment.success_title'.tr(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'payment.success_subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Order ID
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'payment.order_id'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.orderId.substring(0, 8).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Start learning button
                AppButton(
                  text: 'payment.start_learning'.tr(),
                  onPressed: () => _goToMyLearning(context),
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  icon: Icons.play_arrow_rounded,
                  isFullWidth: true,
                ),
                const SizedBox(height: 12),
                // Back to home
                TextButton(
                  onPressed: () => _goToHome(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'payment.back_to_home'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIllustration(bool isDark) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circles
          Positioned(
            top: 10,
            left: 10,
            child: _buildCircle(80, AppColors.primary.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 20,
            right: 10,
            child: _buildCircle(60, AppColors.primary.withValues(alpha: 0.06)),
          ),
          Positioned(
            top: 40,
            right: 30,
            child: _buildCircle(30, AppColors.primary.withValues(alpha: 0.1)),
          ),
          // Main icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          // Decorative elements
          Positioned(
            top: 30,
            left: 40,
            child: _buildDot(8, AppColors.primary.withValues(alpha: 0.4)),
          ),
          Positioned(
            bottom: 40,
            left: 30,
            child: _buildDot(6, AppColors.primary.withValues(alpha: 0.3)),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: _buildDot(10, AppColors.primary.withValues(alpha: 0.5)),
          ),
          Positioned(
            bottom: 30,
            right: 40,
            child: _buildDot(5, AppColors.primary.withValues(alpha: 0.25)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  void _goToMyLearning(BuildContext context) {
    AppRouter.goToMyLearning(context);
  }

  void _goToHome(BuildContext context) {
    AppRouter.goToHome(context);
  }
}
