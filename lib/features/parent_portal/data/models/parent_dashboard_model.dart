import '../../domain/entities/parent_dashboard_entity.dart';

class StudentDashboardModel extends StudentDashboardData {
  const StudentDashboardModel({
    required super.id,
    required super.name,
    super.avatarUrl,
    required super.courses,
    required super.quizzes,
  });

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    return StudentDashboardModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'No Name',
      avatarUrl: json['avatar_url'] as String?,
      courses: (json['courses'] as List<dynamic>?)
              ?.map(
                  (e) => StudentCourseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((e) => StudentQuizModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StudentCourseModel extends StudentCourseData {
  const StudentCourseModel({
    required super.titleAr,
    required super.titleEn,
    super.instructorName,
    required super.progress,
    super.enrolledAt,
  });

  factory StudentCourseModel.fromJson(Map<String, dynamic> json) {
    return StudentCourseModel(
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      instructorName: json['instructor_name'] as String?,
      progress: json['progress'] as int? ?? 0,
      enrolledAt: json['enrolled_at'] != null
          ? DateTime.tryParse(json['enrolled_at'].toString())
          : null,
    );
  }
}

class StudentQuizModel extends StudentQuizData {
  const StudentQuizModel({
    required super.courseTitleAr,
    required super.courseTitleEn,
    required super.quizTitleAr,
    required super.quizTitleEn,
    required super.score,
    required super.totalScore,
    required super.isPassed,
    super.completedAt,
  });

  factory StudentQuizModel.fromJson(Map<String, dynamic> json) {
    return StudentQuizModel(
      courseTitleAr: json['course_title_ar'] as String? ?? '',
      courseTitleEn: json['course_title_en'] as String? ?? '',
      quizTitleAr: json['quiz_title_ar'] as String? ?? '',
      quizTitleEn: json['quiz_title_en'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
      isPassed: json['is_passed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }
}
