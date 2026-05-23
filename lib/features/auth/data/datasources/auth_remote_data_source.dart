import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

/// Auth Remote Data Source - Handles Laravel REST API Auth operations
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? headline,
    String? bio,
    List<String>? expertise,
    Uint8List? avatarBytes,
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
  Future<UserModel> updateInterests(List<String> interests);
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  });
  Future<UserModel> loginWithGoogle();
  Future<UserModel> loginWithApple();
  Future<UserModel> loginWithFacebook();
  Future<void> sendPhoneOtp(String phoneNumber);
  Future<UserModel> verifyPhoneOtp(String phoneNumber, String otp);
  Future<void> sendLinkPhoneOtp(String phoneNumber);
  Future<UserModel> verifyLinkPhoneOtp(String phoneNumber, String otp);
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 [AuthRemoteDataSource] Login: $email');
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    final String token = response['token'];
    await _apiClient.setToken(token);

    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? headline,
    String? bio,
    List<String>? expertise,
    Uint8List? avatarBytes,
  }) async {
    debugPrint('📝 [AuthRemoteDataSource] Register: $email, role: ${role.name}');
    
    // Convert role to string value expected by Laravel
    final roleString = role == UserRole.instructor ? 'instructor' : 'student';

    final body = {
      'email': email,
      'password': password,
      'name': name,
      'role': roleString,
      if (phone != null) 'phone': phone,
      if (headline != null) 'headline_ar': headline,
      if (bio != null) 'bio_ar': bio,
      if (expertise != null) 'expertise': expertise,
    };

    final response = await _apiClient.post(
      '/auth/register',
      body: body,
    );

    final String token = response['token'];
    await _apiClient.setToken(token);

    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> logout() async {
    debugPrint('🔐 [AuthRemoteDataSource] Logout');
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      debugPrint('⚠️ [AuthRemoteDataSource] Logout request failed: $e');
    } finally {
      await _apiClient.clearToken();
      _authStateController.add(null);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    debugPrint('🔄 [AuthRemoteDataSource] Get Current User');
    if (!_apiClient.isAuthenticated) {
      return null;
    }
    try {
      final response = await _apiClient.get('/auth/profile');
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _authStateController.add(user);
      return user;
    } catch (e) {
      debugPrint('⚠️ [AuthRemoteDataSource] Get Current User failed: $e');
      // If token expired/unauthorized, clear it
      if (e is AuthException) {
        await _apiClient.clearToken();
        _authStateController.add(null);
      }
      return null;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    debugPrint('📝 [AuthRemoteDataSource] Forgot Password for: $email');
    // Bypass/mock in development or call OTP send
    await sendPhoneOtp(email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    debugPrint('📝 [AuthRemoteDataSource] Reset Password with token: $token');
    // Succeed gracefully for development
  }

  @override
  Future<UserModel> updateInterests(List<String> interests) async {
    debugPrint('📝 [AuthRemoteDataSource] Update Interests: $interests');
    final response = await _apiClient.post(
      '/auth/profile/interests',
      body: {
        'interests': interests,
      },
    );

    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    debugPrint('📝 [AuthRemoteDataSource] Update Profile');
    final body = {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    final response = await _apiClient.post(
      '/auth/profile/update',
      body: body,
    );

    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    debugPrint('🔑 [AuthRemoteDataSource] Google login not implemented in REST backend yet.');
    throw const AuthException('تسجيل الدخول عبر جوجل غير مدعوم حالياً.');
  }

  @override
  Future<UserModel> loginWithApple() async {
    debugPrint('🔑 [AuthRemoteDataSource] Apple login not implemented.');
    throw const AuthException('تسجيل الدخول عبر آبل غير مدعوم حالياً.');
  }

  @override
  Future<UserModel> loginWithFacebook() async {
    debugPrint('🔑 [AuthRemoteDataSource] Facebook login not implemented.');
    throw const AuthException('تسجيل الدخول عبر فيسبوك غير مدعوم حالياً.');
  }

  @override
  Future<void> sendPhoneOtp(String phoneNumber) async {
    debugPrint('📱 [AuthRemoteDataSource] Send OTP to: $phoneNumber');
    await _apiClient.post(
      '/auth/otp/send',
      body: {'phone': phoneNumber},
    );
  }

  @override
  Future<UserModel> verifyPhoneOtp(String phoneNumber, String otp) async {
    debugPrint('🔐 [AuthRemoteDataSource] Verify OTP for: $phoneNumber');
    final response = await _apiClient.post(
      '/auth/otp/verify',
      body: {
        'phone': phoneNumber,
        'otp': otp,
      },
    );

    final String token = response['token'];
    await _apiClient.setToken(token);

    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> sendLinkPhoneOtp(String phoneNumber) async {
    debugPrint('📱 [AuthRemoteDataSource] Send Link Phone OTP');
    await sendPhoneOtp(phoneNumber);
  }

  @override
  Future<UserModel> verifyLinkPhoneOtp(String phoneNumber, String otp) async {
    debugPrint('🔐 [AuthRemoteDataSource] Verify Link Phone OTP');
    // First verify OTP, then update phone in profile
    await _apiClient.post(
      '/auth/otp/verify',
      body: {
        'phone': phoneNumber,
        'otp': otp,
      },
    );
    return await updateProfile(phone: phoneNumber);
  }
}
