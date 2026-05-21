import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/notification_model.dart';

/// Notifications Remote Data Source
class NotificationsRemoteDataSource {
  final SupabaseClient _client;
  static const _tag = 'NotificationsDS';

  NotificationsRemoteDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    AppLogger.d('[$_tag] getNotifications: page=$page, limit=$limit');
    try {
      var query = _client.from('notifications').select().eq('user_id', _userId);

      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getNotifications: ${(response as List).length} notifications');
      return response.map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getNotifications error', e, s);
      rethrow;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    AppLogger.d('[$_tag] getUnreadCount');
    try {
      final response = await _client.rpc('get_unread_notifications_count');
      AppLogger.success('[$_tag] getUnreadCount: $response');
      return response as int? ?? 0;
    } catch (e, s) {
      AppLogger.e('[$_tag] getUnreadCount error', e, s);
      // Fallback: count manually
      try {
        final response = await _client
            .from('notifications')
            .select('id')
            .eq('user_id', _userId)
            .eq('is_read', false);
        return (response as List).length;
      } catch (_) {
        return 0;
      }
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    AppLogger.d('[$_tag] markAsRead: $notificationId');
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', _userId);

      AppLogger.success('[$_tag] markAsRead success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] markAsRead error', e, s);
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    AppLogger.d('[$_tag] markAllAsRead');
    try {
      // Try using RPC function first
      final response = await _client.rpc('mark_all_notifications_read');
      AppLogger.success(
          '[$_tag] markAllAsRead: $response notifications updated');
      return response as int? ?? 0;
    } catch (e) {
      AppLogger.w('[$_tag] markAllAsRead RPC failed, using fallback');
      // Fallback: update directly
      try {
        await _client
            .from('notifications')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', _userId)
            .eq('is_read', false);
        return 0;
      } catch (e2, s2) {
        AppLogger.e('[$_tag] markAllAsRead fallback error', e2, s2);
        rethrow;
      }
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    AppLogger.d('[$_tag] deleteNotification: $notificationId');
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', _userId);

      AppLogger.success('[$_tag] deleteNotification success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteNotification error', e, s);
      rethrow;
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    AppLogger.d('[$_tag] deleteAllNotifications');
    try {
      await _client.from('notifications').delete().eq('user_id', _userId);

      AppLogger.success('[$_tag] deleteAllNotifications success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAllNotifications error', e, s);
      rethrow;
    }
  }

  /// Subscribe to real-time notifications
  RealtimeChannel subscribeToNotifications(
    void Function(NotificationModel notification) onNewNotification,
  ) {
    AppLogger.d('[$_tag] subscribeToNotifications');
    return _client
        .channel('notifications:$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            AppLogger.d(
                '[$_tag] New notification received: ${payload.newRecord}');
            try {
              final notification =
                  NotificationModel.fromJson(payload.newRecord);
              onNewNotification(notification);
            } catch (e) {
              AppLogger.e('[$_tag] Failed to parse notification', e);
            }
          },
        )
        .subscribe();
  }
}
