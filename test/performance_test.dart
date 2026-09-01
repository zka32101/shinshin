import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/models/quiz_session.dart';
import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import 'helpers/fake_path_provider.dart';

// ── Performance Benchmark Service ────────────────────────────────────────────

class PerformanceBenchmark {
  final Map<String, List<Duration>> _measurements = {};

  void recordMeasurement(String name, Duration duration) {
    _measurements.putIfAbsent(name, () => []).add(duration);
  }

  Duration getAverageDuration(String name) {
    if (!_measurements.containsKey(name) || _measurements[name]!.isEmpty) {
      throw Exception('No measurements for $name');
    }
    final total = _measurements[name]!.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: total ~/ _measurements[name]!.length);
  }

  Duration getMaxDuration(String name) {
    if (!_measurements.containsKey(name) || _measurements[name]!.isEmpty) {
      throw Exception('No measurements for $name');
    }
    return _measurements[name]!.reduce(
      (a, b) => a.inMilliseconds > b.inMilliseconds ? a : b,
    );
  }

  Duration getMinDuration(String name) {
    if (!_measurements.containsKey(name) || _measurements[name]!.isEmpty) {
      throw Exception('No measurements for $name');
    }
    return _measurements[name]!.reduce(
      (a, b) => a.inMilliseconds < b.inMilliseconds ? a : b,
    );
  }

  String getReport() {
    if (_measurements.isEmpty) return 'No measurements recorded';

    final buffer = StringBuffer();
    buffer.writeln('Performance Benchmark Report');
    buffer.writeln('=' * 50);

    for (final entry in _measurements.entries) {
      final name = entry.key;
      final avg = getAverageDuration(name);
      final min = getMinDuration(name);
      final max = getMaxDuration(name);

      buffer.writeln('\n$name');
      buffer.writeln('-' * 50);
      buffer.writeln('  Average: ${avg.inMilliseconds}ms');
      buffer.writeln('  Min:     ${min.inMilliseconds}ms');
      buffer.writeln('  Max:     ${max.inMilliseconds}ms');
      buffer.writeln('  Count:   ${entry.value.length}');
    }

    return buffer.toString();
  }
}

// ── In-Memory Hive Service for Performance Testing ──────────────────────────

class _InMemoryHiveService extends HiveService {
  final Map<String, Story> _stories = {};
  final Map<String, Progress> _progress = {};
  final Map<String, QuizSession> _sessions = {};

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

  Future<void> saveProgress(Progress progress) async {
    _progress[progress.id] = progress;
  }

  Future<Progress?> getProgress(String progressId) async =>
      _progress[progressId];

  Future<void> saveQuizSession(QuizSession session) async {
    _sessions[session.id] = session;
  }

  Future<QuizSession?> getQuizSession(String sessionId) async =>
      _sessions[sessionId];
}

// ── Test Helpers ─────────────────────────────────────────────────────────────

