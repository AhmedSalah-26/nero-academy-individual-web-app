import '../../domain/entities/portfolio_entity.dart';
import 'portfolio_item_model.dart';

/// Portfolio Model - Data Model with JSON serialization
class PortfolioModel extends PortfolioEntity {
  const PortfolioModel({
    required super.userId,
    required super.stats,
    super.completedCourses,
    super.achievements,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      userId: json['user_id'] as String,
      stats: PortfolioStatsModel.fromJson(
          json['stats'] as Map<String, dynamic>? ?? {}),
      completedCourses: (json['completed_courses'] as List<dynamic>?)
              ?.map(
                  (e) => PortfolioItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) =>
                  PortfolioAchievementModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'stats': (stats as PortfolioStatsModel).toJson(),
      'completed_courses': completedCourses
          .map((e) => (e as PortfolioItemModel).toJson())
          .toList(),
      'achievements': achievements
          .map((e) => (e as PortfolioAchievementModel).toJson())
          .toList(),
    };
  }
}

/// Portfolio Stats Model
class PortfolioStatsModel extends PortfolioStatsEntity {
  const PortfolioStatsModel({
    super.totalCourses,
    super.completedCourses,
    super.totalWatchTimeSeconds,
    super.achievementsUnlocked,
    super.averageScore,
  });

  factory PortfolioStatsModel.fromJson(Map<String, dynamic> json) {
    return PortfolioStatsModel(
      totalCourses: json['total_courses'] as int? ?? 0,
      completedCourses: json['completed_courses'] as int? ?? 0,
      totalWatchTimeSeconds: json['total_watch_time_seconds'] as int? ?? 0,
      achievementsUnlocked: json['achievements_unlocked'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_courses': totalCourses,
      'completed_courses': completedCourses,
      'total_watch_time_seconds': totalWatchTimeSeconds,
      'achievements_unlocked': achievementsUnlocked,
      'average_score': averageScore,
    };
  }
}
