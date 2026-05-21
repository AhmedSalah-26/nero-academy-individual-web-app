import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/portfolio_entity.dart';
import '../../domain/entities/portfolio_item_entity.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../datasources/portfolio_local_data_source.dart';
import '../datasources/portfolio_remote_data_source.dart';

/// Portfolio Repository Implementation
class PortfolioRepositoryImpl implements PortfolioRepository {
  final PortfolioRemoteDataSource remoteDataSource;
  final PortfolioLocalDataSource localDataSource;

  PortfolioRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, PortfolioEntity>> getPortfolio({
    required String userId,
  }) async {
    try {
      AppLogger.i('📊 [PortfolioRepo] Getting portfolio for: $userId');

      // Try cache first
      final cached = await localDataSource.getCachedPortfolio(userId);
      if (cached != null) {
        AppLogger.i('[PortfolioRepo] Returning cached portfolio');
        _refreshPortfolio(userId);
        return Right(cached);
      }

      final portfolio = await remoteDataSource.getPortfolio(userId);
      await localDataSource.cachePortfolio(portfolio);

      AppLogger.success('[PortfolioRepo] Portfolio loaded');
      return Right(portfolio);
    } catch (e) {
      AppLogger.e('[PortfolioRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _refreshPortfolio(String userId) async {
    try {
      final portfolio = await remoteDataSource.getPortfolio(userId);
      await localDataSource.cachePortfolio(portfolio);
    } catch (e) {
      AppLogger.e('[PortfolioRepo] Background refresh failed: $e');
    }
  }

  @override
  Future<Either<Failure, PortfolioStatsEntity>> getPortfolioStats({
    required String userId,
  }) async {
    try {
      AppLogger.i('📊 [PortfolioRepo] Getting stats for: $userId');

      final stats = await remoteDataSource.getPortfolioStats(userId);

      AppLogger.success('[PortfolioRepo] Stats loaded');
      return Right(stats);
    } catch (e) {
      AppLogger.e('[PortfolioRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PortfolioItemEntity>>> getCompletedCourses({
    required String userId,
  }) async {
    try {
      AppLogger.i('📊 [PortfolioRepo] Getting completed courses for: $userId');

      final courses = await remoteDataSource.getCompletedCourses(userId);

      AppLogger.success('[PortfolioRepo] Completed courses loaded');
      return Right(courses);
    } catch (e) {
      AppLogger.e('[PortfolioRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PortfolioAchievementEntity>>> getAchievements({
    required String userId,
  }) async {
    try {
      AppLogger.i('📊 [PortfolioRepo] Getting achievements for: $userId');

      final achievements = await remoteDataSource.getAchievements(userId);

      AppLogger.success('[PortfolioRepo] Achievements loaded');
      return Right(achievements);
    } catch (e) {
      AppLogger.e('[PortfolioRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
