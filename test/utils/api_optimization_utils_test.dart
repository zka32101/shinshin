import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/utils/api_optimization_utils.dart';

void main() {
  group('API Optimization Utils', () {
    // ── PRIORITY 6: Debouncer Tests ────────────────────────────────────

    group('Debouncer', () {
      test('debounces rapid calls and only executes last value', () async {
        final results = <int>[];
        final debouncer = Debouncer<int>(
          onValue: (value) => results.add(value),
          duration: const Duration(milliseconds: 50),
        );

        // Add multiple values rapidly
        debouncer.add(1);
        debouncer.add(2);
        debouncer.add(3);

        // No results yet (debouncing)
        expect(results, isEmpty);

        // Wait for debounce duration + buffer
        await Future.delayed(const Duration(milliseconds: 100));

        // Only the last value should have been processed
        expect(results, [3]);
        expect(results.length, 1);
      });

      test('debounces each call separately when spread out', () async {
        final results = <int>[];
        final debouncer = Debouncer<int>(
          onValue: (value) => results.add(value),
          duration: const Duration(milliseconds: 50),
        );

        // Add first value
        debouncer.add(1);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(results, [1]);

        // Add second value (separate debounce window)
        debouncer.add(2);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(results, [1, 2]);
      });

      test('cancel prevents debounced call from executing', () async {
        final results = <int>[];
        final debouncer = Debouncer<int>(
          onValue: (value) => results.add(value),
          duration: const Duration(milliseconds: 50),
        );

        debouncer.add(1);
        debouncer.cancel();

        await Future.delayed(const Duration(milliseconds: 100));

        // Call should not have executed
        expect(results, isEmpty);
      });

      test('dispose cancels pending debounced calls', () async {
        final results = <int>[];
        final debouncer = Debouncer<int>(
          onValue: (value) => results.add(value),
          duration: const Duration(milliseconds: 50),
        );

        debouncer.add(1);
        debouncer.dispose();

        await Future.delayed(const Duration(milliseconds: 100));

        // Call should not have executed after dispose
        expect(results, isEmpty);
      });

      test('works with string values (search use case)', () async {
        final queries = <String>[];
        final debouncer = Debouncer<String>(
          onValue: (query) => queries.add(query),
          duration: const Duration(milliseconds: 50),
        );

        // Simulate typing
        debouncer.add('f');
        debouncer.add('fl');
        debouncer.add('flu');
        debouncer.add('flut');
        debouncer.add('flutt');
        debouncer.add('flutte');
        debouncer.add('flutter');

        await Future.delayed(const Duration(milliseconds: 100));

        // Only final query should be processed
        expect(queries, ['flutter']);
      });
    });

    // ── PRIORITY 6: Request Cache Tests ────────────────────────────────

    group('Request Deduplication Cache', () {
      setUp(() {
        ApiOptimizationUtils.clearAllCache();
      });

      test('caches request response', () async {
        final future = Future.value('response-data');
        ApiOptimizationUtils.cacheRequest('test_key', future);

        final cached = ApiOptimizationUtils.getCachedRequest('test_key');
        expect(cached, isNotNull);
      });

      test('returns cached request without re-executing', () async {
        var callCount = 0;
        final future = Future(() {
          callCount++;
          return 'response-data';
        });

        ApiOptimizationUtils.cacheRequest('test_key', future);

        // First read
        final cached1 = ApiOptimizationUtils.getCachedRequest('test_key');
        expect(cached1, isNotNull);

        // Second read (should be cached)
        final cached2 = ApiOptimizationUtils.getCachedRequest('test_key');
        expect(cached2, isNotNull);
        expect(identical(cached1, cached2), true);
      });

      test('cache expires after configured duration', () async {
        final future = Future.value('response-data');
        ApiOptimizationUtils.cacheRequest(
          'test_key',
          future,
          duration: const Duration(milliseconds: 50),
        );

        // Cache should exist immediately
        expect(ApiOptimizationUtils.getCachedRequest('test_key'), isNotNull);

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 100));

        // Cache should have expired
        expect(ApiOptimizationUtils.getCachedRequest('test_key'), isNull);
      });

      test('clearCacheEntry removes specific cache entry', () async {
        final future = Future.value('data');
        ApiOptimizationUtils.cacheRequest('key1', future);
        ApiOptimizationUtils.cacheRequest('key2', future);

        expect(ApiOptimizationUtils.getCachedRequest('key1'), isNotNull);
        expect(ApiOptimizationUtils.getCachedRequest('key2'), isNotNull);

        ApiOptimizationUtils.clearCacheEntry('key1');

        expect(ApiOptimizationUtils.getCachedRequest('key1'), isNull);
        expect(ApiOptimizationUtils.getCachedRequest('key2'), isNotNull);
      });

      test('clearAllCache removes all cached requests', () async {
        final future = Future.value('data');
        ApiOptimizationUtils.cacheRequest('key1', future);
        ApiOptimizationUtils.cacheRequest('key2', future);
        ApiOptimizationUtils.cacheRequest('key3', future);

        expect(ApiOptimizationUtils.getCachedRequest('key1'), isNotNull);
        expect(ApiOptimizationUtils.getCachedRequest('key2'), isNotNull);
        expect(ApiOptimizationUtils.getCachedRequest('key3'), isNotNull);

        ApiOptimizationUtils.clearAllCache();

        expect(ApiOptimizationUtils.getCachedRequest('key1'), isNull);
        expect(ApiOptimizationUtils.getCachedRequest('key2'), isNull);
        expect(ApiOptimizationUtils.getCachedRequest('key3'), isNull);
      });

      test('clearExpiredCache removes only expired entries', () async {
        final future = Future.value('data');

        // Long-lived cache
        ApiOptimizationUtils.cacheRequest(
          'valid',
          future,
          duration: const Duration(seconds: 60),
        );

        // Short-lived cache
        ApiOptimizationUtils.cacheRequest(
          'expired',
          future,
          duration: const Duration(milliseconds: 50),
        );

        // Wait for expiration of short-lived cache
        await Future.delayed(const Duration(milliseconds: 100));

        ApiOptimizationUtils.clearExpiredCache();

        expect(ApiOptimizationUtils.getCachedRequest('valid'), isNotNull);
        expect(ApiOptimizationUtils.getCachedRequest('expired'), isNull);
      });
    });

    // ── PRIORITY 6: RequestBatcher Tests ────────────────────────────────

    group('RequestBatcher', () {
      test('batches multiple requests into single batch call', () async {
        var batchCallCount = 0;
        final batcher = RequestBatcher<String, List<String>>(
          batchFn: (ids) async {
            batchCallCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 50),
        );

        // Add multiple requests
        final result1 = batcher.add('id-1');
        final result2 = batcher.add('id-2');
        final result3 = batcher.add('id-3');

        final batch1 = await result1;
        final batch2 = await result2;
        final batch3 = await result3;

        // All should get same batch result
        expect(batch1, containsAll(['id-1', 'id-2', 'id-3']));
        expect(batch2, containsAll(['id-1', 'id-2', 'id-3']));
        expect(batch3, containsAll(['id-1', 'id-2', 'id-3']));

        // Should only have called batch function once
        expect(batchCallCount, 1);
      });

      test('processes batch immediately when maxBatchSize reached', () async {
        var batchCallCount = 0;
        final batcher = RequestBatcher<String, List<String>>(
          batchFn: (ids) async {
            batchCallCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 500),
          maxBatchSize: 3,
        );

        // Add requests up to max batch size
        final result1 = batcher.add('id-1');
        final result2 = batcher.add('id-2');
        // This should trigger immediate batch processing
        final result3 = batcher.add('id-3');

        final batch = await result3;

        // Should have processed batch due to max size
        expect(batchCallCount, 1);
        expect(batch, containsAll(['id-1', 'id-2', 'id-3']));
      });

      test('handles batch function errors and propagates to all requests', () async {
        final batcher = RequestBatcher<String, String>(
          batchFn: (_) async => throw Exception('Batch failed'),
          windowDuration: const Duration(milliseconds: 50),
        );

        final result1 = batcher.add('id-1');
        final result2 = batcher.add('id-2');

        // Both should error
        expect(
          result1,
          throwsA(isA<Exception>()),
        );
        expect(
          result2,
          throwsA(isA<Exception>()),
        );
      });

      test('dispose prevents further batching', () async {
        var batchCallCount = 0;
        final batcher = RequestBatcher<String, List<String>>(
          batchFn: (ids) async {
            batchCallCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 50),
        );

        batcher.add('id-1');
        batcher.dispose();

        // Wait for window duration
        await Future.delayed(const Duration(milliseconds: 100));

        // Batch should not have been called after dispose
        expect(batchCallCount, 0);
      });
    });

    // ── PRIORITY 6: Performance Monitoring Tests ─────────────────────

    group('ApiPerformanceMonitor', () {
      setUp(() {
        ApiPerformanceMonitor.clearStats();
      });

      test('records request duration', () {
        const duration = Duration(milliseconds: 150);
        ApiPerformanceMonitor.recordRequestDuration('fetch_stories', duration);

        final stats = ApiPerformanceMonitor.getStats();
        expect(stats, containsKey('fetch_stories'));
        expect(stats['fetch_stories']?['count'], 1);
        expect(stats['fetch_stories']?['averageDuration'], 150);
      });

      test('calculates average duration across multiple requests', () {
        ApiPerformanceMonitor.recordRequestDuration(
          'fetch_stories',
          const Duration(milliseconds: 100),
        );
        ApiPerformanceMonitor.recordRequestDuration(
          'fetch_stories',
          const Duration(milliseconds: 200),
        );
        ApiPerformanceMonitor.recordRequestDuration(
          'fetch_stories',
          const Duration(milliseconds: 300),
        );

        final stats = ApiPerformanceMonitor.getStats();
        expect(stats['fetch_stories']?['count'], 3);
        // Average of 100, 200, 300 = 200
        expect(stats['fetch_stories']?['averageDuration'], 200);
      });

      test('tracks multiple endpoints independently', () {
        ApiPerformanceMonitor.recordRequestDuration(
          'fetch_stories',
          const Duration(milliseconds: 100),
        );
        ApiPerformanceMonitor.recordRequestDuration(
          'fetch_badges',
          const Duration(milliseconds: 50),
        );

        final stats = ApiPerformanceMonitor.getStats();
        expect(stats['fetch_stories']?['averageDuration'], 100);
        expect(stats['fetch_badges']?['averageDuration'], 50);
      });

      test('clearStats removes all recorded statistics', () {
        ApiPerformanceMonitor.recordRequestDuration(
          'fetch_stories',
          const Duration(milliseconds: 100),
        );
        ApiPerformanceMonitor.recordRequestDuration(
          'fetch_badges',
          const Duration(milliseconds: 50),
        );

        var stats = ApiPerformanceMonitor.getStats();
        expect(stats, isNotEmpty);

        ApiPerformanceMonitor.clearStats();
        stats = ApiPerformanceMonitor.getStats();
        expect(stats, isEmpty);
      });

      test('keeps only last 100 requests per endpoint', () {
        // Record 150 requests
        for (int i = 0; i < 150; i++) {
          ApiPerformanceMonitor.recordRequestDuration(
            'test_endpoint',
            Duration(milliseconds: i),
          );
        }

        // Should only keep last 100
        // Average of requests 50-149 = (50+149)/2 = 99.5, rounded down
        final avg =
            ApiPerformanceMonitor.getStats()['test_endpoint']?['averageDuration'];
        expect(avg, greaterThan(80)); // Should be around 99
        expect(avg, lessThan(120));
      });
    });

    // ── Optimization Effectiveness Tests ────────────────────────────

    group('API Optimization Effectiveness', () {
      test('debouncer reduces API calls by 50%+ in rapid input scenario',
          () async {
        var apiCallCount = 0;

        // Without debouncing (simulated)
        for (int i = 0; i < 10; i++) {
          apiCallCount++;
        }
        final callsWithoutDebounce = apiCallCount;

        // With debouncing
        apiCallCount = 0;
        final debouncer = Debouncer<int>(
          onValue: (_) {
            apiCallCount++;
          },
          duration: const Duration(milliseconds: 50),
        );

        for (int i = 0; i < 10; i++) {
          debouncer.add(i);
        }

        await Future.delayed(const Duration(milliseconds: 100));
        final callsWithDebounce = apiCallCount;

        final reduction =
            ((callsWithoutDebounce - callsWithDebounce) / callsWithoutDebounce) *
                100;
        expect(reduction, greaterThan(50),
            reason:
                'Debouncer should reduce API calls by 50%+ (reduction: $reduction%)');
      });

      test('request cache prevents duplicate API calls', () async {
        var fetchCount = 0;

        // First request
        final future1 = Future(() {
          fetchCount++;
          return 'data';
        });
        ApiOptimizationUtils.cacheRequest('user_123', future1);

        // Attempt second request (should use cache)
        final cached = ApiOptimizationUtils.getCachedRequest('user_123');

        expect(fetchCount, 0); // Not executed yet
        expect(cached, isNotNull); // But cached reference exists

        await future1; // Execute the cached future

        // Try to get again (should be same cached future)
        final cached2 = ApiOptimizationUtils.getCachedRequest('user_123');
        expect(identical(cached, cached2), true);
      });

      test('request batcher reduces API calls by grouping', () async {
        var batchCallCount = 0;

        final batcher = RequestBatcher<int, List<int>>(
          batchFn: (ids) async {
            batchCallCount++;
            return ids;
          },
          windowDuration: const Duration(milliseconds: 50),
        );

        // Without batching: 10 individual API calls
        // With batching: 1 API call for all 10 requests
        for (int i = 0; i < 10; i++) {
          batcher.add(i);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        expect(batchCallCount, 1,
            reason: '10 requests should be batched into 1 API call');
        expect(batchCallCount, lessThan(10),
            reason: 'Batching should reduce API calls by 90%');
      });
    });
  });
}
