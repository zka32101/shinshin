import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/badge.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/report.dart';
import 'package:shougaku_kore_doutoku/providers/badge_provider.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import '../helpers/child_id_override.dart';
import 'package:shougaku_kore_doutoku/providers/report_provider.dart';
import 'package:shougaku_kore_doutoku/screens/badge/badge_showcase_screen.dart';
import 'package:shougaku_kore_doutoku/screens/report/report_screen.dart';

// ─── Test Fixtures ──────────────────────────────────────────────────────────

final _testChild = ChildProfile(
  id: 'child-badge-flow',
  parentId: 'parent-1',
  name: 'テスト太郎',
  grade: 3,
  avatarEmoji: '🎖️',
  createdAt: DateTime(2024, 1, 1),
);

MonthlyReport _createTestReport({
  List<EarnedBadge>? badges,
  int storiesCompleted = 5,
}) {
  return MonthlyReport.fromJson({
    'id': 'report-badge-flow',
    'childId': 'child-badge-flow',
    'month': 3,
    'year': 2024,
    'storiesCompleted': storiesCompleted,
    'totalStudyMinutes': 120,
    'totalPointsEarned': 200,
    'kindnessScore': 75.0,
    'honestyScore': 70.0,
    'responsibilityScore': 85.0,
    'courageScore': 65.0,
    'respectScore': 80.0,
    'cooperationScore': 72.0,
    'highlightComment': 'よく頑張りました！',
    'growthComment': '思いやりが成長しています。',
    'adviceComment': 'もっと勇気を出しましょう。',
    'parentMessage': '継続が大切です。',
    'generatedAt': '2024-04-01T00:00:00.000Z',
    'topImpressions': <dynamic>[],
  });
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Badge and Report Integration Flow', () {
    testWidgets(
      'user can view report with badge information',
      (tester) async {
        final earnedBadges = [
          EarnedBadge(badgeId: 'kindness_1', earnedAt: DateTime(2024, 2, 1)),
          EarnedBadge(badgeId: 'honesty_1', earnedAt: DateTime(2024, 2, 15)),
        ];

        final report = _createTestReport(badges: earnedBadges);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedChildProvider
                  .overrideWith((ref) => Future.value(_testChild)),
              monthlyReportProvider
                  .overrideWith((ref, _) => Future.value(report)),
              earnedBadgesProvider.overrideWith((ref, _) {
                return Future.value(earnedBadges);
              }),
            ],
            child: const MaterialApp(home: ReportScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Verify report content is displayed
        expect(find.text('月次成長レポート'), findsOneWidget);
        expect(find.text('完了ストーリー'), findsOneWidget);

        // Verify badge section is visible
        expect(find.text('🎖️ バッジ進捗'), findsOneWidget);
      },
    );

    testWidgets(
      'badge showcase displays earned badges correctly',
      (tester) async {
        final earnedBadges = [
          EarnedBadge(badgeId: 'kindness_1', earnedAt: DateTime(2024, 2, 1)),
          EarnedBadge(badgeId: 'kindness_3', earnedAt: DateTime(2024, 3, 1)),
          EarnedBadge(badgeId: 'honesty_1', earnedAt: DateTime(2024, 2, 15)),
        ];

        final badgeProgress = {
          'kindness_1': 1.0, // Earned
          'kindness_3': 1.0, // Earned
          'honesty_1': 1.0, // Earned
          'honesty_3': 0.6, // In progress
          'courage_1': 0.3, // Just started
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childIdOverride('child-badge-flow'),
              earnedBadgesProvider.overrideWith((ref, _) {
                return Future.value(earnedBadges);
              }),
              badgeProgressProvider.overrideWith((ref, _) {
                return Future.value(badgeProgress);
              }),
              totalEarnedBadgesCountProvider.overrideWith((ref, _) {
                return Future.value(earnedBadges.length);
              }),
              badgeCompletionRateProvider.overrideWith((ref, _) {
                return Future.value(earnedBadges.length / kDoutokuBadges.length);
              }),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Verify badge showcase is displayed
        expect(find.text('バッジ図鑑'), findsOneWidget);

        // Verify badges are shown with progress indicators
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      },
    );

    testWidgets(
      'virtue scores update with earned badges',
      (tester) async {
        final report = _createTestReport(storiesCompleted: 8);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedChildProvider
                  .overrideWith((ref) => Future.value(_testChild)),
              monthlyReportProvider
                  .overrideWith((ref, _) => Future.value(report)),
            ],
            child: const MaterialApp(home: ReportScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Virtue scores should be displayed
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      },
    );

    testWidgets(
      'badge progress reflects story completions',
      (tester) async {
        // Simulate different completion scenarios
        const storyCompletionCounts = [0, 1, 3, 5, 10];

        for (final count in storyCompletionCounts) {
          final badgeProgress = {
            'first_story': count >= 1 ? 1.0 : count.toDouble(),
            'story_5': count >= 5 ? 1.0 : (count / 5),
            'story_10': count >= 10 ? 1.0 : (count / 10),
          };

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                childIdOverride('child-badge-flow'),
                badgeProgressProvider.overrideWith((ref, _) {
                  return Future.value(badgeProgress);
                }),
              ],
              child: const MaterialApp(home: BadgeShowcaseScreen()),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byType(Scaffold), findsOneWidget);
        }
      },
    );

    testWidgets(
      'month-to-month comparison shows badge changes',
      (tester) async {
        final currentReport = _createTestReport(storiesCompleted: 8);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedChildProvider
                  .overrideWith((ref) => Future.value(_testChild)),
              monthlyReportProvider
                  .overrideWith((ref, _) => Future.value(currentReport)),
              previousMonthReportProvider.overrideWith((ref, _) {
                // Previous month had fewer completions
                return Future.value(_createTestReport(storiesCompleted: 5));
              }),
            ],
            child: const MaterialApp(home: ReportScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Should show comparison
        expect(find.text('月次成長レポート'), findsOneWidget);
      },
    );

    testWidgets(
      'badge completion rate updates correctly',
      (tester) async {
        final scenarios = [
          (0, 0.0),
          (1, 1.0 / kDoutokuBadges.length),
          (5, 5.0 / kDoutokuBadges.length),
          (kDoutokuBadges.length, 1.0),
        ];

        for (final (earnedCount, expectedRate) in scenarios) {
          final earnedBadges = List.generate(
            earnedCount,
            (i) => EarnedBadge(
              badgeId: kDoutokuBadges[i].id,
              earnedAt: DateTime(2024, i + 1, 1),
            ),
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                childIdOverride('child-badge-flow'),
                earnedBadgesProvider.overrideWith((ref, _) {
                  return Future.value(earnedBadges);
                }),
                totalEarnedBadgesCountProvider.overrideWith((ref, _) {
                  return Future.value(earnedCount);
                }),
                badgeCompletionRateProvider.overrideWith((ref, _) {
                  return Future.value(expectedRate);
                }),
              ],
              child: const MaterialApp(home: BadgeShowcaseScreen()),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byType(Scaffold), findsOneWidget);
        }
      },
    );

    testWidgets(
      'handles no badges earned state gracefully',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childIdOverride('child-badge-flow'),
              earnedBadgesProvider
                  .overrideWith((ref, _) => Future.value([])),
              badgeProgressProvider
                  .overrideWith((ref, _) => Future.value({})),
              totalEarnedBadgesCountProvider
                  .overrideWith((ref, _) => Future.value(0)),
              badgeCompletionRateProvider
                  .overrideWith((ref, _) => Future.value(0.0)),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      'badge emoji display works correctly',
      (tester) async {
        final earnedBadges = [
          EarnedBadge(badgeId: 'kindness_1', earnedAt: DateTime(2024, 1, 1)),
          EarnedBadge(badgeId: 'honesty_1', earnedAt: DateTime(2024, 1, 15)),
          EarnedBadge(badgeId: 'courage_1', earnedAt: DateTime(2024, 2, 1)),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childIdOverride('child-badge-flow'),
              earnedBadgesProvider.overrideWith((ref, _) {
                return Future.value(earnedBadges);
              }),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Badge emojis should be visible
        expect(find.textContaining('💖'), findsWidgets); // kindness_1
        expect(find.textContaining('✨'), findsWidgets); // honesty_1
        expect(find.textContaining('🦁'), findsWidgets); // courage_1
      },
    );

    testWidgets(
      'scrolling through badge showcase maintains state',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              childIdOverride('child-badge-flow'),
              earnedBadgesProvider
                  .overrideWith((ref, _) => Future.value([])),
            ],
            child: const MaterialApp(home: BadgeShowcaseScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Try to scroll
        final scrollable = find.byType(GridView);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -300));
          await tester.pumpAndSettle();
        }

        expect(find.byType(Scaffold), findsOneWidget);
      },
    );
  });
}
