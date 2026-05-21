import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      // 1. Sign out from Supabase
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
      } catch (_) {
        // Fallback to local sign out
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      }

      // 2. Clear all caches
      await _clearAllCaches();

      AppLogger.success('🚪 [Logout] Done');

      // 3. Navigate to splash
      if (context.mounted) {
        GoRouter.of(context).go('/splash');
      }
    } catch (e) {
      AppLogger.e('🚪 [Logout] Error', e);
      // Even on error, try to navigate away
      if (context.mounted) {
        GoRouter.of(context).go('/splash');
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
