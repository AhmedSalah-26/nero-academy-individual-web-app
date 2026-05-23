import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/features/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/my_learning/data/datasources/my_learning_remote_data_source.dart';
import 'package:lms_platform/features/my_learning/domain/entities/enrollment_entity.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('MyLearningRemoteDataSource integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final authDataSource = AuthRemoteDataSourceImpl(apiClient);
    final myLearningDataSource = MyLearningRemoteDataSourceImpl(apiClient);

    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    // 1. Register Instructor
    print('🔄 Registering instructor...');
    final instructor = await authDataSource.register(
      email: 'inst_mylearn_$uniqueId@example.com',
      password: 'secret123',
      name: 'Instructor $uniqueId',
      role: UserRole.instructor,
    );
    expect(instructor, isNotNull);

    // 2. Fetch category and level
    final categoriesResponse = await apiClient.get('/categories');
    final categoryId = categoriesResponse['categories'].first['id'] as String;
    final levelsResponse = await apiClient.get('/levels');
    final levelId = levelsResponse['levels'].first['id'] as String;

    // 3. Create course
    print('🔄 Creating course...');
    final courseResponse = await apiClient.post(
      '/courses',
      body: {
        'title_ar': 'كورس اختبار التعلم $uniqueId',
        'title_en': 'My Learning Test Course $uniqueId',
        'price': 150.0,
        'category_id': categoryId,
        'level_id': levelId,
      },
    );
    final courseId = courseResponse['course']['id'] as String;

    // 4. Create section under course
    print('🔄 Creating section...');
    final sectionResponse = await apiClient.post(
      '/courses/$courseId/sections',
      body: {
        'title_ar': 'القسم الأول',
        'title_en': 'Section One',
        'sort_order': 0,
      },
    );
    final sectionId = sectionResponse['section']['id'] as String;

    // 5. Create lesson one under section
    print('🔄 Creating lesson one...');
    final lessonResponse = await apiClient.post(
      '/sections/$sectionId/lessons',
      body: {
        'title_ar': 'الدرس الأول',
        'title_en': 'Lesson One',
        'type': 'video',
        'sort_order': 0,
        'duration_seconds': 300,
      },
    );
    final lessonId = lessonResponse['lesson']['id'] as String;

    // 5.5 Create lesson two under section
    print('🔄 Creating lesson two...');
    await apiClient.post(
      '/sections/$sectionId/lessons',
      body: {
        'title_ar': 'الدرس الثاني',
        'title_en': 'Lesson Two',
        'type': 'video',
        'sort_order': 1,
        'duration_seconds': 400,
      },
    );

    // 6. Register Student
    print('🔄 Registering student...');
    final student = await authDataSource.register(
      email: 'student_mylearn_$uniqueId@example.com',
      password: 'secret123',
      name: 'Student $uniqueId',
      role: UserRole.student,
    );
    expect(student, isNotNull);

    // 7. Perform Cart Checkout
    print('🔄 Checking out course...');
    final checkoutResponse = await apiClient.post(
      '/checkout',
      body: {
        'course_ids': [courseId],
      },
    );
    expect(checkoutResponse['success'], isTrue);
    final parentEnrollmentId = checkoutResponse['parent_enrollment']['id'] as String;

    // 8. Settle checkout payment (mocks enrollment activation)
    print('🔄 Settling payment...');
    final settleResponse = await apiClient.post(
      '/checkout/settle/$parentEnrollmentId',
    );
    expect(settleResponse['success'], isTrue);
    final enrollmentId = settleResponse['parent_enrollment']['enrollments'].first['id'] as String;
    print('✅ Enrollment activated: $enrollmentId');

    // 9. Verify getEnrollments
    print('🔄 Testing getEnrollments...');
    final enrollments = await myLearningDataSource.getEnrollments(userId: student.id);
    expect(enrollments, isNotEmpty);
    expect(enrollments.first.id, equals(enrollmentId));
    print('✅ getEnrollments succeeded: ${enrollments.length} found.');

    // 10. Verify getContinueLearning
    print('🔄 Testing getContinueLearning before progress...');
    final continueLearningBefore = await myLearningDataSource.getContinueLearning(student.id);
    expect(continueLearningBefore, isNull); // no progress yet

    // 11. Test updateLessonProgress
    print('🔄 Testing updateLessonProgress...');
    try {
      final progress = await myLearningDataSource.updateLessonProgress(
        enrollmentId: enrollmentId,
        lessonId: lessonId,
        watchedSeconds: 120,
        isCompleted: true,
      );
      expect(progress, isNotNull);
      expect(progress.watchedSeconds, equals(120));
      expect(progress.isCompleted, isTrue);
      print('✅ updateLessonProgress succeeded.');
    } catch (e) {
      fail('updateLessonProgress failed: $e');
    }

    // 12. Test getLessonProgress
    print('🔄 Testing getLessonProgress...');
    try {
      final progress = await myLearningDataSource.getLessonProgress(
        enrollmentId: enrollmentId,
        lessonId: lessonId,
      );
      expect(progress, isNotNull);
      expect(progress!.watchedSeconds, equals(120));
      print('✅ getLessonProgress succeeded.');
    } catch (e) {
      fail('getLessonProgress failed: $e');
    }

    // 13. Test getContinueLearning after progress
    print('🔄 Testing getContinueLearning after progress...');
    final continueLearningAfter = await myLearningDataSource.getContinueLearning(student.id);
    expect(continueLearningAfter, isNotNull);
    expect(continueLearningAfter!.id, equals(enrollmentId));
    print('✅ getContinueLearning returned current enrollment.');

    // 14. Test markCourseCompleted
    print('🔄 Testing markCourseCompleted...');
    try {
      final completedEnrollment = await myLearningDataSource.markCourseCompleted(enrollmentId);
      expect(completedEnrollment.status, equals(EnrollmentStatus.completed));
      print('✅ markCourseCompleted succeeded.');
    } catch (e) {
      fail('markCourseCompleted failed: $e');
    }
  });
}
