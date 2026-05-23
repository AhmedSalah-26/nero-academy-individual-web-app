import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/cart_item_model.dart';
import '../models/cart_model.dart';
import '../models/coupon_model.dart';
import '../models/order_model.dart';
import '../models/payment_method_model.dart';
import '../../domain/entities/payment_method_entity.dart';

/// Cart Remote Data Source - API calls to Laravel REST API
abstract class CartRemoteDataSource {
  Future<CartModel> getCart(String userId);
  Future<CartItemModel> addToCart(String userId, String courseId);
  Future<void> removeFromCart(String userId, String cartItemId);
  Future<void> clearCart(String userId);
  Future<CouponModel> applyCoupon(String userId, String couponCode);
  Future<void> removeCoupon(String userId);
  Future<CouponModel> validateCoupon(String couponCode);
  Future<List<SavedPaymentMethodModel>> getSavedPaymentMethods(String userId);
  Future<OrderModel> checkout({
    required String userId,
    required PaymentMethodType paymentMethod,
    String? savedPaymentMethodId,
    Map<String, dynamic>? cardDetails,
    double couponDiscountTotal = 0,
  });
  Future<List<CartItemModel>> getRecommendedCourses(String userId, int limit);
  Future<int> getCartCount(String userId);
}

/// Cart Remote Data Source Implementation
class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final ApiClient apiClient;

  CartRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<CartModel> getCart(String userId) async {
    try {
      final response = await apiClient.get('/cart');
      final itemsList = response['items'] as List;
      final items = itemsList
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return CartModel.fromItems(userId: userId, items: items, coupon: null);
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CartItemModel> addToCart(String userId, String courseId) async {
    try {
      final response = await apiClient.post('/cart', body: {
        'course_id': courseId,
      });
      final item = response['item'] as Map<String, dynamic>;
      return CartItemModel.fromJson(item);
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    try {
      await apiClient.delete('/cart/item/$cartItemId');
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      await apiClient.delete('/cart');
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CouponModel> validateCoupon(String couponCode) async {
    try {
      final response = await apiClient.post('/coupons/validate', body: {
        'code': couponCode,
      });
      return CouponModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CouponModel> applyCoupon(String userId, String couponCode) async {
    return await validateCoupon(couponCode);
  }

  @override
  Future<void> removeCoupon(String userId) async {
    // No-op
  }

  @override
  Future<List<SavedPaymentMethodModel>> getSavedPaymentMethods(
      String userId) async {
    return [];
  }

  @override
  Future<OrderModel> checkout({
    required String userId,
    required PaymentMethodType paymentMethod,
    String? savedPaymentMethodId,
    Map<String, dynamic>? cardDetails,
    double couponDiscountTotal = 0,
  }) async {
    try {
      // 1. Get current cart items to extract course IDs
      final cartResponse = await apiClient.get('/cart');
      final itemsList = cartResponse['items'] as List;
      final courseIds = itemsList.map((e) => e['course_id'] as String).toList();

      if (courseIds.isEmpty) {
        throw const ServerException('Cart is empty');
      }

      // 2. Perform checkout on backend
      final checkoutResponse = await apiClient.post('/checkout', body: {
        'course_ids': courseIds,
      });

      final json = checkoutResponse['parent_enrollment'] as Map<String, dynamic>;
      
      // If payment is pending, we can settle it immediately for this demo / individual setup
      if (json['payment_status'] == 'pending') {
        final settleResponse = await apiClient.post('/checkout/settle/${json['id']}');
        final settledJson = settleResponse['parent_enrollment'] as Map<String, dynamic>;
        
        // Settle success implies order is now completed and cart cleared
        await clearCart(userId);
        
        final mappedJson = {
          'id': settledJson['id'],
          'user_id': settledJson['user_id'],
          'subtotal': double.tryParse(settledJson['subtotal']?.toString() ?? '') ?? 0.0,
          'discount_amount': double.tryParse(settledJson['discount']?.toString() ?? '') ?? 0.0,
          'total': double.tryParse(settledJson['total']?.toString() ?? '') ?? 0.0,
          'currency': 'EGP',
          'coupon_code': settledJson['coupon_code'],
          'payment_method': settledJson['payment_method'],
          'status': 'completed',
          'transaction_id': settledJson['payment_transaction_id'],
          'created_at': settledJson['created_at'],
          'completed_at': settledJson['paid_at'],
        };
        return OrderModel.fromJson(mappedJson);
      }

      // If already paid (e.g. total is 0)
      await clearCart(userId);

      final mappedJson = {
        'id': json['id'],
        'user_id': json['user_id'],
        'subtotal': double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0,
        'discount_amount': double.tryParse(json['discount']?.toString() ?? '') ?? 0.0,
        'total': double.tryParse(json['total']?.toString() ?? '') ?? 0.0,
        'currency': 'EGP',
        'coupon_code': json['coupon_code'],
        'payment_method': json['payment_method'],
        'status': json['payment_status'] == 'paid' ? 'completed' : 'pending',
        'transaction_id': json['payment_transaction_id'],
        'created_at': json['created_at'],
        'completed_at': json['paid_at'],
      };
      return OrderModel.fromJson(mappedJson);
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CartItemModel>> getRecommendedCourses(
      String userId, int limit) async {
    try {
      // In REST, we get all published courses and take a limit
      final response = await apiClient.get('/courses');
      final courses = response['courses'] as List;
      
      return courses.take(limit).map((e) {
        final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
        final price = double.tryParse(map['price']?.toString() ?? '') ?? 0.0;
        // Format to what CartItemModel.fromJson expects
        return CartItemModel.fromJson({
          'id': map['id'],
          'course_id': map['id'],
          'price_at_add': price,
          'created_at': DateTime.now().toIso8601String(),
          'courses': map,
        });
      }).toList();
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> getCartCount(String userId) async {
    try {
      final response = await apiClient.get('/cart/count');
      return response['count'] as int;
    } catch (e) {
      if (e is ValidationException || e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
