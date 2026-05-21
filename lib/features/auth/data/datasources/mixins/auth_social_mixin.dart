import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../models/user_model.dart';
// import 'auth_helpers_mixin.dart'; // Abstract method needed

mixin AuthSocialMixin {
  // Dependencies
  SupabaseClient get supabase;
  Logger get logger;
  Future<UserModel> getOrCreateProfile(User user);
  app_exceptions.AuthException handleAuthError(AuthApiException e);

  Future<UserModel> loginWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.google,
          redirectTo: 'io.supabase.lms://login-callback/');
      await Future.delayed(const Duration(seconds: 1));
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw const app_exceptions.AuthException('فشل تسجيل الدخول بـ Google');
      }
      return await getOrCreateProfile(user);
    } on AuthApiException catch (e) {
      throw handleAuthError(e);
    }
  }

  Future<UserModel> loginWithApple() async {
    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.apple,
          redirectTo: 'io.supabase.lms://login-callback/');
      await Future.delayed(const Duration(seconds: 1));
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw const app_exceptions.AuthException('فشل تسجيل الدخول بـ Apple');
      }
      return await getOrCreateProfile(user);
    } on AuthApiException catch (e) {
      throw handleAuthError(e);
    }
  }

  Future<UserModel> loginWithFacebook() async {
    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.facebook,
          redirectTo: 'io.supabase.lms://login-callback/');
      await Future.delayed(const Duration(seconds: 1));
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw const app_exceptions.AuthException(
            'فشل تسجيل الدخول بـ Facebook');
      }
      return await getOrCreateProfile(user);
    } on AuthApiException catch (e) {
      throw handleAuthError(e);
    }
  }
}
