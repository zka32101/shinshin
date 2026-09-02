import 'dart:async';
import 'package:flutter/material.dart';

/// API request optimization utilities
/// Implements Priority 6: API Request Optimization
class ApiOptimizationUtils {
  /// Simple debounce implementation for search/filter operations
  /// Usage: Prevents excessive API calls when user is typing/scrolling
  ///
  /// Example:
  /// ```dart
  /// final debouncedSearch = Debouncer<String>(
  ///   onValue: (query) {
  ///     ref.read(searchProvider.notifier).updateQuery(query);
  ///   },
  ///   duration: const Duration(milliseconds: 500),
  /// );
  ///
  /// // In TextField onChange:
  /// debouncedSearch.add(value);
  /// ```
  static Debouncer<T> createDebouncer<T>({
    required Function(T) onValue,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return Debouncer(onValue: onValue, duration: duration);
  }

  /// Request deduplication cache
  /// Prevents duplicate API calls for the same resource within a time window
  static final Map<String, _RequestCache> _requestCache = {};

  /// Check if request was recently cached (within 60 seconds)
  /// Returns cached response if available, null otherwise
  static Future<T>? getCachedRequest<T>(String cacheKey) {
    final cached = _requestCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      debugPrint('[ApiOptimization] Returning cached response for: $cacheKey');
      return cached.response as Future<T>?;
    }
    return null;
  }

  /// Cache a request response for deduplication
  static void cacheRequest<T>(
    String cacheKey,
    Future<T> response, {
    Duration duration = const Duration(seconds: 60),
  }) {
    _requestCache[cacheKey] = _RequestCache(
      response: response,
      expiresAt: DateTime.now().add(duration),
    );
  }

  /// Clear expired cache entries
  static void clearExpiredCache() {
    _requestCache.removeWhere((_, cache) => cache.isExpired);
  }

  /// Clear specific cache entry
  static void clearCacheEntry(String cacheKey) {
    _requestCache.remove(cacheKey);
  }

  /// Clear all request cache
  static void clearAllCache() {
    _requestCache.clear();
  }
}

/// Internal cache entry for request deduplication
class _RequestCache {
  final dynamic response;
  final DateTime expiresAt;

  _RequestCache({required this.response, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Debouncer implementation for rate-limiting user input
/// Common use case: search queries, filter updates, scroll position
class Debouncer<T> {
  final Duration duration;
  final Function(T) onValue;

  Timer? _timer;
  T? _lastValue;

  Debouncer({
    required this.onValue,
    this.duration = const Duration(milliseconds: 500),
  });

  /// Add a value to debounce queue
  /// If called multiple times within duration, only the last value is processed
  void add(T value) {
    _lastValue = value;
    _timer?.cancel();
    _timer = Timer(duration, () {
      if (_lastValue != null) {
        onValue(_lastValue as T);
      }
    });
  }

  /// Cancel pending debounced call
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose debouncer (cleanup)
  void dispose() {
    cancel();
  }
}

/// Request batching utility for efficient API calls
/// Groups multiple requests into one batch request when possible
class RequestBatcher<T, R> {
  final Future<R> Function(List<T>) batchFn;
  final Duration windowDuration;
  final int maxBatchSize;

  List<T> _pendingRequests = [];
  Timer? _batchTimer;
  final List<Completer<R>> _completers = [];

  RequestBatcher({
    required this.batchFn,
    this.windowDuration = const Duration(milliseconds: 100),
    this.maxBatchSize = 20,
  });

  /// Add a request to the batch
  /// Returns a Future that resolves when batch is processed
  Future<R> add(T request) {
    _pendingRequests.add(request);
    final completer = Completer<R>();
    _completers.add(completer);

    // Process immediately if batch is full
    if (_pendingRequests.length >= maxBatchSize) {
      _processBatch();
      return completer.future;
    }

    // Schedule batch processing after window
    _batchTimer?.cancel();
    _batchTimer = Timer(windowDuration, _processBatch);

    return completer.future;
  }

  void _processBatch() async {
    if (_pendingRequests.isEmpty) return;

    _batchTimer?.cancel();
    _batchTimer = null;

    final requestsToProcess = _pendingRequests;
    final completersToResolve = _completers;

    _pendingRequests = [];
    _completers.clear();

    try {
      final result = await batchFn(requestsToProcess);
      for (final completer in completersToResolve) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }
    } catch (e) {
      for (final completer in completersToResolve) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }
}

/// API performance monitoring
class ApiPerformanceMonitor {
  static final Map<String, List<Duration>> _requestDurations = {};
  static final Map<String, int> _requestCounts = {};

  /// Record API request duration
  static void recordRequestDuration(String endpoint, Duration duration) {
    _requestDurations.putIfAbsent(endpoint, () => []);
    _requestDurations[endpoint]!.add(duration);

    _requestCounts.putIfAbsent(endpoint, () => 0);
    _requestCounts[endpoint] = (_requestCounts[endpoint] ?? 0) + 1;

    // Keep only last 100 requests per endpoint
    if (_requestDurations[endpoint]!.length > 100) {
      _requestDurations[endpoint]!.removeAt(0);
    }
  }

  /// Get average request duration for endpoint
  static Duration? getAverageDuration(String endpoint) {
    final durations = _requestDurations[endpoint];
    if (durations == null || durations.isEmpty) return null;

    final totalMs =
        durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  /// Get request count for endpoint
  static int getRequestCount(String endpoint) {
    return _requestCounts[endpoint] ?? 0;
  }

  /// Get performance stats for all endpoints
  static Map<String, Map<String, dynamic>> getStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final endpoint in _requestDurations.keys) {
      stats[endpoint] = {
        'count': getRequestCount(endpoint),
        'averageDuration': getAverageDuration(endpoint)?.inMilliseconds,
      };
    }
    return stats;
  }

  /// Clear performance stats
  static void clearStats() {
    _requestDurations.clear();
    _requestCounts.clear();
  }
}
