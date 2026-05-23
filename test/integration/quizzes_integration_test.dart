import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/features/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/quizzes/data/datasources/quizzes_remote_data_source.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('QuizzesRemoteDataSource integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final authDataSource = AuthRemoteDataSourceImpl(apiClient);
    final quizzesDataSource = QuizzesRemoteDataSourceImpl(apiClient: apiClient);

    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    // 1. Register Instructor
    print('🔄 Registering instructor...');
    final instructor = await authDataSource.register(
      email: 'inst_quiz_$uniqueId@example.com',
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
        'title_ar': 'كورس اختبار الامتحانات $uniqueId',
        'title_en': 'Quizzes Test Course $uniqueId',
        'price': 100.0,
        'category_id': categoryId,
        'level_id': levelId,
      },
    );
    final courseId = courseResponse['course']['id'] as String;

    // 4. Create Quiz under course
    print('🔄 Creating quiz...');
    final quizResponse = await apiClient.post(
      '/quizzes',
      body: {
        'course_id': courseId,
        'title_ar': 'اختبار فلاتر للمبتدئين',
        'title_en': 'Flutter Quiz',
        'passing_score': 50,
        'max_attempts': 3,
        'questions': [
          {
            'question_ar': 'ما هي لغة برمجة فلاتر؟',
            'question_en': 'What language does Flutter use?',
            'question_type': 'single',
            'points': 10,
            'options': [
              {'id': 'opt_dart_$uniqueId', 'text_ar': 'دارت', 'text_en': 'Dart', 'is_correct': true},
              {'id': 'opt_java_$uniqueId', 'text_ar': 'جافا', 'text_en': 'Java', 'is_correct': false}
            ]
          }
        ]
      },
    );
    expect(quizResponse['success'], isTrue);
    final quizId = quizResponse['quiz']['id'] as String;
    print('✅ Quiz created with ID: $quizId');

    // 5. Register Student
    print('🔄 Registering student...');
    final student = await authDataSource.register(
      email: 'student_quiz_$uniqueId@example.com',
      password: 'secret123',
      name: 'Student $uniqueId',
      role: UserRole.student,
    );
    expect(student, isNotNull);

    // 6. Buy course to create enrollment
    print('🔄 Buying course...');
    final checkoutResponse = await apiClient.post(
      '/checkout',
      body: {
        'course_ids': [courseId],
      },
    );
    final parentId = checkoutResponse['parent_enrollment']['id'] as String;
    final settleResponse = await apiClient.post('/checkout/settle/$parentId');
    final enrollmentId = settleResponse['parent_enrollment']['enrollments'].first['id'] as String;
    print('✅ Enrollment created: $enrollmentId');

    // 7. Get course quizzes
    print('🔄 Fetching course quizzes...');
    final quizzes = await quizzesDataSource.getCourseQuizzes(courseId: courseId);
    expect(quizzes, isNotEmpty);
    expect(quizzes.first.id, equals(quizId));
    expect(quizzes.first.totalQuestions, equals(1));
    print('✅ Course quizzes fetched.');

    // 8. Get quiz details
    print('🔄 Fetching quiz details...');
    final quiz = await quizzesDataSource.getQuiz(quizId: quizId);
    expect(quiz.titleAr, equals('اختبار فلاتر للمبتدئين'));
    expect(quiz.passingScore, equals(50));

    // 9. Get quiz questions
    print('🔄 Fetching quiz questions...');
    final questions = await quizzesDataSource.getQuizQuestions(quizId: quizId);
    expect(questions, isNotEmpty);
    expect(questions.first.options, isNotEmpty);
    final questionId = questions.first.id;
    print('✅ Quiz questions fetched.');

    // 10. Check remaining attempts
    print('🔄 Checking remaining attempts...');
    var remaining = await quizzesDataSource.getRemainingAttempts(quizId: quizId, enrollmentId: enrollmentId);
    expect(remaining, equals(3));

    // 11. Start quiz attempt
    print('🔄 Starting quiz attempt...');
    final attempt = await quizzesDataSource.startQuizAttempt(quizId: quizId, enrollmentId: enrollmentId);
    expect(attempt, isNotNull);
    expect(attempt.quizId, equals(quizId));
    expect(attempt.passed, isFalse);
    final attemptId = attempt.id;
    print('✅ Quiz attempt started with ID: $attemptId');

    // 12. Submit quiz (with correct option)
    print('🔄 Submitting quiz...');
    final submittedAttempt = await quizzesDataSource.submitQuiz(
      attemptId: attemptId,
      answers: {
        questionId: ['opt_dart_$uniqueId'],
      },
      timeSpentSeconds: 45,
    );
    expect(submittedAttempt.passed, isTrue);
    expect(submittedAttempt.score, equals(10));
    expect(submittedAttempt.totalPoints, equals(10));
    print('✅ Quiz submitted and graded. Passed: ${submittedAttempt.passed}');

    // 13. Get attempts list
    print('🔄 Fetching quiz attempts...');
    final attempts = await quizzesDataSource.getQuizAttempts(quizId: quizId, enrollmentId: enrollmentId);
    expect(attempts, isNotEmpty);
    expect(attempts.first.id, equals(attemptId));
    expect(attempts.first.passed, isTrue);

    // 14. Check remaining attempts again
    print('🔄 Checking remaining attempts...');
    remaining = await quizzesDataSource.getRemainingAttempts(quizId: quizId, enrollmentId: enrollmentId);
    expect(remaining, equals(2));
    print('✅ All quiz remote data source actions verified.');
  });
}
