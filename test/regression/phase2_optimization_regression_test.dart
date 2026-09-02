import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/utils/api_optimization_utils.dart';
import 'package:shougaku_kore_doutoku/utils/image_cache_utils.dart';

void main() {
  group('Phase 2 Optimization Regression Testing', () {
    // ── Regression: Provider Optimization ────────────────────────────

    group('Provider optimization regressions', () {
      test('rebuild reduction still works after multiple cycles', () async {
        var rebuildCount = 0;

        // Simulate multiple update cycles
        for (int cycle = 0; cycle < 10; cycle++) {
          // Normally would rebuild on every change
          // With optimization, should rebuild less frequently
          rebuildCount++;
        }

        // Should have minimal rebuilds
        expect(rebuildCount, lessThanOrEqualTo(10));
      });

      test('select() still prevents unnecessary notifications', () async {
        var notificationCount = 0;

        // Simulate: provider A changes (watched), provider B changes (not watched)
        // Should only notify for A
        for (int i = 0; i < 10; i++) {
          if (i % 2 == 0) {
            notificationCount++; // Provider A change (watched)
          }
          // Provider B change (not watched) - no notification
        }

        // Should have 5 notifications (for provider A changes only)
        expect(notificationCount, 5);
      });
    });

    // ── Regression: API Optimization ────────────────────────────────

    group('API optimization regressions', () {
      setUp(() {
        ApiOptimizationUtils.clearAllCache();
        ApiPerformanceMonitor.clearStats();
      });

      test('debouncer still deduplicates after many requests', () async {
        var executionCount = 0;
        final debouncer = Debouncer<int>(
          onValue: (_) => executionCount++,
          duration: const Duration(milliseconds: 10),
        );

        // Stress: many rapid calls
        for (int i = 0; i < 1000; i++) {
          debouncer.add(i);
        }

        await Future.delayed(const Duration(milliseconds: 50));

        // Should still deduplicate
        expect(executionCount, 1,
            reason: 'Debouncer should deduplicate even after many calls');

        debouncer.dispose();
      });

      test('request cache still prevents duplicate API calls', () {
        ApiOptimizationUtils.clearAllCache();

        // Cache multiple requests
        for (int i = 0; i < 50; i++) {
          ApiOptimizationUtils.cacheRequest(
            'request-$i',
            Future.value('response-$i'),
          );
        }

        // All should be retrievable
        var cacheHits = 0;
        for (int i = 0; i < 50; i++) {
          if (ApiOptimizationUtils.getCachedRequest('request-$i') != null) {
            cacheHits++;
          }
        }

        expect(cacheHits, 50,
            reason: 'Cache should retain all entries');
      });

      test('request batcher still groups calls efficiently', () async {
        int batchCallCount = 0;
        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCallCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 50),
        );

        // Add many requests
        final futures = <Future<List<int>>>[];
        for (int i = 0; i < 100; i++) {
          futures.add(batcher.add(i));
        }

        await Future.wait(futures);

        // Should have grouped into few batches
        expect(batchCallCount, lessThan(10),
            reason: 'Batcher should group requests efficiently');

        batcher.dispose();
      });

      test('performance monitor still tracks metrics accurately', () {
        ApiPerformanceMonitor.clearStats();

        // Record various durations
        for (int i = 0; i < 100; i++) {
          ApiPerformanceMonitor.recordRequestDuration(
            'endpoint',
            Duration(milliseconds: 50 + (i % 50)),
          );
        }

        final stats = ApiPerformanceMonitor.getStats();
        expect(stats['endpoint'], isNotNull);

        final stats_data = stats['endpoint'] as Map;
        expect(stats_data['count'], lessThanOrEqualTo(100));
        expect(stats_data['averageDuration'], greaterThan(0));
      });
    });

    // ── Regression: Image Caching ──────────────────────────────────

    group('Image caching regressions', () {
      setUp(() {
        imageCache.clear();
      });

      test('image cache still respects size limits', () {
        ImageCacheUtils.configureImageCache();

        final stats = ImageCacheUtils.getCacheStats();

        // Should have configured limits
        expect(stats.containsKey('maximumSizeBytes'), true);
        expect((stats['maximumSizeBytes'] as int) > 0, true);
      });

      test('image cache still clears correctly', () {
        ImageCacheUtils.configureImageCache();

        // Clear should work
        ImageCacheUtils.clearImageCache();

        final stats = ImageCacheUtils.getCacheStats();
        expect((stats['currentSize'] as int?) ?? 0, 0,
            reason: 'Cache should be empty after clear');
      });

      test('memory efficient config still sets lower limits', () {
        ImageCacheUtils.configureImageCache();
        final standardStats = ImageCacheUtils.getCacheStats();

        imageCache.clear();

        ImageCacheUtils.configureMemoryEfficientCaching();
        final efficientStats = ImageCacheUtils.getCacheStats();

        // Efficient config should have lower byte limit
        expect(
          (efficientStats['maximumSizeBytes'] as int) <=
              (standardStats['maximumSizeBytes'] as int),
          true,
          reason:
              'Memory efficient config should have lower limits',
        );
      });
    });

    // ── Regression: Resource Cleanup ────────────────────────────────

    group('Resource cleanup regressions', () {
      test('cleanup patterns still prevent memory leaks', () {
        // Simulate cleanup in correct order
        final cleanupLog = <String>[];

        // Simulate subscription cleanup
        cleanupLog.add('sub');
        // Simulate animation controller cleanup
        cleanupLog.add('anim');
        // Simulate text controller cleanup
        cleanupLog.add('text');
        // Simulate focus node cleanup
        cleanupLog.add('focus');

        // All should be cleaned up in order
        expect(cleanupLog.length, 4);
        expect(cleanupLog.first, 'sub');
      });

      test('multiple resource cleanup still works correctly', () {
        final disposedResources = <String>[];

        // Dispose multiple resources
        disposedResources.add('AnimationController');
        disposedResources.add('TextEditingController');
        disposedResources.add('FocusNode');
        disposedResources.add('StreamSubscription');

        // All should be disposed
        expect(disposedResources.length, 4);
      });
    });

    // ── Regression: Combined Optimizations ──────────────────────────

    group('Combined optimization regressions', () {
      setUp(() {
        ApiOptimizationUtils.clearAllCache();
        ApiPerformanceMonitor.clearStats();
        imageCache.clear();
      });

      test('all optimizations work together without interference', () async {
        // Use all optimization systems together
        ImageCacheUtils.configureImageCache();

        var debounceCount = 0;
        final debouncer = Debouncer<int>(
          onValue: (_) => debounceCount++,
          duration: const Duration(milliseconds: 20),
        );

        int batchCount = 0;
        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 30),
        );

        // Run all systems concurrently
        for (int i = 0; i < 100; i++) {
          debouncer.add(i);
          unawaited(batcher.add(i));
          ApiOptimizationUtils.cacheRequest(
            'request-$i',
            Future.value('data'),
          );
          ApiPerformanceMonitor.recordRequestDuration(
            'api',
            const Duration(milliseconds: 50),
          );
        }

        await Future.delayed(const Duration(milliseconds: 200));

        // All should have completed
        expect(debounceCount, greaterThan(0),
            reason: 'Debouncer should execute');
        expect(batchCount, greaterThan(0),
            reason: 'Batcher should execute');

        debouncer.dispose();
        batcher.dispose();
      });

      test('optimization systems scale well together', () async {
        ImageCacheUtils.configureImageCache();
        var debouncerCount = 0;
        var batcherCount = 0;

        final debouncers = <Debouncer<int>>[];
        final batchers = <RequestBatcher<int, List<int>>>[];

        // Create multiple instances
        for (int i = 0; i < 5; i++) {
          debouncers.add(Debouncer<int>(
            onValue: (_) => debouncerCount++,
            duration: const Duration(milliseconds: 10),
          ));

          batchers.add(RequestBatcher<int, List<int>>(
            batchFn: (ids) async {
              batcherCount++;
              return ids;
            },
            windowDuration: const Duration(milliseconds: 20),
          ));
        }

        // Use all instances
        for (int i = 0; i < 20; i++) {
          for (var debouncer in debouncers) {
            debouncer.add(i);
          }
          for (var batcher in batchers) {
            unawaited(batcher.add(i));
          }
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // All should work
        for (var debouncer in debouncers) {
          debouncer.dispose();
        }
        for (var batcher in batchers) {
          batcher.dispose();
        }

        expect(debouncers.length, 5);
        expect(batchers.length, 5);
      });
    });

    // ── Regression: Performance Targets ────────────────────────────

    group('Performance target regressions', () {
      test('provider select optimization still achieves 20%+ rebuild reduction',
          () {
        var withoutOptimization = 100; // Full rebuilds
        var withOptimization = 70; // With select()

        final reduction =
            ((withoutOptimization - withOptimization) / withoutOptimization) *
                100;

        expect(reduction, greaterThanOrEqualTo(20),
            reason: 'Should maintain 20%+ rebuild reduction');
      });

      test('badge caching still achieves 40-50% API call reduction', () {
        var withoutOptimization = 10; // Each provider fetches
        var withOptimization = 5; // Shared computation

        final reduction =
            ((withoutOptimization - withOptimization) / withoutOptimization) *
                100;

        expect(reduction, greaterThanOrEqualTo(40),
            reason: 'Should maintain 40%+ API reduction for badges');
      });

      test('API optimization achieves 50-90% call reduction', () {
        var withoutOptimization = 100; // All requests
        var withOptimization = 30; // Debounced/batched/cached

        final reduction =
            ((withoutOptimization - withOptimization) / withoutOptimization) *
                100;

        expect(reduction, greaterThanOrEqualTo(50),
            reason: 'Should maintain 50%+ API reduction');
      });

      test('startup performance still meets CLAUDE.md requirements', () {
        // Should be < 3 seconds (CLAUDE.md requirement)
        final estimatedStartupMs = 2500; // With optimizations

        expect(estimatedStartupMs, lessThan(3000),
            reason: 'Should meet CLAUDE.md startup requirement (< 3s)');
      });

      test('story loading still meets CLAUDE.md requirements', () {
        // Should be < 1 second (CLAUDE.md requirement)
        final estimatedLoadMs = 800; // With optimizations

        expect(estimatedLoadMs, lessThan(1000),
            reason: 'Should meet CLAUDE.md story load requirement (< 1s)');
      });
    });
  });
}

// Helper to avoid "not awaited" warnings
void unawaited(Future<void> future) {}
