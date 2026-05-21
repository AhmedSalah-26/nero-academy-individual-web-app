import 'package:equatable/equatable.dart';

class StudentCourseData extends Equatable {
  final String titleAr;
  final String titleEn;
  final String? instructorName;
  final int progress;
  final DateTime? enrolledAt;

  const StudentCourseData({
    required this.titleAr,
    required this.titleEn,
    this.instructorName,
    required this.progress,
    this.enrolledAt,
  });

  @override
  List<Object?> get props =>
      [titleAr, titleEn, instructorName, progress, enrolledAt];
}

class StudentQuizData extends Equatable {
  final String courseTitleAr;
  final String courseTitleEn;
  final String quizTitleAr;
  final String quizTitleEn;
  final int score;
  final int totalScore;
  final bool isPassed;
  final DateTime? completedAt;

  const StudentQuizData({
    required this.courseTitleAr,
    required this.courseTitleEn,
    required this.quizTitleAr,
    required this.quizTitleEn,
    required this.score,
    required this.totalScore,
    required this.isPassed,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        courseTitleAr,
        courseTitleEn,
        quizTitleAr,
        quizTitleEn,
        score,
        totalScore,
        isPassed,
        completedAt,
      ];
}

class StudentDashboardData extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final List<StudentCourseData> courses;
  final List<StudentQuizData> quizzes;

  const StudentDashboardData({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.courses,
    required this.quizzes,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, courses, quizzes];
}
