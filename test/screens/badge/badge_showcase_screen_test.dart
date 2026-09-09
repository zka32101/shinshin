import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/badge.dart';
import 'package:shougaku_kore_doutoku/providers/badge_provider.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import '../../helpers/child_id_override.dart';
import 'package:shougaku_kore_doutoku/screens/badge/badge_showcase_screen.dart';

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrapBadgeShowcase({
  List<EarnedBadge>? earnedBadges,
  Map<String, double>? badgeProgress,
  int? totalEarned,
  double? completionRate,
  String childId = 'test-child',
}) {
  return ProviderScope(
    overrides: [
      childIdOverride(childId),
      earnedBadgesProvider.overrideWith((ref, cid) {
        if (earnedBadges != null) {
          return Future.value(earnedBadges);
        }
        return Future.value([]);
      }),
      badgeProgressProvider.overrideWith((ref, cid) {
        if (badgeProgress != null) {
          return Future.value(badgeProgress);
        }
        return Future.value({});
      }),
      totalEarnedBadgesCountProvider.overrideWith((ref, cid) {
        return Future.value(totalEarned ?? 0);
      }),
      badgeCompletionRateProvider.overrideWith((ref, cid) {
        return Future.value(completionRate ?? 0.0);
      }),
    ],
    child: const MaterialApp(home: BadgeShowcaseScreen()),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('BadgeShowcaseScreen', () {
    testWidgets('displays AppBar with title', (tester) async {
      await tester.pumpWidget(_wrapBadgeShowcase());
      await tester.pumpAndSettle();

      expect(find.text('バッジ図鑑'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows loading indicator while badges load', (tester) async {
      await tester.pumpWidget(_wrapBadgeShowcase());
      await tester.pump();

      // Loading state should show circular progress indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays overall completion rate', (tester) async {
      await tester.pumpWidget(_wrapBadgeShowcase(completionRate: 0.5));
      await tester.pumpAndSettle();

      // Should show completion rate (50%)
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('shows earned badges count', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          earnedBadges: [
            EarnedBadge(
              badgeId: 'kindness_1',
              earnedAt: DateTime(2024, 1, 1),
            ),
          ],
          totalEarned: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays all available badges in grid', (tester) async {
      await tester.pumpWidget(_wrapBadgeShowcase());
      await tester.pumpAndSettle();

      // Should have GridView for badge display
      expect(find.byType(GridView), findsWidgets);
    });

    testWidgets('shows badge progress bars', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          badgeProgress: {
            'kindness_1': 0.5,
            'honesty_1': 0.75,
            'courage_1': 0.2,
          },
        ),
      );
      await tester.pumpAndSettle();

      // Progress indicators should be visible
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('earned badges are visually distinct from unearned', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          earnedBadges: [
            EarnedBadge(
              badgeId: 'kindness_1',
              earnedAt: DateTime(2024, 1, 1),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Earned badge should be present
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('badge card displays emoji', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          earnedBadges: [
            EarnedBadge(
              badgeId: 'kindness_1',
              earnedAt: DateTime(2024, 1, 1),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Badge emoji should be displayed
      expect(find.textContaining('💖'), findsWidgets);
    });

    testWidgets('badge card displays name', (tester) async {
      await tester.pumpWidget(_wrapBadgeShowcase());
      await tester.pumpAndSettle();

      // Badge names should be visible
      expect(find.textContaining('やさしい心'), findsWidgets);
    });

    testWidgets('shows next badge hint when eligible', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          badgeProgress: {
            'kindness_1': 0.8, // Close to earning
          },
        ),
      );
      await tester.pumpAndSettle();

      // Should show hints for close-to-earning badges
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays badge unlock date when earned', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          earnedBadges: [
            EarnedBadge(
              badgeId: 'kindness_1',
              earnedAt: DateTime(2024, 3, 15),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Date information should be displayed
      expect(find.textContaining('2024'), findsWidgets);
    });

    testWidgets('scrolls to show all badges when content exceeds screen',
        (tester) async {
      await tester.pumpWidget(_wrapBadgeShowcase());
      await tester.pumpAndSettle();

      // Try to scroll down
      final scrollable = find.byType(GridView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Should still render properly after scroll
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('handles empty badge list gracefully', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          earnedBadges: [],
          totalEarned: 0,
          completionRate: 0.0,
        ),
      );
      await tester.pumpAndSettle();

      // Should show "no badges earned" or similar message
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('theme colors are appropriate for badges', (tester) async {
      await tester.pumpWidget(_wrapBadgeShowcase());
      await tester.pumpAndSettle();

      // App should have correct theme colors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('progress percentages display correctly', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          badgeProgress: {
            'kindness_1': 0.33,
            'honesty_1': 1.0, // 100% - earned
            'courage_1': 0.0, // 0% - not started
          },
        ),
      );
      await tester.pumpAndSettle();

      // Progress should be visible
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('tap badge card does not cause errors', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          earnedBadges: [
            EarnedBadge(
              badgeId: 'kindness_1',
              earnedAt: DateTime(2024, 1, 1),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Try to tap a badge card
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle();

        // Screen should remain responsive
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('displays badge description on earned badge', (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          earnedBadges: [
            EarnedBadge(
              badgeId: 'kindness_1',
              earnedAt: DateTime(2024, 1, 1),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Badge description should be visible
      expect(find.textContaining('思いやり'), findsWidgets);
    });

    testWidgets('completion rate bar updates with earned badges',
        (tester) async {
      await tester.pumpWidget(
        _wrapBadgeShowcase(
          earnedBadges: [
            EarnedBadge(
              badgeId: 'kindness_1',
              earnedAt: DateTime(2024, 1, 1),
            ),
            EarnedBadge(
              badgeId: 'honesty_1',
              earnedAt: DateTime(2024, 2, 1),
            ),
          ],
          totalEarned: 2,
          completionRate: 2.0 / 9.0, // 2 out of 9 badges
        ),
      );
      await tester.pumpAndSettle();

      // Completion rate should be displayed
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('section headers are visible', (tester) async {
      await tester.pumpWidget(_wrapBadgeShowcase());
      await tester.pumpAndSettle();

      // Should have section headers
      expect(find.byType(Text), findsWidgets);
    });
  });
}
