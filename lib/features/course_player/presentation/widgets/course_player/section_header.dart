import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/section_entity.dart';

/// Section Header Widget
class SectionHeader extends StatelessWidget {
  final SectionEntity section;
  final int sectionIndex;
  final int completedCount;
  final bool isDark;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.completedCount,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Column(
      children: [
        if (showDivider && sectionIndex > 0)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.grey700 : AppColors.grey200,
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.backgroundLight.withValues(alpha: 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${section.getTitle(locale)} - ${_toArabicNumber(sectionIndex + 1)} ${'course_player.section'.tr()}',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completedCount / ${section.totalLessons}',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark.withValues(alpha: 0.7)
                      : AppColors.textMutedLight.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _toArabicNumber(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      final index = int.tryParse(digit);
      return index != null ? arabicNumbers[index] : digit;
    }).join();
  }
}
