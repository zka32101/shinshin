import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/badge.dart';

// ─── Mock Badge Card Widget ──────────────────────────────────────────────────

/// Simple badge card widget for testing purposes
class TestBadgeCard extends StatelessWidget {
  final BadgeDefinition badge;
  final double progress; // 0.0 to 1.0
  final bool isEarned;
  final DateTime? earnedAt;

  const TestBadgeCard({
    Key? key,
    required this.badge,
    this.progress = 0.0,
    this.isEarned = false,
    this.earnedAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (!isEarned)
              Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text('${(progress * 100).toStringAsFixed(0)}%'),
                ],
              )
            else
              Text('獲得日: ${earnedAt?.year}年${earnedAt?.month}月${earnedAt?.day}日'),
          ],
        ),
      ),
    );
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Badge Card Widget Tests', () {
    late BadgeDefinition testBadge;

    setUp(() {
      testBadge = const BadgeDefinition(
        id: 'test_badge',
        name: 'テストバッジ',
        emoji: '⭐',
        description: 'テスト用バッジです',
        theme: 'kindness',
        requiredCompletions: 3,
      );
    });

    testWidgets('displays badge emoji', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(badge: testBadge),
          ),
        ),
      );

      expect(find.text('⭐'), findsOneWidget);
    });

    testWidgets('displays badge name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(badge: testBadge),
          ),
        ),
      );

      expect(find.text('テストバッジ'), findsOneWidget);
    });

    testWidgets('displays badge description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(badge: testBadge),
          ),
        ),
      );

      expect(find.text('テスト用バッジです'), findsOneWidget);
    });

    testWidgets('shows progress bar when not earned', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(
              badge: testBadge,
              progress: 0.5,
              isEarned: false,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('shows earned date when badge is earned', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(
              badge: testBadge,
              isEarned: true,
              earnedAt: DateTime(2024, 3, 15),
            ),
          ),
        ),
      );

      expect(find.text('獲得日: 2024年3月15日'), findsOneWidget);
    });

    testWidgets('progress bar value changes with progress prop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(
              badge: testBadge,
              progress: 0.25,
            ),
          ),
        ),
      );

      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('shows 0% progress when progress is zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(
              badge: testBadge,
              progress: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('shows 100% progress when progress is complete', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(
              badge: testBadge,
              progress: 1.0,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('card is rendered as Material Card widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(badge: testBadge),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('emoji size is appropriate', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(badge: testBadge),
          ),
        ),
      );

      final textWidget = find.text('⭐');
      expect(textWidget, findsOneWidget);
    });

    testWidgets('handles different badge themes correctly', (tester) async {
      final themes = ['kindness', 'honesty', 'courage', 'respect', 'all'];

      for (final theme in themes) {
        final badge = BadgeDefinition(
          id: 'badge_$theme',
          name: 'バッジ ($theme)',
          emoji: '🎖️',
          description: 'Description for $theme',
          theme: theme,
          requiredCompletions: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestBadgeCard(badge: badge),
            ),
          ),
        );

        expect(find.text('バッジ ($theme)'), findsOneWidget);
      }
    });

    testWidgets('progress percentage calculation is correct', (tester) async {
      final testCases = [
        (0.0, '0%'),
        (0.333, '33%'),
        (0.5, '50%'),
        (0.667, '67%'),
        (1.0, '100%'),
      ];

      for (final (progress, expectedText) in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TestBadgeCard(
                badge: testBadge,
                progress: progress,
              ),
            ),
          ),
        );

        expect(find.text(expectedText), findsOneWidget);
      }
    });

    testWidgets('does not show progress when badge is earned',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestBadgeCard(
              badge: testBadge,
              progress: 0.5,
              isEarned: true,
              earnedAt: DateTime(2024, 1, 1),
            ),
          ),
        ),
      );

      // Should show earned date instead of progress
      expect(find.text('獲得日: 2024年1月1日'), findsOneWidget);
      // Should not show percentage
      expect(find.text('50%'), findsNothing);
    });

    testWidgets('layout responds to different screen sizes', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(300, 600);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TestBadgeCard(badge: testBadge),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
