import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/course_model.dart';
import '../../domain/entities/home_courses_entity.dart';

/// Home Remote Data Source - Handles Laravel API operations for Home
abstract class HomeRemoteDataSource {
  Future<List<BannerModel>> getBanners();
  Future<List<CategoryModel>> getCategories();
  Future<HomeCoursesEntity> getHomeCourses({int limit = 10});
  Future<List<CourseModel>> getFeaturedCourses({int limit = 10});
  Future<List<CourseModel>> getPopularCourses({int limit = 10});
  Future<List<CourseModel>> getNewCourses({int limit = 10});
  Future<List<CourseModel>> getFlashSaleCourses({int limit = 10});
  Future<List<CourseModel>> getCoursesByCategory(
    String categoryId, {
    int limit = 10,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient apiClient;

  HomeRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await apiClient.get('/banners');
      final list = response['banners'] as List;
      return list.map((json) => BannerModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ [HomeRemoteDataSource] getBanners failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.get('/categories');
      final list = response['categories'] as List;
      return list.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ [HomeRemoteDataSource] getCategories failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  /// Helper to fetch all active courses for client-side filtering/sorting
  Future<List<CourseModel>> _getAllCourses() async {
    final response = await apiClient.get('/courses');
    final list = response['courses'] as List;
    return list.map((json) => CourseModel.fromJson(json)).toList();
  }

  @override
  Future<HomeCoursesEntity> getHomeCourses({int limit = 10}) async {
    try {
      final courses = await _getAllCourses();

      return HomeCoursesEntity(
        featuredCourses: _featuredCourses(courses, limit),
        popularCourses: _popularCourses(courses, limit),
        newCourses: _newCourses(courses, limit),
        flashSaleCourses: _flashSaleCourses(courses, limit),
      );
    } catch (e) {
      debugPrint('âš ï¸ [HomeRemoteDataSource] getHomeCourses failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CourseModel>> getFeaturedCourses({int limit = 10}) async {
    try {
      final courses = await _getAllCourses();
      return _featuredCourses(courses, limit);
    } catch (e) {
      debugPrint('⚠️ [HomeRemoteDataSource] getFeaturedCourses failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CourseModel>> getPopularCourses({int limit = 10}) async {
    try {
      final courses = await _getAllCourses();
      return _popularCourses(courses, limit);
    } catch (e) {
      debugPrint('⚠️ [HomeRemoteDataSource] getPopularCourses failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CourseModel>> getNewCourses({int limit = 10}) async {
    try {
      final courses = await _getAllCourses();
      return _newCourses(courses, limit);
    } catch (e) {
      debugPrint('⚠️ [HomeRemoteDataSource] getNewCourses failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CourseModel>> getFlashSaleCourses({int limit = 10}) async {
    try {
      final courses = await _getAllCourses();
      return _flashSaleCourses(courses, limit);
    } catch (e) {
      debugPrint('⚠️ [HomeRemoteDataSource] getFlashSaleCourses failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CourseModel>> getCoursesByCategory(
    String categoryId, {
    int limit = 10,
  }) async {
    try {
      final courses = await _getAllCourses();
      final filtered = courses.where((c) => c.categoryId == categoryId).toList();
      filtered.sort((a, b) => b.enrolledCount.compareTo(a.enrolledCount));
      return filtered.take(limit).toList();
    } catch (e) {
      debugPrint('⚠️ [HomeRemoteDataSource] getCoursesByCategory failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  List<CourseModel> _featuredCourses(List<CourseModel> courses, int limit) {
    final featured = courses.where((c) => c.isFeatured).toList();
    featured.sort(_compareNewestFirst);
    return featured.take(limit).toList();
  }

  List<CourseModel> _popularCourses(List<CourseModel> courses, int limit) {
    final popular = [...courses];
    popular.sort((a, b) => b.enrolledCount.compareTo(a.enrolledCount));
    return popular.take(limit).toList();
  }

  List<CourseModel> _newCourses(List<CourseModel> courses, int limit) {
    final newest = [...courses];
    newest.sort(_compareNewestFirst);
    return newest.take(limit).toList();
  }

  List<CourseModel> _flashSaleCourses(List<CourseModel> courses, int limit) {
    final now = DateTime.now();
    final flashSale = courses.where((c) {
      if (!c.isFlashSale) return false;
      if (c.flashSaleStart != null && c.flashSaleStart!.isAfter(now)) {
        return false;
      }
      if (c.flashSaleEnd != null && c.flashSaleEnd!.isBefore(now)) {
        return false;
      }
      return true;
    }).toList();

    flashSale.sort((a, b) {
      if (a.flashSaleEnd == null && b.flashSaleEnd == null) return 0;
      if (a.flashSaleEnd == null) return 1;
      if (b.flashSaleEnd == null) return -1;
      return a.flashSaleEnd!.compareTo(b.flashSaleEnd!);
    });

    return flashSale.take(limit).toList();
  }

  int _compareNewestFirst(CourseModel a, CourseModel b) {
    final aDate = a.publishedAt ?? a.createdAt;
    final bDate = b.publishedAt ?? b.createdAt;
    return bDate.compareTo(aDate);
  }
}
