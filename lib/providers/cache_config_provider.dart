import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cache configuration for Riverpod providers
/// Controls caching behavior, TTL, and memory management
class CacheConfig {
  /// Time-to-live in seconds for cached data
  final int ttlSeconds;

  /// Maximum number of cached instances for a provider
  final int maxInstances;

  /// Whether to keep alive when no listeners
  final bool keepAlive;

  const CacheConfig({
    this.ttlSeconds = 300, // 5 minutes default
    this.maxInstances = 100,
    this.keepAlive = false,
  });

  /// Config for frequently accessed data (stories, profiles, etc.)
  static const frequentAccess = CacheConfig(
    ttlSeconds: 600, // 10 minutes
    maxInstances: 50,
    keepAlive: true,
  );

  /// Config for periodically changing data (reports, rankings)
  static const periodicallyChanging = CacheConfig(
    ttlSeconds: 300, // 5 minutes
    maxInstances: 30,
    keepAlive: false,
  );

  /// Config for rarely changing data (badge definitions, constants)
  static const rarelyChanging = CacheConfig(
    ttlSeconds: 3600, // 1 hour
    maxInstances: 20,
    keepAlive: true,
  );

  /// Config for user-specific data that changes frequently
  static const userSpecific = CacheConfig(
    ttlSeconds: 120, // 2 minutes
    maxInstances: 50,
    keepAlive: true,
  );

  /// Config for network requests (optimize for bandwidth)
  static const networkOptimized = CacheConfig(
    ttlSeconds: 600, // 10 minutes
    maxInstances: 20,
    keepAlive: false,
  );
}

/// Provider for cache configuration
/// Use with .keepAlive() modifier for autoDispose providers
final cacheConfigProvider = Provider<CacheConfig>((ref) {
  return const CacheConfig();
});

/// Provides frequency-appropriate cache config for story data
final storyDataCacheConfigProvider = Provider<CacheConfig>((ref) {
  return CacheConfig.frequentAccess;
});

/// Provides cache config for report data
final reportDataCacheConfigProvider = Provider<CacheConfig>((ref) {
  return CacheConfig.periodicallyChanging;
});

/// Provides cache config for badge data
final badgeDataCacheConfigProvider = Provider<CacheConfig>((ref) {
  return CacheConfig.rarelyChanging;
});

/// Provides cache config for user data
final userDataCacheConfigProvider = Provider<CacheConfig>((ref) {
  return CacheConfig.userSpecific;
});
