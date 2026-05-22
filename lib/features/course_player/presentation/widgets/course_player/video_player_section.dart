import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/lesson_entity.dart';
import '../../cubit/course_player_cubit.dart';
import 'direct_video_player_widget.dart';
import 'youtube_player_widget.dart';

/// Video Player Section Widget
class VideoPlayerSection extends StatelessWidget {
  final LessonEntity lesson;
  final int currentPosition;
  final int totalDuration;
  final bool isPlaying;
  final bool isDark;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay10;
  final VoidCallback onForward10;
  final VoidCallback onFullscreen;
  final VoidCallback onCast;
  final ValueChanged<double> onSeek;
  final VoidCallback onSpeedTap;
  final VoidCallback? onBack;
  final VoidCallback? onTap;
  final String? courseTitle;
  final int sectionIndex;
  final int lessonIndex;

  const VideoPlayerSection({
    super.key,
    required this.lesson,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.isDark,
    required this.onPlayPause,
    required this.onReplay10,
    required this.onForward10,
    required this.onFullscreen,
    required this.onCast,
    required this.onSeek,
    required this.onSpeedTap,
    this.onBack,
    this.onTap,
    this.courseTitle,
    this.sectionIndex = 0,
    this.lessonIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      final videoUrl = lesson.videoUrl!.trim();
      final progress = context.read<CoursePlayerCubit>().state.currentProgress;
      final initialPosition = progress?.lastPosition ?? 0;
      final isYouTube = _isYouTubeUrl(videoUrl) ||
          lesson.videoProvider == VideoProvider.youtube;
      final shouldUseDirectPlayer = !isYouTube ||
          lesson.videoProvider == VideoProvider.supabase ||
          lesson.videoProvider == VideoProvider.bunny;

      if (shouldUseDirectPlayer) {
        return DirectVideoPlayerWidget(
          key: ValueKey('direct-${lesson.id}'),
          videoUrl: videoUrl,
          isDark: isDark,
          initialPosition: initialPosition,
        );
      }

      if (kIsWeb) {
        return _buildUnsupportedWebYouTubeWidget();
      }

      return YouTubePlayerWidget(
        key: ValueKey(lesson.id), // Prevent rebuilds when switching lessons
        videoUrl: videoUrl,
        isDark: isDark,
        initialPosition: initialPosition,
        courseTitle: courseTitle,
        lessonTitle: lesson.titleAr,
      );
    }

    // No video URL - show error message
    return _buildNoVideoWidget();
  }

  bool _isYouTubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') ||
        lower.contains('youtube-nocookie.com') ||
        lower.contains('youtu.be');
  }

  Widget _buildUnsupportedWebYouTubeWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.public_off_rounded,
                color: AppColors.error,
                size: 44,
              ),
              const SizedBox(height: 14),
              Text(
                'course_player.video_unavailable'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'YouTube links need an embed player on web. Upload a direct MP4/Supabase video URL to play with the web video player.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoVideoWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_outlined,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'course_player.video_unavailable'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'course_player.video_unavailable_desc'.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
