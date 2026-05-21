import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Bottom Action Bar Widget
class BottomActionBar extends StatelessWidget {
  final bool hasNextLesson;
  final bool isLastLesson;
  final bool isCompletingCourse;
  final bool isDark;
  final VoidCallback onResourcesTap;
  final VoidCallback onNextLessonTap;
  final VoidCallback? onCompleteCourse;

  const BottomActionBar({
    super.key,
    required this.hasNextLesson,
    this.isLastLesson = false,
    this.isCompletingCourse = false,
    required this.isDark,
    required this.onResourcesTap,
    required this.onNextLessonTap,
    this.onCompleteCourse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Resources button
            Expanded(
              child: _buildResourcesButton(),
            ),
            const SizedBox(width: 12),
            // Next lesson or Complete course button
            Expanded(
              flex: 2,
              child: isLastLesson
                  ? _buildCompleteCourseButton()
                  : _buildNextLessonButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesButton() {
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onResourcesTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.transparent : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'course_player.attachments'.tr(),
                style: TextStyle(
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextLessonButton() {
    return Material(
      color: hasNextLesson
          ? AppColors.primary
          : AppColors.primary.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      elevation: hasNextLesson ? 4 : 0,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      child: InkWell(
        onTap: hasNextLesson ? onNextLessonTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'course_player.next_lesson'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteCourseButton() {
    return Material(
      color: AppColors.success,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: AppColors.success.withValues(alpha: 0.3),
      child: InkWell(
        onTap: isCompletingCourse ? null : onCompleteCourse,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCompletingCourse)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else ...[
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'course_player.complete_course'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
