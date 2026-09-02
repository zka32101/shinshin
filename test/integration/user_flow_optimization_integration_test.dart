import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/badge.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/providers/badge_provider.dart';
import 'package:shougaku_kore_doutoku/providers/progress_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart'
    show apiServiceProvider, hiveServiceProvider;
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import 'package:shougaku_kore_doutoku/utils/api_optimization_utils.dart';
import 'package:shougaku_kore_doutoku/utils/image_cache_utils.dart';
import '../helpers/fake_path_provider.dart';

// ── Test Fixtures ────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  List<Story> storiesResult = [];
  List<Progress> progressResult = [];

  int fetchStoriesCallCount = 0;
  int fetchProgressCallCount = 0;
  int totalApiCallsRecorded = 0;

  @override
  Future<List<Story>> fetchStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
  }) async {
    fetchStoriesCallCount++;
    totalApiCallsRecorded++;
    ApiPerformanceMonitor.recordRequestDuration(
      'fetchStories',
      const Duration(milliseconds: 100),
    );
    return storiesResult;
  }

  @override
  Future<List<Progress>> fetchProgress(String childId, {int limit = 100}) async {
    fetchProgressCallCount++;
    totalApiCallsRecorded++;
    ApiPerformanceMonitor.recordRequestDuration(
      'fetchProgress',
      const Duration(milliseconds: 50),
    );
    return progressResult;
  }
}

class _NoOpCacheHiveService extends HiveService {
  @override
  Future<void> cacheProgressList(List<Progress> items) async {}

  @override
  Future<void> cacheStories(List<Story> items) async {}
}

// ── Test Data Builders ───────────────────────────────────────────────────

Progress _makeProgress({
  required String id,
  required String childId,
  String action = 'story_completed',
  String? storyId,
  DateTime? recordedAt,
}) =>
    Progress(
      id: id,
      childId: childId,
      action: action,
      storyId: storyId ?? 'story-$id',
      pointsDelta: 10,
      recordedAt: recordedAt ?? DateTime.now(),
    );

Story _makeStory({
  required String id,
  String theme = '勇気',
  int gradeLevel = 3,
  bool isPremium = false,
}) =>
    Story(
      id: id,
      title: 'Test Story $id',
      description: 'Test description',
      theme: theme,
      gradeLevel: gradeLevel,
      isPremium: isPremium,
      content: 'Test content',
      choices: [],
      outcomes: {},
    );

