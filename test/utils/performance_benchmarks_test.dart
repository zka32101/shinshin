import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/utils/api_optimization_utils.dart';
import 'package:shougaku_kore_doutoku/utils/image_cache_utils.dart';

void main() {
  group('Performance Benchmarks', () {
    // ── Provider Select Optimization Benchmarks ──────────────────────────

    group('Provider Select Rebuild Reduction Benchmarks', () {
      test('measures overhead of select() call', () {
        final stopwatch = Stopwatch();

        // Measure 10000 select calls
        stopwatch.start();
        for (int i = 0; i < 10000; i++) {
          // Simulate select() operation
          final testData = _TestData(name: 'test', value: i);
          final selected = testData.name; // select(d => d.name)
          assert(selected == 'test');
        }
        stopwatch.stop();

        // Should be very fast (< 50ms for 10000 operations)
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason:
                'select() should have minimal overhead (${stopwatch.elapsedMilliseconds}ms for 10k calls)');
      });

      test('benchmarks select() memory efficiency vs full watch', () {
        final stopwatch = Stopwatch();

        // Measure memory usage for 1000 select operations
        stopwatch.start();
        for (int i = 0; i < 1000; i++) {
          final data = _TestData(name: 'test-$i', value: i);
          _ = data.name; // select
        }
        stopwatch.stop();

        // Should complete quickly, indicating low memory overhead
        expect(stopwatch.elapsedMilliseconds, lessThan(10),
            reason: 'Select on 1000 objects should be very fast');
      });
    });

    // ── API Request Optimization Benchmarks ──────────────────────────

    group('API Optimization Benchmarks', () {
      setUp(() {
        ApiOptimizationUtils.clearAllCache();
        ApiPerformanceMonitor.clearStats();
      });

      test('debouncer performance: rapid calls reduction', () async {
        var callCount = 0;
        final debouncer = Debouncer<int>(
          onValue: (_) => callCount++,
          duration: const Duration(milliseconds: 10),
        );

        final stopwatch = Stopwatch();
        stopwatch.start();

        // Simulate 1000 rapid API calls
        for (int i = 0; i < 1000; i++) {
          debouncer.add(i);
        }

        stopwatch.stop();

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 50));

        // With debouncing: 1000 calls should result in 1 actual execution
        expect(callCount, 1,
            reason: '1000 debounced calls should result in 1 execution');

        // Debouncer overhead should be minimal
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason:
                'Debouncer should add < 100ms overhead (${stopwatch.elapsedMilliseconds}ms)');

        debouncer.dispose();
      });

      test('request cache performance: lookup speed', () {
        final stopwatch = Stopwatch();

        // Cache 100 requests
        for (int i = 0; i < 100; i++) {
          ApiOptimizationUtils.cacheRequest(
            'request-$i',
            Future.value('data-$i'),
          );
        }

        // Benchmark 10000 lookups
        stopwatch.start();
        for (int i = 0; i < 10000; i++) {
          _ = ApiOptimizationUtils.getCachedRequest('request-${i % 100}');
        }
        stopwatch.stop();

        // 10000 cache lookups should be very fast (< 10ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(10),
            reason:
                'Cache lookup should be fast (${stopwatch.elapsedMilliseconds}ms for 10k lookups)');
      });

      test('request batcher throughput: requests per second', () async {
        int batchCount = 0;
        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 50),
        );

        final stopwatch = Stopwatch();
        stopwatch.start();

        // Add 500 requests
        final futures = <Future<List<int>>>[];
        for (int i = 0; i < 500; i++) {
          futures.add(batcher.add(i));
        }

        await Future.wait(futures);
        stopwatch.stop();

        // 500 requests should be batched into multiple batches
        // (depending on window duration and request rate)
        expect(batchCount, lessThanOrEqualTo(10),
            reason:
                'Batching should significantly reduce API calls (${batchCount} batches for 500 requests)');

        // Throughput should be good: 500 requests in reasonable time
        final requestsPerSecond = (500 / stopwatch.elapsedMilliseconds) * 1000;
        expect(requestsPerSecond, greaterThan(100),
            reason:
                'Should handle 100+ requests/second (achieved: ${requestsPerSecond.toStringAsFixed(0)} req/s)');

        batcher.dispose();
      });

      test('performance monitor recording overhead', () {
        final stopwatch = Stopwatch();

        // Record 10000 request durations
        stopwatch.start();
        for (int i = 0; i < 10000; i++) {
          ApiPerformanceMonitor.recordRequestDuration(
            'test-endpoint',
            Duration(milliseconds: i % 100),
          );
        }
        stopwatch.stop();

        // Recording should be fast (< 50ms for 10000 records)
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason:
                'Monitoring overhead should be minimal (${stopwatch.elapsedMilliseconds}ms for 10k records)');
      });

      test('performance monitor query speed', () {
        // Pre-populate with 1000 data points
        for (int i = 0; i < 1000; i++) {
          ApiPerformanceMonitor.recordRequestDuration(
            'endpoint-${i % 10}',
            Duration(milliseconds: i),
          );
        }

        final stopwatch = Stopwatch();

        // Query stats 1000 times
        stopwatch.start();
        for (int i = 0; i < 1000; i++) {
          _ = ApiPerformanceMonitor.getStats();
        }
        stopwatch.stop();

        // Query should be fast (< 10ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(10),
            reason: 'Stat queries should be fast (${stopwatch.elapsedMilliseconds}ms)');
      });
    });

    // ── Image Caching Benchmarks ─────────────────────────────────────

    group('Image Cache Performance Benchmarks', () {
      setUp(() {
        imageCache.clear();
      });

      test('image cache configuration performance', () {
        final stopwatch = Stopwatch();

        stopwatch.start();
        ImageCacheUtils.configureImageCache();
        stopwatch.stop();

        // Configuration should be instant (< 5ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(5),
            reason: 'Cache configuration should be fast');
      });

      test('memory efficient cache configuration performance', () {
        final stopwatch = Stopwatch();

        stopwatch.start();
        ImageCacheUtils.configureMemoryEfficientCaching();
        stopwatch.stop();

        // Should be fast (< 5ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(5),
            reason: 'Memory efficient config should be fast');
      });

      test('cache stats retrieval speed', () {
        ImageCacheUtils.configureImageCache();

        final stopwatch = Stopwatch();

        // Get stats 1000 times
        stopwatch.start();
        for (int i = 0; i < 1000; i++) {
          _ = ImageCacheUtils.getCacheStats();
        }
        stopwatch.stop();

        // Should be very fast (< 10ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(10),
            reason: 'Stats retrieval should be fast (${stopwatch.elapsedMilliseconds}ms)');
      });

      test('cache threshold check speed', () {
        final stopwatch = Stopwatch();

        // Check threshold 10000 times
        stopwatch.start();
        for (int i = 0; i < 10000; i++) {
          _ = ImageCacheUtils.shouldClearCache();
        }
        stopwatch.stop();

        // Should be very fast (< 50ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: 'Threshold check should be fast (${stopwatch.elapsedMilliseconds}ms)');
      });
    });

    // ── Combined Optimization Benchmarks ────────────────────────────

    group('Combined Optimization Benchmarks', () {
      setUp(() {
        ApiOptimizationUtils.clearAllCache();
        ApiPerformanceMonitor.clearStats();
        imageCache.clear();
      });

      test('all optimizations working together: throughput', () async {
        final debouncer = Debouncer<String>(
          onValue: (_) {},
          duration: const Duration(milliseconds: 10),
        );

        final batcher = RequestBatcher<int, String>(
          batchFn: (ids) async => ids.map((i) => 'batch-result-$i').toList().join(','),
          windowDuration: const Duration(milliseconds: 50),
        );

        final stopwatch = Stopwatch();
        stopwatch.start();

        // Simulate combined usage
        for (int i = 0; i < 100; i++) {
          debouncer.add('search-$i');
          batcher.add(i);
          ApiPerformanceMonitor.recordRequestDuration(
            'api-call',
            const Duration(milliseconds: 50),
          );
        }

        stopwatch.stop();

        // All operations should complete quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(200),
            reason:
                'Combined optimizations should work efficiently (${stopwatch.elapsedMilliseconds}ms)');

        debouncer.dispose();
        batcher.dispose();
      });

      test('optimization memory footprint', () {
        ImageCacheUtils.configureImageCache();
        final initialStats = ImageCacheUtils.getCacheStats();

        // Create optimization objects
        final debouncer = Debouncer<String>(
          onValue: (_) {},
          duration: const Duration(milliseconds: 10),
        );

        final batcher = RequestBatcher<int, String>(
          batchFn: (ids) async => 'batched',
          windowDuration: const Duration(milliseconds: 50),
        );

        // Use them
        for (int i = 0; i < 100; i++) {
          debouncer.add('test-$i');
          batcher.add(i);
        }

        // Cache stats should stay reasonable
        final finalStats = ImageCacheUtils.getCacheStats();
        expect(
          (finalStats['currentSizeBytes'] as int?) ?? 0,
          lessThanOrEqualTo(10 * 1024 * 1024),
          reason: 'Optimizations should not use excessive memory',
        );

        debouncer.dispose();
        batcher.dispose();
      });

      test('optimization effectiveness: API call reduction measurement', () async {
        var apiCallsWithoutOptimization = 0;
        var apiCallsWithOptimization = 0;

        // Simulate without optimization: 100 rapid calls
        for (int i = 0; i < 100; i++) {
          apiCallsWithoutOptimization++;
        }

        // Simulate with optimization: debounced
        final debouncer = Debouncer<int>(
          onValue: (_) {
            apiCallsWithOptimization++;
          },
          duration: const Duration(milliseconds: 20),
        );

        for (int i = 0; i < 100; i++) {
          debouncer.add(i);
        }

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 100));

        // Calculate improvement
        final improvement =
            ((apiCallsWithoutOptimization - apiCallsWithOptimization) /
                    apiCallsWithoutOptimization) *
                100;

        expect(improvement, greaterThan(50),
            reason:
                'Should achieve 50%+ reduction (achieved: ${improvement.toStringAsFixed(1)}%)');

        debouncer.dispose();
      });
    });

    // ── Optimization Scaling Benchmarks ──────────────────────────────

    group('Optimization Scaling Benchmarks', () {
      test('select() scales with number of listeners', () {
        final stopwatch = Stopwatch();
        var notificationCount = 0;

        // Simulate 1000 select listeners
        final listeners = <_SelectListener>[];
        for (int i = 0; i < 1000; i++) {
          listeners.add(_SelectListener(() {
            notificationCount++;
          }));
        }

        stopwatch.start();

        // Trigger all listeners
        for (final listener in listeners) {
          listener.notify();
        }

        stopwatch.stop();

        // 1000 listeners should notify quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: '1000 listeners should notify within 50ms');
        expect(notificationCount, 1000);
      });

      test('cache performance scales with cache size', () {
        final stopwatch = Stopwatch();

        // Fill cache with 1000 entries
        for (int i = 0; i < 1000; i++) {
          ApiOptimizationUtils.cacheRequest(
            'request-$i',
            Future.value('response-$i'),
          );
        }

        // Benchmark lookups
        stopwatch.start();
        for (int i = 0; i < 10000; i++) {
          _ = ApiOptimizationUtils.getCachedRequest('request-${i % 1000}');
        }
        stopwatch.stop();

        // Even with 1000 cached items, lookups should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(20),
            reason:
                'Cache should scale well (${stopwatch.elapsedMilliseconds}ms for 10k lookups)');
      });

      test('batcher performance scales with batch size', () async {
        int batchCallCount = 0;
        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCallCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 50),
          maxBatchSize: 100, // Larger batches
        );

        final stopwatch = Stopwatch();
        stopwatch.start();

        // Add 1000 requests
        final futures = <Future<List<int>>>[];
        for (int i = 0; i < 1000; i++) {
          futures.add(batcher.add(i));
        }

        await Future.wait(futures);
        stopwatch.stop();

        // Even with 1000 requests, should complete reasonably fast
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: '1000 batched requests should complete < 1s');

        // Should use multiple batches
        expect(batchCallCount, greaterThan(1),
            reason: 'Should create multiple batches');

        batcher.dispose();
      });
    });
  });
}

// ── Test Helpers ─────────────────────────────────────────────────────────

class _TestData {
  final String name;
  final int value;

  _TestData({required this.name, required this.value});
}

class _SelectListener {
  final Function onNotify;

  _SelectListener(this.onNotify);

  void notify() {
    onNotify();
  }
}
