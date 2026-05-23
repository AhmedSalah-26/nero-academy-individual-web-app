import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../models/instructor_models.dart';

/// Instructor Reviews Data Source - Reviews management
class InstructorReviewsDataSource {
  final ApiClient _apiClient;
  static const _tag = 'InstructorReviewsDS';

  InstructorReviewsDataSource(this._apiClient);

  List<dynamic> _asList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      final reviews = response['reviews'];
      if (reviews is List) return reviews;
    }
    return const [];
  }

  /// Get reviews
  Future<List<InstructorReviewModel>> getReviews({
    String? courseId,
    int? minRating,
    int? maxRating,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getReviews: courseId=$courseId, page=$page');
    try {
      final queryParams = <String>[];
      if (courseId != null) queryParams.add('courseId=$courseId');
      if (minRating != null) queryParams.add('minRating=$minRating');
      if (maxRating != null) queryParams.add('maxRating=$maxRating');
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');

      final url = '/instructor/reviews?${queryParams.join('&')}';
      final response = await _apiClient.get(url);

      final list = _asList(response);
      AppLogger.success('[$_tag] getReviews: ${list.length} reviews');
      return list.map((e) => InstructorReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getReviews error', e, s);
      rethrow;
    }
  }

  /// Reply to a review
  Future<bool> replyToReview(String reviewId, String reply) async {
    AppLogger.d('[$_tag] replyToReview: reviewId=$reviewId');
    try {
      await _apiClient.post(
        '/instructor/reviews/$reviewId/reply',
        body: {'reply': reply},
      );
      AppLogger.success('[$_tag] replyToReview success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] replyToReview error', e, s);
      rethrow;
    }
  }
}
