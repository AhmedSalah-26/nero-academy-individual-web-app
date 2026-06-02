import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../../core/theme/app_colors.dart';

/// Content Tabs Widget
class ContentTabs extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTabChanged;

  const ContentTabs({
    super.key,
    required this.currentIndex,
    required this.isDark,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Row(
          children: [
            _buildTab(0, 'المحاضرات'),
            _buildTab(1, 'المزيد'),
            _buildTab(2, 'الأسئلة'),
            _buildTab(3, 'الاختبارات'),
            _buildTab(4, 'التقييم'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.4,
              ),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
