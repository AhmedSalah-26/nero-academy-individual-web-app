/// Instructor Data Sources - Barrel file
library instructor_data_sources;

/// This file exports all instructor data sources for easy importing.
/// The original instructor_remote_data_source.dart has been split into:
/// - instructor_stats_data_source.dart - Dashboard statistics and charts
/// - instructor_courses_data_source.dart - Course management
/// - instructor_students_data_source.dart - Student management
/// - instructor_enrollments_data_source.dart - Enrollment management
/// - instructor_earnings_data_source.dart - Earnings and payouts
/// - instructor_qa_data_source.dart - Q&A management
/// - instructor_reviews_data_source.dart - Reviews
/// - instructor_course_editor_data_source.dart - Course editor methods

export 'instructor_stats_data_source.dart';
export 'instructor_courses_data_source.dart';
export 'instructor_students_data_source.dart';
export 'instructor_enrollments_data_source.dart';
export 'instructor_earnings_data_source.dart';
export 'instructor_qa_data_source.dart';
export 'instructor_reviews_data_source.dart';
export 'instructor_course_editor_data_source.dart';
export 'instructor_announcements_data_source.dart';
