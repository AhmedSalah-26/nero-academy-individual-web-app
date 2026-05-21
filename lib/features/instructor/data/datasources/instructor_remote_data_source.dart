import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/instructor_entity.dart';
import '../../domain/entities/instructor_course_entity.dart';

abstract class InstructorRemoteDataSource {
  Future<InstructorEntity?> getInstructor(String visitorId);
  Future<List<InstructorCourseEntity>> getInstructorCourses(String visitorId);
  Future<List<InstructorEntity>> getTopInstructors({int limit = 10});
}

class InstructorRemoteDataSourceImpl implements InstructorRemoteDataSource {
  final SupabaseClient client;

  InstructorRemoteDataSourceImpl(this.client);

  @override
  Future<InstructorEntity?> getInstructor(String visitorId) async {
    AppLogger.i('[Instructor] Loading instructor: $visitorId');

    final instructorProfileById = await client
        .from('instructor_profiles')
        .select()
        .eq('id', visitorId)
        .maybeSingle();

    if (instructorProfileById != null) {
      final profileBasics =
          await _loadProfileBasicsForInstructorRow(instructorProfileById);
      return _mapFromInstructorProfiles(
        instructorProfileById,
        fallbackName: profileBasics?['name'] as String?,
        fallbackAvatar: profileBasics?['avatar_url'] as String?,
        fallbackJoinedAtRaw: profileBasics?['created_at'],
      );
    }

    final instructorProfileByInstructorId = await client
        .from('instructor_profiles')
        .select()
        .eq('instructor_id', visitorId)
        .maybeSingle();

    if (instructorProfileByInstructorId != null) {
      final profileBasics = await _loadProfileBasicsForInstructorRow(
          instructorProfileByInstructorId);
      return _mapFromInstructorProfiles(
        instructorProfileByInstructorId,
        fallbackName: profileBasics?['name'] as String?,
        fallbackAvatar: profileBasics?['avatar_url'] as String?,
        fallbackJoinedAtRaw: profileBasics?['created_at'],
      );
    }

    final profile = await client
        .from('profiles')
        .select('id, name, email, avatar_url, created_at')
        .eq('id', visitorId)
        .maybeSingle();

    if (profile != null) {
      return _mapFromProfiles(profile, visitorId);
    }

    AppLogger.w('[Instructor] Instructor not found: $visitorId');
    return null;
  }

