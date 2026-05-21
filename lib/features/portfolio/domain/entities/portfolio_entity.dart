import 'package:equatable/equatable.dart';
import 'portfolio_item_entity.dart';

/// Portfolio Entity - Pure Dart Object
class PortfolioEntity extends Equatable {
  final String userId;
  final PortfolioStatsEntity stats;
  final List<PortfolioItemEntity> completedCourses;
  final List<PortfolioAchievementEntity> achievements;

  const PortfolioEntity({
    required this.userId,
    required this.stats,
    this.completedCourses = const [],
    this.achievements = const [],
  });

  @override
  List<Object?> get props => [
        userId,
        stats,
        completedCourses,
        achievements,
      ];
}

/// Portfolio Stats Entity
class PortfolioStatsEntity extends Equatable {
  final int totalCourses;
  final int completedCourses;
  final int totalWatchTimeSeconds; // Store in seconds for precision
  final int achievementsUnlocked;
  final double averageScore;

  const PortfolioStatsEntity({
    this.totalCourses = 0,
    this.completedCourses = 0,
    this.totalWatchTimeSeconds = 0,
    this.achievementsUnlocked = 0,
    this.averageScore = 0.0,
  });

  /// Get formatted watch time string (e.g., "45m", "2h 30m", "1h")
  String get formattedWatchTime {
    if (totalWatchTimeSeconds <= 0) return '0m';

    final hours = totalWatchTimeSeconds ~/ 3600;
    final minutes = (totalWatchTimeSeconds % 3600) ~/ 60;

    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  @override
  List<Object?> get props => [
        totalCourses,
        completedCourses,
        totalWatchTimeSeconds,
        achievementsUnlocked,
        averageScore,
      ];
}
