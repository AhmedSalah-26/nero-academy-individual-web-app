import '../../domain/entities/portfolio_item_entity.dart';

/// Portfolio Item Model - Data Model with JSON serialization
class PortfolioItemModel extends PortfolioItemEntity {
  const PortfolioItemModel({
    required super.id,
    required super.courseId,
    required super.courseTitle,
    super.courseThumbnail,
    required super.instructorName,
    required super.completedAt,
    super.score,
    super.hoursSpent,
  });

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) {
    return PortfolioItemModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      courseTitle: json['course_title'] as String? ?? '',
      courseThumbnail: json['course_thumbnail'] as String?,
      instructorName: json['instructor_name'] as String? ?? '',
      completedAt: DateTime.parse(json['completed_at'] as String),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      hoursSpent: json['hours_spent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_title': courseTitle,
      'course_thumbnail': courseThumbnail,
      'instructor_name': instructorName,
      'completed_at': completedAt.toIso8601String(),
      'score': score,
      'hours_spent': hoursSpent,
    };
  }
}

/// Portfolio Achievement Model
class PortfolioAchievementModel extends PortfolioAchievementEntity {
  const PortfolioAchievementModel({
    required super.id,
    required super.title,
    required super.description,
    required super.iconName,
    super.category,
    super.isUnlocked,
    super.unlockedAt,
    super.progress,
    super.target,
  });

  factory PortfolioAchievementModel.fromJson(Map<String, dynamic> json) {
    return PortfolioAchievementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      category: json['category'] as String? ?? 'general',
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
      progress: json['progress'] as int? ?? 0,
      target: json['target'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'category': category,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'progress': progress,
      'target': target,
    };
  }
}
