import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/report.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:shougaku_kore_doutoku/providers/report_provider.dart';
import 'package:shougaku_kore_doutoku/screens/report/report_screen.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final _testChild = ChildProfile(
  id: 'child-golden-test',
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
  double kindnessScore = 70.0,
  double honestyScore = 65.0,
  double courageScore = 60.0,
  double respectScore = 75.0,
  double cooperationScore = 68.0,
  double responsibilityScore = 80.0,
}) {
  return MonthlyReport.fromJson({
    'id': 'report-golden',
    'childId': 'child-golden-test',
    'month': 3,
    'year': 2024,
    'storiesCompleted': storiesCompleted,
    'totalStudyMinutes': totalStudyMinutes,
    'totalPointsEarned': totalPointsEarned,
    'kindnessScore': kindnessScore,
    'honestyScore': honestyScore,
    'responsibilityScore': responsibilityScore,
    'courageScore': courageScore,
    'respectScore': respectScore,
    'cooperationScore': cooperationScore,
    'highlightComment': highlightComment ?? 'よく頑張りました！',
    'growthComment': growthComment ?? '思いやりが成長しています。',
    'adviceComment': adviceComment ?? 'もっと勇気を出しましょう。',
    'parentMessage': parentMessage,
    'generatedAt': '2024-04-01T00:00:00.000Z',
    'topImpressions': <dynamic>[],
  });
}

Widget _wrapReport({
  ChildProfile? child,
  MonthlyReport? report,
  MonthlyReport? previousReport,
}) {
  return ProviderScope(
    overrides: [
      selectedChildProvider.overrideWith((ref) => Future.value(child)),
      monthlyReportProvider.overrideWith((ref, _) {
        return Future.value(report);
      }),
      previousMonthReportProvider.overrideWith((ref, _) {
        return Future.value(previousReport);
      }),
    ],
    child: const MaterialApp(home: ReportScreen()),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ReportScreen - Golden Tests', () {
    testWidgets(
      'golden: report screen no report state',
      (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          _wrapReport(child: _testChild, report: null),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ReportScreen),
          matchesGoldenFile('goldens/report_screen_no_report.png'),
        );
      },
    );

    testWidgets(
      'golden: report screen with full data',
      (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final report = _makeReport(
          storiesCompleted: 8,
          totalStudyMinutes: 120,
          totalPointsEarned: 200,
          kindnessScore: 80.0,
          honestyScore: 75.0,
          courageScore: 70.0,
          respectScore: 85.0,
          cooperationScore: 78.0,
          responsibilityScore: 90.0,
        );

        await tester.pumpWidget(
          _wrapReport(child: _testChild, report: report),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ReportScreen),
          matchesGoldenFile('goldens/report_screen_full_data.png'),
        );
      },
    );

    testWidgets(
      'golden: report screen with low scores',
      (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final report = _makeReport(
          storiesCompleted: 2,
          totalStudyMinutes: 30,
          totalPointsEarned: 50,
          kindnessScore: 35.0,
          honestyScore: 40.0,
          courageScore: 25.0,
          respectScore: 30.0,
          cooperationScore: 28.0,
          responsibilityScore: 38.0,
          highlightComment: '継続頑張りましょう',
          adviceComment: '毎日少しずつ学習することが大切です',
        );

        await tester.pumpWidget(
          _wrapReport(child: _testChild, report: report),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ReportScreen),
          matchesGoldenFile('goldens/report_screen_low_scores.png'),
        );
      },
    );

    testWidgets(
      'golden: report screen with high scores',
      (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final report = _makeReport(
          storiesCompleted: 15,
          totalStudyMinutes: 300,
          totalPointsEarned: 500,
          kindnessScore: 95.0,
          honestyScore: 90.0,
          courageScore: 95.0,
          respectScore: 92.0,
          cooperationScore: 94.0,
          responsibilityScore: 96.0,
          highlightComment: '素晴らしい成長ですね！',
          adviceComment: 'このペースを保ち続けてください',
        );

        await tester.pumpWidget(
          _wrapReport(child: _testChild, report: report),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ReportScreen),
          matchesGoldenFile('goldens/report_screen_high_scores.png'),
        );
      },
    );

    testWidgets(
      'golden: report screen with month comparison',
      (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final currentReport = _makeReport(
          storiesCompleted: 8,
          kindnessScore: 80.0,
          honestyScore: 75.0,
          courageScore: 70.0,
          respectScore: 85.0,
          cooperationScore: 78.0,
          responsibilityScore: 90.0,
        );

        final previousReport = _makeReport(
          storiesCompleted: 5,
          kindnessScore: 65.0,
          honestyScore: 60.0,
          courageScore: 55.0,
          respectScore: 70.0,
          cooperationScore: 63.0,
          responsibilityScore: 75.0,
        );

        await tester.pumpWidget(
          _wrapReport(
            child: _testChild,
            report: currentReport,
            previousReport: previousReport,
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ReportScreen),
          matchesGoldenFile('goldens/report_screen_with_comparison.png'),
        );
      },
    );

    testWidgets(
      'golden: report screen with parent message',
      (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final report = _makeReport(
          parentMessage: 'いつもお疲れ様です。'
              'お子様は今月も大きく成長されています。'
              '特に思いやりと責任感の向上が見られます。'
              '引き続き、一緒に応援させていただきます。',
        );

        await tester.pumpWidget(
          _wrapReport(child: _testChild, report: report),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ReportScreen),
          matchesGoldenFile('goldens/report_screen_with_parent_message.png'),
        );
      },
    );

    testWidgets(
      'golden: report screen scrolled down',
      (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final report = _makeReport();

        await tester.pumpWidget(
          _wrapReport(child: _testChild, report: report),
        );
        await tester.pumpAndSettle();

        // Scroll down to show badge section
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ReportScreen),
          matchesGoldenFile('goldens/report_screen_scrolled_badges.png'),
        );
      },
    );

    testWidgets(
      'golden: report screen unbalanced scores',
      (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(540, 960);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final report = _makeReport(
          kindnessScore: 90.0, // Very high
          honestyScore: 30.0,  // Very low
          courageScore: 75.0,
          respectScore: 85.0,
          cooperationScore: 40.0, // Low
          responsibilityScore: 95.0, // Very high
        );

        await tester.pumpWidget(
          _wrapReport(child: _testChild, report: report),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ReportScreen),
          matchesGoldenFile('goldens/report_screen_unbalanced_scores.png'),
        );
      },
    );
  });
}
