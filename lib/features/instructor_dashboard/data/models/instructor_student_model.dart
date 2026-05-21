/// Instructor Student Model - Contains all profile fields from database schema
class InstructorStudentModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String role; // student, instructor, admin
  final int enrolledCoursesCount;
  final double totalProgress;
  final DateTime? firstEnrolledAt;
  final DateTime? lastActivityAt;
  // Additional profile fields from schema
  final List<String> interests;
  final bool isActive;
  final bool isBanned;
  final DateTime? bannedUntil;
  final String? banReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Computed stats
  final int? completedCoursesCount;
  final int? totalWatchTime; // in seconds

  const InstructorStudentModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.role = 'student',
    required this.enrolledCoursesCount,
    required this.totalProgress,
    this.firstEnrolledAt,
    this.lastActivityAt,
    this.interests = const [],
    this.isActive = true,
    this.isBanned = false,
    this.bannedUntil,
    this.banReason,
    this.createdAt,
    this.updatedAt,
    this.completedCoursesCount,
    this.totalWatchTime,
  });

  factory InstructorStudentModel.fromJson(Map<String, dynamic> json) {
    return InstructorStudentModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'student',
      enrolledCoursesCount: json['enrolled_courses'] as int? ?? 0,
      totalProgress: (json['total_progress'] as num?)?.toDouble() ?? 0,
      firstEnrolledAt: json['enrolled_at'] != null
          ? DateTime.tryParse(json['enrolled_at'] as String)
          : null,
      lastActivityAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'] as String)
          : null,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
      isBanned: json['is_banned'] as bool? ?? false,
      bannedUntil: json['banned_until'] != null
          ? DateTime.tryParse(json['banned_until'] as String)
          : null,
      banReason: json['ban_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      completedCoursesCount: json['completed_courses'] as int?,
      totalWatchTime: json['total_watch_time'] as int?,
    );
  }

  /// Format watch time to human readable string
  String get formattedWatchTime {
    if (totalWatchTime == null) return '0h';
    final hours = totalWatchTime! ~/ 3600;
    final minutes = (totalWatchTime! % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
