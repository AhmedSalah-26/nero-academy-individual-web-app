import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/features/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/wishlist/data/datasources/wishlist_remote_data_source.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('WishlistRemoteDataSource integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final authDataSource = AuthRemoteDataSourceImpl(apiClient);
    final wishlistDataSource = WishlistRemoteDataSourceImpl(apiClient: apiClient);

    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    // 1. Register an Instructor to create a course
    print('🔄 Registering instructor...');
    final instructor = await authDataSource.register(
      email: 'instructor_$uniqueId@example.com',
      password: 'secret123',
      name: 'Instructor $uniqueId',
      role: UserRole.instructor,
    );
    expect(instructor, isNotNull);
    print('✅ Instructor registered.');

    // 2. Fetch categories to get a valid category ID
    print('🔄 Fetching categories...');
    final categoriesResponse = await apiClient.get('/categories');
    final categoriesList = categoriesResponse['categories'] as List;
    expect(categoriesList, isNotEmpty);
    final categoryId = categoriesList.first['id'] as String;
    print('✅ Got category ID: $categoryId');

    // 2.5 Fetch levels to get a valid level ID
    print('🔄 Fetching levels...');
    final levelsResponse = await apiClient.get('/levels');
    final levelsList = levelsResponse['levels'] as List;
    expect(levelsList, isNotEmpty);
    final levelId = levelsList.first['id'] as String;
    print('✅ Got level ID: $levelId');

    // 3. Create a course
    print('🔄 Creating course...');
    final courseResponse = await apiClient.post(
      '/courses',
      body: {
        'title_ar': 'كورس اختبار المفضلة $uniqueId',
        'title_en': 'Wishlist Test Course $uniqueId',
        'price': 100.0,
        'category_id': categoryId,
        'level_id': levelId,
      },
    );
    expect(courseResponse['success'], isTrue);
    final courseId = courseResponse['course']['id'] as String;
    print('✅ Course created with ID: $courseId');

    // 4. Register a Student
    print('🔄 Registering student...');
    final student = await authDataSource.register(
      email: 'student_wishlist_$uniqueId@example.com',
      password: 'secret123',
      name: 'Student $uniqueId',
      role: UserRole.student,
    );
    expect(student, isNotNull);
    print('✅ Student registered.');

    // 5. Test addToWishlist
    print('🔄 Adding course to wishlist...');
    try {
      final wishlistItem = await wishlistDataSource.addToWishlist(student.id, courseId);
      expect(wishlistItem, isNotNull);
      expect(wishlistItem.courseId, equals(courseId));
      print('✅ Course added to wishlist.');
    } catch (e) {
      fail('addToWishlist failed: $e');
    }

    // 6. Test getWishlist
    print('🔄 Fetching wishlist...');
    try {
      final wishlist = await wishlistDataSource.getWishlist(student.id);
      expect(wishlist, isNotEmpty);
      expect(wishlist.first.courseId, equals(courseId));
      print('✅ Fetch wishlist succeeded: ${wishlist.length} items.');
    } catch (e) {
      fail('getWishlist failed: $e');
    }

    // 7. Test isInWishlist
    print('🔄 Checking isInWishlist...');
    try {
      final inWishlist = await wishlistDataSource.isInWishlist(student.id, courseId);
      expect(inWishlist, isTrue);
      print('✅ isInWishlist verified.');
    } catch (e) {
      fail('isInWishlist failed: $e');
    }

    // 8. Test removeFromWishlistByCourseId
    print('🔄 Removing course from wishlist...');
    try {
      await wishlistDataSource.removeFromWishlistByCourseId(student.id, courseId);
      final inWishlist = await wishlistDataSource.isInWishlist(student.id, courseId);
      expect(inWishlist, isFalse);
      print('✅ Removed course from wishlist succeeded.');
    } catch (e) {
      fail('removeFromWishlistByCourseId failed: $e');
    }
  });
}
