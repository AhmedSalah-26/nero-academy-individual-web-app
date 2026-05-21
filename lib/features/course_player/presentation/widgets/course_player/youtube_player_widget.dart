import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../../core/services/app_logger.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_player_cubit.dart';
import '../../screens/fullscreen_player_screen.dart';

/// YouTube Player Widget - Optimized with fullscreen support via dedicated screen
class YouTubePlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isDark;
  final int? initialPosition;
  final String? courseTitle;
  final String? lessonTitle;

  const YouTubePlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isDark,
    this.initialPosition,
    this.courseTitle,
    this.lessonTitle,
  });

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget>
    with AutomaticKeepAliveClientMixin {
  late YoutubePlayerController _controller;
  bool _isControllerInitialized = false;
  int _lastSavedPosition = 0;
  Timer? _progressTimer;
  String? _currentVideoId;
  bool _hasAutoPlayed = false;
  bool _isBuffering = false;
  bool _isRestartingAfterEnd = false;
  bool _isHandlingVideoEnd = false;
  bool _isPreloading = true; // Flag to hide player during preload
  Timer? _preloadCheckTimer; // Timer to check video position periodically
  bool _showOverlay = true; // Add overlay to hide YouTube branding
  bool _hasCompletedInitialPreload = false; // Track if initial preload is done
  bool _hasError = false; // Track if video failed to load

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _currentVideoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (_currentVideoId == null) {
      AppLogger.e('[YouTubePlayer] Invalid YouTube URL: ${widget.videoUrl}');
      setState(() => _hasError = true);
      return;
    }

    try {
      _controller = YoutubePlayerController(
        initialVideoId: _currentVideoId!,
        flags: YoutubePlayerFlags(
          autoPlay:
              !_hasCompletedInitialPreload, // Auto play only for initial preload
          mute:
              !_hasCompletedInitialPreload, // Mute only during initial preload
          enableCaption: false, // Disable captions
          hideControls: false, // Show native controls
          controlsVisibleAtStart: true, // Show controls initially
          startAt: _hasCompletedInitialPreload
              ? (widget.initialPosition ?? 0)
              : 0, // Start from 0 only for preload
          hideThumbnail: true,
          forceHD: true,
          disableDragSeek: false,
          loop: false, // Manual replay on end to block YouTube suggestions
          showLiveFullscreenButton:
              false, // Hide fullscreen button from native controls
          useHybridComposition: true, // Better performance and less UI glitches
        ),
      );
      _isControllerInitialized = true;

      _controller.addListener(_onPlayerStateChanged);
      _startProgressTimer();

      // Start preload trick only on first load
      if (!_hasCompletedInitialPreload) {
        _startPreloadCheck();
      } else {
        _showOverlay = false; // Don't show overlay after initial preload
      }

      AppLogger.i('[YouTubePlayer] Initialized with video: $_currentVideoId');
    } catch (e) {
      AppLogger.e('[YouTubePlayer] Failed to initialize: $e');
      setState(() => _hasError = true);
    }
  }

  /// Start checking for actual video playback position
  /// Wait until video has actually played for 3 seconds (not wall-clock time)
  void _startPreloadCheck() {
    int checkCount = 0;
    const maxChecks = 20; // 10 seconds timeout (20 * 500ms)

    // Check every 500ms if video has played 3 seconds
    _preloadCheckTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      checkCount++;

      // Timeout after 10 seconds - video probably failed to load
      if (checkCount >= maxChecks) {
        timer.cancel();
        setState(() => _hasError = true);
        AppLogger.e('[YouTubePlayer] Video loading timeout');
        return;
      }

      // Check if video position has reached 3 seconds
      final currentPosition = _controller.value.position.inSeconds;

      // Check for error state
      if (_controller.value.hasError) {
        timer.cancel();
        setState(() => _hasError = true);
        AppLogger.e('[YouTubePlayer] Video failed to load');
        return;
      }

      if (currentPosition >= 3) {
        timer.cancel();
        _completePreload();
      }
    });
  }

  /// Complete the preload trick after 3 actual seconds of video playback
  void _completePreload() {
    if (!mounted) return;

    // Pause, unmute, and seek to initial position
    _controller.pause();
    _controller.unMute(); // Unmute
    _controller.seekTo(Duration(seconds: widget.initialPosition ?? 0));

    setState(() {
      _showOverlay = false; // Hide black overlay
      _isPreloading = false;
      _hasCompletedInitialPreload = true; // Mark preload as complete
    });

    AppLogger.i(
        '[YouTubePlayer] Preload complete (3 actual seconds played), ready for user');
  }

  void _onPlayerStateChanged() {
    if (!mounted || !_isControllerInitialized) return;

    final playerValue = _controller.value;
    final playerState = playerValue.playerState;

    // Check for error state
    if (playerValue.hasError && !_hasError) {
      setState(() => _hasError = true);
      AppLogger.e('[YouTubePlayer] Player error detected');
      return;
    }

    final isBufferingNow = playerState == PlayerState.buffering;
    if (isBufferingNow != _isBuffering) {
      setState(() => _isBuffering = isBufferingNow);
    }

    final totalMs = playerValue.metaData.duration.inMilliseconds;
    final positionMs = playerValue.position.inMilliseconds;
    final remainingMs = totalMs - positionMs;
    final shouldRestartBeforeLastSecond = !_isPreloading &&
        playerValue.isPlaying &&
        totalMs > 1500 &&
        remainingMs <= 900 &&
        remainingMs >= 0;

    if (shouldRestartBeforeLastSecond && !_isHandlingVideoEnd) {
      unawaited(_restartAfterVideoEnd());
      return;
    }

    if (!_isPreloading &&
        playerState == PlayerState.ended &&
        !_isHandlingVideoEnd) {
      unawaited(_restartAfterVideoEnd());
      return;
    }

    if (!_hasAutoPlayed && _controller.value.isReady && !_isPreloading) {
      _hasAutoPlayed = true;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !_controller.value.isPlaying) {
          _controller.play();
        }
      });
    }
  }

  Future<void> _restartAfterVideoEnd() async {
    if (!_isControllerInitialized || !mounted || _isHandlingVideoEnd) return;

    _isHandlingVideoEnd = true;
    if (!_isRestartingAfterEnd) {
      setState(() => _isRestartingAfterEnd = true);
    }

    try {
      _controller.pause();
      await Future.delayed(const Duration(milliseconds: 60));
      _controller.seekTo(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) {
        _controller.play();
      }
    } catch (_) {
      // Ignore transient webview/player errors during forced replay.
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) {
          setState(() => _isRestartingAfterEnd = false);
        }
      }
      _isHandlingVideoEnd = false;
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _controller.value.isPlaying) {
        final currentPosition = _controller.value.position.inSeconds;
        if (currentPosition > _lastSavedPosition) {
          _lastSavedPosition = currentPosition;
          _saveProgress(currentPosition);
        }
      }
    });
  }

  void _saveProgress(int seconds) {
    if (seconds <= 0 || !mounted) return;

    CoursePlayerCubit? cubit;
    try {
      cubit = context.read<CoursePlayerCubit>();
    } catch (_) {
      // Used outside course-player context (e.g. preview screen).
      return;
    }

    if (cubit.state.currentLesson != null && cubit.state.enrollmentId != null) {
      if (seconds % 60 == 0) {
        AppLogger.i('[YouTubePlayer] Saving watch time: $seconds seconds');
      }
      cubit.updateProgress(
        watchedSeconds: seconds,
        lastPosition: seconds,
      );
    }
  }

  Future<void> _openFullscreen() async {
    // Pause the current player
    _controller.pause();

    final currentPosition = _controller.value.position.inSeconds;

    // Navigate to fullscreen screen
    final result = await Navigator.of(context, rootNavigator: true).push<int>(
      MaterialPageRoute(
        builder: (_) => FullscreenPlayerScreen(
          videoUrl: widget.videoUrl,
          initialPosition: currentPosition,
          courseTitle: widget.courseTitle,
          lessonTitle: widget.lessonTitle,
        ),
      ),
    );

    // Resume from returned position
    if (result != null && mounted) {
      _controller.seekTo(Duration(seconds: result));
    }
  }

  @override
  void dispose() {
    if (_isControllerInitialized) {
      _controller.removeListener(_onPlayerStateChanged);
      final controller = _controller;
      Future.microtask(() {
        try {
          controller.dispose();
        } catch (_) {}
      });
    }
    _progressTimer?.cancel();
    _preloadCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(YouTubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      AppLogger.i('[YouTubePlayer] Switching video...');
      final newVideoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

      if (_isControllerInitialized &&
          newVideoId != null &&
          newVideoId != _currentVideoId) {
        _currentVideoId = newVideoId;
        _lastSavedPosition = 0;
        _hasAutoPlayed = false;
        _isHandlingVideoEnd = false;
        _isRestartingAfterEnd = false;
        // Don't reset _hasCompletedInitialPreload - keep it true
        _controller.load(newVideoId, startAt: widget.initialPosition ?? 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Show error widget if video is invalid or has error
    if (_currentVideoId == null || _hasError) {
      return _buildErrorWidget();
    }

    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            YoutubePlayer(
              controller: _controller,
              bufferIndicator: const SizedBox.shrink(),
              showVideoProgressIndicator: false, // Hide the loading indicator
              progressIndicatorColor: AppColors.primary,
              progressColors: const ProgressBarColors(
                playedColor: AppColors.primary,
                handleColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
              bottomActions: [
                const SizedBox(width: 8),
                const CurrentPosition(),
                const SizedBox(width: 8),
                const ProgressBar(
                  isExpanded: true,
                  colors: ProgressBarColors(
                    playedColor: AppColors.primary,
                    handleColor: AppColors.primary,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(width: 8),
                const RemainingDuration(),
                const SizedBox(width: 8),
                // Rewind 10 seconds button
                IconButton(
                  onPressed: () {
                    final currentPosition = _controller.value.position;
                    final newPosition =
                        currentPosition - const Duration(seconds: 10);
                    _controller.seekTo(
                      newPosition.isNegative ? Duration.zero : newPosition,
                    );
                  },
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'رجوع 10 ثواني',
                ),
                // Forward 10 seconds button
                IconButton(
                  onPressed: () {
                    final currentPosition = _controller.value.position;
                    final duration = _controller.metadata.duration;
                    final newPosition =
                        currentPosition + const Duration(seconds: 10);
                    _controller.seekTo(
                      newPosition > duration ? duration : newPosition,
                    );
                  },
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'تقديم 10 ثواني',
                ),
                const PlaybackSpeedButton(),
                // Custom fullscreen button that opens dedicated screen
                IconButton(
                  onPressed: _openFullscreen,
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
              // Hide the top bar with channel name and video title
              topActions: const [],
              // Use onReady to ensure listeners are attached
              onReady: () {
                // _controller.addListener(_onPlayerStateChanged); // Already added in init
              },
            ),
            if (_showOverlay || _isBuffering || _isRestartingAfterEnd)
              Positioned.fill(
                child: _buildLoadingOverlay(isInitial: _showOverlay),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay({required bool isInitial}) {
    final showLabel = isInitial;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101010), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 12),
              Text(
                'common.loading'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
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
