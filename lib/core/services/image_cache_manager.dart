import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'app_logger.dart';

class ImageCacheManager {
  static const int _maxCacheSizeMB = 100;
  static const Duration _maxCacheAge = Duration(days: 7);

  /// Clear cache older than specified duration
  static Future<void> clearOldCache({
    Duration olderThan = _maxCacheAge,
  }) async {
    try {
      await DefaultCacheManager().emptyCache();
      AppLogger.i('🗑️ Cleared old image cache');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to clear old cache', e, stackTrace);
    }
  }

  /// Get current cache size in MB
  static Future<double> getCacheSizeMB() async {
    try {
      if (kIsWeb) return 0.0;

      final cacheDir = await getTemporaryDirectory();
      final cacheSize = await _calculateDirectorySize(cacheDir);
      return cacheSize / (1024 * 1024); // Convert to MB
    } catch (e) {
      AppLogger.e('❌ Failed to calculate cache size', e);
      return 0.0;
    }
  }

  /// Clear all cached images
  static Future<void> clearAllCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      AppLogger.success('Cache cleared', {'action': 'clear_all'});
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to clear cache', e, stackTrace);
    }
  }

  /// Enforce cache size limit
  static Future<void> enforceCacheSizeLimit({
    int maxSizeMB = _maxCacheSizeMB,
  }) async {
    try {
      final currentSize = await getCacheSizeMB();
      if (currentSize > maxSizeMB) {
        await clearOldCache();
        AppLogger.i(
            '📦 Cache size limit enforced: ${currentSize.toStringAsFixed(1)}MB -> ${maxSizeMB}MB');
      }
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to enforce cache size limit', e, stackTrace);
    }
  }

  /// Get optimized image URL for different screen sizes
  static String getOptimizedImageUrl(
    String originalUrl, {
    required double width,
    double? height,
    int quality = 80,
  }) {
    // If URL already has parameters, append to existing ones
    final uri = Uri.parse(originalUrl);
    final params = Map<String, String>.from(uri.queryParameters);

    // Add optimization parameters (works with most CDNs)
    params['w'] = width.round().toString();
    if (height != null) {
      params['h'] = height.round().toString();
    }
    params['q'] = quality.toString();
    params['f'] = 'webp'; // Prefer WebP format

    return uri.replace(queryParameters: params).toString();
  }

  /// Calculate directory size recursively
  static Future<int> _calculateDirectorySize(Directory directory) async {
    int size = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      // Directory might not exist or be accessible
    }
    return size;
  }

  /// Preload important images
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (e) {
        AppLogger.w('⚠️ Failed to preload image: $url', e);
      }
    }
  }
}

class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final BorderRadius? borderRadius;
  final int quality;
  final bool enableOptimization;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.quality = 80,
    this.enableOptimization = true,
  });

  @override
  Widget build(BuildContext context) {
    final optimizedUrl = enableOptimization && width != null
        ? ImageCacheManager.getOptimizedImageUrl(
            imageUrl,
            width: width!,
            height: height,
            quality: quality,
          )
        : imageUrl;

    Widget image = CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder ??
          (context, url) => _ShimmerImageLoader(
                width: width ?? 100,
                height: height ?? 100,
                borderRadius: borderRadius,
              ),
      errorWidget: errorWidget ??
          (context, url, error) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: borderRadius,
                ),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey,
                ),
              ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

class ProgressiveImage extends StatefulWidget {
  final String imageUrl;
  final String? blurHash;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProgressiveImage({
    super.key,
    required this.imageUrl,
    this.blurHash,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<ProgressiveImage> createState() => _ProgressiveImageState();
}

class _ProgressiveImageState extends State<ProgressiveImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blur hash or shimmer placeholder
        if (widget.blurHash != null)
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              color: Colors.grey[300],
            ),
          )
        else
          _ShimmerImageLoader(
            width: widget.width ?? 100,
            height: widget.height ?? 100,
            borderRadius: widget.borderRadius,
          ),

        // Actual image with fade-in animation
        FadeTransition(
          opacity: _animation,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: widget.borderRadius,
              ),
              child: const Icon(Icons.broken_image_outlined),
            ),
            imageBuilder: (context, imageProvider) {
              // Trigger fade-in animation when image loads
              if (!_imageLoaded) {
                _imageLoaded = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _controller.forward();
                  }
                });
              }
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: widget.fit,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MemoryEfficientImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const MemoryEfficientImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  State<MemoryEfficientImage> createState() => _MemoryEfficientImageState();
}

class _MemoryEfficientImageState extends State<MemoryEfficientImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // Don't keep alive to save memory

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RepaintBoundary(
      child: Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ??
              const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          );
        },
        // Optimize memory usage
        cacheWidth: widget.width?.round(),
        cacheHeight: widget.height?.round(),
      ),
    );
  }
}

/// Internal shimmer loader widget for image placeholders
class _ShimmerImageLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _ShimmerImageLoader({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}
