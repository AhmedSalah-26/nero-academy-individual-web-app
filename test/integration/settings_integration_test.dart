import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/features/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/settings/data/datasources/settings_remote_data_source.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SettingsRemoteDataSource integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final authDataSource = AuthRemoteDataSourceImpl(apiClient);
    final settingsDataSource = SettingsRemoteDataSourceImpl(apiClient: apiClient);

    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    // 1. Register a Student
    print('🔄 Registering student...');
    final student = await authDataSource.register(
      email: 'student_settings_$uniqueId@example.com',
      password: 'secret123',
      name: 'Student Settings $uniqueId',
      role: UserRole.student,
    );
    expect(student, isNotNull);
    print('✅ Student registered.');

    // 2. Fetch User Profile
    print('🔄 Fetching user profile...');
    final profile = await settingsDataSource.getUserProfile(student.id);
    expect(profile, isNotNull);
    expect(profile.email, equals('student_settings_$uniqueId@example.com'));
    expect(profile.coursesCount, equals(0));
    expect(profile.totalWatchTimeSeconds, equals(0));
    expect(profile.dayStreak, equals(0));
    print('✅ Profile fetched successfully.');

    // 3. Update User Profile (name, phone, interests)
    print('🔄 Updating user profile...');
    final updatedProfile = await settingsDataSource.updateUserProfile(
      student.id,
      {
        'name': 'Updated Student Settings $uniqueId',
        'phone': '1234567890',
        'interests': ['flutter', 'dart'],
      },
    );
    expect(updatedProfile.name, equals('Updated Student Settings $uniqueId'));
    expect(updatedProfile.phone, equals('1234567890'));
    expect(updatedProfile.interests, containsAll(['flutter', 'dart']));
    print('✅ Profile updated successfully.');

    // 4. Fetch settings (should get default settings)
    print('🔄 Fetching user settings...');
    final settings = await settingsDataSource.getSettings(student.id);
    expect(settings, isNotNull);
    expect(settings.languageCode, equals('en'));
    expect(settings.isDarkMode, isFalse);
    expect(settings.notificationsEnabled, isTrue);
    print('✅ Default settings fetched successfully.');

    // 5. Update user settings
    print('🔄 Updating user settings...');
    final updatedSettings = await settingsDataSource.updateSettings(
      student.id,
      {
        'language_code': 'ar',
        'is_dark_mode': true,
        'notifications_enabled': false,
        'video_autoplay': false,
      },
    );
    expect(updatedSettings.languageCode, equals('ar'));
    expect(updatedSettings.isDarkMode, isTrue);
    expect(updatedSettings.notificationsEnabled, isFalse);
    expect(updatedSettings.videoAutoplay, isFalse);
    print('✅ Settings updated successfully.');

    // 6. Test logout
    print('🔄 Logging out...');
    final loggedOut = await settingsDataSource.logout();
    expect(loggedOut, isTrue);
    expect(apiClient.isAuthenticated, isFalse);
    print('✅ Logged out successfully.');
  });
}
