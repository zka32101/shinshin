import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/providers/story_provider.dart';
import 'package:shougaku_kore_doutoku/services/api_service.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import '../helpers/fake_path_provider.dart';

// ── In-memory HiveService ─────────────────────────────────────────────────
// Stores stories in-memory to avoid real Hive I/O, making fire-and-forget
// calls inside the provider safe against tearDown's directory deletion.

class _InMemoryHiveService extends HiveService {
  final Map<String, Story> _stories = {};

  @override
  Future<void> cacheStories(List<Story> stories) async {
    for (final s in stories) {
      _stories[s.id] = s;
    }
  }

  @override
  Future<Story?> getCachedStory(String storyId) async => _stories[storyId];

  @override
  Future<List<Story>> getCachedStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
  }) async {
    return _stories.values.where((s) {
      if (theme != null && s.theme != theme) return false;
      if (gradeLevel != null && s.gradeLevel != gradeLevel) return false;
      if (isPremium != null && s.isPremium != isPremium) return false;
      return true;
    }).toList();
  }
}

// ── Fake ApiService ────────────────────────────────────────────────────────

class _FakeApiService extends ApiService {
  List<Story> storiesResult = [];
  Story? detailResult;
  List<Story> weeklyResult = [];
  bool shouldFail = false;

  @override
  Future<List<Map<String, dynamic>>> fetchStories({
    String? theme,
    int? gradeLevel,
  }) async {
    if (shouldFail) throw Exception('network error');
    return storiesResult.map((story) => _storyToJson(story)).toList();
  }

  @override
  Future<Map<String, dynamic>> fetchStoryDetail(String storyId) async {
    if (shouldFail) throw Exception('network error');
    if (detailResult == null) throw Exception('not found');
    return _storyToJson(detailResult!);
  }

  @override
  Future<Map<String, dynamic>> fetchWeeklyTheme() async {
    if (shouldFail) throw Exception('network error');
    return {
      'theme': 'weekly',
      'stories': weeklyResult.map((story) => _storyToJson(story)).toList(),
    };
  }

  Map<String, dynamic> _storyToJson(Story story) => {
    'id': story.id,
    'title': story.title,
    'description': story.description,
    'theme': story.theme,
    'gradeLevel': story.gradeLevel,
    'isPremium': story.isPremium,
  };
}

// ── Helpers ────────────────────────────────────────────────────────────────

Story _makeStory({
  required String id,
  String theme = 'kindness',
  int gradeLevel = 3,
  bool isPremium = false,
}) =>
    Story(
      id: id,
      title: 'タイトル $id',
      theme: theme,
      gradeLevel: gradeLevel,
      isPremium: isPremium,
      durationSeconds: 300,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
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
    testDir = await Directory.systemTemp.createTemp('story_provider_test_');
    Hive.init(testDir.path);
    hive = _InMemoryHiveService();
    api = _FakeApiService();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  // ── storiesProvider ──────────────────────────────────────────────────────

  group('storiesProvider', () {
    test('returns API data on success', () async {
      api.storiesResult = [
        _makeStory(id: 's1', theme: 'kindness'),
        _makeStory(id: 's2', theme: 'honesty'),
      ];
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final stories = await container.read(
        storiesProvider((theme: null, gradeLevel: null, isPremium: null)).future,
      );
      expect(stories.length, 2);
      expect(stories.first.id, 's1');
    });

    test('returns cached stories when API fails and cache is non-empty', () async {
      await hive.cacheStories([_makeStory(id: 'cached-s', theme: 'courage')]);

      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final stories = await container.read(
        storiesProvider((theme: null, gradeLevel: null, isPremium: null)).future,
      );
      expect(stories.length, 1);
      expect(stories.first.id, 'cached-s');
    });

    test('rethrows when API fails and cache is empty', () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      await expectLater(
        container.read(
          storiesProvider((theme: null, gradeLevel: null, isPremium: null)).future,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('theme filter is applied to offline cache', () async {
      await hive.cacheStories([
        _makeStory(id: 's1', theme: 'kindness'),
        _makeStory(id: 's2', theme: 'honesty'),
      ]);

      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final stories = await container.read(
        storiesProvider((theme: 'kindness', gradeLevel: null, isPremium: null)).future,
      );
      expect(stories.length, 1);
      expect(stories.first.theme, 'kindness');
    });

    test('gradeLevel filter is applied to offline cache', () async {
      await hive.cacheStories([
        _makeStory(id: 's1', gradeLevel: 3),
        _makeStory(id: 's2', gradeLevel: 4),
      ]);

      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final stories = await container.read(
        storiesProvider((theme: null, gradeLevel: 3, isPremium: null)).future,
      );
      expect(stories.length, 1);
      expect(stories.first.gradeLevel, 3);
    });

    test('isPremium filter is applied to offline cache', () async {
      await hive.cacheStories([
        _makeStory(id: 's1', isPremium: false),
        _makeStory(id: 's2', isPremium: true),
      ]);

      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final stories = await container.read(
        storiesProvider((theme: null, gradeLevel: null, isPremium: true)).future,
      );
      expect(stories.length, 1);
      expect(stories.first.isPremium, isTrue);
    });
  });

  // ── storyDetailProvider ──────────────────────────────────────────────────

  group('storyDetailProvider', () {
    test('returns story on success', () async {
      api.detailResult = _makeStory(id: 'story-detail-1');
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final story = await container.read(storyDetailProvider('story-detail-1').future);
      expect(story.id, 'story-detail-1');
    });

    test('returns cached story when API fails', () async {
      await hive.cacheStories([_makeStory(id: 'story-cached-1')]);

      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final story = await container.read(storyDetailProvider('story-cached-1').future);
      expect(story.id, 'story-cached-1');
    });

    test('rethrows when API fails and story not in cache', () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      await expectLater(
        container.read(storyDetailProvider('missing-id').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── weeklyThemeProvider ──────────────────────────────────────────────────

  group('weeklyThemeProvider', () {
    test('returns weekly stories on success', () async {
      api.weeklyResult = [
        _makeStory(id: 'w1'),
        _makeStory(id: 'w2'),
      ];
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final stories = await container.read(weeklyThemeProvider(42).future);
      expect(stories.length, 2);
      expect(stories.first.id, 'w1');
    });

    test('returns empty list when API returns nothing', () async {
      api.weeklyResult = [];
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      final stories = await container.read(weeklyThemeProvider(1).future);
      expect(stories, isEmpty);
    });

    test('throws when API fails', () async {
      api.shouldFail = true;
      final container = _makeContainer(api: api, hive: hive);
      addTearDown(container.dispose);

      await expectLater(
        container.read(weeklyThemeProvider(1).future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
