import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/course_details_model.dart';
import '../models/section_model.dart';
import '../models/review_model.dart';

/// Course Details Remote Data Source - API calls
abstract class CourseDetailsRemoteDataSource {
  Future<CourseDetailsModel> getCourseDetails(String courseId,
      {String? userId});
  Future<List<SectionModel>> getCourseCurriculum(String courseId,
      {String? userId});
  Future<List<ReviewModel>> getCourseReviews(String courseId,
      {int page, int limit, String? sortBy});
  Future<RatingSummaryModel> getRatingSummary(String courseId);
  Future<bool> toggleWishlist(String courseId, String userId);
  Future<bool> isInWishlist(String courseId, String userId);
  Future<bool> isInCart(String courseId, String userId);
}

class CourseDetailsRemoteDataSourceImpl
    implements CourseDetailsRemoteDataSource {
  final ApiClient apiClient;

  CourseDetailsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<CourseDetailsModel> getCourseDetails(String courseId,
      {String? userId}) async {
    try {
      final response = await apiClient.get('/courses/$courseId');
      return CourseDetailsModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<SectionModel>> getCourseCurriculum(String courseId,
      {String? userId}) async {
    try {
      final response = await apiClient.get('/courses/$courseId');
      final sections = response['sections'] as List;
      return sections
          .map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ReviewModel>> getCourseReviews(String courseId,
      {int page = 1, int limit = 10, String? sortBy}) async {
    try {
      final response = await apiClient.get(
        '/courses/$courseId/reviews?page=$page&limit=$limit&sort_by=${sortBy ?? 'created_at'}',
      );
      final reviews = response['reviews'] as List;
      return reviews
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RatingSummaryModel> getRatingSummary(String courseId) async {
    try {
      final response = await apiClient.get('/courses/$courseId/reviews/summary');
      return RatingSummaryModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> toggleWishlist(String courseId, String userId) async {
    try {
      final inWishlist = await isInWishlist(courseId, userId);
      if (inWishlist) {
        await apiClient.delete('/wishlist/course/$courseId');
        return false;
      } else {
        await apiClient.post('/wishlist', body: {'course_id': courseId});
        return true;
      }
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> isInWishlist(String courseId, String userId) async {
    try {
      final response = await apiClient.get('/wishlist');
      final wishlist = response['wishlist'] as List;
      return wishlist.any((element) => element['course_id'] == courseId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isInCart(String courseId, String userId) async {
    try {
      final response = await apiClient.get('/cart');
      final items = response['items'] as List;
      return items.any((element) => element['course_id'] == courseId);
    } catch (e) {
      return false;
    }
  }
}
