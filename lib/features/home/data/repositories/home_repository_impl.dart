import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/home_courses_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';
import '../datasources/home_remote_data_source.dart';

/// Home Repository Implementation
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<BannerEntity>>> getBanners() async {
    if (await networkInfo.isConnected) {
      try {
        final banners = await remoteDataSource.getBanners();
        await localDataSource.cacheBanners(banners);
        return Right(banners);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      try {
        final cachedBanners = await localDataSource.getCachedBanners();
        return Right(cachedBanners);
      } on CacheException {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
      }
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final categories = await remoteDataSource.getCategories();
        await localDataSource.cacheCategories(categories);
        return Right(categories);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      try {
        final cachedCategories = await localDataSource.getCachedCategories();
        return Right(cachedCategories);
      } on CacheException {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
      }
    }
  }

  @override
  Future<Either<Failure, HomeCoursesEntity>> getHomeCourses(
      {int limit = 10}) async {
    if (await networkInfo.isConnected) {
      try {
        final courses = await remoteDataSource.getHomeCourses(limit: limit);
        return Right(courses);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      try {
        return Right(HomeCoursesEntity(
          featuredCourses: await localDataSource.getCachedCourses('featured'),
          popularCourses: await localDataSource.getCachedCourses('popular'),
          newCourses: await localDataSource.getCachedCourses('new'),
          flashSaleCourses:
              await localDataSource.getCachedCourses('flash_sale'),
        ));
      } on CacheException {
        return const Left(
          NetworkFailure('Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª'),
        );
      }
    }
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getFeaturedCourses(
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getFeaturedCourses(limit: limit), 'featured');
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getPopularCourses(
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getPopularCourses(limit: limit), 'popular');
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getNewCourses(
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getNewCourses(limit: limit), 'new');
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getFlashSaleCourses(
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getFlashSaleCourses(limit: limit), 'flash_sale');
  }

  @override
  Future<Either<Failure, List<CourseEntity>>> getCoursesByCategory(
      String categoryId,
      {int limit = 10}) async {
    return _getCourses(
        () => remoteDataSource.getCoursesByCategory(categoryId, limit: limit),
        'category_$categoryId');
  }

  Future<Either<Failure, List<CourseEntity>>> _getCourses(
    Future<List<CourseEntity>> Function() remoteFetch,
    String cacheKey,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final courses = await remoteFetch();
        return Right(courses);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.code));
      }
    } else {
      try {
        final cachedCourses = await localDataSource.getCachedCourses(cacheKey);
        return Right(cachedCourses);
      } on CacheException {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
      }
    }
  }
}