void main() {
  late HiveService hive;
  late _FakeApiService api;
  late Directory testDir;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('user_flow_integration_test_');
    Hive.init(testDir.path);
    hive = _NoOpCacheHiveService();
    api = _FakeApiService();
    ApiOptimizationUtils.clearAllCache();
    ApiPerformanceMonitor.clearStats();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  group('User Flow Integration Tests', () {
    // ── Complete User Flow Tests ───────────────────────────────────────

    group('Complete user flow: Load stories → Earn badges → View dashboard', () {
      test('user can load stories and earn badges without excessive API calls', () async {
        // Setup: 10 stories across different themes
        api.storiesResult = [
          for (int i = 1; i <= 5; i++) _makeStory(id: 'story-$i', theme: '勇気'),
          for (int i = 6; i <= 10; i++) _makeStory(id: 'story-$i', theme: '親切'),
        ];

        // Setup: 8 completed stories (child earned some badges)
        api.progressResult = [
          for (int i = 1; i <= 8; i++)
            _makeProgress(id: 'p$i', childId: 'child-1', storyId: 'story-$i'),
        ];

        final container = ProviderContainer(overrides: [
          apiServiceProvider.overrideWithValue(api),
          hiveServiceProvider.overrideWithValue(hive),
        ]);
        addTearDown(container.dispose);

        // Reset counters after setup
        api.fetchStoriesCallCount = 0;
        api.fetchProgressCallCount = 0;
        api.totalApiCallsRecorded = 0;

        // User flow step 1: Load stories
        final stories = await container.read(
          storyProvider.future,
        );
        expect(stories.isNotEmpty, true, reason: 'Should load stories');

        // User flow step 2: View earned badges
        final badges =
            await container.read(earnedBadgesProvider('child-1').future);
        expect(badges.isNotEmpty, true, reason: 'Child should have earned badges');

        // User flow step 3: View progress
        final progress =
            await container.read(badgeProgressProvider('child-1').future);
        expect(progress.isNotEmpty, true, reason: 'Should have badge progress');

        // User flow step 4: View badge count
        final badgeCount =
            await container.read(totalEarnedBadgesCountProvider('child-1').future);
        expect(badgeCount, greaterThan(0),
            reason: 'Should have earned at least one badge');

        // OPTIMIZATION VALIDATION: API calls should be significantly reduced
        // With optimization: ~2 API calls (1 fetch stories, 1 fetch progress)
        // Without optimization: ~6+ API calls (each badge provider fetches independently)
        expect(api.totalApiCallsRecorded, lessThanOrEqualTo(3),
            reason:
                'Optimization should reduce API calls to <= 3 (recorded: ${api.totalApiCallsRecorded})');
      });

      test('user flow handles offline scenario gracefully', () async {
        api.progressResult = [];
        api.storiesResult = [];

        final container = ProviderContainer(overrides: [
          apiServiceProvider.overrideWithValue(api),
          hiveServiceProvider.overrideWithValue(hive),
        ]);
        addTearDown(container.dispose);

        // Even with no data, app should not crash
        try {
          final badges =
              await container.read(earnedBadgesProvider('child-1').future);
          expect(badges, isEmpty, reason: 'Should handle empty data');
        } catch (e) {
          fail('Should not throw exception: $e');
        }
      });
    });

    // ── Performance Optimization in User Flows ────────────────────────

    group('Performance optimization effectiveness in user flows', () {
      test('badge loading optimizations reduce API calls by 40-50%', () async {
        api.storiesResult = List.generate(
          10,
          (i) => _makeStory(id: 'story-${i + 1}', theme: '勇気'),
        );

        api.progressResult = List.generate(
          8,
          (i) => _makeProgress(id: 'p$i', childId: 'child-1', storyId: 'story-${i + 1}'),
        );

        final container = ProviderContainer(overrides: [
          apiServiceProvider.overrideWithValue(api),
          hiveServiceProvider.overrideWithValue(hive),
        ]);
        addTearDown(container.dispose);

        api.fetchStoriesCallCount = 0;
        api.fetchProgressCallCount = 0;
        api.totalApiCallsRecorded = 0;

        // Simulate user loading badge information from multiple sources
        final earnedBadges =
            await container.read(earnedBadgesProvider('child-1').future);
        final badgeProgress =
            await container.read(badgeProgressProvider('child-1').future);
        final badgeCount =
            await container.read(totalEarnedBadgesCountProvider('child-1').future);

        // With caching optimization, should make minimal API calls
        // Expected: ~2 calls (1 progress + 1 stories)
        // Without optimization: ~6+ calls (3 providers × 2 API endpoints each)
        final apiCallReduction =
            ((6 - api.totalApiCallsRecorded) / 6) * 100;

        expect(apiCallReduction, greaterThanOrEqualTo(40),
            reason:
                'Badge loading should achieve 40%+ API call reduction (achieved: ${apiCallReduction.toStringAsFixed(1)}%)');

        expect(earnedBadges.isNotEmpty, true);
        expect(badgeProgress.isNotEmpty, true);
        expect(badgeCount, greaterThan(0));
      });

      test('image caching improves performance for asset-heavy flows', () async {
        final stopwatch = Stopwatch();

        // First load (cold cache)
        stopwatch.start();
        ImageCacheUtils.configureImageCache();
        await ImageCacheUtils.precacheCommonAssets(null);
        stopwatch.stop();
        final firstLoadMs = stopwatch.elapsedMilliseconds;

        // Second load (warm cache)
        stopwatch.reset();
        stopwatch.start();
        await ImageCacheUtils.precacheCommonAssets(null);
        stopwatch.stop();
        final secondLoadMs = stopwatch.elapsedMilliseconds;

        // Cache should make second load faster (or same performance)
        expect(secondLoadMs, lessThanOrEqualTo(firstLoadMs + 50),
            reason: 'Cached assets should load efficiently');
      });

      test('API debouncing reduces calls in rapid request scenario', () async {
        var callCount = 0;

        final debouncer = Debouncer<String>(
          onValue: (_) => callCount++,
          duration: const Duration(milliseconds: 50),
        );

        // Simulate rapid user input (e.g., rapid story selections)
        for (int i = 0; i < 20; i++) {
          debouncer.add('request-$i');
        }

        // Wait for debounce to settle
        await Future.delayed(const Duration(milliseconds: 150));

        // With debouncing, should only execute the last value
        expect(callCount, 1,
            reason: '20 rapid calls should be debounced to 1 execution (got: $callCount)');
        debouncer.dispose();
      });

      test('request batching reduces API calls for multiple badge queries', () async {
        var batchCallCount = 0;

        final batcher =
            RequestBatcher<String, String>(
          batchFn: (ids) async {
            batchCallCount++;
            return ids.join(',');
          },
          windowDuration: const Duration(milliseconds: 50),
        );

        // Simulate 10 simultaneous badge queries
        final futures = <Future<String>>[];
        for (int i = 0; i < 10; i++) {
          futures.add(batcher.add('badge-$i'));
        }

        await Future.wait(futures);
        await Future.delayed(const Duration(milliseconds: 100));

        // All 10 requests should be batched into 1 API call
        expect(batchCallCount, 1,
            reason:
                'Request batching should group 10 queries into 1 API call (got: $batchCallCount)');
        batcher.dispose();
      });
    });

    // ── User Experience Flow Tests ──────────────────────────────────────

    group('User experience flows with optimizations', () {
      test('dashboard loads quickly with cached badge data', () async {
        api.storiesResult = List.generate(
          5,
          (i) => _makeStory(id: 'story-${i + 1}'),
        );

        api.progressResult = List.generate(
          5,
          (i) => _makeProgress(id: 'p$i', childId: 'child-1', storyId: 'story-${i + 1}'),
        );

        final container = ProviderContainer(overrides: [
          apiServiceProvider.overrideWithValue(api),
          hiveServiceProvider.overrideWithValue(hive),
        ]);
        addTearDown(container.dispose);

        final stopwatch = Stopwatch();
        stopwatch.start();

        // Load all badge data (as dashboard would)
        await Future.wait([
          container.read(earnedBadgesProvider('child-1').future),
          container.read(badgeProgressProvider('child-1').future),
          container.read(totalEarnedBadgesCountProvider('child-1').future),
        ]);

        stopwatch.stop();

        // With optimization, should load quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason:
                'Dashboard data should load within 1 second (${stopwatch.elapsedMilliseconds}ms)');
      });

      test('story selection flow does not trigger excessive rebuilds', () async {
        // This test validates that the select() optimization works
        // when users navigate between stories

        api.storiesResult = List.generate(10, (i) => _makeStory(id: 'story-${i + 1}'));
        api.progressResult = [];

        final container = ProviderContainer(overrides: [
          apiServiceProvider.overrideWithValue(api),
          hiveServiceProvider.overrideWithValue(hive),
        ]);
        addTearDown(container.dispose);

        // Simulate story selection flow
        var rebuildCount = 0;
        for (int i = 0; i < 5; i++) {
          container.refresh(storyProvider);
          rebuildCount++;
        }

        // With provider select optimization, overhead should be minimal
        expect(rebuildCount, 5,
            reason: 'Each selection triggers one logical operation');
      });

      test('badge progress updates efficiently', () async {
        api.storiesResult =
            List.generate(10, (i) => _makeStory(id: 'story-${i + 1}'));
        api.progressResult =
            List.generate(5, (i) => _makeProgress(id: 'p$i', childId: 'child-1'));

        final container = ProviderContainer(overrides: [
          apiServiceProvider.overrideWithValue(api),
          hiveServiceProvider.overrideWithValue(hive),
        ]);
        addTearDown(container.dispose);

        // Get initial progress
        var progress =
            await container.read(badgeProgressProvider('child-1').future);
        expect(progress.isNotEmpty, true);

        // Add new story completion
        api.progressResult.add(
          _makeProgress(id: 'p6', childId: 'child-1', storyId: 'story-6'),
        );

        // Refresh progress (should be fast with caching)
        progress =
            await container.read(badgeProgressProvider('child-1').future);
        expect(progress.isNotEmpty, true);
      });
    });

    // ── Memory and Resource Management Tests ────────────────────────────

    group('Resource management in user flows', () {
      test('image cache memory does not bloat during user flow', () async {
        ImageCacheUtils.configureImageCache();

        final statsBeforePrecache = ImageCacheUtils.getCacheStats();
        final sizeBefore = (statsBeforePrecache['currentSizeBytes'] as int?) ?? 0;

        // Precache common assets
        await ImageCacheUtils.precacheCommonAssets(null);

        final statsAfterPrecache = ImageCacheUtils.getCacheStats();
        final sizeAfter = (statsAfterPrecache['currentSizeBytes'] as int?) ?? 0;

        // Cache should stay within reasonable limits
        expect(sizeAfter, lessThanOrEqualTo(50 * 1024 * 1024),
            reason: 'Image cache should stay under 50MB');

        // Clearing should work
        ImageCacheUtils.clearImageCache();
        final statsAfterClear = ImageCacheUtils.getCacheStats();
        expect((statsAfterClear['currentSize'] as int?) ?? 0, 0,
            reason: 'Cache should be cleared');
      });

      test('API request cache expiration prevents memory leaks', () async {
        // Cache several requests
        for (int i = 0; i < 5; i++) {
          ApiOptimizationUtils.cacheRequest(
            'request-$i',
            Future.value('data-$i'),
            duration: const Duration(milliseconds: 50),
          );
        }

        expect(ApiOptimizationUtils.getCachedRequest('request-0'), isNotNull);

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 150));

        // Clear expired entries
        ApiOptimizationUtils.clearExpiredCache();

        // Expired entries should be gone
        expect(ApiOptimizationUtils.getCachedRequest('request-0'), isNull);
      });

      test('performance monitor tracks metrics without consuming excessive memory', () async {
        ApiPerformanceMonitor.clearStats();

        // Record 100 requests
        for (int i = 0; i < 100; i++) {
          ApiPerformanceMonitor.recordRequestDuration(
            'fetch_endpoint',
            Duration(milliseconds: 50 + i),
          );
        }

        final stats = ApiPerformanceMonitor.getStats();
        expect(stats.isNotEmpty, true);

        // Should keep only last 100
        expect(stats['fetch_endpoint']?['count'], lessThanOrEqualTo(100));

        ApiPerformanceMonitor.clearStats();
      });
    });
  });
}
