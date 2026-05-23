import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/instructor_entity.dart';
import '../../domain/entities/instructor_course_entity.dart';

abstract class InstructorRemoteDataSource {
  Future<InstructorEntity?> getInstructor(String visitorId);
  Future<List<InstructorCourseEntity>> getInstructorCourses(String visitorId);
  Future<List<InstructorEntity>> getTopInstructors({int limit = 10});
}

class InstructorRemoteDataSourceImpl implements InstructorRemoteDataSource {
  final ApiClient apiClient;

  InstructorRemoteDataSourceImpl(this.apiClient);

  @override
  Future<InstructorEntity?> getInstructor(String visitorId) async {
    try {
      final response = await apiClient.get('/instructors/$visitorId');
      if (response['instructor'] == null) return null;
      return _mapToInstructorEntity(response['instructor'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<InstructorCourseEntity>> getInstructorCourses(
      String visitorId) async {
    try {
      final response = await apiClient.get('/instructors/$visitorId/courses');
      final coursesList = response['courses'] as List;
      return coursesList.map((e) {
        final row = e as Map<String, dynamic>;
        return InstructorCourseEntity(
          id: row['id'] as String,
          title: row['title'] as String? ?? '',
          titleAr: row['title_ar'] as String?,
          thumbnailUrl: row['thumbnail_url'] as String?,
          price: (row['price'] as num?)?.toDouble() ?? 0.0,
          discountPrice: (row['discount_price'] as num?)?.toDouble(),
          isFlashSale: row['is_flash_sale'] == true,
          flashSaleStart: row['flash_sale_start'] != null
              ? DateTime.tryParse(row['flash_sale_start'].toString())
              : null,
          flashSaleEnd: row['flash_sale_end'] != null
              ? DateTime.tryParse(row['flash_sale_end'].toString())
              : null,
          currency: row['currency'] as String? ?? 'EGP',
          rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
          ratingCount: row['rating_count'] as int? ?? 0,
          enrolledCount: row['enrolled_count'] as int? ?? 0,
          isFree: row['is_free'] == true,
          isBestseller: (row['enrolled_count'] as int? ?? 0) > 100,
        );
      }).toList();
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<InstructorEntity>> getTopInstructors({int limit = 10}) async {
    try {
      final response = await apiClient.get('/instructors/top?limit=$limit');
      final instructorsList = response['instructors'] as List;
      return instructorsList
          .map((e) => _mapToInstructorEntity(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  InstructorEntity _mapToInstructorEntity(Map<String, dynamic> data) {
    return InstructorEntity(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Instructor',
      avatarUrl: data['avatar_url'] as String?,
      coverImageUrl: data['cover_image_url'] as String?,
      headline: data['headline'] as String?,
      bio: data['bio'] as String?,
      expertise: data['expertise'] != null
          ? List<String>.from(data['expertise'] as List)
          : null,
      totalStudents: data['total_students'] as int? ?? 0,
      totalCourses: data['total_courses'] as int? ?? 0,
      averageRating: (data['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['total_reviews'] as int? ?? 0,
      website: data['website_url'] as String?,
      linkedin: data['linkedin'] as String?,
      twitter: data['twitter'] as String?,
      facebook: data['facebook'] as String?,
      youtube: data['youtube'] as String?,
      joinedAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'] as String)
          : null,
    );
  }
}
