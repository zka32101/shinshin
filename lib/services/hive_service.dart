import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/story.dart';
import '../models/progress.dart';
import '../models/report.dart';
import 'logger_service.dart';

class HiveService {
  static const String storiesBox = 'stories';
  static const String progressBox = 'progress';
  static const String userBox = 'user';
  static const String reportsBox = 'reports';
  static const String pendingSyncBox = 'pending_sync';
  static const String settingsBox = 'settings';

  // Cached box instances to prevent race conditions
  late Box<String> _storiesBoxInstance;
  late Box<String> _progressBoxInstance;
  late Box<String> _userBoxInstance;
  late Box<String> _reportsBoxInstance;
  late Box<String> _pendingSyncBoxInstance;
  late Box<dynamic> _settingsBoxInstance;

  final _logger = LoggerService();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      // Open all boxes once during initialization
      _storiesBoxInstance = await Hive.openBox<String>(storiesBox);
      _progressBoxInstance = await Hive.openBox<String>(progressBox);
      _userBoxInstance = await Hive.openBox<String>(userBox);
      _reportsBoxInstance = await Hive.openBox<String>(reportsBox);
      _pendingSyncBoxInstance = await Hive.openBox<String>(pendingSyncBox);
      _settingsBoxInstance = await Hive.openBox<dynamic>(settingsBox);

