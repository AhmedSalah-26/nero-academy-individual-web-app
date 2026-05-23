import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../../../core/services/app_logger.dart';
import '../../../domain/entities/review_entity.dart';
import 'rating_widgets.dart';

/// Rating Section Widget - Allows users to rate and review the course
class RatingSection extends StatefulWidget {
  final bool isDark;
  final String courseId;
  final String enrollmentId;

  const RatingSection({
    super.key,
    required this.isDark,
    required this.courseId,
    required this.enrollmentId,
  });

  @override
  State<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<RatingSection> {
  final _reviewController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;
  bool _hasExistingRating = false;
  int? _existingRating;
  String? _existingReview;

  // Reviews data
  List<ReviewEntity> _reviews = [];
  bool _isLoadingReviews = false;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  double _averageRating = 0;
  int _totalReviews = 0;
  bool _showWriteReview = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
    _loadAllReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadAllReviews() async {
    AppLogger.i(
        '⭐ [RatingSection] Loading all reviews for course: ${widget.courseId}');
    setState(() => _isLoadingReviews = true);

    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/courses/${widget.courseId}/reviews');

      if (mounted) {
        final rawList = response is List
            ? response
            : (response['reviews'] ?? response['data'] ?? []) as List;

        final reviews = rawList.map((json) {
          return ReviewEntity.fromJson(json as Map<String, dynamic>);
        }).toList();

        // Calculate statistics
        final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        for (var review in reviews) {
          distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
        }

        final total = reviews.length;
        final average = total > 0
            ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / total
            : 0.0;

        setState(() {
          _reviews = reviews;
          _ratingDistribution = distribution;
          _totalReviews = total;
          _averageRating = average;
        });

        AppLogger.success('[RatingSection] Loaded ${reviews.length} reviews');
      }
    } catch (e) {
      AppLogger.e('[RatingSection] Error loading reviews: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _loadExistingRating() async {
    AppLogger.i(
        '⭐ [RatingSection] Loading existing rating for course: ${widget.courseId}');
    setState(() => _isLoading = true);

    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/courses/${widget.courseId}/my-review');

      if (response != null && response['rating'] != null && mounted) {
        AppLogger.success(
            '[RatingSection] Found existing rating: ${response['rating']} stars');
        setState(() {
          _hasExistingRating = true;
          _existingRating = response['rating'] as int?;
          _existingReview = response['review'] as String?;
          _rating = _existingRating ?? 0;
          _reviewController.text = _existingReview ?? '';
        });
      } else {
        AppLogger.i('[RatingSection] No existing rating found');
      }
    } catch (e) {
      AppLogger.e('[RatingSection] Error loading rating: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      AppLogger.w('[RatingSection] Rating is 0, cannot submit');
      ToastUtils.showError('يرجى اختيار تقييم');
      return;
    }

    AppLogger.i(
        '⭐ [RatingSection] Submitting rating: $_rating stars for course: ${widget.courseId}');
    setState(() => _isLoading = true);

    try {
      final apiClient = sl<ApiClient>();
      final reviewText = _reviewController.text.trim();

      final body = {
        'rating': _rating,
        'review': reviewText.isEmpty ? null : reviewText,
      };

      if (_hasExistingRating) {
        // Update existing rating
        AppLogger.i('[RatingSection] Updating existing rating');
        await apiClient.put('/courses/${widget.courseId}/reviews', body: body);
        AppLogger.success('[RatingSection] Rating updated successfully');
      } else {
        // Insert new rating
        AppLogger.i('[RatingSection] Inserting new rating');
        await apiClient.post('/courses/${widget.courseId}/reviews', body: body);
        AppLogger.success('[RatingSection] Rating inserted successfully');
      }

      if (mounted) {
        ToastUtils.showSuccess('course_player.rating_submitted'.tr());
        setState(() {
          _hasExistingRating = true;
          _existingRating = _rating;
          _existingReview = reviewText;
          _showWriteReview = false;
        });
        AppLogger.i('[RatingSection] UI updated with new rating');
        // Reload all reviews to show the new one
        _loadAllReviews();
      }
    } catch (e) {
      AppLogger.e('[RatingSection] Error submitting rating: $e');
      if (mounted) {
        ToastUtils.showError('حدث خطأ أثناء إرسال التقييم');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_hasExistingRating) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Overview (Amazon style)
          RatingOverview(
            averageRating: _averageRating,
            totalReviews: _totalReviews,
            ratingDistribution: _ratingDistribution,
            isDark: widget.isDark,
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Write Review Button or Form
          if (!_showWriteReview)
            _buildWriteReviewButton()
          else
            WriteReviewForm(
              rating: _rating,
              reviewController: _reviewController,
              hasExistingRating: _hasExistingRating,
              isLoading: _isLoading,
              isDark: widget.isDark,
              onRatingChanged: (rating) => setState(() => _rating = rating),
              onSubmit: _submitRating,
              onCancel: () => setState(() => _showWriteReview = false),
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Reviews List
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildWriteReviewButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _showWriteReview = true;
          });
        },
        icon: const Icon(Icons.edit_outlined),
        label: Text(
          _hasExistingRating
              ? 'course_player.update_rating'.tr()
              : 'course_player.rate_course'.tr(),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoadingReviews) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'لا توجد تقييمات بعد',
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ),
      );
    }

    // Using current user check to highlight own reviews - no auth call needed (removed)
    const currentUserId = null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التقييمات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.isDark
                ? AppColors.textMainDark
                : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 16),
        ..._reviews.map((review) => ReviewCard(
              review: review,
              isDark: widget.isDark,
              isCurrentUser: currentUserId == review.userId,
            )),
      ],
    );
  }
}
