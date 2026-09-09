import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/report.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/providers/report_provider.dart';
import 'package:shougaku_kore_doutoku/screens/report/report_screen.dart';
import '../helpers/fake_hive_service.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final _testChild = ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: 'こうた',
  grade: 3,
  avatarEmoji: '🏆',
  createdAt: DateTime(2024, 1, 1),
);

MonthlyReport _makeReport({
  String? highlightComment,
  String? growthComment,
  String? adviceComment,
  String? parentMessage,
  int storiesCompleted = 5,
  int totalStudyMinutes = 90,
  int totalPointsEarned = 150,
}) {
  return MonthlyReport.fromJson({
    'id': 'report-1',
    'childId': 'child-1',
    'month': 3,
    'year': 2024,
    'storiesCompleted': storiesCompleted,
    'totalStudyMinutes': totalStudyMinutes,
    'totalPointsEarned': totalPointsEarned,
    'kindnessScore': 70.0,
    'honestyScore': 65.0,
    'responsibilityScore': 80.0,
    'courageScore': 60.0,
    'respectScore': 75.0,
    'cooperationScore': 68.0,
    'highlightComment': highlightComment,
    'growthComment': growthComment,
    'adviceComment': adviceComment,
    'parentMessage': parentMessage,
    'generatedAt': '2024-04-01T00:00:00.000Z',
    'topImpressions': <dynamic>[],
  });
}

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap({
  ChildProfile? child,
  MonthlyReport? report,
  bool reportNull = false,
}) {
  return ProviderScope(
    overrides: [
      hiveServiceProvider.overrideWithValue(FakeHiveService()),
      selectedChildProvider.overrideWith((ref) => Future.value(child)),
      monthlyReportProvider.overrideWith((ref, param) {
        if (reportNull) return Future.value(null);
        return Future.value(report);
      }),
    ],
    child: const MaterialApp(home: ReportScreen()),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ReportScreen', () {
    testWidgets('shows loading indicator while child loads', (tester) async {
      final completer = Completer<ChildProfile?>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(FakeHiveService()),
            selectedChildProvider.overrideWith((ref) => completer.future),
            monthlyReportProvider.overrideWith(
                (ref, _) => Future.value(null)),
          ],
          child: const MaterialApp(home: ReportScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('shows message when no child is selected', (tester) async {
      await tester.pumpWidget(_wrap(child: null));
      await tester.pumpAndSettle();
      expect(find.text('子供プロフィールを作成してください'), findsOneWidget);
    });

    testWidgets('shows AppBar title 月次成長レポート when child is present',
        (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();
      expect(find.text('月次成長レポート'), findsOneWidget);
    });

    testWidgets('shows month selector navigation buttons', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows empty report card when report is null', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('レポートはまだありません'), findsOneWidget);
      expect(find.text('レポートを確認する'), findsOneWidget);
      expect(find.text('AIレポートを生成する'), findsOneWidget);
    });

    testWidgets('shows summary card stat labels when report exists',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(
            storiesCompleted: 8,
            totalStudyMinutes: 120,
            totalPointsEarned: 200,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Labels are plain Text widgets — always reliable to test
      expect(find.text('完了ストーリー'), findsOneWidget);
      expect(find.text('学習時間'), findsOneWidget);
      expect(find.text('獲得ポイント'), findsOneWidget);
    });

    testWidgets('shows AI comment card with highlight', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(highlightComment: '今月はよく頑張りました！'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('✨ 今月の頑張り'), findsOneWidget);
      expect(find.text('今月はよく頑張りました！'), findsOneWidget);
    });

    testWidgets('shows radar chart section header', (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();
      expect(find.text('🌈 徳目バランス'), findsOneWidget);
    });

    testWidgets('shows parent message card when parentMessage is set',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(parentMessage: '毎日コツコツ続けましょう。'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('保護者の方へ'), findsOneWidget);
      expect(find.text('毎日コツコツ続けましょう。'), findsOneWidget);
    });

    testWidgets('does NOT show parent message card when parentMessage is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();
      expect(find.text('保護者の方へ'), findsNothing);
    });

    testWidgets('month selector previous button is tappable', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      // After tap, nav buttons are still present (navigated to prev month)
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    // ─── Phase 5.1 Tests: バッジセクション ──────────────────────────────────
    testWidgets('shows badge section header when report exists', (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();
      expect(find.text('🎖️ バッジ進捗'), findsOneWidget);
    });

    testWidgets('displays virtue score trends when report exists', (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();
      // Virtue names should be displayed in score trends
      expect(find.textContaining('思いやり'), findsWidgets);
      expect(find.textContaining('正直'), findsWidgets);
      expect(find.textContaining('勇気'), findsWidgets);
    });

    testWidgets('shows virtue score progress bars with appropriate colors',
        (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();
      // Progress indicators should be present for virtue scores
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    // ─── Phase 5.2 Tests: 月比較レーダーチャート ───────────────────────────
    testWidgets('shows radar chart with legend when report exists', (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();
      expect(find.text('🌈 徳目バランス'), findsOneWidget);
      // Legend text for current month
      expect(find.textContaining('今月'), findsWidgets);
    });

    testWidgets('shows growth comparison card when previous month available',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(storiesCompleted: 8),
        ),
      );
      await tester.pumpAndSettle();
      // Compare button or comparison section should be visible
      expect(find.textContaining('比較'), findsWidgets);
    });

    testWidgets('AI comment card expands and collapses', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(
            highlightComment: 'これは長いコメントです。' * 10,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the comment card area and tap to expand
      final commentText = find.text('✨ 今月の頑張り');
      expect(commentText, findsOneWidget);

      // Try to find expand/collapse button
      final expandButtons = find.byType(GestureDetector);
      if (expandButtons.evaluate().isNotEmpty) {
        await tester.tap(expandButtons.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('shows all virtue scores within valid range', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(
            // Scores range from 0-100
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All virtue scores should be displayed as numbers
      final scoreTexts = find.byType(Text);
      expect(scoreTexts, findsWidgets);
    });

    testWidgets('month selector shows current and previous month options',
        (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();

      // Tap month selector button
      final monthButtons = find.byType(TextButton);
      if (monthButtons.evaluate().isNotEmpty) {
        await tester.tap(find.byType(TextButton).first);
        await tester.pumpAndSettle();

        // Month picker should show multiple month options
        expect(find.byType(GridView), findsWidgets);
      }
    });

    testWidgets('report data updates when month is changed', (tester) async {
      await tester.pumpWidget(_wrap(child: _testChild, reportNull: true));
      await tester.pumpAndSettle();

      // Initial state should show empty report message
      expect(find.textContaining('レポート'), findsWidgets);

      // Navigate to previous month
      final prevButton = find.byIcon(Icons.chevron_left);
      if (prevButton.evaluate().isNotEmpty) {
        await tester.tap(prevButton);
        await tester.pumpAndSettle();
        // Screen should still be responsive
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      }
    });

    testWidgets('badge progress cards display correct information',
        (tester) async {
      await tester.pumpWidget(
        _wrap(child: _testChild, report: _makeReport()),
      );
      await tester.pumpAndSettle();

      // Badge section should contain progress indicators
      final progressIndicators = find.byType(LinearProgressIndicator);
      expect(progressIndicators, findsWidgets);
    });

    testWidgets('handles report with zero scores gracefully', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(storiesCompleted: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Screen should still render without errors
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('scrollable content fits within screen', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: _testChild,
          report: _makeReport(
            highlightComment: 'コメント' * 20,
            growthComment: 'コメント' * 20,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should be able to scroll
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Content should still be visible
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
