import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/course_model.dart';
import '../models/search_filter_model.dart';

/// Course Search Remote Data Source - Abstract
abstract class CourseSearchRemoteDataSource {
  Future<CourseSearchRemoteResult> searchCourses(SearchFilterModel filter);
  Future<List<CategoryModel>> getCategories();
  Future<List<String>> getPopularSearches();
}

/// Course Search Remote Result
class CourseSearchRemoteResult {
  final List<CourseModel> courses;
  final int totalCount;

  const CourseSearchRemoteResult({
    required this.courses,
    required this.totalCount,
  });
}

/// Course Search Remote Data Source Implementation
class CourseSearchRemoteDataSourceImpl implements CourseSearchRemoteDataSource {
  final ApiClient apiClient;

  CourseSearchRemoteDataSourceImpl(this.apiClient);

  @override
  Future<CourseSearchRemoteResult> searchCourses(
    SearchFilterModel filter,
  ) async {
    try {
      final queryParams = filter.toQueryParams();
      
      // Build query string safely
      final querySegments = <String>[];
      queryParams.forEach((key, value) {
        if (value != null) {
          querySegments.add('$key=${Uri.encodeComponent(value.toString())}');
        }
      });
      final queryString = querySegments.join('&');
      
      final response = await apiClient.get('/courses?$queryString');
      
      final coursesList = response['courses'] as List;
      final courses = coursesList.map((e) {
        final courseMap = Map<String, dynamic>.from(e as Map<String, dynamic>);
        
        // Ensure keys are correctly formatted for CourseModel
        final originalPrice = (courseMap['price'] as num?)?.toDouble() ?? 0.0;
        final discountPrice = (courseMap['discount_price'] as num?)?.toDouble();
        
        // CourseModel expects 'original_price' and 'price' key mapping
        if (discountPrice != null && discountPrice < originalPrice) {
          courseMap['original_price'] = originalPrice;
          courseMap['price'] = discountPrice;
        } else {
          courseMap['original_price'] = null;
          courseMap['price'] = originalPrice;
        }
        
        courseMap['duration_minutes'] = courseMap['total_duration'];
        courseMap['lecture_count'] = courseMap['total_lessons'];
        courseMap['review_count'] = courseMap['rating_count'];
        
        return CourseModel.fromJson(courseMap);
      }).toList();

      final totalCount = response['total_count'] as int? ?? 0;

      return CourseSearchRemoteResult(
        courses: courses,
        totalCount: totalCount,
      );
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.get('/categories');
      final categoriesList = response['categories'] as List;
      
      return categoriesList.map((e) {
        final json = Map<String, dynamic>.from(e as Map<String, dynamic>);
        json['name'] = json['name_ar'] ?? json['name_en'] ?? '';
        json['course_count'] = json['courses_count'] ?? 0;
        return CategoryModel.fromJson(json);
      }).toList();
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<String>> getPopularSearches() async {
    // Return standard popular searches since table is legacy / not used.
    return [
      'Flutter',
      'Dart',
      'PHP',
      'Laravel',
      'Clean Architecture',
      'UI/UX',
      'Mobile Development',
    ];
  }
}
