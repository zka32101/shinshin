import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

import '../models/badge.dart';
import '../models/cached_badge.dart';
import '../models/cached_report.dart';
import '../models/cached_story.dart';
import '../models/progress.dart';
import '../models/report.dart';
import '../models/story.dart';
import 'logger_service.dart';

/// Cache TTL configuration (in days)
class CacheTTL {
  static const int storiesCacheTTLDays = 7;
  static const int reportsCacheTTLDays = 90;
  static const int progressCacheTTLDays = 30;
  static const int badgesCacheTTLDays = 30;
}

class HiveService {
  static const String storiesBox = 'stories';
  static const String progressBox = 'progress';
  static const String userBox = 'user';
  static const String reportsBox = 'reports';
  static const String badgesBox = 'badges';
  static const String pendingSyncBox = 'pending_sync';
  static const String settingsBox = 'settings';

  // Cached box instances to prevent race conditions
  late Box<String> _storiesBoxInstance;
  late Box<String> _progressBoxInstance;
  late Box<String> _userBoxInstance;
  late Box<String> _reportsBoxInstance;
  late Box<String> _badgesBoxInstance;
  late Box<String> _pendingSyncBoxInstance;
  late Box<dynamic> _settingsBoxInstance;

  final _logger = LoggerService();
  bool _initialized = false;

