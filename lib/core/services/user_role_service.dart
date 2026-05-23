import '../di/injection_container.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

/// Service to check user role from database / AuthCubit
class UserRoleService {
  /// Get current user role
  static Future<String?> getCurrentUserRole() async {
    final user = sl<AuthCubit>().state.user;
    if (user == null) return null;
    return user.role.name;
  }

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'instructor' || role == 'admin';
  }

  /// Check if current user is instructor
  static Future<bool> isInstructor() async {
    final role = await getCurrentUserRole();
    return role == 'instructor' || role == 'admin';
  }

  /// Check if current user is parent
  static Future<bool> isParent() async {
    final role = await getCurrentUserRole();
    return role == 'parent';
  }

  /// Check if current user is student
  static Future<bool> isStudent() async {
    final role = await getCurrentUserRole();
    return role == 'student';
  }

  /// Clear cached role (no-op since AuthCubit state is the single source of truth)
  static void clearCache() {}

  /// Get role synchronously from cache
  static String? getCachedRole() {
    try {
      return sl<AuthCubit>().state.user?.role.name;
    } catch (_) {
      return null;
    }
  }
}
