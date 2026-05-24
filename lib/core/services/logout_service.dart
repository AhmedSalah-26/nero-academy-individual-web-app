import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../network/api_client.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import 'app_logger.dart';
import 'user_role_service.dart';
import 'video_cache_service.dart';

/// Centralized logout service — clears ALL caches then navigates to splash.
class LogoutService {
  LogoutService._();

  /// Call from any screen to sign out + clear everything + go to login.
  static Future<void> logout(BuildContext context) async {
    try {
      AppLogger.i('🚪 [Logout] Signing out & clearing caches...');

      // 1. Sign out and clear auth state/cache
      try {
        await sl<AuthCubit>().logout();
      } catch (e) {
        AppLogger.e('🚪 [Logout] Error signing out auth cubit', e);
      }

      try {
        await sl<ApiClient>().clearToken();
      } catch (e) {
        AppLogger.e('🚪 [Logout] Error clearing API client token', e);
      }

      try {
        await sl<AuthLocalDataSource>().clearCache();
      } catch (e) {
        AppLogger.e('🚪 [Logout] Error clearing auth cache', e);
      }

      // 2. Clear all non-auth caches
      await _clearAllCaches();

      AppLogger.success('🚪 [Logout] Done');

      // 3. Navigate to login
      if (context.mounted) {
        GoRouter.of(context).go('/login');
      }
    } catch (e) {
      AppLogger.e('🚪 [Logout] Error', e);
      // Even on error, try to navigate away
      if (context.mounted) {
        GoRouter.of(context).go('/login');
      }
    }
  }

  /// Clears every cache in the app.
  static Future<void> _clearAllCaches() async {
    // User role cache
    UserRoleService.clearCache();

    // Video metadata cache
    VideoCacheService().clearCache();

    // Image cache (CachedNetworkImage / DefaultCacheManager)
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}

    // Flutter image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    AppLogger.i('🗑️ [Logout] All caches cleared');
  }
}
