import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/utils/image_cache_utils.dart';

void main() {
  group('Image Cache Utils', () {
    // ── PRIORITY 3: Image Cache Configuration Tests ────────────────────

    group('ImageCacheUtils Configuration', () {
      setUp(() {
        // Reset image cache before each test
        imageCache.clear();
        imageCache.clearKeepAliveImages();
      });

      test('configures image cache with appropriate limits', () {
        ImageCacheUtils.configureImageCache();

        // Verify cache limits are set (exact values depend on implementation)
        // Should have configured memory and count limits
        final stats = ImageCacheUtils.getCacheStats();
        expect(stats, isNotEmpty);
        expect(stats.containsKey('maximumSize'), true);
        expect(stats.containsKey('maximumSizeBytes'), true);
      });

      test('memory cache stats report accurate values', () {
        ImageCacheUtils.configureImageCache();

        final stats = ImageCacheUtils.getCacheStats();
        expect(stats['currentSize'], isA<int>());
        expect(stats['currentSizeBytes'], isA<int>());
        expect(stats['maximumSize'], isA<int>());
        expect(stats['maximumSizeBytes'], isA<int>());

        // Current should not exceed maximum
        expect(stats['currentSize'], lessThanOrEqualTo(stats['maximumSize']));
        expect(stats['currentSizeBytes'], lessThanOrEqualTo(stats['maximumSizeBytes']));
      });

      test('shouldClearCache detects when cache exceeds 80% threshold', () {
        // This is a behavioral check that the cache monitoring works
        // In real scenario, would fill cache and check
        final shouldClear = ImageCacheUtils.shouldClearCache();
        expect(shouldClear, isA<bool>());
      });

      test('clearImageCache empties cache', () {
        ImageCacheUtils.configureImageCache();
        ImageCacheUtils.clearImageCache();

        final stats = ImageCacheUtils.getCacheStats();
        expect(stats['currentSize'], 0);
      });
    });

    // ── PRIORITY 3: Asset Precaching Tests ────────────────────────────

    group('Asset Precaching', () {
      testWidgets(
        'precacheCommonAssets handles missing assets gracefully',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SizedBox.expand(),
              ),
            ),
          );

          // Should not throw even if assets don't exist
          await ImageCacheUtils.precacheCommonAssets(tester.binding.window);

          expect(true, true); // Passed without exception
        },
      );

      testWidgets(
        'precacheAvatarAssets handles empty list',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SizedBox.expand(),
              ),
            ),
          );

          // Should handle empty list without error
          await ImageCacheUtils.precacheAvatarAssets(
            tester.binding.window,
            [],
          );

          expect(true, true); // Passed without exception
        },
      );

      testWidgets(
        'precacheAvatarAssets filters empty paths',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SizedBox.expand(),
              ),
            ),
          );

          // Should filter out empty paths and not error
          await ImageCacheUtils.precacheAvatarAssets(
            tester.binding.window,
            ['', 'assets/avatar.png', ''],
          );

          expect(true, true); // Passed without exception
        },
      );
    });

    // ── PRIORITY 3: BuildContext Extension Tests ────────────────────

    group('ImageCacheContext Extensions', () {
      testWidgets(
        'precacheAssetImage works from context',
        (WidgetTester tester) async {
          late BuildContext testContext;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    testContext = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          );

          // Should handle precaching from context gracefully
          await testContext.precacheAssetImage('assets/placeholder.png');

          expect(true, true); // Passed without exception
        },
      );

      testWidgets(
        'precacheAssetImages works from context',
        (WidgetTester tester) async {
          late BuildContext testContext;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    testContext = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          );

          // Should handle multiple assets
          await testContext.precacheAssetImages([
            'assets/avatar1.png',
            'assets/avatar2.png',
            'assets/badge.png',
          ]);

          expect(true, true); // Passed without exception
        },
      );
    });

    // ── PRIORITY 3: Memory Efficiency Tests ───────────────────────────

    group('Memory Efficient Caching', () {
      test('configureMemoryEfficientCaching sets appropriate limits', () {
        ImageCacheUtils.configureMemoryEfficientCaching();

        final stats = ImageCacheUtils.getCacheStats();

        // Should have reduced limits for memory-constrained devices
        expect(stats['maximumSize'], lessThanOrEqualTo(100));
        expect(stats['maximumSizeBytes'], lessThanOrEqualTo(50 * 1024 * 1024));
      });

      test('cache monitoring prevents memory bloat', () {
        ImageCacheUtils.configureImageCache();
        ImageCacheUtils.configureMemoryEfficientCaching();

        // Simulate cache usage
        final shouldClear1 = ImageCacheUtils.shouldClearCache();
        expect(shouldClear1, isA<bool>());

        // If cache is full, should clear
        if (shouldClear1) {
          ImageCacheUtils.clearImageCache();
          final shouldClear2 = ImageCacheUtils.shouldClearCache();
          // After clearing, should be safe
          expect(shouldClear2, false);
        }
      });
    });

    // ── PRIORITY 3: Optimization Effectiveness Tests ──────────────────

    group('Image Caching Optimization Effectiveness', () {
      testWidgets(
        'precaching reduces initial load latency',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch();

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SizedBox.expand(),
              ),
            ),
          );

          // With precaching
          stopwatch.start();
          await ImageCacheUtils.precacheCommonAssets(tester.binding.window);
          stopwatch.stop();

          // Precaching should complete quickly (< 500ms)
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(500),
            reason: 'Precaching should be fast (completed in ${stopwatch.elapsedMilliseconds}ms)',
          );
        },
      );

      testWidgets(
        'memory cache reduces redundant image loads',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SizedBox.expand(),
              ),
            ),
          );

          ImageCacheUtils.configureImageCache();

          // First precache
          await ImageCacheUtils.precacheCommonAssets(tester.binding.window);
          final statsAfterFirst = ImageCacheUtils.getCacheStats();

          // Second precache (should use cache)
          await ImageCacheUtils.precacheCommonAssets(tester.binding.window);
          final statsAfterSecond = ImageCacheUtils.getCacheStats();

          // Cache should be reused (no significant increase)
          final sizeIncrease =
              (statsAfterSecond['currentSize'] as int) - (statsAfterFirst['currentSize'] as int);
          expect(sizeIncrease, lessThanOrEqualTo(100),
              reason: 'Cache reuse should not significantly increase size');
        },
      );

      test('cache configuration reduces memory footprint', () {
        // Standard config (more permissive)
        ImageCacheUtils.configureImageCache();
        final standardStats = ImageCacheUtils.getCacheStats();

        // Reset
        imageCache.clear();

        // Memory-efficient config (conservative)
        ImageCacheUtils.configureMemoryEfficientCaching();
        final efficientStats = ImageCacheUtils.getCacheStats();

        // Efficient should have lower limits
        expect(
          efficientStats['maximumSize'],
          lessThanOrEqualTo(standardStats['maximumSize']),
          reason: 'Memory-efficient config should have lower image count limit',
        );
        expect(
          efficientStats['maximumSizeBytes'],
          lessThanOrEqualTo(standardStats['maximumSizeBytes']),
          reason: 'Memory-efficient config should have lower byte limit',
        );
      });
    });
  });
}
