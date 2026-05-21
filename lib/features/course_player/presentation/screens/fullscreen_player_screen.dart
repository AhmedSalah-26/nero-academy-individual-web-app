import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/screen_protection_service.dart';

/// Fullscreen Player Screen - Dedicated screen for fullscreen video playback
class FullscreenPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final int initialPosition;
  final String? courseTitle;
  final String? lessonTitle;

  const FullscreenPlayerScreen({
    super.key,
    required this.videoUrl,
    this.initialPosition = 0,
    this.courseTitle,
    this.lessonTitle,
  });

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isControllerInitialized = false;
  String? _videoId;
  int _currentPosition = 0;
  bool _isExiting = false;
  bool _hasAutoPlayed = false;
  bool _isBuffering = false;
  bool _isRestartingAfterEnd = false;
  bool _isHandlingVideoEnd = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isPreloading = true; // Flag for preload trick
  bool _showOverlay = true; // Overlay to hide YouTube branding
  Timer? _preloadCheckTimer; // Timer to check video position periodically

  @override
  void initState() {
    super.initState();
    // Ensure screen protection stays on during fullscreen
    ScreenProtectionService.enable();
    unawaited(_setupFullscreen());
    _initializePlayer();
  }

  Future<void> _setupFullscreen() async {
    // Hide system UI for immersive experience
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    // Force landscape orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializePlayer() {
    _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (_videoId == null) {
      AppLogger.e('[Fullscreen] Invalid YouTube URL: ${widget.videoUrl}');
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true, // Auto play for preload trick
        mute: true, // Mute during preload
        enableCaption: false, // Disable captions
        hideControls: true,
        controlsVisibleAtStart: false,
        startAt: 0, // Start from 0 for preload
        hideThumbnail: true,
        forceHD: true,
        disableDragSeek: false,
        loop: false, // Manual replay on end to block YouTube suggestions
        isLive: false,
      ),
    );
    _isControllerInitialized = true;

    _controller.addListener(_updatePosition);
    _controller.addListener(_onPlayerStateChanged);
    AppLogger.i(
        '[Fullscreen] Player initialized at position: ${widget.initialPosition}');

    // Start preload trick - wait for actual video playback
    _startPreloadCheck();

    // Auto-hide controls initially
    _startControlsTimer();
  }

  void _onPlayerStateChanged() {
    if (!mounted || !_isControllerInitialized) return;

    final playerValue = _controller.value;
    final playerState = playerValue.playerState;

    final isBufferingNow = playerState == PlayerState.buffering;
    final isPlayingNow = playerValue.isPlaying;

    if (isBufferingNow != _isBuffering || isPlayingNow != _isPlaying) {
      setState(() {
        _isBuffering = isBufferingNow;
        _isPlaying = isPlayingNow;
      });
    }

    final totalMs = playerValue.metaData.duration.inMilliseconds;
    final positionMs = playerValue.position.inMilliseconds;
    final remainingMs = totalMs - positionMs;
    final shouldRestartBeforeLastSecond = !_isPreloading &&
        isPlayingNow &&
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

  /// Start checking for actual video playback position
  /// Wait until video has actually played for 3 seconds (not wall-clock time)
  void _startPreloadCheck() {
    // Check every 500ms if video has played 3 seconds
    _preloadCheckTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Check if video position has reached 3 seconds
      final currentPosition = _controller.value.position.inSeconds;

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
    _controller.seekTo(Duration(seconds: widget.initialPosition));

    setState(() {
      _showOverlay = false; // Hide black overlay
      _isPreloading = false;
      _isPlaying = false;
    });

    AppLogger.i(
        '[Fullscreen] Preload complete (3 actual seconds played), ready for user');
  }

  void _updatePosition() {
    if (mounted && _controller.value.isReady) {
      _currentPosition = _controller.value.position.inSeconds;
    }
  }

  Future<void> _restorePortraitMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _exitFullscreen() async {
    if (_isExiting) return;
    _isExiting = true;

    await _restorePortraitMode();

    // Return current position to previous screen
    if (mounted) {
      Navigator.of(context).pop(_currentPosition);
    }
  }

  @override
  void dispose() {
    unawaited(_restorePortraitMode());

    _controlsTimer?.cancel();
    _preloadCheckTimer?.cancel();
    if (_isControllerInitialized) {
      _controller.removeListener(_updatePosition);
      _controller.removeListener(_onPlayerStateChanged);
      final controller = _controller;
      Future.microtask(() {
        try {
          controller.dispose();
        } catch (_) {}
      });
    }
    super.dispose();
  }

  Timer? _controlsTimer;

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_exitFullscreen());
        }
      },
      child: _videoId == null
          ? _buildErrorScreen()
          : Scaffold(
              backgroundColor: Colors.black,
              body: GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    // Video Player
                    Center(
                      child: YoutubePlayer(
                        controller: _controller,
                        bufferIndicator: const SizedBox.shrink(),
                        showVideoProgressIndicator:
                            false, // Hide loading indicator
                        progressIndicatorColor: AppColors.primary,
                        progressColors: const ProgressBarColors(
                          playedColor: AppColors.primary,
                          handleColor: AppColors.primary,
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                        // Disable default actions as we build custom ones
                        bottomActions: const [],
                        topActions: const [],
                      ),
                    ),

                    if (_showOverlay || _isBuffering || _isRestartingAfterEnd)
                      Positioned.fill(
                        child: _buildLoadingOverlay(isInitial: _showOverlay),
                      ),

                    // Custom Controls Overlay
                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: Stack(
                          children: [
                            // Top Bar (Back & Title)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: SafeArea(
                                  bottom: false,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            unawaited(_exitFullscreen()),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (widget.courseTitle != null)
                                              Text(
                                                widget.courseTitle!,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (widget.lessonTitle != null)
                                              Text(
                                                widget.lessonTitle!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Center Play/Pause Button
                            Center(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _controller.value.isPlaying
                                        ? _controller.pause()
                                        : _controller.play();
                                    setState(() {}); // Update UI
                                    _startControlsTimer(); // Reset timer
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Bottom Controls (Progress Bar, etc.)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.only(
                                    bottom: 20, left: 16, right: 16, top: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: SafeArea(
                                  top: false,
                                  child: Row(
                                    children: [
                                      CurrentPosition(controller: _controller),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ProgressBar(
                                          isExpanded: true,
                                          colors: const ProgressBarColors(
                                            playedColor: AppColors.primary,
                                            handleColor: AppColors.primary,
                                            bufferedColor: Colors.white24,
                                            backgroundColor: Colors.white12,
                                          ),
                                          controller: _controller,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      RemainingDuration(
                                          controller: _controller),
                                      const SizedBox(width: 8),
                                      // Rewind 10 seconds button
                                      IconButton(
                                        onPressed: () {
                                          final currentPosition =
                                              _controller.value.position;
                                          final newPosition = currentPosition -
                                              const Duration(seconds: 10);
                                          _controller.seekTo(
                                            newPosition.isNegative
                                                ? Duration.zero
                                                : newPosition,
                                          );
                                          _startControlsTimer();
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
                                          final currentPosition =
                                              _controller.value.position;
                                          final duration =
                                              _controller.metadata.duration;
                                          final newPosition = currentPosition +
                                              const Duration(seconds: 10);
                                          _controller.seekTo(
                                            newPosition > duration
                                                ? duration
                                                : newPosition,
                                          );
                                          _startControlsTimer();
                                        },
                                        icon: const Icon(
                                          Icons.forward_10,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        tooltip: 'تقديم 10 ثواني',
                                      ),
                                      PlaybackSpeedButton(
                                          controller: _controller),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () =>
                                            unawaited(_exitFullscreen()),
                                        icon: const Icon(
                                          Icons.fullscreen_exit,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'errors.invalid_video_url'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => unawaited(_exitFullscreen()),
              icon: const Icon(Icons.arrow_back),
              label: Text('common.back'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
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
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 14),
              Text(
                'common.loading'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
