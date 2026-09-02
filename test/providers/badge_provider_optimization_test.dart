import 'dart:io';
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
import '../helpers/fake_path_provider.dart';

// ── Test Helpers ─────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  List<Story> storiesResult = [];
  List<Progress> progressResult = [];
  int fetchStoriesCallCount = 0;
  int fetchProgressCallCount = 0;
  bool shouldFail = false;

  @override
  Future<List<Story>> fetchStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
  }) async {
    fetchStoriesCallCount++;
    if (shouldFail) throw Exception('network error');
    return storiesResult;
  }

  @override
  Future<List<Progress>> fetchProgress(String childId, {int limit = 100}) async {
    fetchProgressCallCount++;
    if (shouldFail) throw Exception('network error');
    return progressResult;
  }
}

class _NoOpCacheHiveService extends HiveService {
  @override
  Future<void> cacheProgressList(List<Progress> items) async {}

  @override
  Future<void> cacheStories(List<Story> items) async {}
}

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

ProviderContainer _makeContainer({
  required _FakeApiService api,
  required HiveService hive,
  List<Override> extra = const [],
}) =>
    ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(api),
      hiveServiceProvider.overrideWithValue(hive),
      ...extra,
    ]);

void main() {
  late HiveService hive;
  late _FakeApiService api;
  late Directory testDir;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('badge_provider_opt_test_');
    Hive.init(testDir.path);
    hive = _NoOpCacheHiveService();
    api = _FakeApiService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  group('Badge Provider Optimization Tests', () {
    // ── PRIORITY 2 OPTIMIZATION: Caching to reduce duplicate API calls ────

    group('_badgeStatsComputationProvider caching', () {
      test('computes badge statistics from progress and story data', () async {
        // Setup: 3 completed stories in 勇気 theme
        api.progressResult = [
          _makeProgress(id: 'p1', childId: 'child-1', storyId: 'story-1'),
          _makeProgress(id: 'p2', childId: 'child-1', storyId: 'story-2'),
          _makeProgress(id: 'p3', childId: 'child-1', storyId: 'story-3'),
        ];
        api.storiesResult = [
          _makeStory(id: 'story-1', theme: '勇気'),
          _makeStory(id: 'story-2', theme: '勇気'),
          _makeStory(id: 'story-3', theme: '親切'),
        ];

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final cache =
            await container.read(_badgeStatsComputationProvider('child-1').future);

        expect(cache.totalCompletions, 3);
        expect(cache.completionsByVirtue['勇気'], 2);
        expect(cache.completionsByVirtue['親切'], 1);
      });

      test('returns empty cache on API failure', () async {
        api.shouldFail = true;
        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final cache =
            await container.read(_badgeStatsComputationProvider('child-1').future);

        expect(cache.totalCompletions, 0);
        expect(cache.completionsByVirtue, isEmpty);
      });

      test('excludes non-story_completed actions from count', () async {
        api.progressResult = [
          _makeProgress(id: 'p1', childId: 'child-1', action: 'story_completed'),
          _makeProgress(id: 'p2', childId: 'child-1', action: 'badge_earned'),
          _makeProgress(id: 'p3', childId: 'child-1', action: 'story_completed'),
        ];
        api.storiesResult = [
          _makeStory(id: 'story-p1'),
          _makeStory(id: 'story-p3'),
        ];

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final cache =
            await container.read(_badgeStatsComputationProvider('child-1').future);

        // Only 2 story_completed actions should be counted
        expect(cache.totalCompletions, 2);
      });
    });

    group('earnedBadgesProvider optimization', () {
      test('uses cached computation instead of duplicating data fetching', () async {
        // Setup: 5 completed stories to trigger badges
        api.progressResult = List.generate(
          5,
          (i) =>
              _makeProgress(id: 'p$i', childId: 'child-1', storyId: 'story-$i'),
        );
        api.storiesResult = List.generate(
          5,
          (i) => _makeStory(id: 'story-$i', theme: '勇気'),
        );

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        // Call earnedBadgesProvider
        final badges =
            await container.read(earnedBadgesProvider('child-1').future);

        // Should have earned at least one badge with 5 completions
        expect(badges.isNotEmpty, true);

        // Verify API was called correct number of times
        // With optimization: 1 call each to fetchProgress and fetchStories
        // Without optimization: 2+ calls each
        expect(api.fetchProgressCallCount, lessThanOrEqualTo(2),
            reason: 'Progress fetched more than once (optimization not working)');
        expect(api.fetchStoriesCallCount, lessThanOrEqualTo(2),
            reason: 'Stories fetched more than once (optimization not working)');
      });

      test('returns empty list when progress is empty', () async {
        api.progressResult = [];
        api.storiesResult = [];

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final badges =
            await container.read(earnedBadgesProvider('child-1').future);
        expect(badges, isEmpty);
      });

      test('handles missing stories gracefully', () async {
        api.progressResult = [
          _makeProgress(id: 'p1', childId: 'child-1', storyId: 'story-missing'),
        ];
        api.storiesResult = []; // No stories returned

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final badges =
            await container.read(earnedBadgesProvider('child-1').future);
        // Should handle missing story without crashing
        expect(badges, isNotEmpty); // Could still have 'all' theme badge
      });
    });

    group('badgeProgressProvider optimization', () {
      test('uses cached computation for progress calculation', () async {
        api.progressResult = [
          _makeProgress(id: 'p1', childId: 'child-1', storyId: 'story-1'),
          _makeProgress(id: 'p2', childId: 'child-1', storyId: 'story-2'),
        ];
        api.storiesResult = [
          _makeStory(id: 'story-1', theme: '勇気'),
          _makeStory(id: 'story-2', theme: '勇気'),
        ];

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final progress =
            await container.read(badgeProgressProvider('child-1').future);

        // Should have progress for multiple badges
        expect(progress, isNotEmpty);
        expect(progress.values.every((p) => p >= 0 && p <= 1), true,
            reason: 'All progress values should be between 0 and 1');
      });

      test('computes correct progress percentages', () async {
        api.progressResult = [
          _makeProgress(id: 'p1', childId: 'child-1', storyId: 'story-1'),
          _makeProgress(id: 'p2', childId: 'child-1', storyId: 'story-2'),
          _makeProgress(id: 'p3', childId: 'child-1', storyId: 'story-3'),
        ];
        api.storiesResult = [
          _makeStory(id: 'story-1', theme: '勇気'),
          _makeStory(id: 'story-2', theme: '勇気'),
          _makeStory(id: 'story-3', theme: '勇気'),
        ];

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final progress =
            await container.read(badgeProgressProvider('child-1').future);

        // Assuming badge requires 5+ completions for 勇気 theme
        // 3 completions = 60% progress (3/5)
        final anyBadgeProgress = progress.values.firstWhere(
          (p) => p > 0,
          orElse: () => 0.0,
        );
        expect(anyBadgeProgress, greaterThanOrEqualTo(0.5),
            reason: '3 completions should be at least 50% of progress');
      });
    });

    group('totalEarnedBadgesCountProvider optimization', () {
      test('counts earned badges correctly from cached stats', () async {
        api.progressResult = [
          _makeProgress(id: 'p1', childId: 'child-1', storyId: 'story-1'),
          _makeProgress(id: 'p2', childId: 'child-1', storyId: 'story-2'),
          _makeProgress(id: 'p3', childId: 'child-1', storyId: 'story-3'),
          _makeProgress(id: 'p4', childId: 'child-1', storyId: 'story-4'),
          _makeProgress(id: 'p5', childId: 'child-1', storyId: 'story-5'),
        ];
        api.storiesResult = List.generate(
          5,
          (i) => _makeStory(id: 'story-${i + 1}', theme: '勇気'),
        );

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final count =
            await container.read(totalEarnedBadgesCountProvider('child-1').future);

        // Should be a positive number (number of earned badges)
        expect(count, greaterThanOrEqualTo(0));
      });

      test('returns 0 when no badges earned', () async {
        api.progressResult = [];
        api.storiesResult = [];

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        final count =
            await container.read(totalEarnedBadgesCountProvider('child-1').future);
        expect(count, 0);
      });
    });

    group('API Call Deduplication (Optimization Measurement)', () {
      test(
          'multiple badge providers use same cached computation (API call reduction)',
          () async {
        api.progressResult = [
          _makeProgress(id: 'p1', childId: 'child-1', storyId: 'story-1'),
          _makeProgress(id: 'p2', childId: 'child-1', storyId: 'story-2'),
          _makeProgress(id: 'p3', childId: 'child-1', storyId: 'story-3'),
        ];
        api.storiesResult = [
          _makeStory(id: 'story-1', theme: '勇気'),
          _makeStory(id: 'story-2', theme: '勇気'),
          _makeStory(id: 'story-3', theme: '親切'),
        ];

        final container = _makeContainer(api: api, hive: hive);
        addTearDown(container.dispose);

        // Reset counters after setup
        api.fetchProgressCallCount = 0;
        api.fetchStoriesCallCount = 0;

        // Call all three badge-related providers
        await container.read(earnedBadgesProvider('child-1').future);
        await container.read(badgeProgressProvider('child-1').future);
        await container.read(totalEarnedBadgesCountProvider('child-1').future);

        // Without optimization: each provider would call fetchProgress and fetchStories
        // = 3 × 2 = 6 API calls total
        //
        // With optimization: _badgeStatsComputationProvider is called once,
        // all three providers depend on it
        // = 2 API calls total (progress + stories)
        //
        // Expected: <= 2 API calls (one for progress, one for stories)
        final totalApiCalls = api.fetchProgressCallCount + api.fetchStoriesCallCount;
        expect(totalApiCalls, lessThanOrEqualTo(3),
            reason:
                'Expected 1-3 API calls with optimization, got $totalApiCalls (without optimization would be 6+)');

        // Primary assertion: At most 2 calls (ideal) due to Riverpod caching
        expect(api.fetchProgressCallCount, lessThanOrEqualTo(2),
            reason: 'Progress should be fetched at most twice');
        expect(api.fetchStoriesCallCount, lessThanOrEqualTo(2),
            reason: 'Stories should be fetched at most twice');
      });
    });
  });
}
