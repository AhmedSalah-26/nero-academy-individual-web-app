import 'dart:io';

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../models/user_model.dart';
// import 'auth_helpers_mixin.dart';

mixin AuthPhoneMixin {
  // Dependencies
  SupabaseClient get supabase;
  Logger get logger;
  Future<UserModel> getProfile(String userId);
  void checkUserAccess(UserModel user);
  app_exceptions.AuthException handleAuthError(AuthApiException e);

  Future<void> sendPhoneOtp(String phoneNumber) async {
    logger.i('📱 [DataSource] Sending OTP to: $phoneNumber');

    // In development mode, bypass account check
    // We will use 000000 to verify later
    logger.i('✅ [DataSource] Skipping account check in development mode');
    logger.i('   Use OTP: 000000 to login');

    // Currently we don't send real OTP, just success
    logger.i('✅ [DataSource] OTP ready (bypass mode)');
  }

  Future<UserModel> verifyPhoneOtp(String phoneNumber, String otp) async {
    logger.i('🔐 [DataSource] Verifying OTP for: $phoneNumber');
    logger.d('  OTP token: $otp');

    try {
      // ✅ BYPASS MODE: Accept 000000 as valid OTP for development
      if (otp == '000000') {
        logger.w('⚠️ [DataSource] BYPASS MODE: Using development OTP 000000');

        // Search for profile related to this number
        logger.i('📝 [DataSource] Getting profile by phone...');
        final profilesData = await supabase
            .from('profiles')
            .select()
            .eq('phone', phoneNumber)
            .limit(10); // Fetch up to 10 to check

        if (profilesData.isEmpty) {
          logger.e('❌ [DataSource] No profile found with phone: $phoneNumber');
          throw const app_exceptions.AuthException(
            'لا يوجد حساب مرتبط بهذا الرقم.\nيرجى إنشاء حساب جديد أولاً.',
            code: 'phone_not_registered',
          );
        }

        // If multiple profiles, take first & warn
        final profilesList = profilesData as List;
        if (profilesList.length > 1) {
          logger.w(
              '⚠️ [DataSource] Multiple profiles found with phone: $phoneNumber (${profilesList.length} profiles)');
          logger.w('   Taking the first profile...');
        }

        final profileData = profilesList.first as Map<String, dynamic>;
        final userId = profileData['id'] as String;
        final userEmail = profileData['email'] as String;

        logger.i('🔑 [DataSource] User found: $userEmail (ID: $userId)');
        logger.i('🔑 [DataSource] Calling add_phone_to_auth_user for: $userId');

        try {
          await supabase.rpc('add_phone_to_auth_user', params: {
            'user_id': userId,
            'phone_number': phoneNumber,
          });
          logger.i('✅ [DataSource] Phone added to auth.users successfully');

          // Attempt login via Supabase OTP
          logger.i('🔐 [DataSource] Attempting Supabase OTP verification');
          try {
            final response = await supabase.auth.verifyOTP(
              type: OtpType.sms,
              phone: phoneNumber,
              token: otp,
            );

            if (response.user != null) {
              logger.i('✅ [DataSource] Supabase OTP verified, user logged in');
            } else {
              logger.w(
                  '⚠️ [DataSource] Supabase OTP verification returned null user');
            }
          } catch (otpError) {
            logger.w(
                '⚠️ [DataSource] Supabase OTP verification failed: $otpError');
            logger.w('   Continuing with profile data only (no auth session)');
          }
        } catch (e) {
          logger.w('⚠️ [DataSource] Failed to add phone to auth.users: $e');
          // Continue even if fail
        }

        final userModel = UserModel.fromJson(profileData);
        logger
            .i('✅ [DataSource] User profile ready (BYPASS): ${userModel.name}');
        checkUserAccess(userModel);
        return userModel;
      }

      // Normal OTP verification flow
      logger.d('  Calling supabase.auth.verifyOTP...');
      final response = await supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phoneNumber,
        token: otp,
      );

      logger.d('  Response received');
      logger.d('  User: ${response.user?.id}');
      logger.d(
          '  Session: ${response.session?.accessToken != null ? "exists" : "null"}');

      if (response.user == null) {
        logger.e('❌ [DataSource] OTP verification failed: user is null');
        throw const app_exceptions.AuthException('فشل التحقق من رمز OTP');
      }

      logger.i('✅ [DataSource] OTP verified successfully!');

      // Get profile by phone
      logger.i('📝 [DataSource] Getting profile by phone...');
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('phone', phoneNumber)
          .maybeSingle();

      if (profileData == null) {
        logger.e('❌ [DataSource] No profile found with phone: $phoneNumber');
        // Sign out
        await supabase.auth.signOut();
        throw const app_exceptions.AuthException(
          'لا يوجد حساب مرتبط بهذا الرقم.\nيرجى إنشاء حساب جديد أولاً.',
          code: 'phone_not_registered',
        );
      }

      final userModel = UserModel.fromJson(profileData);
      logger.i('✅ [DataSource] User profile ready: ${userModel.name}');
      checkUserAccess(userModel);
      return userModel;
    } on AuthApiException catch (e) {
      logger.e('❌ [DataSource] AuthApiException: ${e.message}');
      logger.e('   Code: ${e.code}');
      logger.e('   Status: ${e.statusCode}');
      throw handleAuthError(e);
    } catch (e, stackTrace) {
      logger.e('❌ [DataSource] Unexpected error: $e');
      logger.e('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> sendLinkPhoneOtp(String phoneNumber) async {
    logger.i('📱 [DataSource] Adding phone directly (no OTP): $phoneNumber');

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw const app_exceptions.AuthException(
        'يجب تسجيل الدخول أولاً لربط رقم الهاتف',
        code: 'not_authenticated',
      );
    }

    // Check if phone used
    try {
      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('phone', phoneNumber)
          .neq('id', currentUser.id)
          .maybeSingle();

      if (existingProfile != null) {
        logger.w('❌ [DataSource] Phone already used by another account');
        throw const app_exceptions.AuthException(
          'هذا الرقم مرتبط بحساب آخر',
          code: 'phone_already_used',
        );
      }
    } catch (e) {
      if (e is app_exceptions.AuthException) rethrow;
      logger.e('❌ [DataSource] Error checking phone: $e');
    }

    // Add phone directly to auth.users without OTP
    try {
      final result = await supabase.rpc('add_phone_to_auth_user', params: {
        'user_id': currentUser.id,
        'phone_number': phoneNumber,
      });
      logger.i('✅ [DataSource] Phone added directly to auth.users');
      logger.d('   Result: $result');
    } on SocketException catch (e) {
      logger.e('❌ [DataSource] Network error: $e');
      throw const app_exceptions.AuthException(
        'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.',
        code: 'network_error',
      );
    } on PostgrestException catch (e) {
      logger.e('❌ [DataSource] Failed to add phone: ${e.message}');
      logger.e('   Error code: ${e.code}');
      logger.e('   Details: ${e.details}');
      logger.e('   Hint: ${e.hint}');

      // Check if it's a function not found error
      if (e.code == '42883' ||
          e.message.contains('function') &&
              e.message.contains('does not exist')) {
        throw const app_exceptions.AuthException(
          'خطأ في الإعدادات. يرجى التواصل مع الدعم الفني.\n(RPC function not found)',
          code: 'function_not_found',
        );
      }

      throw app_exceptions.ServerException(e.message, code: e.code);
    } catch (e) {
      logger.e('❌ [DataSource] Unexpected error: $e');
      rethrow;
    }
  }

  Future<UserModel> verifyLinkPhoneOtp(String phoneNumber, String otp) async {
    logger
        .i('🔐 [DataSource] Verifying phone link (bypass mode): $phoneNumber');

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw const app_exceptions.AuthException(
        'يجب تسجيل الدخول أولاً',
        code: 'not_authenticated',
      );
    }

    try {
      // ✅ BYPASS MODE: Accept 000000 as valid OTP for development
      if (otp == '000000') {
        logger.w(
            '⚠️ [DataSource] BYPASS MODE: Using development OTP 000000 for phone linking');

        // Update profile with phone
        await supabase.from('profiles').update({
          'phone': phoneNumber,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentUser.id);

        // Call RPC
        logger.i(
            '🔑 [DataSource] Calling add_phone_to_auth_user for: ${currentUser.id}');
        try {
          await supabase.rpc('add_phone_to_auth_user', params: {
            'user_id': currentUser.id,
            'phone_number': phoneNumber,
          });
          logger.i('✅ [DataSource] Phone added to auth.users successfully');

          // Refresh session
          logger.i('🔄 [DataSource] Refreshing session to update user data');
          await supabase.auth.refreshSession();
          logger.i('✅ [DataSource] Session refreshed successfully');
        } catch (e) {
          logger.w('⚠️ [DataSource] Failed to add phone to auth.users: $e');
        }

        logger.i('✅ [DataSource] Phone linked successfully (BYPASS)!');
        return await getProfile(currentUser.id);
      }

      // Normal flow: update profile
      await supabase.from('profiles').update({
        'phone': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      logger.i('✅ [DataSource] Phone linked successfully!');
      return await getProfile(currentUser.id);
    } on PostgrestException catch (e) {
      logger.e('❌ [DataSource] PostgrestException: ${e.message}');
      throw app_exceptions.ServerException(e.message, code: e.code);
    }
  }
}
