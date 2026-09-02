import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge.dart';
import '../models/story.dart';
import 'progress_provider.dart';
import 'story_provider.dart';

/// Cached badge computation result (internal use)
class _BadgeComputationCache {
  final int totalCompletions;
  final Map<String, int> completionsByVirtue;
  final DateTime computedAt;

  _BadgeComputationCache({
    required this.totalCompletions,
    required this.completionsByVirtue,
    required this.computedAt,
  });
}

/// Shared computation of badge statistics from progress data
/// Optimization: Prevents duplicate computation when multiple providers
/// (earnedBadgesProvider, badgeProgressProvider) need the same data
final _badgeStatsComputationProvider = FutureProvider.autoDispose
    .family<_BadgeComputationCache, String>((ref, childId) async {
  try {
    // 進捗データを取得
    final progressList = await ref.watch(userProgressProvider(childId).future);

    // ストーリーデータを取得
    final allStories = await ref.watch(
      storiesProvider((theme: null, gradeLevel: null, isPremium: null)).future,
    );
    final storyMap = {for (final s in allStories) s.id: s};

    // 完了したストーリーから徳目別に完了数をカウント
    final completionsByVirtue = <String, int>{};
    var totalCompletions = 0;

    for (final p in progressList) {
      if (p.action == 'story_completed' && p.storyId != null) {
        final story = storyMap[p.storyId];
        if (story != null) {
          totalCompletions++;
          completionsByVirtue.update(
            story.theme,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    return _BadgeComputationCache(
      totalCompletions: totalCompletions,
      completionsByVirtue: completionsByVirtue,
      computedAt: DateTime.now(),
    );
  } catch (_) {
    return _BadgeComputationCache(
      totalCompletions: 0,
      completionsByVirtue: {},
      computedAt: DateTime.now(),
    );
  }
});

/// 子どもが獲得したバッジ一覧プロバイダー
/// 完了したストーリーとその徳目に基づいてバッジ獲得を計算
///
/// Optimization: Now uses cached computation from _badgeStatsComputationProvider
/// to avoid duplicate progress/story data fetching
final earnedBadgesProvider = FutureProvider.autoDispose
    .family<List<EarnedBadge>, String>((ref, childId) async {
  try {
    // Use cached computation result
    final cache = await ref.watch(_badgeStatsComputationProvider(childId).future);
    final completionsByVirtue = cache.completionsByVirtue;
    final totalCompletions = cache.totalCompletions;

    // バッジ獲得判定
    final earnedBadgeIds = <String>{};
    final now = DateTime.now();

    for (final badge in kDoutokuBadges) {
      bool isEarned = false;

      if (badge.theme == 'all') {
        // 全テーマバッジ: 総完了数で判定
        isEarned = totalCompletions >= badge.requiredCompletions;
      } else {
        // 徳目別バッジ: 該当徳目の完了数で判定
        final virtueCompletions = completionsByVirtue[badge.theme] ?? 0;
        isEarned = virtueCompletions >= badge.requiredCompletions;
      }

      if (isEarned) {
        earnedBadgeIds.add(badge.id);
      }
    }

    // EarnedBadge オブジェクトに変換
    return earnedBadgeIds
        .map((id) => EarnedBadge(badgeId: id, earnedAt: now))
        .toList();
  } catch (_) {
    return [];
  }
});

/// バッジ進捗プロバイダー
/// バッジ獲得までの進捗パーセンテージを計算
///
/// Optimization: Now uses cached computation from _badgeStatsComputationProvider
/// to avoid duplicate progress/story data fetching
final badgeProgressProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, childId) async {
  try {
    // Use cached computation result
    final cache = await ref.watch(_badgeStatsComputationProvider(childId).future);
    final completionsByVirtue = cache.completionsByVirtue;
    final totalCompletions = cache.totalCompletions;

    // バッジごとに進捗を計算
    final progress = <String, double>{};

    for (final badge in kDoutokuBadges) {
      double progressValue;

      if (badge.theme == 'all') {
        // 全テーマバッジ: 総完了数で判定
        progressValue = (totalCompletions / badge.requiredCompletions)
            .clamp(0, 1)
            .toDouble();
      } else {
        // 徳目別バッジ: 該当徳目の完了数で判定
        final virtueCompletions = completionsByVirtue[badge.theme] ?? 0;
        progressValue =
            (virtueCompletions / badge.requiredCompletions).clamp(0, 1).toDouble();
      }

      progress[badge.id] = progressValue;
    }

    return progress;
  } catch (_) {
    return {};
  }
});

/// 獲得したバッジの総数プロバイダー
///
/// Optimization: Directly computes from cached stats instead of
/// depending on earnedBadgesProvider (which also depends on cache)
final totalEarnedBadgesCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, childId) async {
  try {
    final cache = await ref.watch(_badgeStatsComputationProvider(childId).future);
    final completionsByVirtue = cache.completionsByVirtue;
    final totalCompletions = cache.totalCompletions;

    var earnedCount = 0;
    for (final badge in kDoutokuBadges) {
      bool isEarned;
      if (badge.theme == 'all') {
        isEarned = totalCompletions >= badge.requiredCompletions;
      } else {
        final virtueCompletions = completionsByVirtue[badge.theme] ?? 0;
        isEarned = virtueCompletions >= badge.requiredCompletions;
      }
      if (isEarned) earnedCount++;
    }
    return earnedCount;
  } catch (_) {
    return 0;
  }
});

/// 獲得可能なバッジの総数（定数）
final totalAvailableBadgesCountProvider = Provider<int>((ref) {
  return kDoutokuBadges.length;
});

/// バッジ獲得率プロバイダー（0.0 ~ 1.0）
final badgeCompletionRateProvider = FutureProvider.autoDispose
    .family<double, String>((ref, childId) async {
  try {
    final earnedCount = await ref.watch(totalEarnedBadgesCountProvider(childId).future);
    final totalCount = ref.watch(totalAvailableBadgesCountProvider);
    return totalCount > 0 ? (earnedCount / totalCount).clamp(0, 1).toDouble() : 0.0;
  } catch (_) {
    return 0.0;
  }
});
