import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child_profile.dart';
import '../services/hive_service.dart';
import 'story_provider.dart' show apiServiceProvider;
import 'firestore_provider.dart';

// ── 選択中の子どもID を Hive に永続化するノティファイアー ──────────────
class _ChildIdNotifier extends StateNotifier<String?> {
  _ChildIdNotifier() : super(null) {
    // Don't call async operations in constructor
    // State updates will happen immediately when mount is complete
  }

  static const _key = 'selected_child_id';
  final _hive = HiveService();

  /// Load the selected child ID from persistent storage
  /// This should be called after the notifier is mounted
  Future<void> loadFromPersistentStorage() async {
    try {
      final id = await _hive.getSetting<String>(_key);
      if (id != null && mounted) {
        state = id;
      }
    } catch (e) {
      // Log but don't crash if persistence fails
      debugPrint('[ChildIdNotifier] Failed to load from persistent storage: $e');
    }
  }

  @override
  set state(String? value) {
    super.state = value;
    // 永続化 (null で消去) — non-blocking
    _hive.saveSetting(_key, value).catchError((e) {
      debugPrint('[ChildIdNotifier] Failed to persist state: $e');
    });
  }
}

/// 現在選択されている子ども ID プロバイダー（アプリ再起動後も復元）
final currentChildIdProvider =
    StateNotifierProvider<_ChildIdNotifier, String?>(
  (ref) {
    final notifier = _ChildIdNotifier();
    // Load from persistent storage without blocking
    unawaited(notifier.loadFromPersistentStorage());
    return notifier;
  },
);

/// Initializes persistent child ID storage (fire-and-forget)
/// This is separated from currentChildIdProvider to avoid cyclic dependency
final _childIdInitProvider = FutureProvider<void>((ref) async {
  // Ensure the notifier is properly initialized
  await Future.delayed(const Duration(milliseconds: 100));
  // The initialization happens in the notifier constructor
});

/// 親の全子どもプロフィール取得（バックエンド API）
final childrenProfilesProvider =
    FutureProvider.autoDispose<List<ChildProfile>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchChildrenProfiles();
});

/// 特定の子どもプロフィール取得（バックエンド API）
final childProfileProvider =
    FutureProvider.autoDispose.family<ChildProfile, String>((ref, childId) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchChildProfile(childId);
});

/// 現在選択されている子どもプロフィール取得
final currentChildProfileProvider = FutureProvider.autoDispose<ChildProfile?>(
  (ref) async {
    final childId = ref.watch(currentChildIdProvider);
    if (childId == null) return null;
    return ref.watch(childProfileProvider(childId).future);
  },
);

/// 成長画面・レポート画面で使うエイリアス
final selectedChildProvider = currentChildProfileProvider;

/// 子どもプロフィール管理Notifier
class ChildProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ChildProfileNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 子どもプロフィールを作成
  Future<ChildProfile> createChildProfile({
    required String name,
    required int grade,
    required String avatarEmoji,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiServiceProvider);
      final profile = await api.createChild(
        name: name,
        grade: grade,
        avatarEmoji: avatarEmoji,
      );
      state = const AsyncValue.data(null);
      // 子どもリストを再取得
      _ref.invalidate(childrenProfilesProvider);

      // Firestore にも同期 (fire-and-forget — uid が null の場合はスキップ)
      _syncChildToFirestore(profile);

      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void _syncChildToFirestore(ChildProfile profile) {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    final fs = _ref.read(firestoreServiceProvider);
    fs.createChildWithId(uid, profile).catchError((e) {
      debugPrint('[ChildProfileNotifier] Firestore sync failed: $e');
    });
  }

  /// 子どもプロフィールを更新
  Future<void> updateChildProfile({
    required String childId,
    String? name,
    int? grade,
    String? avatarEmoji,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiServiceProvider);
      // ignore: use_null_aware_elements
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (grade != null) 'grade': grade,
        if (avatarEmoji != null) 'avatarEmoji': avatarEmoji,
      };
      await api.updateChild(childId, updates);
      state = const AsyncValue.data(null);
      _ref.invalidate(childProfileProvider(childId));
      _ref.invalidate(childrenProfilesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 子どもプロフィールを削除
  Future<void> deleteChildProfile(String childId) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiServiceProvider);
      await api.deleteChild(childId);

      // 削除されたプロフィールが現在選択されていた場合、リセット
      if (_ref.read(currentChildIdProvider) == childId) {
        _ref.read(currentChildIdProvider.notifier).state = null;
      }

      state = const AsyncValue.data(null);
      _ref.invalidate(childrenProfilesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 現在の子どもを選択
  void selectChild(String childId) {
    _ref.read(currentChildIdProvider.notifier).state = childId;
  }

  /// 現在の子どもの選択を解除
  void deselectChild() {
    _ref.read(currentChildIdProvider.notifier).state = null;
  }
}

/// 子どもプロフィール管理プロバイダー
final childProfileNotifierProvider =
    StateNotifierProvider<ChildProfileNotifier, AsyncValue<void>>((ref) {
  return ChildProfileNotifier(ref);
});
