import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/portfolio_item_entity.dart';
import 'portfolio_empty_state.dart';

/// Portfolio Courses Tab Widget
class PortfolioCoursesTab extends StatelessWidget {
  final List<PortfolioItemEntity> courses;
  final ValueChanged<PortfolioItemEntity>? onTap;
  final VoidCallback? onBrowseCourses;
  final bool isDark;

  const PortfolioCoursesTab({
    super.key,
    required this.courses,
    this.onTap,
    this.onBrowseCourses,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return PortfolioEmptyState(
        title: 'No completed courses yet',
        subtitle: 'Complete your enrolled courses to see them here',
        icon: Icons.school_outlined,
        buttonText: 'my_learning.browse_courses'.tr(),
        onButtonPressed: onBrowseCourses,
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _buildCourseCard(courses[index]);
      },
    );
  }

  Widget _buildCourseCard(PortfolioItemEntity course) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onTap?.call(course),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildThumbnail(course),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCourseInfo(course, dateFormat),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(PortfolioItemEntity course) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey700 : AppColors.grey200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child:
            course.courseThumbnail != null && course.courseThumbnail!.isNotEmpty
                ? Image.network(
                    course.courseThumbnail!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: isDark ? AppColors.grey700 : AppColors.grey200,
      child: Icon(
        Icons.play_circle_outline,
        color: isDark ? AppColors.grey500 : AppColors.grey400,
        size: 28,
      ),
    );
  }

  Widget _buildCourseInfo(PortfolioItemEntity course, DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.courseTitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          course.instructorName,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.check_circle,
              size: 14,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              'Completed ${dateFormat.format(course.completedAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
