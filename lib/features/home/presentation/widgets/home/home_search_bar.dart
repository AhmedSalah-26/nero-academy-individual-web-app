import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Home Search Bar Widget - Responsive
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenWidth * 0.02;
    final searchHeight = (screenHeight * 0.058).clamp(44.0, 52.0);
    final borderRadius = (screenWidth * 0.03).clamp(10.0, 14.0);
    final iconSize = (screenWidth * 0.055).clamp(20.0, 24.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: GestureDetector(
        onTap: () => _navigateToSearch(context),
        child: Container(
          height: searchHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.7)
                  : AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Search Icon
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                child: Icon(
                  Icons.search_rounded,
                  color:
                      isDark ? AppColors.grey400 : AppColors.grey500, // رصاصي
                  size: iconSize,
                ),
              ),
              // Placeholder Text
              Expanded(
                child: Text(
                  'home.search_placeholder'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: (screenWidth * 0.035).clamp(13.0, 15.0),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Filter Button
              Container(
                height: searchHeight,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                child: Icon(
                  Icons.tune_rounded,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                  size: iconSize * 0.9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    context.pushNamed('search');
  }
}
