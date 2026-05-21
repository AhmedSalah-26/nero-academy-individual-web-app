import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Interests Search Bar
class InterestsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const InterestsSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.grey800.withValues(alpha: 0.5) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? AppColors.white : AppColors.textMainLight,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن موضوعات مثل "Python"...',
          hintStyle: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.grey500 : AppColors.grey400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.grey500 : AppColors.grey400,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
