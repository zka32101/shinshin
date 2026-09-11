import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/progress.dart';

/// Firestore からクエスト（ストーリー）完了履歴を取得する (Firestore 版)
final questHistoryFsProvider =
    FutureProvider.autoDispose.family<List<Progress>, String>(
  (ref, childId) async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return [];
    return ref
        .watch(firestoreServiceProvider)
        .getQuestHistory(uid, childId);
  },
);

/// Firestore から子どもの学習統計を取得する (Firestore 版)
final learningStatsFsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, childId) async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return {};
    return ref
        .watch(firestoreServiceProvider)
        .getLearningStats(uid, childId);
  },
);

/// クエスト完了を Firestore に記録し、関連プロバイダーを無効化する (Firestore 版)
final recordQuestFsProvider = FutureProvider.autoDispose.family<void,
    ({
      String childId,
      String storyId,
      int points,
      String virtue,
      int timeSeconds,
    })>(
  (ref, params) async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return;
    await ref.watch(firestoreServiceProvider).recordQuestCompletion(
          uid: uid,
          childId: params.childId,
          storyId: params.storyId,
          pointsDelta: params.points,
          chosenVirtue: params.virtue,
          timeSpentSeconds: params.timeSeconds,
        );
    // 記録後に関連プロバイダーを無効化してデータを再取得させる
    ref.invalidate(questHistoryFsProvider(params.childId));
    ref.invalidate(learningStatsFsProvider(params.childId));
  },
);
