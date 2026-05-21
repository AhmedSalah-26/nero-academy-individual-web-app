import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Portfolio App Bar Widget
class PortfolioAppBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onShare;

  const PortfolioAppBar({
    super.key,
    required this.isDark,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.95)
            : AppColors.backgroundLight.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.grey800 : AppColors.grey200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? AppColors.white : AppColors.textMainLight,
              size: 22,
            ),
          ),
          Expanded(
            child: Text(
              'My Portfolio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textMainLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onShare != null)
            IconButton(
              onPressed: onShare,
              icon: Icon(
                Icons.share_outlined,
                color: isDark ? AppColors.white : AppColors.textMainLight,
                size: 22,
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
