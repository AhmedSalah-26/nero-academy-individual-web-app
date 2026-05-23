import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../models/notification_model.dart';

/// Notifications Remote Data Source - API calls to Laravel Backend
class NotificationsRemoteDataSource {
  final ApiClient _apiClient;
  static const _tag = 'NotificationsDS';

  NotificationsRemoteDataSource(this._apiClient);

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    AppLogger.d('[$_tag] getNotifications: page=$page, limit=$limit');
    try {
      final response = await _apiClient.get(
        '/notifications?page=$page&limit=$limit${unreadOnly != null ? '&unread_only=$unreadOnly' : ''}',
      );
      final list = response as List;
      return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getNotifications error', e, s);
      throw ServerException(e.toString());
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    AppLogger.d('[$_tag] getUnreadCount');
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      return response as int? ?? 0;
    } catch (e, s) {
      AppLogger.e('[$_tag] getUnreadCount error', e, s);
      throw ServerException(e.toString());
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    AppLogger.d('[$_tag] markAsRead: $notificationId');
    try {
      final response = await _apiClient.post('/notifications/$notificationId/read');
      return response as bool? ?? false;
    } catch (e, s) {
      AppLogger.e('[$_tag] markAsRead error', e, s);
      throw ServerException(e.toString());
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    AppLogger.d('[$_tag] markAllAsRead');
    try {
      final response = await _apiClient.post('/notifications/read-all');
      return response as int? ?? 0;
    } catch (e, s) {
      AppLogger.e('[$_tag] markAllAsRead error', e, s);
      throw ServerException(e.toString());
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    AppLogger.d('[$_tag] deleteNotification: $notificationId');
    try {
      final response = await _apiClient.delete('/notifications/$notificationId');
      return response as bool? ?? false;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteNotification error', e, s);
      throw ServerException(e.toString());
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    AppLogger.d('[$_tag] deleteAllNotifications');
    try {
      final response = await _apiClient.delete('/notifications');
      return response as bool? ?? false;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAllNotifications error', e, s);
      throw ServerException(e.toString());
    }
  }
}
