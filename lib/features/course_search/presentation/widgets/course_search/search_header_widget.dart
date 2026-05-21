import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Search Header Widget - Simple TextField only
class SearchHeaderWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onBackPressed;
  final VoidCallback onFilterPressed;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final int activeFilterCount;
  final bool showBackButton;

  const SearchHeaderWidget({
    super.key,
    required this.controller,
    this.onBackPressed,
    required this.onFilterPressed,
    required this.onChanged,
    required this.onSubmitted,
    this.activeFilterCount = 0,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.06).clamp(22.0, 26.0);

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.025,
          ),
          child: Row(
            children: [
              if (showBackButton && onBackPressed != null)
                GestureDetector(
                  onTap: onBackPressed,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.colorScheme.onSurface,
                    size: iconSize,
                  ),
                ),
              SizedBox(width: showBackButton ? 12 : 0),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  style: theme.textTheme.bodyLarge,
                  cursorColor: isDark
                      ? AppColors.grey400
                      : AppColors.grey500, // cursor رصاصي
                  decoration: InputDecoration(
                    hintText: 'home.search_placeholder'.tr(),
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? AppColors.grey400
                          : AppColors.grey500, // أيقونة رصاصي
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onFilterPressed,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: activeFilterCount > 0
                          ? AppColors.primary
                          : isDark
                              ? AppColors.grey500
                              : AppColors.grey400,
                      size: iconSize,
                    ),
                    if (activeFilterCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
