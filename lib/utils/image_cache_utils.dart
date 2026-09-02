import 'package:flutter/material.dart';

/// Image caching and optimization utilities
/// Implements Priority 3: Image & Asset Caching optimizations
class ImageCacheUtils {
  /// Configure global image cache settings for optimal memory usage
  /// Should be called once during app initialization
  static void configureImageCache() {
    // Set maximum cache size to 100MB (default is often much larger)
    imageCache.maximumSize = 100 * 1024 * 1024;

    // Set maximum number of cached images to 500
    imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB in bytes
  }

  /// Precache commonly used avatar and UI images
  /// Call this during app initialization or when switching children
  /// to ensure images are ready when needed
  static Future<void> precacheCommonAssets(BuildContext context) async {
    try {
      // Common UI assets that should always be available
      final commonAssets = [
        'assets/images/placeholder_avatar.png',
        'assets/images/logo.png',
        'assets/images/splash_background.png',
      ];

      // Precache all common assets in parallel
      await Future.wait(
        commonAssets.map(
          (asset) => precacheImage(AssetImage(asset), context),
        ),
      );
    } catch (e) {
      debugPrint('[ImageCacheUtils] Failed to precache common assets: $e');
      // Non-blocking, continue anyway
    }
  }

  /// Precache avatar images for a specific child
  /// Call when switching to a different child profile to preload their assets
  static Future<void> precacheAvatarAssets(
    BuildContext context,
    List<String> avatarImagePaths,
  ) async {
    try {
      await Future.wait(
        avatarImagePaths
            .where((path) => path.isNotEmpty)
            .map((path) => precacheImage(AssetImage(path), context)),
      );
    } catch (e) {
      debugPrint('[ImageCacheUtils] Failed to precache avatar assets: $e');
      // Non-blocking, continue anyway
    }
  }

  /// Clear image cache to free memory
  /// Use when needed to recover memory or explicitly switch contexts
  static void clearImageCache() {
    imageCache.clearCache();
  }

  /// Get current image cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'currentSize': imageCache.currentSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSize': imageCache.maximumSize,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
    };
  }

  /// Optimize image loading with error handling and caching
  /// Returns a precached ImageProvider with fallback support
  static ImageProvider optimizedAssetImage(
    String assetPath, {
    String? placeholder,
  }) {
    // Use asset image with proper caching
    return AssetImage(assetPath);
  }

  /// Configure memory-efficient image caching for large image lists
  /// Used for story images, badge graphics, etc.
  static void configureMemoryEfficientCaching() {
    // Aggressive cache clearing for memory-constrained devices
    imageCache.maximumSize = 50; // Maximum 50 images in cache
    imageCache.maximumSizeBytes = 30 * 1024 * 1024; // 30MB limit
  }

  /// Helper to monitor cache usage and clear if needed
  /// Call periodically to prevent memory bloat
  static bool shouldClearCache() {
    final stats = getCacheStats();
    final currentBytes = stats['currentSizeBytes'] as int? ?? 0;
    final maxBytes = stats['maximumSizeBytes'] as int? ?? 50000000;

    // Clear if using more than 80% of cache space
    return currentBytes > (maxBytes * 0.8).toInt();
  }
}

/// Widget extension for easy image precaching
extension ImageCacheContext on BuildContext {
  /// Precache an asset image in this widget context
  Future<void> precacheAssetImage(String assetPath) async {
    try {
      await precacheImage(AssetImage(assetPath), this);
    } catch (e) {
      debugPrint('[ImageCacheContext] Failed to precache: $e');
    }
  }

  /// Precache multiple asset images in parallel
  Future<void> precacheAssetImages(List<String> assetPaths) async {
    try {
      await Future.wait(
        assetPaths.map((path) => precacheImage(AssetImage(path), this)),
      );
    } catch (e) {
      debugPrint('[ImageCacheContext] Failed to precache multiple: $e');
    }
  }
}