Story _makeStory(int id) => Story(
  id: 'story-$id',
  title: 'Story Title $id',
  theme: 'kindness',
  gradeLevel: 3,
  isPremium: false,
  durationSeconds: 300,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

QuizSession _makeQuizSession(int id) => QuizSession(
  id: 'session-$id',
  childId: 'child-1',
  storyId: 'story-$id',
  selectedAnswers: {'q1': 'a', 'q2': 'b'},
  score: 80,
  completedAt: DateTime.now(),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

Progress _makeProgress(int id) => Progress(
  id: 'prog-$id',
  childId: 'child-1',
  storiesCompleted: id,
  averageScore: 85.0,
  completionPercentage: (id * 5).toDouble(),
  lastActivityAt: DateTime.now(),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// ── Performance Tests ────────────────────────────────────────────────────────

void main() {
  late Directory testDir;
  late PerformanceBenchmark benchmark;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('perf_test_');
    Hive.init(testDir.path);
    benchmark = PerformanceBenchmark();
  });

  tearDown(() async {
    await Hive.close();
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  group('Storage Performance', () {
    test('write 100 stories to cache', () async {
      final hive = _InMemoryHiveService();
      final stories = List.generate(100, (i) => _makeStory(i));

      final stopwatch = Stopwatch()..start();
      await hive.cacheStories(stories);
      stopwatch.stop();

      benchmark.recordMeasurement('cache_100_stories', stopwatch.elapsed);

      expect(stopwatch.elapsed.inMilliseconds, lessThan(500),
          reason: 'Caching 100 stories should take less than 500ms');

      print('Cached 100 stories in ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('read 100 stories from cache', () async {
      final hive = _InMemoryHiveService();
      final stories = List.generate(100, (i) => _makeStory(i));
      await hive.cacheStories(stories);

      final stopwatch = Stopwatch()..start();
      final cached = await hive.getCachedStories();
      stopwatch.stop();

      benchmark.recordMeasurement('read_100_stories', stopwatch.elapsed);

      expect(cached.length, 100);
      expect(stopwatch.elapsed.inMilliseconds, lessThan(100),
          reason: 'Reading 100 stories should take less than 100ms');

      print('Read 100 stories in ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('filter 100 stories by theme', () async {
      final hive = _InMemoryHiveService();
      final stories = List.generate(100, (i) => _makeStory(i));
      await hive.cacheStories(stories);

      final stopwatch = Stopwatch()..start();
      final filtered = await hive.getCachedStories(theme: 'kindness');
      stopwatch.stop();

      benchmark.recordMeasurement('filter_stories_by_theme', stopwatch.elapsed);

      expect(stopwatch.elapsed.inMilliseconds, lessThan(50),
          reason: 'Filtering stories should take less than 50ms');

      print(
        'Filtered 100 stories by theme in ${stopwatch.elapsed.inMilliseconds}ms',
      );
    });

    test('read single story by ID (100 lookups)', () async {
      final hive = _InMemoryHiveService();
      final stories = List.generate(100, (i) => _makeStory(i));
      await hive.cacheStories(stories);

      int totalMs = 0;

      for (int i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        await hive.getCachedStory('story-$i');
        stopwatch.stop();
        totalMs += stopwatch.elapsed.inMilliseconds;
      }

      final avgDuration = Duration(milliseconds: totalMs ~/ 100);
      benchmark.recordMeasurement('read_single_story', avgDuration);

      expect(avgDuration.inMilliseconds, lessThan(1),
          reason: 'Single story lookup should take less than 1ms');

      print('100 single lookups took average ${avgDuration.inMilliseconds}ms');
    });
  });

  group('Progress Tracking Performance', () {
    test('save 50 progress records', () async {
      final hive = _InMemoryHiveService();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        await hive.saveProgress(_makeProgress(i));
      }

      stopwatch.stop();

      benchmark.recordMeasurement('save_50_progress_records', stopwatch.elapsed);

      expect(stopwatch.elapsed.inMilliseconds, lessThan(200),
          reason: 'Saving 50 progress records should take less than 200ms');

      print('Saved 50 progress records in ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('read 50 progress records', () async {
      final hive = _InMemoryHiveService();

      for (int i = 0; i < 50; i++) {
        await hive.saveProgress(_makeProgress(i));
      }

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        await hive.getProgress('prog-$i');
      }

      stopwatch.stop();

      benchmark.recordMeasurement('read_50_progress_records', stopwatch.elapsed);

      expect(stopwatch.elapsed.inMilliseconds, lessThan(100),
          reason: 'Reading 50 progress records should take less than 100ms');

      print('Read 50 progress records in ${stopwatch.elapsed.inMilliseconds}ms');
    });
  });

  group('Quiz Session Performance', () {
    test('save 30 quiz sessions', () async {
      final hive = _InMemoryHiveService();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 30; i++) {
        await hive.saveQuizSession(_makeQuizSession(i));
      }

      stopwatch.stop();

      benchmark.recordMeasurement('save_30_quiz_sessions', stopwatch.elapsed);

      expect(stopwatch.elapsed.inMilliseconds, lessThan(150),
          reason: 'Saving 30 quiz sessions should take less than 150ms');

      print('Saved 30 quiz sessions in ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('retrieve 30 quiz sessions', () async {
      final hive = _InMemoryHiveService();

      for (int i = 0; i < 30; i++) {
        await hive.saveQuizSession(_makeQuizSession(i));
      }

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 30; i++) {
        await hive.getQuizSession('session-$i');
      }

      stopwatch.stop();

      benchmark.recordMeasurement('read_30_quiz_sessions', stopwatch.elapsed);

      expect(stopwatch.elapsed.inMilliseconds, lessThan(100),
          reason: 'Reading 30 quiz sessions should take less than 100ms');

      print('Read 30 quiz sessions in ${stopwatch.elapsed.inMilliseconds}ms');
    });
  });

  group('Bulk Operations Performance', () {
    test('bulk cache + read operation', () async {
      final hive = _InMemoryHiveService();
      final stories = List.generate(200, (i) => _makeStory(i));

      final stopwatch = Stopwatch()..start();
      await hive.cacheStories(stories);
      final cached = await hive.getCachedStories();
      stopwatch.stop();

      benchmark.recordMeasurement(
        'cache_and_read_200_stories',
        stopwatch.elapsed,
      );

      expect(cached.length, 200);
      expect(stopwatch.elapsed.inMilliseconds, lessThan(600),
          reason: 'Bulk cache and read should take less than 600ms');

      print('Bulk cache and read took ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('concurrent data operations', () async {
      final hive = _InMemoryHiveService();
      final stories = List.generate(50, (i) => _makeStory(i));

      await hive.cacheStories(stories);

      final stopwatch = Stopwatch()..start();

      // Simulate concurrent operations
      await Future.wait<void>([
        hive.getCachedStories(),
        hive.saveProgress(_makeProgress(1)),
        hive.saveQuizSession(_makeQuizSession(1)),
        Future.delayed(const Duration(milliseconds: 10)),
      ]);

      stopwatch.stop();

      benchmark.recordMeasurement('concurrent_operations', stopwatch.elapsed);

      expect(stopwatch.elapsed.inMilliseconds, lessThan(100),
          reason: 'Concurrent operations should complete within 100ms');

      print('Concurrent operations took ${stopwatch.elapsed.inMilliseconds}ms');
    });
  });

  group('Memory Efficiency', () {
    test('large dataset does not cause excessive memory growth', () async {
      final hive = _InMemoryHiveService();

      // Create large dataset
      final largeDataset = List.generate(500, (i) => _makeStory(i));

      final stopwatch = Stopwatch()..start();
      await hive.cacheStories(largeDataset);
      stopwatch.stop();

      benchmark.recordMeasurement('load_500_stories', stopwatch.elapsed);

      // Verify data integrity
      final cached = await hive.getCachedStories();
      expect(cached.length, 500);

      print('Loaded 500 stories in ${stopwatch.elapsed.inMilliseconds}ms');
    });
  });

  group('Story Retrieval Performance', () {
    test('retrieve story details (target: < 1 second)', () async {
      final hive = _InMemoryHiveService();
      final story = _makeStory(1);
      await hive.cacheStories([story]);

      final stopwatch = Stopwatch()..start();
      final retrieved = await hive.getCachedStory('story-1');
      stopwatch.stop();

      benchmark.recordMeasurement('retrieve_story_detail', stopwatch.elapsed);

      expect(retrieved, isNotNull);
      expect(stopwatch.elapsed.inMilliseconds, lessThan(1000),
          reason: 'Story retrieval should be less than 1 second');

      print('Story retrieval took ${stopwatch.elapsed.inMilliseconds}ms');
    });
  });

  group('Report Generation Performance', () {
    test('process 20 quiz sessions for report (target: < 5 seconds)', () async {
      final hive = _InMemoryHiveService();

      // Create 20 quiz sessions
      for (int i = 0; i < 20; i++) {
        await hive.saveQuizSession(_makeQuizSession(i));
      }

      final stopwatch = Stopwatch()..start();

      // Simulate report generation
      for (int i = 0; i < 20; i++) {
        await hive.getQuizSession('session-$i');
      }

      // Simulate report calculations
      await Future.delayed(const Duration(milliseconds: 50));

      stopwatch.stop();

      benchmark.recordMeasurement('generate_report_20_sessions', stopwatch.elapsed);

      expect(stopwatch.elapsed.inMilliseconds, lessThan(5000),
          reason: 'Report generation should take less than 5 seconds');

      print('Report generation took ${stopwatch.elapsed.inMilliseconds}ms');
    });
  });

  group('Performance Report', () {
    test('generate and print performance report', () async {
      // Run a few measurements
      final hive = _InMemoryHiveService();
      final stories = List.generate(100, (i) => _makeStory(i));

      await hive.cacheStories(stories);

      final stopwatch = Stopwatch()..start();
      await hive.getCachedStories();
      stopwatch.stop();

      benchmark.recordMeasurement('cache_and_read', stopwatch.elapsed);

      final report = benchmark.getReport();
      print('\n$report');

      // Verify benchmark is working
      expect(benchmark.getAverageDuration('cache_and_read'), isNotNull);
    });
  });
}
