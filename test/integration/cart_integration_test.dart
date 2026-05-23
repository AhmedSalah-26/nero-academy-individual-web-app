import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/features/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:lms_platform/features/cart/domain/entities/payment_method_entity.dart';
import 'package:lms_platform/features/cart/domain/entities/order_entity.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('CartRemoteDataSource integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final authDataSource = AuthRemoteDataSourceImpl(apiClient);
    final cartDataSource = CartRemoteDataSourceImpl(apiClient: apiClient);

    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    // 1. Register an Instructor to create a course
    print('🔄 Registering instructor...');
    final instructor = await authDataSource.register(
      email: 'instructor_cart_$uniqueId@example.com',
      password: 'secret123',
      name: 'Instructor Cart $uniqueId',
      role: UserRole.instructor,
    );
    expect(instructor, isNotNull);
    print('✅ Instructor registered.');

    // 2. Fetch categories & levels to get valid IDs
    print('🔄 Fetching categories and levels...');
    final categoriesResponse = await apiClient.get('/categories');
    final categoriesList = categoriesResponse['categories'] as List;
    expect(categoriesList, isNotEmpty);
    final categoryId = categoriesList.first['id'] as String;

    final levelsResponse = await apiClient.get('/levels');
    final levelsList = levelsResponse['levels'] as List;
    expect(levelsList, isNotEmpty);
    final levelId = levelsList.first['id'] as String;

    // 3. Create a course
    print('🔄 Creating course...');
    final courseResponse = await apiClient.post(
      '/courses',
      body: {
        'title_ar': 'كورس اختبار السلة $uniqueId',
        'title_en': 'Cart Test Course $uniqueId',
        'price': 200.0,
        'category_id': categoryId,
        'level_id': levelId,
      },
    );
    expect(courseResponse['success'], isTrue);
    final courseId = courseResponse['course']['id'] as String;
    print('✅ Course created with ID: $courseId');

    // Publish the course so it is public
    print('🔄 Publishing course...');
    final publishResponse = await apiClient.post('/instructor/courses/$courseId/publish');
    expect(publishResponse['success'], isTrue);
    print('✅ Course published.');

    // 4. Register a Student
    print('🔄 Registering student...');
    final student = await authDataSource.register(
      email: 'student_cart_$uniqueId@example.com',
      password: 'secret123',
      name: 'Student Cart $uniqueId',
      role: UserRole.student,
    );
    expect(student, isNotNull);
    print('✅ Student registered.');

    // 5. Check Initial Cart Count
    print('🔄 Checking initial cart count...');
    final initialCount = await cartDataSource.getCartCount(student.id);
    expect(initialCount, equals(0));
    print('✅ Initial cart count is 0.');

    // 6. Add Course to Cart
    print('🔄 Adding course to cart...');
    final cartItem = await cartDataSource.addToCart(student.id, courseId);
    expect(cartItem, isNotNull);
    expect(cartItem.courseId, equals(courseId));
    expect(cartItem.price, equals(200.0));
    print('✅ Course added to cart successfully.');

    // 7. Check Cart Count and Get Cart
    print('🔄 Checking cart count and details...');
    final count = await cartDataSource.getCartCount(student.id);
    expect(count, equals(1));

    final cart = await cartDataSource.getCart(student.id);
    expect(cart.items, isNotEmpty);
    expect(cart.items.first.courseId, equals(courseId));
    print('✅ Cart count is 1, and getCart returned correct item details.');

    // 8. Try adding the same course again
    print('🔄 Trying to add same course again...');
    final addedAgain = await cartDataSource.addToCart(student.id, courseId);
    expect(addedAgain, isNotNull);
    // Since our backend returns the already existing cart item if it exists
    expect(addedAgain.courseId, equals(courseId));
    print('✅ Handled duplicate add to cart gracefully.');

    // 9. Remove from Cart
    print('🔄 Removing item from cart...');
    await cartDataSource.removeFromCart(student.id, cartItem.id);
    final countAfterRemove = await cartDataSource.getCartCount(student.id);
    expect(countAfterRemove, equals(0));
    print('✅ Course removed. Cart is empty again.');

    // 10. Re-add and Clear Cart
    print('🔄 Re-adding course then clearing cart...');
    await cartDataSource.addToCart(student.id, courseId);
    await cartDataSource.clearCart(student.id);
    final countAfterClear = await cartDataSource.getCartCount(student.id);
    expect(countAfterClear, equals(0));
    print('✅ Cart cleared successfully.');

    // 11. Re-add and Checkout
    print('🔄 Re-adding course for checkout...');
    await cartDataSource.addToCart(student.id, courseId);
    
    print('🔄 Checking out cart...');
    final order = await cartDataSource.checkout(
      userId: student.id,
      paymentMethod: PaymentMethodType.card,
    );
    expect(order, isNotNull);
    expect(order.total, equals(200.0));
    expect(order.status, equals(OrderStatus.completed));
    print('✅ Checkout succeeded. Order ID: ${order.id}');

    // 12. Verify Cart is Empty after checkout
    final finalCount = await cartDataSource.getCartCount(student.id);
    expect(finalCount, equals(0));
    print('✅ Cart verified empty after checkout.');

    // 13. Get recommended courses
    print('🔄 Fetching recommended courses...');
    final recommendations = await cartDataSource.getRecommendedCourses(student.id, 5);
    expect(recommendations, isNotEmpty);
    print('✅ Recommendations fetched successfully. Count: ${recommendations.length}');
  });
}
