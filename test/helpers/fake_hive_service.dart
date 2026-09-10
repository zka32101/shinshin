import 'package:shougaku_kore_doutoku/services/hive_service.dart';
import 'package:shougaku_kore_doutoku/models/story.dart';
import 'package:shougaku_kore_doutoku/models/progress.dart';
import 'package:shougaku_kore_doutoku/models/cached_badge.dart';
import 'package:shougaku_kore_doutoku/models/badge.dart';

/// In-memory HiveService implementation for testing.
/// Stores data in-memory to avoid real Hive I/O.
class FakeHiveService extends HiveService {
  final Map<String, dynamic> _settings = {};
  final Map<String, Story> _stories = {};
  final Map<String, List<EarnedBadge>> _badgeData = {};
  final Map<String, List<Progress>> _childProgress = {};

  @override
  Future<T?> getSetting<T>(String key) async => _settings[key] as T?;

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  Future<void> clearSetting(String key) async {
    _settings.remove(key);
  }

  @override
  Future<void> cacheStories(List<Story> stories) async {
    _stories.clear();
    for (final story in stories) {
      _stories[story.id] = story;
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
    return _stories.values.toList();
  }

  @override
  Future<void> cacheBadgeData(String childId, List<EarnedBadge> badges) async {
    _badgeData[childId] = badges;
  }

  @override
  Future<List<CachedBadge>> getCachedBadges(String childId) async {
    final earnedBadges = _badgeData[childId] ?? [];
    return earnedBadges
        .map((e) => CachedBadge(badgeId: e.badgeId, earnedAt: e.earnedAt))
        .toList();
  }

  @override
  Future<void> cacheChildProgress(String childId, List<Progress> progress) async {
    _childProgress[childId] = progress;
  }

  @override
  Future<List<Progress>> getCachedProgress(String childId) async =>
      _childProgress[childId] ?? [];

  /// Clear all cached data
  void clear() {
    _settings.clear();
    _stories.clear();
    _badgeData.clear();
    _childProgress.clear();
  }
}
