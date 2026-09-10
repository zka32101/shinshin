import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend.dart';
import '../services/friend_service.dart';

// Service provider
final friendServiceProvider = Provider((ref) {
  return FriendService();
});

/// 友だち一覧取得（child_id ごと）
final friendsListProvider =
    FutureProvider.autoDispose.family<List<Friend>, String>((ref, childId) async {
  final friendService = ref.watch(friendServiceProvider);
  return friendService.getFriends(childId);
});

/// 友だち追加・削除アクションを行う Notifier
class FriendActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FriendActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 招待コードで友だちを追加
  Future<void> addFriend(String childId, String inviteCode) async {
    state = const AsyncValue.loading();
    try {
      final friendService = _ref.read(friendServiceProvider);
      await friendService.addFriend(childId, inviteCode);
      state = const AsyncValue.data(null);
      _ref.invalidate(friendsListProvider(childId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 友だちを削除
  Future<void> removeFriend(String friendId, String childId) async {
    state = const AsyncValue.loading();
    try {
      final friendService = _ref.read(friendServiceProvider);
      await friendService.removeFriend(friendId, childId);
      state = const AsyncValue.data(null);
      _ref.invalidate(friendsListProvider(childId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final friendActionsProvider =
    StateNotifierProvider<FriendActionsNotifier, AsyncValue<void>>((ref) {
  return FriendActionsNotifier(ref);
});