  String? _sanitizeText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _parseDate(dynamic value) {
    final raw = _sanitizeText(value);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<Map<String, dynamic>?> _loadProfileBasicsForInstructorRow(
      Map<String, dynamic> instructorRow) async {
    final instructorId = _sanitizeText(instructorRow['instructor_id']) ??
        _sanitizeText(instructorRow['id']);
    if (instructorId == null) return null;

    return client
        .from('profiles')
        .select('id, name, avatar_url, created_at')
        .eq('id', instructorId)
        .maybeSingle();
  }

  InstructorEntity _mapFromInstructorProfiles(
    Map<String, dynamic> data, {
    String? fallbackName,
    String? fallbackAvatar,
    dynamic fallbackJoinedAtRaw,
  }) {
    final socialLinks = data['social_links'] as Map<String, dynamic>?;

    return InstructorEntity(
      id: _sanitizeText(data['id']) ?? '',
      name: _sanitizeText(data['display_name']) ?? fallbackName ?? 'Instructor',
      avatarUrl: _sanitizeText(data['avatar_url']) ?? fallbackAvatar,
      coverImageUrl: _sanitizeText(data['cover_image_url']),
      headline: _sanitizeText(data['headline_ar']) ??
          _sanitizeText(data['headline_en']),
      bio: _sanitizeText(data['bio_ar']) ?? _sanitizeText(data['bio_en']),
      expertise: data['expertise'] != null
          ? List<String>.from(data['expertise'] as List)
          : null,
      totalStudents: data['total_students'] as int? ?? 0,
      totalCourses: data['total_courses'] as int? ?? 0,
      averageRating: _asDouble(data['average_rating']),
      totalReviews: data['total_reviews'] as int? ?? 0,
      website: _sanitizeText(data['website_url']) ??
          _sanitizeText(socialLinks?['website']),
      linkedin: _sanitizeText(socialLinks?['linkedin']),
      twitter: _sanitizeText(socialLinks?['twitter']),
      facebook: _sanitizeText(socialLinks?['facebook']),
      youtube: _sanitizeText(socialLinks?['youtube']),
      joinedAt:
          _parseDate(data['created_at']) ?? _parseDate(fallbackJoinedAtRaw),
    );
  }

  Future<InstructorEntity> _mapFromProfiles(
    Map<String, dynamic> profile,
    String instructorId,
  ) async {
    final instructorProfile = await client
        .from('instructor_profiles')
        .select()
        .eq('instructor_id', instructorId)
        .maybeSingle();

    if (instructorProfile != null) {
      return _mapFromInstructorProfiles(
        instructorProfile,
        fallbackName: _sanitizeText(profile['name']) ??
            _sanitizeText(profile['email'])?.split('@').first,
        fallbackAvatar: _sanitizeText(profile['avatar_url']),
        fallbackJoinedAtRaw: profile['created_at'],
      );
    }

    final coursesResponse = await client
        .from('courses')
        .select('id, rating, rating_count')
        .eq('instructor_id', instructorId);

    final courses = coursesResponse as List;
    int totalStudents = 0;
    double totalRating = 0;
    int totalReviews = 0;

    for (final course in courses) {
      final row = course as Map<String, dynamic>;
      totalRating += _asDouble(row['rating']);
      totalReviews += row['rating_count'] as int? ?? 0;
    }

    if (courses.isNotEmpty) {
      final courseIds = courses
          .map((c) => (c as Map<String, dynamic>)['id'])
          .where((id) => id != null)
          .toList();
      if (courseIds.isNotEmpty) {
        final enrollmentsResponse = await client
            .from('enrollments')
            .select('id')
            .inFilter('course_id', courseIds);
        totalStudents = (enrollmentsResponse as List).length;
      }
    }

    return InstructorEntity(
      id: _sanitizeText(profile['id']) ?? instructorId,
      name: _sanitizeText(profile['name']) ??
          _sanitizeText(profile['email'])?.split('@').first ??
          'Instructor',
      avatarUrl: _sanitizeText(profile['avatar_url']),
      coverImageUrl: null,
      headline: null,
      bio: null,
      expertise: null,
      totalStudents: totalStudents,
      totalCourses: courses.length,
      averageRating: courses.isNotEmpty ? totalRating / courses.length : 0.0,
      totalReviews: totalReviews,
      website: null,
      linkedin: null,
      twitter: null,
      facebook: null,
      youtube: null,
      joinedAt: _parseDate(profile['created_at']),
    );
  }

  @override
  Future<List<InstructorCourseEntity>> getInstructorCourses(
      String visitorId) async {
    AppLogger.i('[Instructor] Loading courses for: $visitorId');

    final instructorProfile = await client
        .from('instructor_profiles')
        .select('instructor_id')
        .eq('id', visitorId)
        .maybeSingle();

    final actualInstructorId = instructorProfile?['instructor_id'] ?? visitorId;

    final response = await client
        .from('courses')
        .select()
        .eq('instructor_id', actualInstructorId)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final row = json as Map<String, dynamic>;
      return InstructorCourseEntity(
        id: row['id'] as String,
        title: row['title_en'] ?? row['title_ar'] ?? '',
        titleAr: row['title_ar'] as String?,
        thumbnailUrl: row['thumbnail_url'] as String?,
        price: _asDouble(row['price']),
        discountPrice: row['discount_price'] != null
            ? _asDouble(row['discount_price'])
            : null,
        isFlashSale: row['is_flash_sale'] == true,
        flashSaleStart: row['flash_sale_start'] != null
            ? DateTime.tryParse(row['flash_sale_start'].toString())
            : null,
        flashSaleEnd: row['flash_sale_end'] != null
            ? DateTime.tryParse(row['flash_sale_end'].toString())
            : null,
        currency: row['currency'] as String? ?? 'EGP',
        rating: _asDouble(row['rating']),
        ratingCount: row['rating_count'] as int? ?? 0,
        enrolledCount: row['enrolled_count'] as int? ?? 0,
        isFree: row['is_free'] == true,
        isBestseller: (row['enrolled_count'] as int? ?? 0) > 100,
      );
    }).toList();
  }

  @override
  Future<List<InstructorEntity>> getTopInstructors({int limit = 10}) async {
    AppLogger.i('[Instructor] Loading top instructors (limit: $limit)');

    final instructors = <InstructorEntity>[];
    final seenInstructorIds = <String>{};

    final instructorProfilesQuery = client
        .from('instructor_profiles')
        .select()
        .eq('is_active', true)
        .order('total_students', ascending: false);

    final instructorProfilesResponse = limit > 0
        ? await instructorProfilesQuery.limit(limit)
        : await instructorProfilesQuery;

    final instructorRows =
        (instructorProfilesResponse as List).cast<Map<String, dynamic>>();
    final instructorIds = instructorRows
        .map((row) => _sanitizeText(row['instructor_id']))
        .whereType<String>()
        .toList();

    final profileByInstructorId = <String, Map<String, dynamic>>{};
    if (instructorIds.isNotEmpty) {
      final profiles = await client
          .from('profiles')
          .select('id, name, email, avatar_url, created_at')
          .inFilter('id', instructorIds);
      for (final row in (profiles as List).cast<Map<String, dynamic>>()) {
        final id = _sanitizeText(row['id']);
        if (id != null) {
          profileByInstructorId[id] = row;
        }
      }
    }

    for (final row in instructorRows) {
      final instructorId = _sanitizeText(row['instructor_id']);
      final profile =
          instructorId != null ? profileByInstructorId[instructorId] : null;

      instructors.add(
        _mapFromInstructorProfiles(
          row,
          fallbackName: _sanitizeText(profile?['name']) ??
              _sanitizeText(profile?['email'])?.split('@').first,
          fallbackAvatar: _sanitizeText(profile?['avatar_url']),
          fallbackJoinedAtRaw: profile?['created_at'],
        ),
      );

      if (instructorId != null && instructorId.isNotEmpty) {
        seenInstructorIds.add(instructorId);
      }
    }

    final fallbackProfiles = await client
        .from('profiles')
        .select('id, name, email, avatar_url, created_at')
        .eq('role', 'instructor')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    for (final profileData in (fallbackProfiles as List)) {
      final profile = profileData as Map<String, dynamic>;
      final profileId = _sanitizeText(profile['id']);

      if (profileId == null || profileId.isEmpty) continue;
      if (seenInstructorIds.contains(profileId)) continue;

      final mapped = await _mapFromProfiles(profile, profileId);
      instructors.add(mapped);
      seenInstructorIds.add(profileId);

      if (limit > 0 && instructors.length >= limit) {
        break;
      }
    }

    if (limit > 0 && instructors.length > limit) {
      return instructors.take(limit).toList();
    }

    return instructors;
  }
}
