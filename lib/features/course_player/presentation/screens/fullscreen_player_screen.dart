import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/screen_protection_service.dart';
import '../../data/services/youtube_stream_service.dart';

/// Landscape fullscreen player for YouTube videos.
///
/// Uses [YouTubeStreamService] to fetch direct stream URLs (no iframes),
/// then plays natively via [video_player] + [chewie].
///
/// Returns the last playback position (in seconds) via [Navigator.pop]
/// so the caller can resume from where the user left off.
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
  // ──────────────── State ────────────────
  YouTubeStreamService? _streamService;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _isLoading = true;
  String? _errorMessage;
  int _currentPosition = 0;
  bool _isExiting = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  // ══════════════════════════════════════════════════════════════
  //  Lifecycle
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _streamService = YouTubeStreamService();
    ScreenProtectionService.enable();
    unawaited(_setupFullscreen());
    _initializePlayer();
  }

  @override
  void dispose() {
    unawaited(_restorePortraitMode());
    _controlsTimer?.cancel();
    _videoController?.removeListener(_onVideoChanged);
    _chewieController?.dispose();
    _videoController?.dispose();
    _streamService?.dispose();
    _streamService = null;
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  Orientation & System UI
  // ══════════════════════════════════════════════════════════════

  Future<void> _setupFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

  // ══════════════════════════════════════════════════════════════
  //  Player initialization
  // ══════════════════════════════════════════════════════════════

  Future<void> _initializePlayer() async {
    final videoId = YouTubeStreamService.extractVideoId(widget.videoUrl);

    if (videoId == null) {
      AppLogger.e('[Fullscreen] Invalid YouTube URL: ${widget.videoUrl}');
      if (mounted) {
        setState(() {
          _errorMessage = 'errors.invalid_video_url'.tr();
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 1) Resolve direct stream URL
      final result = await _streamService!.resolveStreamUrl(widget.videoUrl);

      if (!mounted) return;

      // 2) Create native video player
      _videoController = VideoPlayerController.networkUrl(
        result.streamUrl,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _videoController!.initialize();

      if (!mounted) return;

      // 3) Seek to saved position
      if (widget.initialPosition > 0) {
        await _videoController!.seekTo(
          Duration(seconds: widget.initialPosition),
        );
      }

      // 4) Chewie for controls
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio == 0
            ? 16 / 9
            : _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white12,
          bufferedColor: Colors.white24,
        ),
        allowFullScreen: false,
        allowPlaybackSpeedChanging: true,
        showControls: true,
      );

      _videoController!.addListener(_onVideoChanged);
      _startControlsTimer();

      if (mounted) {
        setState(() => _isLoading = false);
      }

      AppLogger.i(
        '[Fullscreen] Player initialized at position: '
        '${widget.initialPosition}s',
      );
    } on YouTubeStreamException catch (e) {
      AppLogger.e('[Fullscreen] Stream error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'course_player.video_unavailable'.tr();
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('[Fullscreen] Failed to initialize', e, stack);
      if (mounted) {
        setState(() {
          _errorMessage = 'course_player.video_unavailable'.tr();
          _isLoading = false;
        });
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Playback listener
  // ══════════════════════════════════════════════════════════════

  void _onVideoChanged() {
    if (!mounted || _videoController == null) return;

    if (_videoController!.value.hasError) {
      setState(() {
        _errorMessage = 'course_player.video_unavailable'.tr();
      });
      return;
    }

    _currentPosition = _videoController!.value.position.inSeconds;
    final isPlayingNow = _videoController!.value.isPlaying;
    if (isPlayingNow != _isPlaying) {
      setState(() => _isPlaying = isPlayingNow);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Controls visibility
  // ══════════════════════════════════════════════════════════════

  void _toggleControls() {
    setState(() => _showControls = !_showControls);

    if (_showControls) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  Navigation
  // ══════════════════════════════════════════════════════════════

  Future<void> _exitFullscreen() async {
    if (_isExiting) return;
    _isExiting = true;

    await _restorePortraitMode();

    if (mounted) {
      Navigator.of(context).pop(_currentPosition);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_exitFullscreen());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? _buildLoadingScreen()
            : _errorMessage != null
                ? _buildErrorScreen()
                : GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio:
                                _videoController!.value.aspectRatio == 0
                                    ? 16 / 9
                                    : _videoController!.value.aspectRatio,
                            child: Chewie(controller: _chewieController!),
                          ),
                        ),

                        // Overlay controls (top bar + center play/pause + bottom bar)
                        AnimatedOpacity(
                          opacity: _showControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            ignoring: !_showControls,
                            child: Stack(
                              children: [
                                // ── Top bar ──
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black
                                              .withValues(alpha: 0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: SafeArea(
                                      bottom: false,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => unawaited(
                                                _exitFullscreen()),
                                            icon: const Icon(
                                              Icons
                                                  .arrow_back_ios_new_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                if (widget.courseTitle !=
                                                    null)
                                                  Text(
                                                    widget.courseTitle!,
                                                    style: const TextStyle(
                                                      color:
                                                          Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                if (widget.lessonTitle !=
                                                    null)
                                                  Text(
                                                    widget.lessonTitle!,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // ── Center play/pause ──
                                Center(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        if (_videoController!
                                            .value.isPlaying) {
                                          _videoController!.pause();
                                        } else {
                                          _videoController!.play();
                                        }
                                        setState(() {});
                                        _startControlsTimer();
                                      },
                                      borderRadius:
                                          BorderRadius.circular(50),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
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

                                // ── Bottom bar ──
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                      bottom: 20,
                                      left: 16,
                                      right: 16,
                                      top: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black
                                              .withValues(alpha: 0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: SafeArea(
                                      top: false,
                                      child: Row(
                                        children: [
                                          Text(
                                            _formatDuration(
                                              _videoController!
                                                  .value.position,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                VideoProgressIndicator(
                                              _videoController!,
                                              allowScrubbing: true,
                                              colors:
                                                  const VideoProgressColors(
                                                playedColor:
                                                    AppColors.primary,
                                                bufferedColor:
                                                    Colors.white24,
                                                backgroundColor:
                                                    Colors.white12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDuration(
                                              _videoController!
                                                  .value.duration,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () {
                                              final pos = _videoController!
                                                  .value.position;
                                              final newPos = pos -
                                                  const Duration(
                                                      seconds: 10);
                                              _videoController!.seekTo(
                                                newPos.isNegative
                                                    ? Duration.zero
                                                    : newPos,
                                              );
                                              _startControlsTimer();
                                            },
                                            icon: const Icon(
                                              Icons.replay_10,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              final pos = _videoController!
                                                  .value.position;
                                              final dur = _videoController!
                                                  .value.duration;
                                              final newPos = pos +
                                                  const Duration(
                                                      seconds: 10);
                                              _videoController!.seekTo(
                                                newPos > dur
                                                    ? dur
                                                    : newPos,
                                              );
                                              _startControlsTimer();
                                            },
                                            icon: const Icon(
                                              Icons.forward_10,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => unawaited(
                                                _exitFullscreen()),
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

  // ══════════════════════════════════════════════════════════════
  //  Helpers
  // ══════════════════════════════════════════════════════════════

  String _formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
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
              _errorMessage ?? 'errors.invalid_video_url'.tr(),
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
}