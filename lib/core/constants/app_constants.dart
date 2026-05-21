/// App Constants - Central configuration
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'منصة التعليم';
  static const String appNameEn = 'Learning Platform';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  static const String supabaseUrl = 'https://glffragviwrrveqojlhb.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsZmZyYWd2aXdycnZlcW9qbGhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MzUxNjgsImV4cCI6MjA4MzMxMTE2OH0.7D9RPvizCEe-k6TiJSs8PdH14eidt5AoXzkHcF7ri-A';

  // Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String coursesBucket = 'courses';
  static const String certificatesBucket = 'certificates';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration shortCacheDuration = Duration(minutes: 15);

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxBioLength = 500;

  // Deep Links
  static const String deepLinkScheme = 'io.supabase.lms';
  static const String deepLinkHost = 'login-callback';

  // Password Reset Web Page
  static const String passwordResetRedirectUrl =
      'https://ahmedsalah-26.github.io/yalla-course/reset-password/';
}
