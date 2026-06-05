import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/src/reverse_engineering/youtube_http_client.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_logger.dart';

/// Result of resolving a YouTube video stream URL.
class YouTubeStreamResult {
  final Uri streamUrl;
  final String videoId;
  final String? title;

  const YouTubeStreamResult({
    required this.streamUrl,
    required this.videoId,
    this.title,
  });
}

/// A custom HTTP client that prepends a CORS proxy URL to requests when running on the web.
class CorsProxyClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  
  // Use our custom Supabase Edge Function proxy
  final String proxyUrl = '${AppConstants.supabaseUrl}/functions/v1/youtube-proxy?url=';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (kIsWeb) {
      final proxyUri = Uri.parse('$proxyUrl${Uri.encodeComponent(request.url.toString())}');
      final proxyRequest = http.Request(request.method, proxyUri);
      proxyRequest.headers.addAll(request.headers);
      
      // Add Supabase authentication header for the Edge Function
      proxyRequest.headers['Authorization'] = 'Bearer ${AppConstants.supabaseAnonKey}';
      
      // Remove restricted headers that cause issues with some proxies
      proxyRequest.headers.remove('origin');
      proxyRequest.headers.remove('referer');
      
      if (request is http.Request) {
        proxyRequest.bodyBytes = request.bodyBytes;
      }
      return _inner.send(proxyRequest);
    }
    return _inner.send(request);
  }
}

/// Shared service for extracting YouTube video IDs and fetching
/// direct playback stream URLs via youtube_explode_dart.
class YouTubeStreamService {
  late final YoutubeExplode _yt;

  YouTubeStreamService() {
    if (kIsWeb) {
      // Use the proxy client on the Web to bypass CORS errors.
      _yt = YoutubeExplode(httpClient: YoutubeHttpClient(CorsProxyClient()));
    } else {
      _yt = YoutubeExplode();
    }
  }

  // ──────────────────── Video ID extraction ────────────────────

  /// Extracts the 11-character YouTube video ID from various URL formats.
  ///
  /// Supports:
  /// - `https://www.youtube.com/watch?v=VIDEO_ID`
  /// - `https://youtu.be/VIDEO_ID`
  /// - `https://www.youtube.com/embed/VIDEO_ID`
  /// - `https://www.youtube-nocookie.com/embed/VIDEO_ID`
  /// - Raw 11-character ID string
  ///
  /// Returns `null` if no valid ID can be extracted.
  static String? extractVideoId(String url) {
    final trimmed = url.trim();
    final patterns = [
      RegExp(
        r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/|youtube-nocookie\.com/embed/)'
        r'([A-Za-z0-9_-]{11})',
      ),
      RegExp(r'^([A-Za-z0-9_-]{11})$'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) return match.group(1);
    }
    return null;
  }

  // ──────────────────── Stream resolution ────────────────────

  /// Fetches the best available direct stream URL for a YouTube video.
  ///
  /// Strategy (in order of preference):
  /// 1. **Muxed stream** with highest bitrate (MP4 audio+video)
  /// 2. **Video-only stream** with highest bitrate (fallback for
  ///    videos where muxed streams are unavailable)
  ///
  /// Throws [YouTubeStreamException] if:
  /// - The [videoUrl] does not contain a valid YouTube video ID
  /// - No playable streams are found (video unavailable / age-restricted)
  /// - A network or parsing error occurs
  Future<YouTubeStreamResult> resolveStreamUrl(String videoUrl) async {
    final videoId = extractVideoId(videoUrl);

    if (videoId == null) {
      throw YouTubeStreamException(
        'Invalid YouTube URL: $videoUrl',
        type: YouTubeStreamErrorType.invalidUrl,
      );
    }

    try {
      AppLogger.i('[YouTubeStream] Fetching manifest for video: $videoId');

      final manifest =
          await _yt.videos.streamsClient.getManifest(videoId);

      // 1) Try muxed streams first (audio + video in one container)
      if (manifest.muxed.isNotEmpty) {
        final best = manifest.muxed.withHighestBitrate();
        AppLogger.i(
          '[YouTubeStream] Using muxed stream — '
          '${best.qualityLabel}, ${best.size.totalMegaBytes.toStringAsFixed(1)} MB',
        );
        return YouTubeStreamResult(
          streamUrl: best.url,
          videoId: videoId,
        );
      }

      // 2) Fallback: video-only stream (no audio — still plays on mobile)
      if (manifest.videoOnly.isNotEmpty) {
        final best = manifest.videoOnly.withHighestBitrate();
        AppLogger.w(
          '[YouTubeStream] No muxed streams available; '
          'using video-only stream: ${best.qualityLabel}',
        );
        return YouTubeStreamResult(
          streamUrl: best.url,
          videoId: videoId,
        );
      }

      throw YouTubeStreamException(
        'No playable streams found for video: $videoId',
        type: YouTubeStreamErrorType.noStreams,
      );
    } on YouTubeStreamException {
      rethrow;
    } catch (e, stack) {
      AppLogger.e('[YouTubeStream] Failed to resolve stream', e, stack);
      throw YouTubeStreamException(
        'Failed to fetch video stream: $e',
        type: YouTubeStreamErrorType.network,
        cause: e,
      );
    }
  }

  /// Releases all resources held by the internal [YoutubeExplode] client.
  void dispose() {
    _yt.close();
  }
}

// ──────────────────── Error types ────────────────────

enum YouTubeStreamErrorType {
  /// The provided URL is not a valid YouTube URL.
  invalidUrl,

  /// The manifest was fetched but contained no playable streams.
  noStreams,

  /// A network or unexpected error occurred.
  network,
}

class YouTubeStreamException implements Exception {
  final String message;
  final YouTubeStreamErrorType type;
  final Object? cause;

  const YouTubeStreamException(
    this.message, {
    required this.type,
    this.cause,
  });

  @override
  String toString() => 'YouTubeStreamException($type): $message';
}
