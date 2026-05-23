import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/settings_model.dart';
import '../models/user_profile_model.dart';

/// Settings Remote Data Source
abstract class SettingsRemoteDataSource {
  Future<SettingsModel> getSettings(String userId);
  Future<SettingsModel> updateSettings(
      String userId, Map<String, dynamic> data);
  Future<UserProfileModel> getUserProfile(String userId);
  Future<UserProfileModel> updateUserProfile(
      String userId, Map<String, dynamic> data);
  Future<List<AchievementModel>> getUserAchievements(String userId);
  Future<bool> deleteAccount(String userId);
  Future<bool> logout();
}

/// Settings Remote Data Source Implementation using Laravel REST API
class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final ApiClient apiClient;

  SettingsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<SettingsModel> getSettings(String userId) async {
    debugPrint('⚙️ [SettingsRemote] Getting settings for: $userId');
    try {
      final response = await apiClient.get('/auth/settings');
      if (response == null || response['settings'] == null) {
        return SettingsModel.defaultSettings(userId);
      }
      return SettingsModel.fromJson(response['settings']);
    } catch (e) {
      debugPrint('⚠️ [SettingsRemote] getSettings failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<SettingsModel> updateSettings(
      String userId, Map<String, dynamic> data) async {
    debugPrint('⚙️ [SettingsRemote] Updating settings for: $userId');
    try {
      final response = await apiClient.post(
        '/auth/settings',
        body: data,
      );
      return SettingsModel.fromJson(response['settings']);
    } catch (e) {
      debugPrint('⚠️ [SettingsRemote] updateSettings failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    debugPrint('👤 [SettingsRemote] Getting profile for: $userId');
    try {
      final response = await apiClient.get('/auth/profile?user_id=$userId');
      return UserProfileModel.fromJson(response['user']);
    } catch (e) {
      debugPrint('⚠️ [SettingsRemote] getUserProfile failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    debugPrint('👤 [SettingsRemote] Updating profile for: $userId');
    try {
      final response = await apiClient.post(
        '/auth/profile/update',
        body: data,
      );
      return UserProfileModel.fromJson(response['user']);
    } catch (e) {
      debugPrint('⚠️ [SettingsRemote] updateUserProfile failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<AchievementModel>> getUserAchievements(String userId) async {
    debugPrint('🏆 [SettingsRemote] Getting achievements for: $userId');
    // Mock achievements for now - can be replaced with actual DB query
    return [
      const AchievementModel(
        id: '1',
        title: 'First Steps',
        description: 'Completed 1st Course',
        iconName: 'military_tech',
        isUnlocked: true,
      ),
      const AchievementModel(
        id: '2',
        title: 'Fast Learner',
        description: '3h in one day',
        iconName: 'electric_bolt',
        isUnlocked: true,
      ),
      const AchievementModel(
        id: '3',
        title: 'Scholar',
        description: '5 Courses Done',
        iconName: 'auto_stories',
        isUnlocked: false,
      ),
      const AchievementModel(
        id: '4',
        title: 'Champion',
        description: '10 Courses Done',
        iconName: 'trophy',
        isUnlocked: false,
      ),
    ];
  }

  @override
  Future<bool> deleteAccount(String userId) async {
    debugPrint('🗑️ [SettingsRemote] Deleting account: $userId');
    try {
      await apiClient.delete('/auth/profile');
      await apiClient.clearToken();
      return true;
    } catch (e) {
      debugPrint('⚠️ [SettingsRemote] deleteAccount failed: $e');
      return false;
    }
  }

  @override
  Future<bool> logout() async {
    debugPrint('🚪 [SettingsRemote] Logging out');
    try {
      await apiClient.post('/auth/logout');
    } catch (e) {
      debugPrint('⚠️ [SettingsRemote] Remote logout error: $e');
    } finally {
      await apiClient.clearToken();
    }
    return true;
  }
}
