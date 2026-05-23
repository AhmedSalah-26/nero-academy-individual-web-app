import '../../domain/entities/cart_item_entity.dart';

/// Cart Item Model - Data Model with JSON serialization
class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.id,
    required super.courseId,
    super.titleAr,
    super.titleEn,
    super.thumbnailUrl,
    super.instructorName,
    super.rating,
    super.ratingCount,
    super.price,
    super.discountPrice,
    super.priceAtAdd,
    super.currency,
    super.isFree,
    required super.addedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Parse course data if nested
    final course = json['courses'] as Map<String, dynamic>?;

    // Handle instructor - can be from profiles (new) or instructor_profiles (old)
    String? instructorName;
    final profiles = course?['profiles'] as Map<String, dynamic>?;
    final instructorProfiles =
        course?['instructor_profiles'] as Map<String, dynamic>?;

    if (profiles != null) {
      instructorName = profiles['name'] as String?;
    } else if (instructorProfiles != null) {
      instructorName = instructorProfiles['display_name'] as String?;
    } else {
      instructorName = json['instructor_name'] as String?;
    }

    return CartItemModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      titleAr: course?['title_ar'] as String? ?? json['title_ar'] as String?,
      titleEn: course?['title_en'] as String? ?? json['title_en'] as String?,
      thumbnailUrl: course?['thumbnail_url'] as String? ??
          json['thumbnail_url'] as String?,
      instructorName: instructorName,
      rating: _toDouble(course?['rating']) ?? _toDouble(json['rating']) ?? 0,
      ratingCount: _toInt(course?['rating_count']) ??
          _toInt(json['rating_count']) ??
          0,
      price: _toDouble(course?['price']) ?? _toDouble(json['price']) ?? 0,
      discountPrice: _resolveEffectiveDiscountPrice(course, json),
      priceAtAdd: _toDouble(json['price_at_add']) ?? 0,
      currency: course?['currency'] as String? ??
          json['currency'] as String? ??
          'EGP',
      isFree: _toBool(course?['is_free']) ?? _toBool(json['is_free']) ?? false,
      addedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'thumbnail_url': thumbnailUrl,
      'instructor_name': instructorName,
      'rating': rating,
      'rating_count': ratingCount,
      'price': price,
      'discount_price': discountPrice,
      'price_at_add': priceAtAdd,
      'currency': currency,
      'is_free': isFree,
      'created_at': addedAt.toIso8601String(),
    };
  }

  static double? _resolveEffectiveDiscountPrice(
    Map<String, dynamic>? course,
    Map<String, dynamic> json,
  ) {
    final baseDiscountPrice =
        _toDouble(course?['discount_price']) ?? _toDouble(json['discount_price']);

    final isFlashSale =
        _toBool(course?['is_flash_sale']) ?? _toBool(json['is_flash_sale']) ?? false;

    if (!isFlashSale) {
      // Regular permanent discount
      return baseDiscountPrice;
    }

    // Flash sale: discount only applies during the sale window
    final flashSaleStart =
        _parseDateTime(course?['flash_sale_start'] ?? json['flash_sale_start']);
    final flashSaleEnd =
        _parseDateTime(course?['flash_sale_end'] ?? json['flash_sale_end']);
    final now = DateTime.now();
    final isFlashSaleActive =
        (flashSaleStart == null || !now.isBefore(flashSaleStart)) &&
            (flashSaleEnd == null || !now.isAfter(flashSaleEnd));

    return isFlashSaleActive ? baseDiscountPrice : null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') return true;
      if (value == '0' || value.toLowerCase() == 'false') return false;
    }
    return null;
  }
}
