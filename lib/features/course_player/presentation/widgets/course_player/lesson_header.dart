import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/lesson_entity.dart';
import '../../../domain/entities/section_entity.dart';

/// Lesson Header Widget
class LessonHeader extends StatelessWidget {
  final LessonEntity lesson;
  final SectionEntity? section;
  final int sectionIndex;
  final int lessonIndex;
  final bool isDark;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;
  final String? instructorName;
  final String? instructorAvatar;
  final VoidCallback? onInstructorTap;
  final VoidCallback? onHeaderTap;

  const LessonHeader({
    super.key,
    required this.lesson,
    this.section,
    required this.sectionIndex,
    required this.lessonIndex,
    required this.isDark,
    this.isBookmarked = false,
    this.onBookmarkTap,
    this.instructorName,
    this.instructorAvatar,
    this.onInstructorTap,
    this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onHeaderTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section & Lesson number with bookmark icon
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${'course_player.section'.tr()} ${sectionIndex + 1} • ${'course_player.lesson'.tr()} ${lessonIndex + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Bookmark icon
                    if (onBookmarkTap != null)
                      IconButton(
                        onPressed: onBookmarkTap,
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight),
                        ),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Lesson title
                Text(
                  lesson.getTitle(locale),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // Description
          if (lesson.getDescription(locale) != null) ...[
            const SizedBox(height: 8),
            Text(
              lesson.getDescription(locale)!,
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Instructor Card
          if (instructorName != null && instructorName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInstructorCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructorCard() {
    return GestureDetector(
      onTap: onInstructorTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: instructorAvatar != null && instructorAvatar!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: instructorAvatar!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                instructorName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.verified,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