      _initialized = true;
      _logger.log('HiveService initialized with all boxes cached');
    } catch (e) {
      _logger.logError('Failed to initialize HiveService', e);
      rethrow;
    }
  }

  /// Ensure boxes are initialized before use
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('HiveService not initialized. Call initialize() first.');
    }
  }

  // Stories cache
  Future<void> cacheStories(List<Story> stories) async {
    _ensureInitialized();
    try {
      for (final story in stories) {
        await _storiesBoxInstance.put(story.id, jsonEncode(story.toJson()));
      }
      _logger.log('Cached ${stories.length} stories');
    } catch (e) {
      _logger.logError('Failed to cache stories', e);
      rethrow;
    }
  }

  Future<Story?> getCachedStory(String storyId) async {
    _ensureInitialized();
    try {
      final jsonString = _storiesBoxInstance.get(storyId);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Story.fromJson(json);
    } catch (e) {
      _logger.logError('Failed to get cached story: $storyId', e);
      return null;
    }
  }

  /// キャッシュ済みストーリー一覧を返す。theme / gradeLevel / isPremium でフィルタ可。
  Future<List<Story>> getCachedStories({
    String? theme,
    int? gradeLevel,
    bool? isPremium,
  }) async {
    _ensureInitialized();
    try {
      final stories = <Story>[];
      for (final jsonString in _storiesBoxInstance.values) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final story = Story.fromJson(json);
          if (theme != null && story.theme != theme) continue;
          if (gradeLevel != null && story.gradeLevel != gradeLevel) continue;
          if (isPremium != null && story.isPremium != isPremium) continue;
          stories.add(story);
        } catch (_) {
          // 壊れたエントリはスキップ
        }
      }
      // 更新日時降順
      stories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return stories;
    } catch (e) {
      _logger.logError('Failed to get cached stories', e);
      return [];
    }
  }

  Future<void> clearStoriesCache() async {
    _ensureInitialized();
    try {
      await _storiesBoxInstance.clear();
      _logger.log('Stories cache cleared');
    } catch (e) {
      _logger.logError('Failed to clear stories cache', e);
      rethrow;
    }
  }

  // Progress cache
  Future<void> cacheProgress(Progress progress) async {
    _ensureInitialized();
    try {
      await _progressBoxInstance.put(progress.id, jsonEncode(progress.toJson()));
      _logger.log('Progress cached: ${progress.id}');
    } catch (e) {
      _logger.logError('Failed to cache progress', e);
      rethrow;
    }
  }

  /// 進捗リストをまとめてキャッシュ
  Future<void> cacheProgressList(List<Progress> items) async {
    if (items.isEmpty) return;
    _ensureInitialized();
    try {
      for (final p in items) {
        await _progressBoxInstance.put(p.id, jsonEncode(p.toJson()));
      }
      _logger.log('Cached ${items.length} progress items');
    } catch (e) {
      _logger.logError('Failed to cache progress list', e);
      rethrow;
    }
  }

  Future<List<Progress>> getCachedProgress(String childId) async {
    _ensureInitialized();
    try {
      final progressList = <Progress>[];

      for (final entry in _progressBoxInstance.values) {
        try {
          final json = jsonDecode(entry) as Map<String, dynamic>;
          final progress = Progress.fromJson(json);
          if (progress.childId == childId) {
            progressList.add(progress);
          }
        } catch (e) {
          // Skip corrupted entries
          _logger.log('Skipped corrupted progress entry: $e');
        }
      }

      return progressList;
    } catch (e) {
      _logger.logError('Failed to get cached progress', e);
      return [];
    }
  }

  Future<void> clearProgressCache() async {
    _ensureInitialized();
    try {
      await _progressBoxInstance.clear();
      _logger.log('Progress cache cleared');
    } catch (e) {
      _logger.logError('Failed to clear progress cache', e);
      rethrow;
    }
  }

  // User cache
  Future<void> cacheUserId(String userId) async {
    _ensureInitialized();
    try {
      await _userBoxInstance.put('currentUserId', userId);
      _logger.log('User ID cached: $userId');
    } catch (e) {
      _logger.logError('Failed to cache user ID', e);
      rethrow;
    }
  }

  Future<String?> getCachedUserId() async {
    _ensureInitialized();
    try {
      return _userBoxInstance.get('currentUserId');
    } catch (e) {
      _logger.logError('Failed to get cached user ID', e);
      return null;
    }
  }

  Future<void> clearUserCache() async {
    _ensureInitialized();
    try {
      await _userBoxInstance.clear();
      _logger.log('User cache cleared');
    } catch (e) {
      _logger.logError('Failed to clear user cache', e);
      rethrow;
    }
  }

  // ============ レポートキャッシュ ============

  Future<void> cacheMonthlyReport(MonthlyReport report) async {
    _ensureInitialized();
    try {
      final key = '${report.childId}_${report.year}_${report.month}';
      await _reportsBoxInstance.put(key, jsonEncode(report.toJson()));
      _logger.log('Report cached: $key');
      developer.log('Report cached: $key', name: 'HiveService');
    } catch (e) {
      _logger.logError('Failed to cache monthly report', e);
      rethrow;
    }
  }

  Future<MonthlyReport?> getCachedMonthlyReport(
    String childId,
    int year,
    int month,
  ) async {
    _ensureInitialized();
    try {
      final key = '${childId}_${year}_$month';
      final jsonString = _reportsBoxInstance.get(key);
      if (jsonString == null) return null;
      return MonthlyReport.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (e) {
      _logger.logError('Report cache parse error for $childId', e);
      developer.log('Report cache parse error: $e', name: 'HiveService', error: e);
      return null;
    }
  }

  // ============ オフライン同期キュー ============

  /// オフライン時に完了したクイズを同期キューに追加
  Future<void> enqueuePendingQuizCompletion(Map<String, dynamic> data) async {
    _ensureInitialized();
    try {
      final key = 'quiz_${DateTime.now().millisecondsSinceEpoch}';
      await _pendingSyncBoxInstance.put(
        key,
        jsonEncode({'type': 'quiz_completion', 'data': data}),
      );
      _logger.log('Pending quiz enqueued: $key');
      developer.log('Pending quiz enqueued: $key', name: 'HiveService');
    } catch (e) {
      _logger.logError('Failed to enqueue pending quiz', e);
      rethrow;
    }
  }

  /// 同期待ちアイテムをすべて取得
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    _ensureInitialized();
    try {
      final items = <Map<String, dynamic>>[];
      for (final entry in _pendingSyncBoxInstance.toMap().entries) {
        try {
          final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
          items.add({'key': entry.key, ...decoded});
        } catch (e) {
          _logger.log('Skipped corrupted pending sync item: $e');
        }
      }
      return items;
    } catch (e) {
      _logger.logError('Failed to get pending sync items', e);
      return [];
    }
  }

  /// 同期完了したアイテムを削除
  Future<void> removePendingSyncItem(String key) async {
    _ensureInitialized();
    try {
      await _pendingSyncBoxInstance.delete(key);
      _logger.log('Pending sync item removed: $key');
    } catch (e) {
      _logger.logError('Failed to remove pending sync item: $key', e);
      rethrow;
    }
  }

  Future<int> getPendingSyncCount() async {
    _ensureInitialized();
    try {
      return _pendingSyncBoxInstance.length;
    } catch (e) {
      _logger.logError('Failed to get pending sync count', e);
      return 0;
    }
  }

  // ============ 設定 ============

  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();
    try {
      await _settingsBoxInstance.put(key, value);
      _logger.log('Setting saved: $key');
    } catch (e) {
      _logger.logError('Failed to save setting: $key', e);
      rethrow;
    }
  }

  Future<T?> getSetting<T>(String key) async {
    _ensureInitialized();
    try {
      final value = _settingsBoxInstance.get(key);
      if (value is T) {
        _logger.log('Setting retrieved: $key (type: $T)');
        return value;
      }

      if (value != null) {
        _logger.log(
          'Setting type mismatch: $key expected $T but got ${value.runtimeType}',
        );
      }
      return null;
    } catch (e) {
      _logger.logError('Failed to get setting: $key', e);
      return null;
    }
  }

  // ============ 全クリア ============

  Future<void> clearAll() async {
    try {
      if (_storiesBoxInstance.isOpen) await _storiesBoxInstance.clear();
      if (_progressBoxInstance.isOpen) await _progressBoxInstance.clear();
      if (_reportsBoxInstance.isOpen) await _reportsBoxInstance.clear();
      if (_userBoxInstance.isOpen) await _userBoxInstance.clear();
      if (_pendingSyncBoxInstance.isOpen) await _pendingSyncBoxInstance.clear();
      if (_settingsBoxInstance.isOpen) await _settingsBoxInstance.clear();

      // Delete from disk
      await Hive.deleteBoxFromDisk(storiesBox);
      await Hive.deleteBoxFromDisk(progressBox);
      await Hive.deleteBoxFromDisk(reportsBox);
      await Hive.deleteBoxFromDisk(userBox);
      await Hive.deleteBoxFromDisk(pendingSyncBox);
      await Hive.deleteBoxFromDisk(settingsBox);

      _initialized = false;
      _logger.log('All Hive data cleared');
      developer.log('All Hive data cleared', name: 'HiveService');
    } catch (e) {
      _logger.logError('Failed to clear all Hive data', e);
      rethrow;
    }
  }
}
