import 'package:equatable/equatable.dart';

/// Portfolio Item Entity - Completed Course
class PortfolioItemEntity extends Equatable {
  final String id;
  final String courseId;
  final String courseTitle;
  final String? courseThumbnail;
  final String instructorName;
  final DateTime completedAt;
  final double score;
  final int hoursSpent;

  const PortfolioItemEntity({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    this.courseThumbnail,
    required this.instructorName,
    required this.completedAt,
    this.score = 0.0,
    this.hoursSpent = 0,
  });

  @override
  List<Object?> get props => [
        id,
        courseId,
        courseTitle,
        courseThumbnail,
        instructorName,
        completedAt,
        score,
        hoursSpent,
      ];
}

/// Portfolio Achievement Entity
class PortfolioAchievementEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String category;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int target;

  const PortfolioAchievementEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.category = 'general',
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    this.target = 1,
  });

  double get progressPercentage =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconName,
        category,
        isUnlocked,
        unlockedAt,
        progress,
        target,
      ];
}
