import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _videoController;
  bool _isVideoReady = false;
  bool _hasNavigated = false;
  bool _isFadingOut = false;

  @override
  void initState() {
    super.initState();
    _videoController = _createVideoController();
    _initializeVideo();
  }

  VideoPlayerController _createVideoController() {
    if (kIsWeb) {
      // On web, load asset as a URL from the compiled assets directory.
      final webVideoUrl =
          Uri.base.resolve('assets/assets/splach.mp4').toString();
      return VideoPlayerController.networkUrl(Uri.parse(webVideoUrl));
    }
    return VideoPlayerController.asset('assets/splach.mp4');
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize().timeout(const Duration(seconds: 8));
      if (!mounted) return;

      await _videoController.setLooping(false);
      if (kIsWeb) {
        // Web autoplay usually requires muted playback.
        await _videoController.setVolume(0);
      }
      _videoController.addListener(_handleVideoProgress);
      await _videoController.play();

      setState(() => _isVideoReady = true);

      // Safety fallback in case duration metadata is not readable.
      if (_videoController.value.duration == Duration.zero) {
        Future.delayed(const Duration(seconds: 2), _navigateNext);
      }
    } catch (_) {
      _navigateNext();
    }
  }

  void _handleVideoProgress() {
    if (!_videoController.value.isInitialized) return;
    final position = _videoController.value.position;
    final duration = _videoController.value.duration;
    if (duration == Duration.zero) return;

    // Fade out 600ms before video ends for a smooth transition
    final startFading =
        position >= duration - const Duration(milliseconds: 600);

    if (startFading && !_isFadingOut && !_hasNavigated) {
      setState(() {
        _isFadingOut = true;
      });
      // Navigate slightly after fade completes
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _navigateNext();
      });
    }

    // Fallback: immediate navigation if we reached the very end
    final isEnded = position >= duration - const Duration(milliseconds: 50);
    if (isEnded && !_hasNavigated && !_isFadingOut) {
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    try {
      final user = await sl<AuthLocalDataSource>().getCachedUser();
      if (user != null) {
        if (mounted) context.go('/home');
      } else {
        if (mounted) context.go('/login');
      }
    } catch (e) {
      // Handle any errors during navigation (e.g., after logout)
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _videoController
      ..removeListener(_handleVideoProgress)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isVideoReady
            ? AnimatedOpacity(
                opacity: _isFadingOut ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 600),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
