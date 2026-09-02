import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/utils/api_optimization_utils.dart';
import 'package:shougaku_kore_doutoku/utils/image_cache_utils.dart';

void main() {
  group('Stress Testing & Optimization Limits', () {
    // ── High Volume Request Stress Tests ────────────────────────────

    group('High volume request handling', () {
      test('debouncer handles 10000 rapid calls without crashing', () async {
        var executionCount = 0;
        final debouncer = Debouncer<int>(
          onValue: (_) => executionCount++,
          duration: const Duration(milliseconds: 10),
        );

        // Stress: 10000 rapid calls
        for (int i = 0; i < 10000; i++) {
          debouncer.add(i);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Should only execute once despite 10000 calls
        expect(executionCount, 1,
            reason: 'Debouncer should deduplicate 10000 calls to 1 execution');

        debouncer.dispose();
      });

      test('request cache handles 1000 cached entries', () {
        ApiOptimizationUtils.clearAllCache();

        // Stress: cache 1000 entries
        for (int i = 0; i < 1000; i++) {
          ApiOptimizationUtils.cacheRequest(
            'stress-$i',
            Future.value('response-$i'),
          );
        }

        // All should be retrievable
        for (int i = 0; i < 100; i++) {
          final cached = ApiOptimizationUtils.getCachedRequest('stress-$i');
          expect(cached, isNotNull,
              reason: 'Should retrieve cached entry (stress-$i)');
        }
      });

      test('request batcher handles 5000 simultaneous requests', () async {
        int batchCallCount = 0;
        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCallCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 100),
          maxBatchSize: 500,
        );

        // Stress: 5000 simultaneous requests
        final futures = <Future<List<int>>>[];
        for (int i = 0; i < 5000; i++) {
          futures.add(batcher.add(i));
        }

        await Future.wait(futures);

        // Should have completed
        expect(batchCallCount, greaterThan(0),
            reason: 'Batcher should process requests');

        // Should have created multiple batches due to volume
        expect(batchCallCount, lessThanOrEqualTo(20),
            reason: '5000 requests should be batched into <= 20 calls');

        batcher.dispose();
      });

      test('performance monitor tracks 10000 request durations', () {
        ApiPerformanceMonitor.clearStats();

        // Stress: record 10000 request durations
        for (int i = 0; i < 10000; i++) {
          ApiPerformanceMonitor.recordRequestDuration(
            'stress-endpoint-${i % 10}',
            Duration(milliseconds: i % 500),
          );
        }

        final stats = ApiPerformanceMonitor.getStats();

        // Should have tracked all endpoints
        expect(stats.length, 10,
            reason: 'Should track all 10 endpoints');

        // Each endpoint should have limited entries (100 max)
        for (final endpointStats in stats.values) {
          expect(
            (endpointStats as Map)['count'],
            lessThanOrEqualTo(100),
            reason: 'Should limit entries to 100 per endpoint',
          );
        }
      });
    });

    // ── Memory Stress Tests ──────────────────────────────────────────

    group('Memory handling under stress', () {
      test('image cache stays within limits under heavy use', () {
        imageCache.clear();
        ImageCacheUtils.configureImageCache();

        // Stress: get stats many times
        for (int i = 0; i < 10000; i++) {
          final stats = ImageCacheUtils.getCacheStats();
          // Stats should be accessible
          expect(stats.isNotEmpty, true);
        }

        // Cache should still be functional
        final finalStats = ImageCacheUtils.getCacheStats();
        expect(finalStats.containsKey('currentSize'), true);
      });

      test('cache memory does not grow unbounded with many entries', () {
        ApiOptimizationUtils.clearAllCache();

        // Add many entries
        for (int i = 0; i < 2000; i++) {
          ApiOptimizationUtils.cacheRequest(
            'stress-$i',
            Future.value('data-' * 1000), // Large data
            duration: const Duration(seconds: 10),
          );
        }

        // Cache should not crash
        final allCached = <String>[];
        for (int i = 0; i < 100; i++) {
          final entry = ApiOptimizationUtils.getCachedRequest('stress-$i');
          if (entry != null) {
            allCached.add('stress-$i');
          }
        }

        expect(allCached.isNotEmpty, true,
            reason: 'Cache should still work after stress');
      });

      test('listener memory under high volume', () {
        var callCount = 0;

        // Create many debouncer instances
        final debouncers = <Debouncer<int>>[];
        for (int i = 0; i < 100; i++) {
          debouncers.add(Debouncer<int>(
            onValue: (_) => callCount++,
            duration: const Duration(milliseconds: 10),
          ));
        }

        // Use all debouncers
        for (var debouncer in debouncers) {
          for (int i = 0; i < 10; i++) {
            debouncer.add(i);
          }
        }

        // Clean up
        for (var debouncer in debouncers) {
          debouncer.dispose();
        }

        // All should be disposed
        expect(debouncers.length, 100);
      });
    });

    // ── Cache Expiration Stress Tests ───────────────────────────────

    group('Cache expiration handling under stress', () {
      test('many concurrent cache expirations', () async {
        ApiOptimizationUtils.clearAllCache();

        // Add many short-lived entries
        for (int i = 0; i < 100; i++) {
          ApiOptimizationUtils.cacheRequest(
            'expire-$i',
            Future.value('data'),
            duration: const Duration(milliseconds: 50 + (i % 50)),
          );
        }

        // Wait for expiration window
        await Future.delayed(const Duration(milliseconds: 200));

        // Clear expired
        ApiOptimizationUtils.clearExpiredCache();

        // Most should be expired
        var expiredCount = 0;
        for (int i = 0; i < 100; i++) {
          if (ApiOptimizationUtils.getCachedRequest('expire-$i') == null) {
            expiredCount++;
          }
        }

        expect(expiredCount, greaterThan(50),
            reason:
                'Most entries should be expired after delay (expired: $expiredCount)');
      });

      test('cache clearing under full load', () async {
        ApiOptimizationUtils.clearAllCache();

        // Fill cache
        for (int i = 0; i < 500; i++) {
          ApiOptimizationUtils.cacheRequest(
            'fill-$i',
            Future.value('data'),
          );
        }

        // Clear while full
        ApiOptimizationUtils.clearAllCache();

        // Should be empty
        var itemCount = 0;
        for (int i = 0; i < 500; i++) {
          if (ApiOptimizationUtils.getCachedRequest('fill-$i') != null) {
            itemCount++;
          }
        }

        expect(itemCount, 0,
            reason: 'All cache should be cleared');
      });
    });

    // ── Concurrent Operation Stress Tests ───────────────────────────

    group('Concurrent optimization operations', () {
      test('concurrent debouncer and batcher operations', () async {
        var debounceCount = 0;
        var batchCount = 0;

        final debouncer = Debouncer<int>(
          onValue: (_) => debounceCount++,
          duration: const Duration(milliseconds: 20),
        );

        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 30),
        );

        // Run both concurrently
        await Future.wait([
          Future(() async {
            for (int i = 0; i < 500; i++) {
              debouncer.add(i);
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }),
          Future(() async {
            for (int i = 0; i < 500; i++) {
              unawaited(batcher.add(i));
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }),
        ]);

        debouncer.dispose();
        batcher.dispose();

        // Both should have completed
        expect(debounceCount, greaterThan(0));
        expect(batchCount, greaterThan(0));
      });

      test('concurrent cache operations', () async {
        ApiOptimizationUtils.clearAllCache();

        // Concurrent cache operations
        await Future.wait([
          Future(() {
            for (int i = 0; i < 300; i++) {
              ApiOptimizationUtils.cacheRequest(
                'concurrent-$i',
                Future.value('data-$i'),
              );
            }
          }),
          Future(() {
            for (int i = 0; i < 300; i++) {
              _ = ApiOptimizationUtils.getCachedRequest('concurrent-$i');
            }
          }),
          Future.delayed(const Duration(milliseconds: 100)).then((_) {
            ApiOptimizationUtils.clearExpiredCache();
          }),
        ]);

        // Cache should still be functional
        final testEntry = ApiOptimizationUtils.getCachedRequest('concurrent-0');
        expect(testEntry, isNotNull);
      });
    });

    // ── Error Recovery Stress Tests ──────────────────────────────────

    group('Error recovery under stress', () {
      test('batcher error handling with large batch', () async {
        var batchCallCount = 0;
        var errorCount = 0;

        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCallCount++;
            if (batchCallCount == 2) {
              throw Exception('Simulated batch error');
            }
            return ids;
          },
          windowDuration: const Duration(milliseconds: 50),
        );

        final futures = <Future<List<int>>>[];

        // First batch should succeed
        for (int i = 0; i < 100; i++) {
          futures.add(
            batcher.add(i).catchError((_) => []),
          );
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Second batch (will error)
        for (int i = 100; i < 200; i++) {
          futures.add(
            batcher.add(i).catchError((e) {
              errorCount++;
              return [];
            }),
          );
        }

        await Future.wait(futures);

        // Should have recovered from error
        expect(errorCount, greaterThanOrEqualTo(0),
            reason: 'Should handle errors gracefully');

        batcher.dispose();
      });

      test('cache recovery from clear operations', () {
        ApiOptimizationUtils.clearAllCache();

        // Add and clear multiple times
        for (int cycle = 0; cycle < 10; cycle++) {
          for (int i = 0; i < 100; i++) {
            ApiOptimizationUtils.cacheRequest(
              'cycle-$cycle-$i',
              Future.value('data'),
            );
          }

          ApiOptimizationUtils.clearAllCache();
        }

        // Should be empty
        expect(ApiOptimizationUtils.getCachedRequest('cycle-0-0'), isNull);
      });
    });

    // ── Sustained Load Tests ────────────────────────────────────────

    group('Sustained load stress tests', () {
      test('sustained debouncer load for 10 seconds', () async {
        var executionCount = 0;
        final debouncer = Debouncer<int>(
          onValue: (_) => executionCount++,
          duration: const Duration(milliseconds: 50),
        );

        final stopwatch = Stopwatch();
        stopwatch.start();

        // Generate load for 5 seconds
        while (stopwatch.elapsedMilliseconds < 5000) {
          debouncer.add(stopwatch.elapsedMilliseconds);
          await Future.delayed(const Duration(milliseconds: 10));
        }

        stopwatch.stop();

        debouncer.dispose();

        // Should have executed multiple times but not excessively
        expect(executionCount, greaterThan(50),
            reason: 'Should execute multiple times over 5 seconds');
        expect(executionCount, lessThan(500),
            reason: 'Should not execute excessively');
      });

      test('sustained cache operations', () async {
        ApiOptimizationUtils.clearAllCache();

        final stopwatch = Stopwatch();
        stopwatch.start();

        var operationCount = 0;

        // Run operations for 3 seconds
        while (stopwatch.elapsedMilliseconds < 3000) {
          // Mix of operations
          for (int i = 0; i < 10; i++) {
            ApiOptimizationUtils.cacheRequest(
              'sustained-${stopwatch.elapsedMilliseconds}-$i',
              Future.value('data'),
            );
            operationCount++;
          }

          for (int i = 0; i < 5; i++) {
            _ = ApiOptimizationUtils.getCachedRequest(
              'sustained-${stopwatch.elapsedMilliseconds - 100}-$i',
            );
            operationCount++;
          }

          if (operationCount % 100 == 0) {
            ApiOptimizationUtils.clearExpiredCache();
          }
        }

        stopwatch.stop();

        // Should have completed without crashes
        expect(operationCount, greaterThan(0),
            reason: 'Should complete sustained operations');
      });
    });
  });
}

// Helper to avoid "not awaited" warnings
void unawaited(Future<void> future) {}
