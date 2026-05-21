import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/portfolio_model.dart';
import '../models/portfolio_item_model.dart';

/// Portfolio Remote Data Source
abstract class PortfolioRemoteDataSource {
  Future<PortfolioModel> getPortfolio(String userId);
  Future<PortfolioStatsModel> getPortfolioStats(String userId);
  Future<List<PortfolioItemModel>> getCompletedCourses(String userId);
  Future<List<PortfolioAchievementModel>> getAchievements(String userId);
}

/// Portfolio Remote Data Source Implementation
class PortfolioRemoteDataSourceImpl implements PortfolioRemoteDataSource {
  final SupabaseClient client;

  PortfolioRemoteDataSourceImpl({required this.client});

  @override
  Future<PortfolioModel> getPortfolio(String userId) async {
    AppLogger.i('📊 [PortfolioRemote] Getting portfolio for: $userId');

    final stats = await getPortfolioStats(userId);
    final completedCourses = await getCompletedCourses(userId);
    final achievements = await getAchievements(userId);

    return PortfolioModel(
      userId: userId,
      stats: stats,
      completedCourses: completedCourses,
      achievements: achievements,
    );
  }

  @override
  Future<PortfolioStatsModel> getPortfolioStats(String userId) async {
    AppLogger.i('📊 [PortfolioRemote] Getting stats for: $userId');

    // Get enrollments count
    final enrollments = await client
        .from('enrollments')
        .select('id, status')
        .eq('user_id', userId);

    final totalCourses = (enrollments as List).length;
    final completedCourses =
        enrollments.where((e) => e['status'] == 'completed').length;

    // Get total hours learned
    final progress = await client
        .from('lesson_progress')
        .select('watch_time')
        .eq('user_id', userId);

    int totalSeconds = 0;
    for (final item in progress as List) {
      totalSeconds += (item['watch_time'] as int?) ?? 0;
    }

    return PortfolioStatsModel(
      totalCourses: totalCourses,
      completedCourses: completedCourses,
      totalWatchTimeSeconds: totalSeconds,
      achievementsUnlocked: 3, // Mock value
      averageScore: 85.0, // Mock value
    );
  }

  @override
  Future<List<PortfolioItemModel>> getCompletedCourses(String userId) async {
    AppLogger.i('📊 [PortfolioRemote] Getting completed courses for: $userId');

    final response = await client
        .from('enrollments')
        .select('''
          id,
          course_id,
          completed_at,
          courses (
            title_en,
            thumbnail_url,
            instructor_id,
            profiles:instructor_id (name)
          )
        ''')
        .eq('user_id', userId)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);

    return (response as List).map((item) {
      final course = item['courses'] as Map<String, dynamic>?;
      final instructor = course?['profiles'] as Map<String, dynamic>?;

      return PortfolioItemModel(
        id: item['id'] as String,
        courseId: item['course_id'] as String,
        courseTitle: course?['title_en'] as String? ?? '',
        courseThumbnail: course?['thumbnail_url'] as String?,
        instructorName: instructor?['name'] as String? ?? '',
        completedAt: DateTime.parse(item['completed_at'] as String),
      );
    }).toList();
  }

  @override
  Future<List<PortfolioAchievementModel>> getAchievements(String userId) async {
    AppLogger.i('📊 [PortfolioRemote] Getting achievements for: $userId');

    // Mock achievements - replace with actual DB query
    return const [
      PortfolioAchievementModel(
        id: '1',
        title: 'First Steps',
        description: 'Complete your first course',
        iconName: 'military_tech',
        category: 'learning',
        isUnlocked: true,
        progress: 1,
        target: 1,
      ),
      PortfolioAchievementModel(
        id: '2',
        title: 'Fast Learner',
        description: 'Learn for 3 hours in one day',
        iconName: 'electric_bolt',
        category: 'learning',
        isUnlocked: true,
        progress: 3,
        target: 3,
      ),
      PortfolioAchievementModel(
        id: '3',
        title: 'Scholar',
        description: 'Complete 5 courses',
        iconName: 'auto_stories',
        category: 'learning',
        isUnlocked: false,
        progress: 2,
        target: 5,
      ),
      PortfolioAchievementModel(
        id: '4',
        title: 'Champion',
        description: 'Complete 10 courses',
        iconName: 'trophy',
        category: 'learning',
        isUnlocked: false,
        progress: 2,
        target: 10,
      ),
    ];
  }
}
