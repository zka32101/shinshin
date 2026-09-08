import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/badge.dart';
import 'package:shougaku_kore_doutoku/providers/badge_provider.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/screens/badge/badge_showcase_screen.dart';

void main() {
  group('BadgeShowcaseScreen - Golden Tests', () {
    testWidgets(
      'golden: badge showcase initial state',
      (WidgetTester tester) async {
        await tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedChildIdProvider.overrideWith((ref) => 'test-child'),
              earnedBadgesProvider.overrideWith((ref, _) {
                return Future.value([]);
              }),
              badgeProgressProvider.overrideWith((ref, _) {
                return Future.value({});
              }),
              totalEarnedBadgesCountProvider.overrideWith((ref, _) {
                return Future.value(0);
              }),
              badgeCompletionRateProvider.overrideWith((ref, _) {
                return Future.value(0.0);
              }),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await expectLater(
          find.byType(BadgeShowcaseScreen),
          matchesGoldenFile('goldens/badge_showcase_initial_state.png'),
        );
      },
    );

    testWidgets(
      'golden: badge showcase with earned badges',
      (WidgetTester tester) async {
        await tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final earnedBadges = [
          EarnedBadge(
            badgeId: 'kindness_1',
            earnedAt: DateTime(2024, 2, 1),
          ),
          EarnedBadge(
            badgeId: 'honesty_1',
            earnedAt: DateTime(2024, 2, 15),
          ),
          EarnedBadge(
            badgeId: 'courage_1',
            earnedAt: DateTime(2024, 3, 1),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedChildIdProvider.overrideWith((ref) => 'test-child'),
              earnedBadgesProvider.overrideWith((ref, _) {
                return Future.value(earnedBadges);
              }),
              badgeProgressProvider.overrideWith((ref, _) {
                return Future.value({
                  'kindness_1': 1.0,
                  'kindness_3': 0.67,
                  'honesty_1': 1.0,
                  'honesty_3': 0.5,
                  'courage_1': 1.0,
                  'courage_3': 0.33,
                });
              }),
              totalEarnedBadgesCountProvider.overrideWith((ref, _) {
                return Future.value(3);
              }),
              badgeCompletionRateProvider.overrideWith((ref, _) {
                return Future.value(3.0 / kDoutokuBadges.length);
              }),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await expectLater(
          find.byType(BadgeShowcaseScreen),
          matchesGoldenFile('goldens/badge_showcase_with_earned_badges.png'),
        );
      },
    );

    testWidgets(
      'golden: badge showcase with mixed progress',
      (WidgetTester tester) async {
        await tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final earnedBadges = [
          EarnedBadge(
            badgeId: 'first_story',
            earnedAt: DateTime(2024, 1, 15),
          ),
          EarnedBadge(
            badgeId: 'story_5',
            earnedAt: DateTime(2024, 2, 1),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedChildIdProvider.overrideWith((ref) => 'test-child'),
              earnedBadgesProvider.overrideWith((ref, _) {
                return Future.value(earnedBadges);
              }),
              badgeProgressProvider.overrideWith((ref, _) {
                return Future.value({
                  'first_story': 1.0,
                  'story_5': 1.0,
                  'story_10': 0.5,
                  'kindness_1': 0.75,
                  'kindness_3': 0.33,
                  'honesty_1': 1.0,
                  'honesty_3': 0.0,
                  'courage_1': 0.0,
                  'courage_3': 0.0,
                  'respect_1': 0.25,
                });
              }),
              totalEarnedBadgesCountProvider.overrideWith((ref, _) {
                return Future.value(2);
              }),
              badgeCompletionRateProvider.overrideWith((ref, _) {
                return Future.value(2.0 / kDoutokuBadges.length);
              }),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await expectLater(
          find.byType(BadgeShowcaseScreen),
          matchesGoldenFile('goldens/badge_showcase_mixed_progress.png'),
        );
      },
    );

    testWidgets(
      'golden: badge showcase all badges earned',
      (WidgetTester tester) async {
        await tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        // Create earned badges for all defined badges
        final earnedBadges = kDoutokuBadges.map((badge) {
          return EarnedBadge(
            badgeId: badge.id,
            earnedAt: DateTime(2024, 1, (earnedBadges.length % 28) + 1),
          );
        }).toList();

        final badgeProgress = {
          for (final badge in kDoutokuBadges) badge.id: 1.0,
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedChildIdProvider.overrideWith((ref) => 'test-child'),
              earnedBadgesProvider.overrideWith((ref, _) {
                return Future.value(earnedBadges);
              }),
              badgeProgressProvider.overrideWith((ref, _) {
                return Future.value(badgeProgress);
              }),
              totalEarnedBadgesCountProvider.overrideWith((ref, _) {
                return Future.value(kDoutokuBadges.length);
              }),
              badgeCompletionRateProvider.overrideWith((ref, _) {
                return Future.value(1.0);
              }),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await expectLater(
          find.byType(BadgeShowcaseScreen),
          matchesGoldenFile('goldens/badge_showcase_all_earned.png'),
        );
      },
    );

    testWidgets(
      'golden: badge showcase scrolled state',
      (WidgetTester tester) async {
        await tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedChildIdProvider.overrideWith((ref) => 'test-child'),
              earnedBadgesProvider.overrideWith((ref, _) {
                return Future.value([]);
              }),
              badgeProgressProvider.overrideWith((ref, _) {
                return Future.value({
                  for (final badge in kDoutokuBadges)
                    badge.id: (badge.id.hashCode % 100) / 100.0,
                });
              }),
              totalEarnedBadgesCountProvider.overrideWith((ref, _) {
                return Future.value(0);
              }),
              badgeCompletionRateProvider.overrideWith((ref, _) {
                return Future.value(0.3);
              }),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll down
        await tester.drag(
          find.byType(GridView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(BadgeShowcaseScreen),
          matchesGoldenFile('goldens/badge_showcase_scrolled.png'),
        );
      },
    );
  });
}
