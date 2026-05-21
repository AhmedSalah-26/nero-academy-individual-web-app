import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/portfolio_entity.dart';
import '../entities/portfolio_item_entity.dart';

/// Portfolio Repository - Abstract Contract
abstract class PortfolioRepository {
  /// Get user portfolio
  Future<Either<Failure, PortfolioEntity>> getPortfolio({
    required String userId,
  });

  /// Get portfolio stats
  Future<Either<Failure, PortfolioStatsEntity>> getPortfolioStats({
    required String userId,
  });

  /// Get completed courses
  Future<Either<Failure, List<PortfolioItemEntity>>> getCompletedCourses({
    required String userId,
  });

  /// Get achievements
  Future<Either<Failure, List<PortfolioAchievementEntity>>> getAchievements({
    required String userId,
  });
}
