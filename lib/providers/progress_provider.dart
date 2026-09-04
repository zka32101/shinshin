import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress.dart';
import '../models/story.dart';
import '../constants/app_constants.dart';
import '../utils/date_time_utils.dart';
import 'story_provider.dart'
    show apiServiceProvider, hiveServiceProvider, storiesProvider;

/// 子どもの進捗履歴プロバイダー（Hive オフラインキャッシュ付き）
/// 学習活動履歴を取得し、ローカルキャッシュでオフライン対応
///
/// 返値: 子どもの全進捗レコードのリスト
///
/// キャッシング戦略:
/// - オンライン: APIから取得し、Hiveに自動キャッシュ
/// - オフライン: キャッシュからフォールバック
final userProgressProvider = FutureProvider.autoDispose
    .family<List<Progress>, String>((ref, childId) async {
  final api = ref.watch(apiServiceProvider);
  final hive = ref.read(hiveServiceProvider);
  try {
    final items = await api.fetchProgress(childId);
    unawaited(hive.cacheProgressList(items));
    return items;
  } catch (_) {
    final cached = await hive.getCachedProgress(childId);
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
});

/// 完了済みストーリー一覧（重複なし、完了日時順）
/// 子どもが完了したストーリーの一覧を返す。
/// 同じストーリーの重複は除去し、最新の完了記録のみを保持する。
///
/// 返値: 完了済みストーリーのリスト
///
/// エラーハンドリング:
/// - 進捗取得失敗時: 空リストを返す（エラーを隠蔽）
/// - 無効なストーリーID: リストから除外
final completedStoriesProvider = FutureProvider.autoDispose
    .family<List<Story>, String>((ref, childId) async {
  try {
    final progressList =
        await ref.watch(userProgressProvider(childId).future);

    // story_completed アクションのみ & 重複を除去
    final seenIds = <String>{};
    final uniqueStoryIds = <String>[];
    for (final p in progressList) {
      if (p.action == AppConstants.actionStoryCompleted &&
          p.storyId != null &&
          seenIds.add(p.storyId!)) {
        uniqueStoryIds.add(p.storyId!);
      }
    }

    if (uniqueStoryIds.isEmpty) return [];

    // すべてのストーリーを取得してIDフィルタリング
    final allStories = await ref.watch(
      storiesProvider((theme: null, gradeLevel: null, isPremium: null)).future,
    );
    final storyMap = {for (final s in allStories) s.id: s};

    return uniqueStoryIds
        .where((id) => storyMap.containsKey(id))
        .map((id) => storyMap[id]!)
        .toList();
  } catch (_) {
    return [];
  }
});

/// 過去7日間の学習件数（曜日インデックス: 0=月曜, 6=日曜）
/// ダッシュボードの週間アクティビティチャートに使用される
/// 各曜日の学習活動数をカウントして返す。
///
/// 返値: 7要素のリスト [月曜数, 火曜数, ..., 日曜数]
///
/// エラーハンドリング:
/// - 進捗取得失敗時: 全て0の配列を返す
final weeklyActivityProvider = FutureProvider.autoDispose
    .family<List<int>, String>((ref, childId) async {
  try {
    final progressList =
        await ref.watch(userProgressProvider(childId).future);
    final now = DateTime.now();
    final counts = List<int>.filled(AppConstants.daysInWeek, 0);
    for (final p in progressList) {
      if (p.action != AppConstants.actionStoryCompleted) continue;
      final diff = now.difference(p.recordedAt).inDays;
      if (diff < AppConstants.daysInWeek) {
        final dayIdx = DateTimeUtils.getDayIndexOfWeek(p.recordedAt);
        counts[dayIdx]++;
      }
    }
    return counts;
  } catch (_) {
    return List<int>.filled(AppConstants.daysInWeek, 0);
  }
});
