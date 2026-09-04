import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/child_profile.dart';
import 'package:shougaku_kore_doutoku/models/notification_preferences.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/models/report.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/providers/auth_provider.dart';
import 'package:shougaku_kore_doutoku/providers/notification_preferences_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart'; // apiServiceProvider
import 'package:shougaku_kore_doutoku/providers/story_provider_fs.dart'; // storiesFsProvider
import 'package:shougaku_kore_doutoku/screens/home/home_screen.dart';
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import '../helpers/fake_path_provider.dart';

// ─── Fake API ─────────────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  final List<ChildProfile> children;
  final ChildProfile? singleChild;

  _FakeApiService({this.children = const [], this.singleChild});

  @override
  Future<List<ChildProfile>> fetchChildrenProfiles() async => children;

  @override
  Future<ChildProfile> fetchChildProfile(String childId) async {
    if (singleChild != null) return singleChild!;
    throw Exception('not found');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchStories({
    String? theme,
    int? gradeLevel,
  }) async =>
      [];

  @override
  Future<Map<String, dynamic>> fetchWeeklyTheme() async => {};

  @override
  Future<List<Progress>> fetchProgress(String childId,
          {int limit = 100}) async =>
      [];

  @override
  Future<MonthlyReport> fetchMonthlyReport({
    required String childId,
    required int month,
    required int year,
  }) async =>
      _makeEmptyReport();

  MonthlyReport _makeEmptyReport() => const MonthlyReport(
    month: '2024-01',
    totalQuestsCompleted: 0,
    totalCorrectAnswers: 0,
    totalAnswers: 0,
    accuracyRate: 0.0,
    totalStudyMinutes: 0,
    totalCoinsEarned: 0,
    studyDaysCount: 0,
    categoryStats: {},
  );

  @override
  Future<Map<String, dynamic>> loginWithFirebase(String idToken) async =>
      {'accessToken': null};
}

// ─── Fixtures ────────────────────────────────────────────────────────────────

final _testChild = ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: 'たろう',
  grade: 3,
  avatarEmoji: '🦁',
  createdAt: DateTime(2024, 1, 1),
  level: 2,
  totalPoints: 150,
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap({List<ChildProfile>? children, ChildProfile? singleChild}) {
  final api = _FakeApiService(
    children: children ?? [],
    singleChild: singleChild,
  );
  return ProviderScope(
    overrides: [
      userAuthStateProvider.overrideWith((_) => Stream.value(null)),
      apiServiceProvider.overrideWith((ref) => api),
      storiesFsProvider.overrideWith(
        (ref, _) => Future.value(<Story>[]),
      ),
      notificationPreferencesProvider.overrideWith(
        (ref, userId) => Future.value(
          NotificationPreferences(updatedAt: DateTime.now()),
        ),
      ),
    ],
    child: MaterialApp(
      home: const HomeScreen(),
      routes: {
        '/child-registration': (_) =>
            const Scaffold(body: Text('ChildRegistrationPage')),
        '/login': (_) => const Scaffold(body: Text('LoginPage')),
        '/home': (_) => const Scaffold(body: Text('HomePage')),
      },
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
    await Hive.initFlutter();
  });

  tearDownAll(() async {
    try {
      await Hive.close();
    } catch (_) {}
  });

  group('HomeScreen', () {
    testWidgets('shows loading indicator before child init completes',
        (tester) async {
      // Use an api that never resolves fetchChildrenProfiles
      final neverApi = _FakeApiServiceNever();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAuthStateProvider.overrideWith((_) => Stream.value(null)),
            apiServiceProvider.overrideWith((ref) => neverApi),
            storiesProvider.overrideWith((ref, _) => Future.value(<Story>[])),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      // One frame: postFrameCallback fires but fetchChildrenProfiles hasn't resolved
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('redirects to /child-registration when no children exist',
        (tester) async {
      await tester.pumpWidget(_wrap(children: []));
      await tester.pumpAndSettle();
      expect(find.text('ChildRegistrationPage'), findsOneWidget);
    });

    testWidgets('shows BottomNavigationBar after init', (tester) async {
      await tester.pumpWidget(
          _wrap(children: [_testChild], singleChild: _testChild));
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('shows all five bottom nav labels', (tester) async {
      await tester.pumpWidget(
          _wrap(children: [_testChild], singleChild: _testChild));
      await tester.pumpAndSettle();
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('学習'), findsOneWidget);
      expect(find.text('成長'), findsOneWidget);
      expect(find.text('レポート'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('shows 心のレッスン in home header', (tester) async {
      await tester.pumpWidget(
          _wrap(children: [_testChild], singleChild: _testChild));
      await tester.pumpAndSettle();
      expect(find.text('心のレッスン'), findsOneWidget);
    });

    testWidgets('shows child name in home header', (tester) async {
      await tester.pumpWidget(
          _wrap(children: [_testChild], singleChild: _testChild));
      await tester.pumpAndSettle();
      expect(find.textContaining('たろう'), findsOneWidget);
    });

    testWidgets('shows level info in header', (tester) async {
      await tester.pumpWidget(
          _wrap(children: [_testChild], singleChild: _testChild));
      await tester.pumpAndSettle();
      expect(find.textContaining('レベル 2'), findsOneWidget);
    });

    testWidgets('shows すべてのストーリーを見る CTA', (tester) async {
      await tester.pumpWidget(
          _wrap(children: [_testChild], singleChild: _testChild));
      await tester.pumpAndSettle();
      expect(find.text('すべてのストーリーを見る'), findsOneWidget);
    });
  });
}

// ─── Helper for never-resolving API ──────────────────────────────────────────

class _FakeApiServiceNever extends ApiService {
  // Never completes — keeps HomeScreen in the loading state indefinitely
  // without leaving a pending timer that violates '!timersPending'.
  final _completer = Completer<List<ChildProfile>>();

  @override
  Future<List<ChildProfile>> fetchChildrenProfiles() => _completer.future;

  @override
  Future<Map<String, dynamic>> loginWithFirebase(String idToken) async =>
      {'accessToken': null};
}
