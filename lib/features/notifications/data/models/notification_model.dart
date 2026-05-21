import '../../domain/entities/notification_entity.dart';

/// Notification Model - Maps to database table
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.titleAr,
    super.titleEn,
    super.bodyAr,
    super.bodyEn,
    super.imageUrl,
    super.iconName,
    super.actionType,
    super.actionValue,
    super.data,
    super.isRead,
    super.readAt,
    super.senderId,
    super.courseId,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create from JSON (database row)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String? ?? 'system'),
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      bodyAr: json['body_ar'] as String?,
      bodyEn: json['body_en'] as String?,
      imageUrl: json['image_url'] as String?,
      iconName: json['icon_name'] as String?,
      actionType: json['action_type'] as String?,
      actionValue: json['action_value'] as String?,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      senderId: json['sender_id'] as String?,
      courseId: json['course_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON (for insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'image_url': imageUrl,
      'icon_name': iconName,
      'action_type': actionType,
      'action_value': actionValue,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'sender_id': senderId,
      'course_id': courseId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from entity
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      titleAr: entity.titleAr,
      titleEn: entity.titleEn,
      bodyAr: entity.bodyAr,
      bodyEn: entity.bodyEn,
      imageUrl: entity.imageUrl,
      iconName: entity.iconName,
      actionType: entity.actionType,
      actionValue: entity.actionValue,
      data: entity.data,
      isRead: entity.isRead,
      readAt: entity.readAt,
      senderId: entity.senderId,
      courseId: entity.courseId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
