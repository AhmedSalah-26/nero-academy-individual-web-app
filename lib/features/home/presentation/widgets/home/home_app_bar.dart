import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../../notifications/presentation/cubit/notifications_state.dart';

/// Home App Bar Widget - Responsive
class HomeAppBar extends StatelessWidget {
  final String? userName;

  const HomeAppBar({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenWidth * 0.03;

    // Build greeting with name (first two words only)
    String greeting;
    if (userName != null && userName!.isNotEmpty) {
      final nameParts = userName!.trim().split(' ');
      final displayName = nameParts.take(2).join(' ');
      greeting = '${'home.hello'.tr()} $displayName';
    } else {
      greeting = 'home.hello'.tr();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              greeting,
              style: AppTextStyles.headlineMedium.copyWith(
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
                fontWeight: FontWeight.w700,
                fontSize: (screenWidth * 0.05).clamp(18.0, 22.0),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              // Wishlist button
              _ActionButton(
                icon: Icons.favorite_border_rounded,
                onTap: () => AppRouter.goToWishlist(context),
                isDark: isDark,
              ),
              SizedBox(width: screenWidth * 0.02),
              // History button
              _ActionButton(
                icon: Icons.history_rounded,
                onTap: () => AppRouter.goToHistory(context),
                isDark: isDark,
              ),
              SizedBox(width: screenWidth * 0.02),
              // Cart button with badge from CartCubit
              BlocBuilder<CartCubit, CartState>(
                bloc: sl<CartCubit>(),
                builder: (context, state) {
                  return _ActionButton(
                    icon: Icons.shopping_cart_outlined,
                    onTap: () => AppRouter.goToCart(context),
                    isDark: isDark,
                    badgeCount: state.itemsCount,
                    compactBadge: true,
                  );
                },
              ),
              SizedBox(width: screenWidth * 0.02),
              BlocBuilder<NotificationsCubit, NotificationsState>(
                bloc: sl<NotificationsCubit>(),
                builder: (context, state) {
                  final hasUnread =
                      state is NotificationsLoaded && state.unreadCount > 0;
                  return _ActionButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => AppRouter.goToNotifications(context),
                    isDark: isDark,
                    hasNotification: hasUnread,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool hasNotification;
  final int? badgeCount;
  final bool compactBadge;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.hasNotification = false,
    this.badgeCount,
    this.compactBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonPadding = (screenWidth * 0.018).clamp(6.0, 9.0);
    final iconSize = (screenWidth * 0.045).clamp(17.0, 20.0);
    final borderRadius = (screenWidth * 0.025).clamp(8.0, 11.0);
    final numberBadgeScale = compactBadge ? 0.78 : 1.0;

    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding: EdgeInsets.all(buttonPadding),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Icon(icon,
                  size: iconSize,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight),
            ),
          ),
        ),
        if (hasNotification || (badgeCount != null && badgeCount! > 0))
          Positioned(
            right: screenWidth * 0.015,
            top: screenWidth * 0.015,
            child: Container(
              padding: badgeCount != null
                  ? EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01 * numberBadgeScale,
                      vertical: screenWidth * 0.002 * numberBadgeScale,
                    )
                  : EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: screenWidth * 0.02 * numberBadgeScale,
                minHeight: screenWidth * 0.02 * numberBadgeScale,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(
                    screenWidth * 0.025 * numberBadgeScale),
                border: Border.all(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    width: compactBadge ? 1.2 : 1.5),
              ),
              child: badgeCount != null
                  ? Text('$badgeCount',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: (screenWidth * 0.022 * numberBadgeScale)
                              .clamp(7.0, 10.0),
                          fontWeight: FontWeight.w700))
                  : null,
            ),
          ),
      ],
    );
  }
}
