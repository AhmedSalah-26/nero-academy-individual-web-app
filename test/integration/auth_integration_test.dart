import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/features/auth/domain/entities/user_entity.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AuthRemoteDataSource integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final dataSource = AuthRemoteDataSourceImpl(apiClient);
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final email = 'student_$uniqueId@example.com';
    final password = 'secret123';
    final name = 'Test Student $uniqueId';

    // 1. Test Register
    print('🔄 Testing register...');
    try {
      final user = await dataSource.register(
        email: email,
        password: password,
        name: name,
        role: UserRole.student,
        phone: '01012345678',
      );
      expect(user, isNotNull);
      expect(user.email, equals(email));
      expect(user.name, equals(name));
      expect(apiClient.isAuthenticated, isTrue);
      print('✅ Register succeeded for user ID: ${user.id}');
    } catch (e) {
      fail('Register failed: $e');
    }

    // 2. Test Get Current User Profile
    print('🔄 Testing get profile...');
    try {
      final profile = await dataSource.getCurrentUser();
      expect(profile, isNotNull);
      expect(profile!.email, equals(email));
      print('✅ Profile retrieval succeeded.');
    } catch (e) {
      fail('Profile retrieval failed: $e');
    }

    // 3. Test Logout
    print('🔄 Testing logout...');
    try {
      await dataSource.logout();
      expect(apiClient.isAuthenticated, isFalse);
      print('✅ Logout succeeded.');
    } catch (e) {
      fail('Logout failed: $e');
    }

    // 4. Test Login
    print('🔄 Testing login...');
    try {
      final loggedInUser = await dataSource.login(email: email, password: password);
      expect(loggedInUser, isNotNull);
      expect(loggedInUser.email, equals(email));
      expect(apiClient.isAuthenticated, isTrue);
      print('✅ Login succeeded.');
    } catch (e) {
      fail('Login failed: $e');
    }

    // 5. Test Send Phone OTP
    print('🔄 Testing Send OTP...');
    try {
      await dataSource.sendPhoneOtp('01012345678');
      print('✅ Send OTP request succeeded.');
    } catch (e) {
      fail('Send OTP failed: $e');
    }

    // 6. Test Verify Phone OTP
    print('🔄 Testing Verify OTP...');
    try {
      // The local backend has a static mock OTP: '123456'
      final otpUser = await dataSource.verifyPhoneOtp('01012345678', '123456');
      expect(otpUser, isNotNull);
      expect(otpUser.phone, equals('01012345678'));
      print('✅ Verify OTP succeeded.');
    } catch (e) {
      fail('Verify OTP failed: $e');
    }
  });
}
