import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/providers/quiz_completion_provider.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart'
    show apiServiceProvider, hiveServiceProvider;
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import '../helpers/fake_path_provider.dart';

// ── Fake ApiService ────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  // startQuizSession behaviour
  bool startShouldFail = false;
  String? startReturnId = 'session-001';

  // completeQuizSession behaviour
  bool completeShouldFail = false;
  int completeCalls = 0;

  @override
  Future<String> startQuizSession({
    required String childId,
    required String contentId,
  }) async {
    if (startShouldFail) throw Exception('API error');
    return startReturnId ?? 'session-123';
  }

  @override
  Future<Map<String, dynamic>> completeQuizSession({
    required String sessionId,
    required String chosenChoiceId,
    required int timeSpentSeconds,
    String? reflectionText,
  }) async {
    if (completeShouldFail) throw Exception('offline');
    completeCalls++;
    return {
      'pointsEarned': 15,
      'newLevel': 2,
      'newTotalPoints': 115,
      'scoreDeltas': {'kindness': 5.0},
    };
  }
}

// ── Test helpers ───────────────────────────────────────────────────────────

ProviderContainer _makeContainer({
  required _FakeApiService api,
  required HiveService hive,
}) =>
    ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(api),
      hiveServiceProvider.overrideWithValue(hive),
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
    testDir = await Directory.systemTemp.createTemp('quiz_provider_test_');
    Hive.init(testDir.path);
    hive = HiveService();
    api = _FakeApiService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  // ── quizStartProvider ────────────────────────────────────────────────────

  group('quizStartProvider', () {
    test('returns session ID on success', () async {
      api.startReturnId = 'session-abc';
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final key = (childId: 'child-1', storyId: 'story-1');
      final sessionId = await container.read(quizStartProvider(key).future);

      expect(sessionId, 'session-abc');
    });

    test('throws StateError when response has no id field', () async {
      api.startReturnId = null; // response will be {}
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final key = (childId: 'child-1', storyId: 'story-1');
      await expectLater(
        container.read(quizStartProvider(key).future),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when API call fails', () async {
      api.startShouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final key = (childId: 'child-1', storyId: 'story-1');
      await expectLater(
        container.read(quizStartProvider(key).future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── quizCompleteProvider ─────────────────────────────────────────────────

  group('quizCompleteProvider', () {
    test('returns QuizCompleteResult on success', () async {
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final key = (
        sessionId: 'session-001',
        childId: 'child-1',
        chosenChoiceId: 'choice-a',
        timeSpentSeconds: 90,
        reflectionText: null,
      );
      final result =
          await container.read(quizCompleteProvider(key).future);

      expect(result.pointsEarned, 15);
      expect(result.newLevel, 2);
      expect(result.newTotalPoints, 115);
      expect(result.scoreDeltas['kindness'], 5.0);
      expect(api.completeCalls, 1);
    });

    test('returns QuizCompleteResult.offline when API fails', () async {
      api.completeShouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final key = (
        sessionId: 'session-offline',
        childId: 'child-1',
        chosenChoiceId: 'choice-b',
        timeSpentSeconds: 45,
        reflectionText: null,
      );
      final result =
          await container.read(quizCompleteProvider(key).future);

      // Returns the sentinel offline value
      expect(result.pointsEarned, 0);
      expect(result.newLevel, 0);
      expect(result.scoreDeltas, isEmpty);

      // Item is enqueued in Hive for later sync
      final pending = await hive.getPendingSyncCount();
      expect(pending, 1);
      final items = await hive.getPendingSyncItems();
      expect(items.first['data']['sessionId'], 'session-offline');
    });

    test('offline fallback includes reflectionText in queued item', () async {
      api.completeShouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final key = (
        sessionId: 'session-reflect',
        childId: 'child-1',
        chosenChoiceId: 'choice-c',
        timeSpentSeconds: 60,
        reflectionText: '今日はよく考えました',
      );
      await container.read(quizCompleteProvider(key).future);

      final items = await hive.getPendingSyncItems();
      expect(items.first['data']['reflectionText'], '今日はよく考えました');
    });

    test('offline item without reflectionText omits the field', () async {
      api.completeShouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final key = (
        sessionId: 'session-no-reflect',
        childId: 'child-1',
        chosenChoiceId: 'choice-d',
        timeSpentSeconds: 30,
        reflectionText: null,
      );
      await container.read(quizCompleteProvider(key).future);

      final items = await hive.getPendingSyncItems();
      // reflectionText should NOT be present in the queued data
      expect(items.first['data'].containsKey('reflectionText'), isFalse);
    });
  });

  // ── QuizCompleteResult ───────────────────────────────────────────────────

  group('QuizCompleteResult', () {
    test('offline sentinel has zero values', () {
      expect(QuizCompleteResult.offline.pointsEarned, 0);
      expect(QuizCompleteResult.offline.newLevel, 0);
      expect(QuizCompleteResult.offline.newTotalPoints, 0);
      expect(QuizCompleteResult.offline.scoreDeltas, isEmpty);
    });

    test('constructor stores all fields correctly', () {
      const r = QuizCompleteResult(
        pointsEarned: 20,
        newLevel: 3,
        newTotalPoints: 220,
        scoreDeltas: {'honesty': 3.0},
      );
      expect(r.pointsEarned, 20);
      expect(r.newLevel, 3);
      expect(r.newTotalPoints, 220);
      expect(r.scoreDeltas['honesty'], 3.0);
    });
  });
}
