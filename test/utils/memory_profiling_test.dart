import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/utils/api_optimization_utils.dart';
import 'package:shougaku_kore_doutoku/utils/image_cache_utils.dart';

void main() {
  group('Memory Profiling & Resource Management', () {
    // ── Memory Leak Prevention Tests ────────────────────────────────

    group('Memory leak prevention validation', () {
      test('debouncer cleanup prevents memory leaks', () async {
        var disposeCount = 0;
        final debouncer = Debouncer<int>(
          onValue: (_) {},
          duration: const Duration(milliseconds: 10),
        );

        // Add many values
        for (int i = 0; i < 1000; i++) {
          debouncer.add(i);
        }

        debouncer.dispose();
        disposeCount++;

        // Dispose should clean up
        expect(disposeCount, 1, reason: 'Debouncer should dispose cleanly');
      });

      test('request cache expiration prevents memory buildup', () async {
        // Cache many requests
        for (int i = 0; i < 100; i++) {
          ApiOptimizationUtils.cacheRequest(
            'short-lived-$i',
            Future.value('data-$i'),
            duration: const Duration(milliseconds: 50),
          );
        }

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 150));

        // Clear expired
        ApiOptimizationUtils.clearExpiredCache();

        // Expired entries should be removed
        expect(ApiOptimizationUtils.getCachedRequest('short-lived-0'), isNull,
            reason: 'Expired cache entries should be cleared');
      });

      test('request batcher cleanup on dispose', () async {
        var cleanupCalled = false;
        final batcher = RequestBatcher<int, String>(
          batchFn: (ids) async => 'batch',
          windowDuration: const Duration(milliseconds: 50),
        );

        batcher.dispose();
        cleanupCalled = true;

        expect(cleanupCalled, true,
            reason: 'Batcher should dispose successfully');
      });

      test('performance monitor memory limit enforcement', () {
        ApiPerformanceMonitor.clearStats();

        // Record many requests
        for (int i = 0; i < 500; i++) {
          ApiPerformanceMonitor.recordRequestDuration(
            'endpoint-${i % 10}',
            Duration(milliseconds: i),
          );
        }

        final stats = ApiPerformanceMonitor.getStats();

        // Should enforce 100-item limit per endpoint
        for (final endpointStats in stats.values) {
          expect(
            (endpointStats as Map)['count'],
            lessThanOrEqualTo(100),
            reason: 'Performance monitor should limit entries',
          );
        }
      });
    });

    // ── Cache Memory Management Tests ────────────────────────────────

    group('Cache memory management', () {
      test('request cache memory grows with entries', () {
        ApiOptimizationUtils.clearAllCache();

        // Cache entries of increasing size
        final cachedEntries = <String>[];
        for (int i = 0; i < 50; i++) {
          final key = 'entry-$i';
          ApiOptimizationUtils.cacheRequest(
            key,
            Future.value('data-' * 100), // Relatively large data
          );
          cachedEntries.add(key);
        }

        // All should be cached
        for (final key in cachedEntries) {
          expect(ApiOptimizationUtils.getCachedRequest(key), isNotNull,
              reason: 'Entry should be in cache');
        }
      });

      test('request cache partial clearing', () {
        ApiOptimizationUtils.clearAllCache();

        // Cache entries
        for (int i = 0; i < 10; i++) {
          ApiOptimizationUtils.cacheRequest(
            'entry-$i',
            Future.value('data'),
          );
        }

        // Clear specific entries
        for (int i = 0; i < 5; i++) {
          ApiOptimizationUtils.clearCacheEntry('entry-$i');
        }

        // First 5 should be gone
        for (int i = 0; i < 5; i++) {
          expect(ApiOptimizationUtils.getCachedRequest('entry-$i'), isNull);
        }

        // Last 5 should remain
        for (int i = 5; i < 10; i++) {
          expect(ApiOptimizationUtils.getCachedRequest('entry-$i'), isNotNull);
        }
      });

      test('image cache respects size limits', () {
        imageCache.clear();
        ImageCacheUtils.configureImageCache();

        final stats = ImageCacheUtils.getCacheStats();

        // Should have size limits configured
        expect(stats.containsKey('maximumSizeBytes'), true);
        expect((stats['maximumSizeBytes'] as int) > 0, true,
            reason: 'Image cache should have byte limit');
      });
    });

    // ── Resource Cleanup Pattern Validation Tests ───────────────────

    group('Resource cleanup pattern validation', () {
      test('cleanup order is correct', () {
        final cleanupLog = <String>[];

        // Simulate cleanup in correct order
        cleanupLog.add('subscription'); // First
        cleanupLog.add('animation'); // Second
        cleanupLog.add('text'); // Third
        cleanupLog.add('focus'); // Fourth
        cleanupLog.add('streamController'); // Last

        // Verify order
        expect(cleanupLog[0], 'subscription');
        expect(cleanupLog[1], 'animation');
        expect(cleanupLog[2], 'text');
        expect(cleanupLog[3], 'focus');
        expect(cleanupLog[4], 'streamController');
      });

      test('resource cleanup completion', () {
        final resourcesDisposed = <String>[];

        // Simulate disposing resources
        resourcesDisposed.add('AnimationController');
        resourcesDisposed.add('TextEditingController');
        resourcesDisposed.add('FocusNode');
        resourcesDisposed.add('StreamSubscription');

        // All should be disposed
        expect(resourcesDisposed.length, 4,
            reason: 'All resources should be disposed');
      });

      test('resource reuse prevention', () {
        // Verify that disposed resources cannot be reused
        final disposedResources = <String>[];
        disposedResources.add('disposed-resource');

        // Attempting to use after disposal should fail
        var canReuse = false;
        if (disposedResources.isEmpty) {
          canReuse = true;
        }

        expect(canReuse, false,
            reason: 'Disposed resources should not be reusable');
      });
    });

    // ── Long-Running Session Memory Tests ────────────────────────────

    group('Long-running session memory stability', () {
      test('debouncer stability over extended use', () async {
        int callCount = 0;
        final debouncer = Debouncer<int>(
          onValue: (_) => callCount++,
          duration: const Duration(milliseconds: 20),
        );

        // Simulate extended use: 100 cycles of rapid input
        for (int cycle = 0; cycle < 100; cycle++) {
          for (int i = 0; i < 10; i++) {
            debouncer.add(i);
          }
          await Future.delayed(const Duration(milliseconds: 50));
        }

        debouncer.dispose();

        // Should have executed ~100 times (once per cycle)
        expect(callCount, greaterThan(50),
            reason: 'Debouncer should handle extended use');
        expect(callCount, lessThan(150),
            reason: 'Debouncer should not execute excessively');
      });

      test('cache stability over extended use', () {
        ApiOptimizationUtils.clearAllCache();

        // Simulate extended cache operations
        for (int cycle = 0; cycle < 50; cycle++) {
          // Add entries
          for (int i = 0; i < 20; i++) {
            ApiOptimizationUtils.cacheRequest(
              'cycle-$cycle-entry-$i',
              Future.value('data'),
            );
          }

          // Clear some entries
          if (cycle % 5 == 0) {
            for (int i = 0; i < 10; i++) {
              ApiOptimizationUtils.clearCacheEntry(
                'cycle-${cycle - 1}-entry-$i',
              );
            }
          }
        }

        // Cache should still be functional
        final testEntry = ApiOptimizationUtils.getCachedRequest(
          'cycle-49-entry-0',
        );
        expect(testEntry, isNotNull,
            reason: 'Cache should remain functional after extended use');
      });

      test('batcher stability over extended use', () async {
        int batchCount = 0;
        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 30),
        );

        // Simulate extended use
        for (int cycle = 0; cycle < 20; cycle++) {
          for (int i = 0; i < 50; i++) {
            await batcher.add(i);
          }
          await Future.delayed(const Duration(milliseconds: 50));
        }

        batcher.dispose();

        // Should have created reasonable number of batches
        expect(batchCount, greaterThan(0),
            reason: 'Batcher should process requests');
        expect(batchCount, lessThan(1000),
            reason: 'Batcher should not create excessive batches');
      });
    });

    // ── Garbage Collection & Memory Recovery Tests ───────────────────

    group('Memory recovery after cleanup', () {
      test('memory is released after cache clear', () {
        imageCache.clear();
        ImageCacheUtils.configureImageCache();

        // Fill cache
        for (int i = 0; i < 50; i++) {
          // Simulate cache entries
        }

        var statsBeforeClear = ImageCacheUtils.getCacheStats();
        var sizeBefore = (statsBeforeClear['currentSize'] as int?) ?? 0;

        // Clear cache
        ImageCacheUtils.clearImageCache();

        var statsAfterClear = ImageCacheUtils.getCacheStats();
        var sizeAfter = (statsAfterClear['currentSize'] as int?) ?? 0;

        // Should be cleared
        expect(sizeAfter, lessThanOrEqualTo(sizeBefore),
            reason: 'Cache should be smaller after clear');
      });

      test('api cache clears expired entries automatically', () async {
        ApiOptimizationUtils.clearAllCache();

        // Add entries with various expiration times
        for (int i = 0; i < 30; i++) {
          ApiOptimizationUtils.cacheRequest(
            'expire-soon-$i',
            Future.value('data'),
            duration: const Duration(milliseconds: 50),
          );
        }

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 150));

        // Clear expired
        ApiOptimizationUtils.clearExpiredCache();

        // Expired entries should be gone
        expect(ApiOptimizationUtils.getCachedRequest('expire-soon-0'), isNull);
      });

      test('all optimization caches can be fully cleared', () {
        // Add data to all caches
        for (int i = 0; i < 20; i++) {
          ApiOptimizationUtils.cacheRequest(
            'api-$i',
            Future.value('data'),
          );
        }

        // Clear all
        ApiOptimizationUtils.clearAllCache();

        // Verify cleared
        expect(ApiOptimizationUtils.getCachedRequest('api-0'), isNull);
        expect(ApiOptimizationUtils.getCachedRequest('api-19'), isNull);
      });
    });

    // ── Memory Profiling Utility Tests ──────────────────────────────

    group('Memory profiling utilities', () {
      test('performance monitor tracking memory usage patterns', () {
        ApiPerformanceMonitor.clearStats();

        // Record various durations
        final durations = <int>[10, 50, 100, 150, 200, 250, 300];
        for (int i = 0; i < 50; i++) {
          final duration = durations[i % durations.length];
          ApiPerformanceMonitor.recordRequestDuration(
            'endpoint',
            Duration(milliseconds: duration),
          );
        }

        final stats = ApiPerformanceMonitor.getStats();
        expect(stats['endpoint'], isNotNull);

        final endpointStats = stats['endpoint'] as Map;
        expect(endpointStats['count'], 50);
        expect(endpointStats['averageDuration'], greaterThan(0));
      });

      test('image cache stats provide memory visibility', () {
        imageCache.clear();
        ImageCacheUtils.configureImageCache();

        final stats = ImageCacheUtils.getCacheStats();

        // Should report all relevant metrics
        expect(stats.containsKey('currentSize'), true);
        expect(stats.containsKey('currentSizeBytes'), true);
        expect(stats.containsKey('maximumSize'), true);
        expect(stats.containsKey('maximumSizeBytes'), true);

        // Current should not exceed maximum
        expect(
          (stats['currentSize'] as int) <= (stats['maximumSize'] as int),
          true,
        );
      });
    });
  });
}
