import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/child_profile.dart';

/// Firestore から子どものリストをリアルタイムで監視する StreamProvider
final childrenStreamProvider =
    StreamProvider.autoDispose<List<ChildProfile>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).childrenStream(uid);
});

/// 現在選択中の子どものプロフィールを Firestore から取得する (Firestore 版)
final currentChildFsProvider =
    FutureProvider.autoDispose<ChildProfile?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  final childId = ref.watch(currentChildIdProvider);
  if (uid == null || childId == null) return null;
  return ref.watch(firestoreServiceProvider).getChild(uid, childId);
});

/// 子どもを Firestore に新規作成し、生成された childId を返す (Firestore 版)
final createChildFsProvider = FutureProvider.autoDispose
    .family<String, ({String name, int grade, String avatarEmoji})>(
  (ref, params) async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) throw StateError('Not authenticated');
    final id = await ref.watch(firestoreServiceProvider).createChild(
      uid,
      name: params.name,
      grade: params.grade,
      avatarEmoji: params.avatarEmoji,
    );
    // 子どもリストのキャッシュを無効化
    ref.invalidate(childrenStreamProvider);
    return id;
  },
);

/// 子どもプロフィールを Firestore で更新する (Firestore 版)
final updateChildFsProvider = FutureProvider.autoDispose
    .family<void, ({String childId, Map<String, dynamic> updates})>(
  (ref, params) async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) throw StateError('Not authenticated');
    await ref
        .watch(firestoreServiceProvider)
        .updateChild(uid, params.childId, params.updates);
    // 関連キャッシュを無効化
    ref.invalidate(childrenStreamProvider);
    ref.invalidate(currentChildFsProvider);
  },
);

/// 子どもプロフィールを Firestore から削除する (Firestore 版)
final deleteChildFsProvider =
    FutureProvider.autoDispose.family<void, String>(
  (ref, childId) async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) throw StateError('Not authenticated');
    await ref.watch(firestoreServiceProvider).deleteChild(uid, childId);
    // 関連キャッシュを無効化
    ref.invalidate(childrenStreamProvider);
    ref.invalidate(currentChildFsProvider);
  },
);
