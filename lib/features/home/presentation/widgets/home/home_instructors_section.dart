import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../instructor/domain/entities/instructor_entity.dart';

/// Home Instructors Section - Displays top instructors
class HomeInstructorsSection extends StatefulWidget {
  final List<InstructorEntity> instructors;

  const HomeInstructorsSection({
    super.key,
    required this.instructors,
  });

  @override
  State<HomeInstructorsSection> createState() => _HomeInstructorsSectionState();
}

class _HomeInstructorsSectionState extends State<HomeInstructorsSection> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant HomeInstructorsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.instructors.length) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.instructors.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'home.top_instructors'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Instructors Slider (center-focused, auto-play)
        SizedBox(
          height: 308,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CarouselSlider.builder(
              itemCount: widget.instructors.length,
              itemBuilder: (context, index, realIndex) {
                return _InstructorCard(
                  instructor: widget.instructors[index],
                  isDark: isDark,
                  isCenter: index == _currentIndex,
                );
              },
              options: CarouselOptions(
                height: 308,
                viewportFraction: widget.instructors.length == 1 ? 0.74 : 0.58,
                enlargeCenterPage: true,
                enlargeFactor: 0.14,
                autoPlay: widget.instructors.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 750),
                autoPlayCurve: Curves.easeInOutCubic,
                enableInfiniteScroll: widget.instructors.length > 1,
                pauseAutoPlayOnTouch: true,
                onPageChanged: (index, reason) {
                  if (!mounted) return;
                  setState(() => _currentIndex = index);
                },
              ),
            ),
          ),
        ),
        if (widget.instructors.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.instructors.length, (index) {
              final active = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _InstructorCard extends StatelessWidget {
  final InstructorEntity instructor;
  final bool isDark;
  final bool isCenter;

  const _InstructorCard({
    required this.instructor,
    required this.isDark,
    required this.isCenter,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        AppRouter.goToInstructor(context, instructor.id);
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isCenter ? 12 : 18,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              isDark ? Border.all(color: AppColors.borderDark, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.1),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top gradient section with avatar
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Decorative circles
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    left: -15,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Avatar positioned to overlap
                  Positioned(
                    bottom: -45,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.cardDark : AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: ClipOval(
                            child: instructor.avatarUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: instructor.avatarUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => _buildPlaceholder(),
                                    errorWidget: (_, __, ___) =>
                                        _buildPlaceholder(),
                                  )
                                : _buildPlaceholder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Verified badge (show for high-rated instructors)
                  if (instructor.averageRating >= 4.5)
                    Positioned(
                      bottom: -35,
                      right: 45,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? AppColors.cardDark : AppColors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 50, 10, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      instructor.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    // Headline
                    if (instructor.headline != null)
                      Text(
                        instructor.headline!,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    // Stats Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.grey800.withValues(alpha: 0.5)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            Icons.star_rounded,
                            instructor.averageRating.toStringAsFixed(1),
                            AppColors.warning,
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color:
                                isDark ? AppColors.grey700 : AppColors.grey300,
                          ),
                          _buildStatItem(
                            Icons.people_rounded,
                            _formatNumber(instructor.totalStudents),
                            AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.grey200,
      child: const Icon(
        Icons.person_rounded,
        size: 40,
        color: AppColors.grey400,
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
