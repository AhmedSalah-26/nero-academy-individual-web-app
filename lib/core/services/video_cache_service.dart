/// Video Cache Service - Caches video metadata to reduce network calls
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Cache for video metadata (URL -> metadata)
  final _cache = <String, VideoMetadata>{};
  static const _maxCacheSize = 20;

  /// Cache video metadata
  void cacheMetadata(String videoUrl, VideoMetadata metadata) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      _cache.remove(_cache.keys.first);
    }
    _cache[videoUrl] = metadata;
  }

  /// Get cached metadata
  VideoMetadata? getMetadata(String videoUrl) {
    return _cache[videoUrl];
  }

  /// Check if video is cached
  bool isCached(String videoUrl) {
    return _cache.containsKey(videoUrl);
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Remove specific video from cache
  void removeFromCache(String videoUrl) {
    _cache.remove(videoUrl);
  }
}

/// Video metadata model
class VideoMetadata {
  final String url;
  final int? duration;
  final String? thumbnailUrl;
  final DateTime cachedAt;

  VideoMetadata({
    required this.url,
    this.duration,
    this.thumbnailUrl,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  /// Check if cache is still valid (1 hour)
  bool get isValid {
    return DateTime.now().difference(cachedAt).inHours < 1;
  }
}
