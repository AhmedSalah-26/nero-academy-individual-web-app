import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/features/home/data/datasources/home_remote_data_source.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('HomeRemoteDataSource integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final dataSource = HomeRemoteDataSourceImpl(apiClient);

    // 1. Test getBanners
    print('🔄 Testing getBanners...');
    try {
      final banners = await dataSource.getBanners();
      expect(banners, isNotNull);
      expect(banners, isList);
      print('✅ getBanners succeeded: ${banners.length} banners fetched.');
    } catch (e) {
      fail('getBanners failed: $e');
    }

    // 2. Test getCategories
    print('🔄 Testing getCategories...');
    try {
      final categories = await dataSource.getCategories();
      expect(categories, isNotNull);
      expect(categories, isList);
      print('✅ getCategories succeeded: ${categories.length} categories fetched.');
    } catch (e) {
      fail('getCategories failed: $e');
    }

    // 3. Test getFeaturedCourses
    print('🔄 Testing getFeaturedCourses...');
    try {
      final courses = await dataSource.getFeaturedCourses();
      expect(courses, isNotNull);
      expect(courses, isList);
      print('✅ getFeaturedCourses succeeded: ${courses.length} courses fetched.');
    } catch (e) {
      fail('getFeaturedCourses failed: $e');
    }

    // 4. Test getPopularCourses
    print('🔄 Testing getPopularCourses...');
    try {
      final courses = await dataSource.getPopularCourses();
      expect(courses, isNotNull);
      expect(courses, isList);
      print('✅ getPopularCourses succeeded: ${courses.length} courses fetched.');
    } catch (e) {
      fail('getPopularCourses failed: $e');
    }
  });
}
