import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';

/// Firestore からストーリー一覧を取得する (Firestore 版)
///
/// [params] でテーマ・学年・プレミアムフラグによるフィルタリングが可能。
/// null の場合は該当フィルターを適用しない。
final storiesFsProvider = FutureProvider.autoDispose
    .family<List<Story>, ({String? theme, int? gradeLevel, bool? isPremium})>(
  (ref, params) => ref.watch(firestoreServiceProvider).getStories(
        theme: params.theme,
        gradeLevel: params.gradeLevel,
        isPremium: params.isPremium,
      ),
);

/// Firestore から特定のストーリー詳細を取得する (Firestore 版)
///
/// 該当ストーリーが存在しない場合は null を返す。
final storyDetailFsProvider =
    FutureProvider.autoDispose.family<Story?, String>(
  (ref, storyId) =>
      ref.watch(firestoreServiceProvider).getStory(storyId),
);
