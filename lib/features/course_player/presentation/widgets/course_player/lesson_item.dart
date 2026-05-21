import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/lesson_entity.dart';

/// Lesson Item Widget
class LessonItem extends StatelessWidget {
  final LessonEntity lesson;
  final int lessonNumber;
  final bool isCurrentLesson;
  final bool isCompleted;
  final bool isLocked;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onDownloadTap;

  const LessonItem({
    super.key,
    required this.lesson,
    this.lessonNumber = 0,
    required this.isCurrentLesson,
    required this.isCompleted,
    required this.isLocked,
    required this.isDark,
    required this.onTap,
    this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Material(
      color: _getBackgroundColor(),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isCurrentLesson
                ? const Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: Opacity(
            opacity: isLocked ? 0.7 : 1.0,
            child: Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(locale),
                      const SizedBox(height: 4),
                      _buildSubtitle(),
                    ],
                  ),
                ),
                if (onDownloadTap != null && !isLocked) _buildDownloadButton(),
                if (lessonNumber > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$lessonNumber',
                    style: TextStyle(
                      color: isDark ? AppColors.grey500 : AppColors.grey400,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isCurrentLesson) {
      return AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.05);
    }
    return isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  }

  Widget _buildStatusIcon() {
    if (isCurrentLesson) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 14,
        ),
      );
    }

    if (isLocked) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.lock,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          size: 12,
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Icon(
        _getLessonTypeIcon(),
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        size: 12,
      ),
    );
  }

  IconData _getLessonTypeIcon() {
    switch (lesson.type) {
      case LessonType.video:
        return Icons.play_circle_outline;
      case LessonType.article:
        return Icons.description_outlined;
      case LessonType.quiz:
        return Icons.quiz_outlined;
      case LessonType.assignment:
        return Icons.assignment_outlined;
      case LessonType.resource:
        return Icons.folder_outlined;
      case LessonType.live:
        return Icons.live_tv_outlined;
      case LessonType.document:
        return Icons.insert_drive_file_outlined;
    }
  }

  Widget _buildTitle(String locale) {
    return Text(
      lesson.getTitle(locale),
      style: TextStyle(
        color: isCurrentLesson
            ? AppColors.primary
            : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
        fontSize: 14,
        fontWeight: isCurrentLesson ? FontWeight.bold : FontWeight.w500,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle() {
    return Row(
      children: [
        Text(
          lesson.durationInMinutes > 0
              ? '${lesson.durationInMinutes} ${'course_player.min'.tr()}'
              : '',
          style: TextStyle(
            color: isCurrentLesson
                ? AppColors.primary.withValues(alpha: 0.8)
                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            fontSize: 12,
          ),
        ),
        if (isCurrentLesson) ...[
          const SizedBox(width: 8),
          const Text('•', style: TextStyle(color: AppColors.primary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'course_player.playing'.tr().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadButton() {
    return IconButton(
      onPressed: onDownloadTap,
      icon: Icon(
        isCompleted ? Icons.download_done : Icons.download,
        color: isCompleted
            ? AppColors.primary
            : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
