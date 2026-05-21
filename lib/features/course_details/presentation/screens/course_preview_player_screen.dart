import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../course_player/presentation/widgets/course_player/youtube_player_widget.dart';

/// In-app preview player screen for course preview videos.
class CoursePreviewPlayerScreen extends StatelessWidget {
  final String videoUrl;
  final String? courseTitle;

  const CoursePreviewPlayerScreen({
    super.key,
    required this.videoUrl,
    this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidVideo = YoutubePlayer.convertUrlToId(videoUrl) != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: hasValidVideo
              ? YouTubePlayerWidget(
                  videoUrl: videoUrl,
                  isDark: true,
                  courseTitle: courseTitle,
                )
              : _buildInvalidLinkState(),
        ),
      ),
    );
  }

  Widget _buildInvalidLinkState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            'course_details.invalid_preview_link'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
