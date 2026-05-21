/// Instructor Course Model
class InstructorCourseModel {
  final String id;
  final String titleAr;
  final String? titleEn;
  final String? thumbnailUrl;
  final double price;
  final double? discountPrice;
  final bool isPublished;
  final bool isSuspended;
  final String? suspensionReason;
  final int enrollmentCount;
  final double averageRating;
  final int reviewCount;
  final double totalRevenue;
  final int lessonCount;
  final int sectionCount;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? badge;
  final bool isFlashSale;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;

  const InstructorCourseModel({
    required this.id,
    required this.titleAr,
    this.titleEn,
    this.thumbnailUrl,
    required this.price,
    this.discountPrice,
    required this.isPublished,
    required this.isSuspended,
    this.suspensionReason,
    required this.enrollmentCount,
    required this.averageRating,
    required this.reviewCount,
    required this.totalRevenue,
    required this.lessonCount,
    required this.sectionCount,
    required this.createdAt,
    this.publishedAt,
    this.badge,
    this.isFlashSale = false,
    this.flashSaleStart,
    this.flashSaleEnd,
  });

  String getTitle(bool isArabic) => isArabic ? titleAr : (titleEn ?? titleAr);

  InstructorCourseModel copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    String? thumbnailUrl,
    double? price,
    double? discountPrice,
    bool? isPublished,
    bool? isSuspended,
    String? suspensionReason,
    int? enrollmentCount,
    double? averageRating,
    int? reviewCount,
    double? totalRevenue,
    int? lessonCount,
    int? sectionCount,
    DateTime? createdAt,
    DateTime? publishedAt,
    String? badge,
    bool? isFlashSale,
    DateTime? flashSaleStart,
    DateTime? flashSaleEnd,
  }) {
    return InstructorCourseModel(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      isPublished: isPublished ?? this.isPublished,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      lessonCount: lessonCount ?? this.lessonCount,
      sectionCount: sectionCount ?? this.sectionCount,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      badge: badge ?? this.badge,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      flashSaleStart: flashSaleStart ?? this.flashSaleStart,
      flashSaleEnd: flashSaleEnd ?? this.flashSaleEnd,
    );
  }

  factory InstructorCourseModel.fromJson(Map<String, dynamic> json) {
    // Parse section and lesson counts from nested aggregates
    int sectionCount = 0;
    int lessonCount = 0;

    if (json['sections'] != null) {
      if (json['sections'] is List && json['sections'].isNotEmpty) {
        final sectionsData = json['sections'][0];
        if (sectionsData is Map && sectionsData['count'] != null) {
          sectionCount = sectionsData['count'] as int;
        }
      } else if (json['sections'] is int) {
        sectionCount = json['sections'] as int;
      }
    }

    if (json['lessons'] != null) {
      if (json['lessons'] is List && json['lessons'].isNotEmpty) {
        final lessonsData = json['lessons'][0];
        if (lessonsData is Map && lessonsData['count'] != null) {
          lessonCount = lessonsData['count'] as int;
        }
      } else if (json['lessons'] is int) {
        lessonCount = json['lessons'] as int;
      }
    }

    // Fallback to direct fields
    sectionCount =
        sectionCount > 0 ? sectionCount : (json['section_count'] as int? ?? 0);
    lessonCount =
        lessonCount > 0 ? lessonCount : (json['lesson_count'] as int? ?? 0);

    return InstructorCourseModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      isPublished: json['is_published'] as bool? ?? false,
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspensionReason: json['suspension_reason'] as String?,
      // Use database fields: enrolled_count, rating, rating_count
      enrollmentCount: json['enrolled_count'] as int? ??
          json['enrollment_count'] as int? ??
          0,
      averageRating: (json['rating'] as num?)?.toDouble() ??
          (json['average_rating'] as num?)?.toDouble() ??
          0,
      reviewCount:
          json['rating_count'] as int? ?? json['review_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      lessonCount: lessonCount,
      sectionCount: sectionCount,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      badge: json['badge'] as String?,
      isFlashSale: json['is_flash_sale'] as bool? ?? false,
      flashSaleStart: json['flash_sale_start'] != null
          ? DateTime.parse(json['flash_sale_start'] as String)
          : null,
      flashSaleEnd: json['flash_sale_end'] != null
          ? DateTime.parse(json['flash_sale_end'] as String)
          : null,
    );
  }
}
