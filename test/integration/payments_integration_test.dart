import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/features/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/payments_history/data/datasources/payments_remote_data_source.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('PaymentsRemoteDataSource integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final authDataSource = AuthRemoteDataSourceImpl(apiClient);
    final paymentsDataSource = PaymentsRemoteDataSourceImpl(apiClient: apiClient);

    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    // 1. Register an Instructor to create a course
    print('🔄 Registering instructor...');
    final instructor = await authDataSource.register(
      email: 'instructor_payment_$uniqueId@example.com',
      password: 'secret123',
      name: 'Instructor $uniqueId',
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
    print('✅ Got category ID: $categoryId, level ID: $levelId');

    // 3. Create a course
    print('🔄 Creating course...');
    final courseResponse = await apiClient.post(
      '/courses',
      body: {
        'title_ar': 'كورس اختبار الدفع $uniqueId',
        'title_en': 'Payment Test Course $uniqueId',
        'price': 150.0,
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
      email: 'student_payment_$uniqueId@example.com',
      password: 'secret123',
      name: 'Student $uniqueId',
      role: UserRole.student,
    );
    expect(student, isNotNull);
    print('✅ Student registered.');

    // 5. Perform Checkout (Create Parent Enrollment)
    print('🔄 Checking out course...');
    final checkoutResponse = await apiClient.post(
      '/checkout',
      body: {
        'course_ids': [courseId],
      },
    );
    expect(checkoutResponse['success'], isTrue);
    final parentEnrollment = checkoutResponse['parent_enrollment'];
    expect(parentEnrollment, isNotNull);
    final parentEnrollmentId = parentEnrollment['id'] as String;
    print('✅ Checkout succeeded. Parent Enrollment ID: $parentEnrollmentId');

    // 6. Verify payment history lists the pending payment
    print('🔄 Fetching payment history (expecting pending)...');
    try {
      final payments = await paymentsDataSource.getUserPayments(student.id);
      expect(payments, isNotEmpty);
      expect(payments.first.id, equals(parentEnrollmentId));
      expect(payments.first.paymentStatus, equals('pending'));
      expect(payments.first.courses.first.courseId, equals(courseId));
      print('✅ Payment history verification succeeded.');
    } catch (e) {
      fail('getUserPayments failed: $e');
    }

    // 7. Settle/Complete Payment (Callback)
    print('🔄 Settling payment...');
    final settleResponse = await apiClient.post(
      '/checkout/settle/$parentEnrollmentId',
      body: {
        'transaction_id': 'TXN-$uniqueId',
      },
    );
    expect(settleResponse['success'], isTrue);
    print('✅ Payment settled successfully.');

    // 8. Verify payment history updates to paid
    print('🔄 Fetching payment history again (expecting paid)...');
    try {
      final payments = await paymentsDataSource.getUserPayments(student.id);
      expect(payments, isNotEmpty);
      final payment = payments.firstWhere((p) => p.id == parentEnrollmentId);
      expect(payment.paymentStatus, equals('paid'));
      expect(payment.transactionId, equals('TXN-$uniqueId'));
      print('✅ Payment status updated to paid successfully.');
    } catch (e) {
      fail('getUserPayments updated status failed: $e');
    }

    // 9. Fetch specific payment by ID
    print('🔄 Fetching specific payment by ID...');
    try {
      final payment = await paymentsDataSource.getPaymentById(parentEnrollmentId);
      expect(payment, isNotNull);
      expect(payment!.id, equals(parentEnrollmentId));
      expect(payment.paymentStatus, equals('paid'));
      expect(payment.courses.first.title, contains('Payment Test Course'));
      print('✅ Fetching payment by ID succeeded.');
    } catch (e) {
      fail('getPaymentById failed: $e');
    }
  });
}
