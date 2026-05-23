import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/wishlist_item_model.dart';

/// Wishlist Remote Data Source - API calls to Laravel Backend
abstract class WishlistRemoteDataSource {
  Future<List<WishlistItemModel>> getWishlist(String userId);
  Future<WishlistItemModel> addToWishlist(String userId, String courseId);
  Future<void> removeFromWishlist(String userId, String wishlistItemId);
  Future<void> removeFromWishlistByCourseId(String userId, String courseId);
  Future<bool> isInWishlist(String userId, String courseId);
  Future<void> clearWishlist(String userId);
  Future<int> getWishlistCount(String userId);
}

/// Wishlist Remote Data Source Implementation
class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final ApiClient apiClient;

  WishlistRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<WishlistItemModel>> getWishlist(String userId) async {
    debugPrint('❤️ [WishlistRemote] Getting wishlist');
    try {
      final response = await apiClient.get('/wishlist');
      final list = response['wishlist'] as List;
      return list.map((e) => WishlistItemModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('⚠️ [WishlistRemote] getWishlist failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<WishlistItemModel> addToWishlist(String userId, String courseId) async {
    debugPrint('❤️ [WishlistRemote] Adding to wishlist - course: $courseId');
    try {
      final response = await apiClient.post(
        '/wishlist',
        body: {'course_id': courseId},
      );
      return WishlistItemModel.fromJson(response['wishlist_item']);
    } catch (e) {
      debugPrint('⚠️ [WishlistRemote] addToWishlist failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeFromWishlist(String userId, String wishlistItemId) async {
    debugPrint('❤️ [WishlistRemote] Removing item: $wishlistItemId');
    try {
      await apiClient.delete('/wishlist/item/$wishlistItemId');
    } catch (e) {
      debugPrint('⚠️ [WishlistRemote] removeFromWishlist failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeFromWishlistByCourseId(String userId, String courseId) async {
    debugPrint('❤️ [WishlistRemote] Removing course: $courseId');
    try {
      await apiClient.delete('/wishlist/course/$courseId');
    } catch (e) {
      debugPrint('⚠️ [WishlistRemote] removeFromWishlistByCourseId failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> isInWishlist(String userId, String courseId) async {
    debugPrint('❤️ [WishlistRemote] Checking if in wishlist: $courseId');
    try {
      final wishlist = await getWishlist(userId);
      return wishlist.any((item) => item.courseId == courseId);
    } catch (e) {
      debugPrint('⚠️ [WishlistRemote] isInWishlist failed: $e');
      return false;
    }
  }

  @override
  Future<void> clearWishlist(String userId) async {
    debugPrint('❤️ [WishlistRemote] Clearing wishlist');
    try {
      await apiClient.delete('/wishlist');
    } catch (e) {
      debugPrint('⚠️ [WishlistRemote] clearWishlist failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> getWishlistCount(String userId) async {
    try {
      final wishlist = await getWishlist(userId);
      return wishlist.length;
    } catch (e) {
      debugPrint('⚠️ [WishlistRemote] getWishlistCount failed: $e');
      return 0;
    }
  }
}
