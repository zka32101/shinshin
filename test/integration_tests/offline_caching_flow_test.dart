import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/badge.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/providers/badge_provider.dart';
import 'package:shougaku_kore_doutoku/providers/offline_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';

void main() {
  group('Offline Caching Integration Tests', () {
    late HiveService hiveService;

    setUpAll(() async {
      hiveService = HiveService();
      await hiveService.initialize();
    });

    tearDownAll(() async {
      await hiveService.clearAll();
    });

    testWidgets(
      'offline: cache stories and retrieve from cache when offline',
      (WidgetTester tester) async {
        final testStories = [
          Story(
            id: 'story-1',
            title: 'Test Story 1',
            description: 'A test story',
            theme: 'kindness',
            gradeLevel: 3,
            isPremium: false,
            durationSeconds: 300,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Story(
            id: 'story-2',
            title: 'Test Story 2',
            description: 'Another test story',
            theme: 'honesty',
            gradeLevel: 4,
            isPremium: true,
            durationSeconds: 350,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // キャッシュにストーリーを保存
        await hiveService.cacheStories(testStories);

        // キャッシュから取得
        final cachedStories = await hiveService.getCachedStories();
        expect(cachedStories, isNotEmpty);
        expect(cachedStories.length, equals(2));
        expect(cachedStories[0].id, equals('story-1'));
        expect(cachedStories[1].id, equals('story-2'));
      },
    );

    testWidgets(
      'offline: cache badge data and retrieve from cache',
      (WidgetTester tester) async {
        final childId = 'test-child-1';
        final badges = [
          const EarnedBadge(badgeId: 'kindness_1', earnedAt: DateTime(2024, 1, 1)),
          const EarnedBadge(badgeId: 'honesty_1', earnedAt: DateTime(2024, 1, 15)),
        ];

        // バッジデータをキャッシュに保存
        await hiveService.cacheBadgeData(childId, badges);

        // キャッシュから取得
        final cachedBadges = await hiveService.getCachedBadges(childId);
        expect(cachedBadges, isNotEmpty);
        expect(cachedBadges.length, equals(2));
        expect(cachedBadges[0].badgeId, equals('kindness_1'));
        expect(cachedBadges[1].badgeId, equals('honesty_1'));
      },
    );

    testWidgets(
      'offline: get cache size information',
      (WidgetTester tester) async {
        final testStories = [
          Story(
            id: 'size-test-1',
            title: 'Size Test Story',
            description: 'For size testing',
            theme: 'kindness',
            gradeLevel: 3,
            isPremium: false,
            durationSeconds: 300,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await hiveService.cacheStories(testStories);

        final sizeInfo = await hiveService.getCacheSizeInfo();
        expect(sizeInfo, isNotEmpty);
        expect(sizeInfo.containsKey('stories'), isTrue);
        expect(sizeInfo.containsKey('reports'), isTrue);
        expect(sizeInfo.containsKey('badges'), isTrue);
        expect(sizeInfo.containsKey('total'), isTrue);
      },
    );

    testWidgets(
      'offline: clear cache by age',
      (WidgetTester tester) async {
        final oldStories = [
          Story(
            id: 'old-story',
            title: 'Old Story',
            description: 'Old story for testing',
            theme: 'kindness',
            gradeLevel: 3,
            isPremium: false,
            durationSeconds: 300,
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
            updatedAt: DateTime.now().subtract(const Duration(days: 365)),
          ),
        ];

        await hiveService.cacheStories(oldStories);

        // キャッシュがあることを確認
        var cachedStories = await hiveService.getCachedStories();
        expect(cachedStories, isNotEmpty);

        // 30日以上前のキャッシュをクリア
        await hiveService.clearCacheByAge(const Duration(days: 30));

        // 古いキャッシュが削除されたことを確認
        cachedStories = await hiveService.getCachedStories();
        expect(cachedStories.isEmpty, isTrue);
      },
    );

    testWidgets(
      'offline: set and check offline mode status',
      (WidgetTester tester) async {
        // オフラインモードを設定
        await hiveService.setOfflineMode(true);
        var isOffline = await hiveService.isOfflineModeEnabled();
        expect(isOffline, isTrue);

        // オンラインモードに設定
        await hiveService.setOfflineMode(false);
        isOffline = await hiveService.isOfflineModeEnabled();
        expect(isOffline, isFalse);
      },
    );

    testWidgets(
      'offline: badge provider offline mode widget tree',
      (WidgetTester tester) async {
        // キャッシュにテストバッジを保存
        final childId = 'badge-test-child';
        final testBadges = [
          const EarnedBadge(badgeId: 'kindness_1', earnedAt: DateTime(2024, 1, 1)),
        ];
        await hiveService.cacheBadgeData(childId, testBadges);

        // Provider でバッジを取得するテストは別途実装
        // ここではキャッシュが正常に機能することを確認
        final cachedBadges = await hiveService.getCachedBadges(childId);
        expect(cachedBadges, isNotEmpty);
        expect(cachedBadges[0].badgeId, equals('kindness_1'));
      },
    );

    testWidgets(
      'offline: verify cache ttl validity',
      (WidgetTester tester) async {
        final testStories = [
          Story(
            id: 'ttl-test',
            title: 'TTL Test Story',
            description: 'For TTL testing',
            theme: 'kindness',
            gradeLevel: 3,
            isPremium: false,
            durationSeconds: 300,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // ストーリーをキャッシュに保存（TTL: 7日）
        await hiveService.cacheStories(testStories);

        // キャッシュは有効なはず
        var cachedStories = await hiveService.getCachedStories();
        expect(cachedStories, isNotEmpty);

        // 7日以上経過した場合のシミュレーション
        // clearCacheByAge メソッドで検証
        await hiveService.clearCacheByAge(const Duration(days: 8));
        cachedStories = await hiveService.getCachedStories();
        expect(cachedStories.isEmpty, isTrue);
      },
    );

    testWidgets(
      'offline: multiple children badge caching',
      (WidgetTester tester) async {
        final child1 = 'child-1';
        final child2 = 'child-2';

        final badges1 = [
          const EarnedBadge(badgeId: 'kindness_1', earnedAt: DateTime(2024, 1, 1)),
        ];

        final badges2 = [
          const EarnedBadge(badgeId: 'honesty_1', earnedAt: DateTime(2024, 1, 15)),
          const EarnedBadge(badgeId: 'courage_1', earnedAt: DateTime(2024, 2, 1)),
        ];

        // 複数の子どもについてバッジをキャッシュ
        await hiveService.cacheBadgeData(child1, badges1);
        await hiveService.cacheBadgeData(child2, badges2);

        // 個別に取得
        final cached1 = await hiveService.getCachedBadges(child1);
        final cached2 = await hiveService.getCachedBadges(child2);

        expect(cached1.length, equals(1));
        expect(cached2.length, equals(2));
        expect(cached1[0].badgeId, equals('kindness_1'));
        expect(cached2[0].badgeId, equals('honesty_1'));
        expect(cached2[1].badgeId, equals('courage_1'));
      },
    );
  });
}
