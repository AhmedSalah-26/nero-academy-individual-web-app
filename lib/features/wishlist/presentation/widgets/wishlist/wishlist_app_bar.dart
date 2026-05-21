import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';

/// Wishlist App Bar - Header with title and clear button
class WishlistAppBar extends StatelessWidget {
  final bool isDark;
  final bool hasItems;
  final VoidCallback? onClear;

  const WishlistAppBar({
    super.key,
    required this.isDark,
    this.hasItems = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.95)
              : AppColors.backgroundLight.withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? AppColors.grey800.withValues(alpha: 0.5)
                  : AppColors.grey200.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'wishlist.title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
              ],
            ),
            if (hasItems && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.grey800.withValues(alpha: 0.5)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 22,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
