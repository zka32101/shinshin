import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/report.dart';
import 'package:shougaku_kore_doutoku/providers/report_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart'
    show apiServiceProvider, hiveServiceProvider;
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import '../helpers/fake_path_provider.dart';

// ── In-memory HiveService ─────────────────────────────────────────────────
// Stores reports in memory so fire-and-forget cacheMonthlyReport calls are
// safe and can be read back in offline-fallback tests.

class _InMemoryHiveService extends HiveService {
  final Map<String, MonthlyReport> _reports = {};

  @override
  Future<void> cacheMonthlyReport(MonthlyReport report) async {
    final key = '${report.childId}_${report.year}_${report.month}';
    _reports[key] = report;
  }

  @override
  Future<MonthlyReport?> getCachedMonthlyReport(
    String childId,
    int year,
    int month,
  ) async {
    return _reports['${childId}_${year}_$month'];
  }
}

// ── Fake ApiService ────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  MonthlyReport? fetchResult;
  MonthlyReport? generateResult;
  bool fetchShouldFail = false;
  bool generateShouldFail = false;

  @override
  Future<MonthlyReport> fetchMonthlyReport({
    required String childId,
    required int month,
    required int year,
  }) async {
    if (fetchShouldFail) throw Exception('network error');
    return fetchResult ?? _makeEmptyReport();
  }

  MonthlyReport _makeEmptyReport() => MonthlyReport(
    id: 'report-1',
    childId: 'child-1',
    month: 1,
    year: 2024,
    generatedAt: DateTime.now(),
    storiesCompleted: 0,
    totalStudyMinutes: 0,
    totalPointsEarned: 0,
    topImpressions: const [],
  );

  @override
  Future<MonthlyReport> generateMonthlyReport({
    required String childId,
    required int year,
    required int month,
  }) async {
    if (generateShouldFail) throw Exception('network error');
    if (generateResult == null) throw StateError('generateResult not set');
    return generateResult!;
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

MonthlyReport _makeReport({
  required String childId,
  int year = 2024,
  int month = 6,
  int storiesCompleted = 3,
  String? highlightComment,
}) =>
    MonthlyReport(
      id: '${childId}_${year}_$month',
      childId: childId,
      year: year,
      month: month,
      storiesCompleted: storiesCompleted,
      generatedAt: DateTime(2024, 6, 30),
      highlightComment: highlightComment,
    );

ProviderContainer _makeContainer({
  required _FakeApiService api,
  required HiveService hive,
}) =>
    ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(api),
      hiveServiceProvider.overrideWithValue(hive),
    ]);

void main() {
  late _InMemoryHiveService hive;
  late _FakeApiService api;
  late Directory testDir;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('report_provider_test_');
    Hive.init(testDir.path);
    hive = _InMemoryHiveService();
    api = _FakeApiService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  // ── monthlyReportProvider ─────────────────────────────────────────────────

  group('monthlyReportProvider', () {
    const key = (childId: 'child-1', year: 2024, month: 6);

    test('returns report from API on success', () async {
      api.fetchResult = _makeReport(childId: 'child-1', storiesCompleted: 5);
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final report = await container.read(monthlyReportProvider(key).future);
      expect(report, isNotNull);
      expect(report!.storiesCompleted, 5);
      expect(report.childId, 'child-1');
    });

    test('returns null when API returns no report', () async {
      api.fetchResult = null; // No report exists yet
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final report = await container.read(monthlyReportProvider(key).future);
      expect(report, isNull);
    });

    test('API success caches report for offline use', () async {
      api.fetchResult = _makeReport(childId: 'child-1', storiesCompleted: 7);
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      await container.read(monthlyReportProvider(key).future);

      // Verify the in-memory cache was updated
      final cached = await hive.getCachedMonthlyReport('child-1', 2024, 6);
      expect(cached, isNotNull);
      expect(cached!.storiesCompleted, 7);
    });

    test('returns cached report when API fails', () async {
      await hive.cacheMonthlyReport(
        _makeReport(childId: 'child-1', storiesCompleted: 4),
      );

      api.fetchShouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final report = await container.read(monthlyReportProvider(key).future);
      expect(report, isNotNull);
      expect(report!.storiesCompleted, 4);
    });

    test('returns null from cache when API fails and no cache', () async {
      api.fetchShouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final report = await container.read(monthlyReportProvider(key).future);
      expect(report, isNull);
    });
  });

  // ── generateMonthlyReportProvider ─────────────────────────────────────────

  group('generateMonthlyReportProvider', () {
    const key = (childId: 'child-2', year: 2024, month: 7);

    test('returns generated report', () async {
      api.generateResult = _makeReport(
        childId: 'child-2',
        year: 2024,
        month: 7,
        storiesCompleted: 10,
        highlightComment: '素晴らしい一ヶ月でした',
      );
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final report = await container.read(generateMonthlyReportProvider(key).future);
      expect(report.storiesCompleted, 10);
      expect(report.highlightComment, '素晴らしい一ヶ月でした');
    });

    test('generated report is cached', () async {
      api.generateResult = _makeReport(
        childId: 'child-2',
        year: 2024,
        month: 7,
        storiesCompleted: 8,
      );
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      await container.read(generateMonthlyReportProvider(key).future);

      final cached = await hive.getCachedMonthlyReport('child-2', 2024, 7);
      expect(cached, isNotNull);
      expect(cached!.storiesCompleted, 8);
    });

    test('throws when API fails', () async {
      api.generateShouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      await expectLater(
        container.read(generateMonthlyReportProvider(key).future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