  /// Wrapper to store cached data with timestamp for TTL validation
  static Map<String, dynamic> _wrapWithTimestamp(dynamic data) => {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

  /// Unwrap cached data and check if it's still valid based on TTL
  static dynamic _unwrapIfValid(String? jsonString, int ttlDays) {
    if (jsonString == null) return null;

    try {
      final wrapped = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = wrapped['timestamp'] as int?;
      if (timestamp == null) {
        // Legacy cache entry without timestamp, consider it expired
        return null;
      }

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );

      if (age.inDays > ttlDays) {
        return null; // Cache expired
      }

      return wrapped['data'];
    } catch (_) {
      return null; // Corrupted cache entry
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      // Open all boxes once during initialization
      // Note: For production, enable encryption with HiveAesCipher
      // final cipher = HiveAesCipher(yourEncryptionKey);
      _storiesBoxInstance = await Hive.openBox<String>(storiesBox);
      _progressBoxInstance = await Hive.openBox<String>(progressBox);
      _userBoxInstance = await Hive.openBox<String>(userBox);
      _reportsBoxInstance = await Hive.openBox<String>(reportsBox);
      _badgesBoxInstance = await Hive.openBox<String>(badgesBox);
      _pendingSyncBoxInstance = await Hive.openBox<String>(pendingSyncBox);
      _settingsBoxInstance = await Hive.openBox<dynamic>(settingsBox);

      _initialized = true;
      _logger.log('HiveService initialized with all boxes cached');
    } catch (e) {
      _logger.logError('Failed to initialize HiveService', error: e);
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
        final wrapped = _wrapWithTimestamp(story.toJson());
        await _storiesBoxInstance.put(story.id, jsonEncode(wrapped));
      }
      _logger.log('Cached ${stories.length} stories');
    } catch (e) {
      _logger.logError('Failed to cache stories', error: e);
      rethrow;
    }
  }

  Future<Story?> getCachedStory(String storyId) async {
    _ensureInitialized();
    try {
      final jsonString = _storiesBoxInstance.get(storyId);
      final data = _unwrapIfValid(jsonString, CacheTTL.storiesCacheTTLDays);
      if (data == null) return null;

      final json = data as Map<String, dynamic>;
      return Story.fromJson(json);
    } catch (e) {
      _logger.logError('Failed to get cached story: $storyId', error: e);
      return null;
    }
  }

  /// キャッシュ済みストーリー一覧を返す。theme / gradeLevel / isPremium でフィルタ可。
  /// Expired cache entries are automatically skipped.
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
          final data = _unwrapIfValid(jsonString, CacheTTL.storiesCacheTTLDays);
          if (data == null) continue; // Skip expired entries

          final json = data as Map<String, dynamic>;
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
      _logger.logError('Failed to get cached stories', error: e);
      return [];
    }
  }

  Future<void> clearStoriesCache() async {
    _ensureInitialized();
    try {
      await _storiesBoxInstance.clear();
      _logger.log('Stories cache cleared');
    } catch (e) {
      _logger.logError('Failed to clear stories cache', error: e);
      rethrow;
    }
  }

  // Progress cache
  Future<void> cacheProgress(Progress progress) async {
    _ensureInitialized();
    try {
      final wrapped = _wrapWithTimestamp(progress.toJson());
      await _progressBoxInstance.put(progress.id, jsonEncode(wrapped));
      _logger.log('Progress cached: ${progress.id}');
    } catch (e) {
      _logger.logError('Failed to cache progress', error: e);
      rethrow;
    }
  }

  /// 進捗リストをまとめてキャッシュ
  Future<void> cacheProgressList(List<Progress> items) async {
    if (items.isEmpty) return;
    _ensureInitialized();
    try {
      for (final p in items) {
        final wrapped = _wrapWithTimestamp(p.toJson());
        await _progressBoxInstance.put(p.id, jsonEncode(wrapped));
      }
      _logger.log('Cached ${items.length} progress items');
    } catch (e) {
      _logger.logError('Failed to cache progress list', error: e);
      rethrow;
    }
  }

  Future<List<Progress>> getCachedProgress(String childId) async {
    _ensureInitialized();
    try {
      final progressList = <Progress>[];

      for (final entry in _progressBoxInstance.values) {
        try {
          final data = _unwrapIfValid(entry, CacheTTL.progressCacheTTLDays);
          if (data == null) continue; // Skip expired entries

          final json = data as Map<String, dynamic>;
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
      _logger.logError('Failed to get cached progress', error: e);
      return [];
    }
  }

  Future<void> clearProgressCache() async {
    _ensureInitialized();
    try {
      await _progressBoxInstance.clear();
      _logger.log('Progress cache cleared');
    } catch (e) {
      _logger.logError('Failed to clear progress cache', error: e);
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
      _logger.logError('Failed to cache user ID', error: e);
      rethrow;
    }
  }

  Future<String?> getCachedUserId() async {
    _ensureInitialized();
    try {
      return _userBoxInstance.get('currentUserId');
    } catch (e) {
      _logger.logError('Failed to get cached user ID', error: e);
      return null;
    }
  }

  Future<void> clearUserCache() async {
    _ensureInitialized();
    try {
      await _userBoxInstance.clear();
      _logger.log('User cache cleared');
    } catch (e) {
      _logger.logError('Failed to clear user cache', error: e);
      rethrow;
    }
  }

  // ============ レポートキャッシュ ============

  Future<void> cacheMonthlyReport(MonthlyReport report) async {
    _ensureInitialized();
    try {
      final key = '${report.childId}_${report.year}_${report.month}';
      final wrapped = _wrapWithTimestamp(report.toJson());
      await _reportsBoxInstance.put(key, jsonEncode(wrapped));
      _logger.log('Report cached: $key');
      developer.log('Report cached: $key', name: 'HiveService');
    } catch (e) {
      _logger.logError('Failed to cache monthly report', error: e);
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
      final data = _unwrapIfValid(jsonString, CacheTTL.reportsCacheTTLDays);
      if (data == null) return null;
      return MonthlyReport.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      _logger.logError('Report cache parse error for $childId', error: e);
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
      _logger.logError('Failed to enqueue pending quiz', error: e);
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
      _logger.logError('Failed to get pending sync items', error: e);
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
      _logger.logError('Failed to remove pending sync item: $key', error: e);
      rethrow;
    }
  }

  Future<int> getPendingSyncCount() async {
    _ensureInitialized();
    try {
      return _pendingSyncBoxInstance.length;
    } catch (e) {
      _logger.logError('Failed to get pending sync count', error: e);
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
      _logger.logError('Failed to save setting: $key', error: e);
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
      _logger.logError('Failed to get setting: $key', error: e);
      return null;
    }
  }

  // ============ バッジキャッシュ ============

  /// 子どものバッジデータをキャッシュ
  Future<void> cacheBadgeData(String childId, List<EarnedBadge> badges) async {
    _ensureInitialized();
    try {
      final badgeData = CachedBadgeData(
        id: 'badges_$childId',
        childId: childId,
        earned: badges.map((b) => CachedBadge(
          badgeId: b.badgeId,
          earnedAt: b.earnedAt,
        )).toList(),
        cachedAt: DateTime.now(),
      );
      final wrapped = _wrapWithTimestamp(badgeData.toJson());
      await _badgesBoxInstance.put(childId, jsonEncode(wrapped));
      _logger.log('Badge data cached for child: $childId (${badges.length} badges)');
    } catch (e) {
      _logger.logError('Failed to cache badge data for $childId', error: e);
      rethrow;
    }
  }

  /// 子どものキャッシュされたバッジデータを取得
  Future<List<CachedBadge>> getCachedBadges(String childId) async {
    _ensureInitialized();
    try {
      final jsonString = _badgesBoxInstance.get(childId);
      final data = _unwrapIfValid(jsonString, CacheTTL.badgesCacheTTLDays);
      if (data == null) return [];

      final badgeData = CachedBadgeData.fromJson(data as Map<String, dynamic>);
      return badgeData.earned;
    } catch (e) {
      _logger.logError('Failed to get cached badges for $childId', error: e);
      return [];
    }
  }

  Future<void> clearBadgesCache() async {
    _ensureInitialized();
    try {
      await _badgesBoxInstance.clear();
      _logger.log('Badges cache cleared');
    } catch (e) {
      _logger.logError('Failed to clear badges cache', error: e);
      rethrow;
    }
  }

  // ============ キャッシュ管理 ============

  /// キャッシュサイズ情報を取得（各カテゴリ）
  Future<Map<String, String>> getCacheSizeInfo() async {
    _ensureInitialized();
    try {
      // 簡易的なサイズ計算（JSON文字列の長さから推定）
      int storiesSize = 0;
      int reportsSize = 0;
      int badgesSize = 0;

      for (final entry in _storiesBoxInstance.values) {
        storiesSize += entry.length;
      }

      for (final entry in _reportsBoxInstance.values) {
        reportsSize += entry.length;
      }

      for (final entry in _badgesBoxInstance.values) {
        badgesSize += entry.length;
      }

      // Bytes から MB に変換
      final storiesMB = (storiesSize / (1024 * 1024)).toStringAsFixed(2);
      final reportsMB = (reportsSize / (1024 * 1024)).toStringAsFixed(2);
      final badgesMB = (badgesSize / (1024 * 1024)).toStringAsFixed(2);
      final totalMB = ((storiesSize + reportsSize + badgesSize) / (1024 * 1024)).toStringAsFixed(2);

      _logger.log('Cache size: stories=${storiesMB}MB, reports=${reportsMB}MB, badges=${badgesMB}MB, total=${totalMB}MB');

      return {
        'stories': '${storiesMB} MB',
        'reports': '${reportsMB} MB',
        'badges': '${badgesMB} MB',
        'total': '${totalMB} MB',
      };
    } catch (e) {
      _logger.logError('Failed to get cache size info', error: e);
      return {'error': 'Unable to calculate cache size'};
    }
  }

  /// 指定した期間より古いキャッシュをクリア
  Future<void> clearCacheByAge(Duration age) async {
    _ensureInitialized();
    try {
      final now = DateTime.now();
      int storiesCleared = 0;
      int reportsCleared = 0;
      int badgesCleared = 0;

      // Stories キャッシュから期限切れを削除
      final storiesToDelete = <String>[];
      for (final entry in _storiesBoxInstance.toMap().entries) {
        try {
          final data = _unwrapIfValid(entry.value, CacheTTL.storiesCacheTTLDays);
          if (data == null) {
            storiesToDelete.add(entry.key);
          } else {
            final json = data as Map<String, dynamic>;
            final story = Story.fromJson(json);
            if (now.difference(story.updatedAt) > age) {
              storiesToDelete.add(entry.key);
            }
          }
        } catch (_) {
          storiesToDelete.add(entry.key);
        }
      }
      for (final key in storiesToDelete) {
        await _storiesBoxInstance.delete(key);
        storiesCleared++;
      }

      // Reports キャッシュから期限切れを削除
      final reportsToDelete = <String>[];
      for (final entry in _reportsBoxInstance.toMap().entries) {
        try {
          final data = _unwrapIfValid(entry.value, CacheTTL.reportsCacheTTLDays);
          if (data == null) {
            reportsToDelete.add(entry.key);
          } else {
            final json = data as Map<String, dynamic>;
            final report = MonthlyReport.fromJson(json);
            if (now.difference(report.generatedAt) > age) {
              reportsToDelete.add(entry.key);
            }
          }
        } catch (_) {
          reportsToDelete.add(entry.key);
        }
      }
      for (final key in reportsToDelete) {
        await _reportsBoxInstance.delete(key);
        reportsCleared++;
      }

      // Badges キャッシュから期限切れを削除
      final badgesToDelete = <String>[];
      for (final entry in _badgesBoxInstance.toMap().entries) {
        try {
          final data = _unwrapIfValid(entry.value, CacheTTL.badgesCacheTTLDays);
          if (data == null) {
            badgesToDelete.add(entry.key);
          } else {
            final json = data as Map<String, dynamic>;
            final badgeData = CachedBadgeData.fromJson(json);
            if (now.difference(badgeData.cachedAt) > age) {
              badgesToDelete.add(entry.key);
            }
          }
        } catch (_) {
          badgesToDelete.add(entry.key);
        }
      }
      for (final key in badgesToDelete) {
        await _badgesBoxInstance.delete(key);
        badgesCleared++;
      }

      _logger.log('Cache cleared: stories=$storiesCleared, reports=$reportsCleared, badges=$badgesCleared');
    } catch (e) {
      _logger.logError('Failed to clear cache by age', error: e);
      rethrow;
    }
  }

  /// オフラインモードかどうかを保存
  Future<void> setOfflineMode(bool isOffline) async {
    _ensureInitialized();
    try {
      await _settingsBoxInstance.put('isOfflineMode', isOffline);
      _logger.log('Offline mode set to: $isOffline');
    } catch (e) {
      _logger.logError('Failed to set offline mode', error: e);
      rethrow;
    }
  }

  /// オフラインモード状態を取得
  Future<bool> isOfflineModeEnabled() async {
    _ensureInitialized();
    try {
      return _settingsBoxInstance.get('isOfflineMode', defaultValue: false) as bool;
    } catch (e) {
      _logger.logError('Failed to get offline mode status', error: e);
      return false;
    }
  }

  // ============ 全クリア ============

  Future<void> clearAll() async {
    try {
      if (_storiesBoxInstance.isOpen) await _storiesBoxInstance.clear();
      if (_progressBoxInstance.isOpen) await _progressBoxInstance.clear();
      if (_reportsBoxInstance.isOpen) await _reportsBoxInstance.clear();
      if (_userBoxInstance.isOpen) await _userBoxInstance.clear();
      if (_badgesBoxInstance.isOpen) await _badgesBoxInstance.clear();
      if (_pendingSyncBoxInstance.isOpen) await _pendingSyncBoxInstance.clear();
      if (_settingsBoxInstance.isOpen) await _settingsBoxInstance.clear();

      // Delete from disk
      await Hive.deleteBoxFromDisk(storiesBox);
      await Hive.deleteBoxFromDisk(progressBox);
      await Hive.deleteBoxFromDisk(reportsBox);
      await Hive.deleteBoxFromDisk(userBox);
      await Hive.deleteBoxFromDisk(badgesBox);
      await Hive.deleteBoxFromDisk(pendingSyncBox);
      await Hive.deleteBoxFromDisk(settingsBox);

      _initialized = false;
      _logger.log('All Hive data cleared');
      developer.log('All Hive data cleared', name: 'HiveService');
    } catch (e) {
      _logger.logError('Failed to clear all Hive data', error: e);
      rethrow;
    }
  }
}
