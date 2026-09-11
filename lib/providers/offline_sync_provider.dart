import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/hive_service.dart';

enum SyncStatus { idle, syncing, success, error }

class OfflineSyncState {
  final SyncStatus status;
  final int pendingCount;
  final String? lastError;

  const OfflineSyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastError,
  });

  OfflineSyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    String? lastError,
  }) =>
      OfflineSyncState(
        status: status ?? this.status,
        pendingCount: pendingCount ?? this.pendingCount,
        lastError: lastError ?? this.lastError,
      );
}

/// オフライン同期管理Notifier
class OfflineSyncNotifier extends StateNotifier<OfflineSyncState> {
  final HiveService _hive;
  final ApiService _api;

  OfflineSyncNotifier(this._hive, this._api) : super(const OfflineSyncState()) {
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final count = await _hive.getPendingSyncCount();
    state = state.copyWith(pendingCount: count);
  }

  /// ネットワーク復帰時に同期実行
  Future<void> syncPendingItems() async {
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      final items = await _hive.getPendingSyncItems();
      developer.log(
        'Syncing ${items.length} pending items',
        name: 'OfflineSyncNotifier',
      );

      for (final item in items) {
        try {
          await _processItem(item);
          await _hive.removePendingSyncItem(item['key'] as String);
        } catch (e) {
          developer.log(
            'Sync item failed: $e',
            name: 'OfflineSyncNotifier',
            error: e,
          );
        }
      }

      state = state.copyWith(status: SyncStatus.success, pendingCount: 0);
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, lastError: e.toString());
    }
  }

  Future<void> _processItem(Map<String, dynamic> item) async {
    final type = item['type'] as String;
    final data = item['data'] as Map<String, dynamic>;

    switch (type) {
      case 'quiz_completion':
        // APIにクイズ完了を送信
        final sessionId = data['sessionId'] as String;
        final chosenChoiceId = data['chosenChoiceId'] as String;
        final timeSpentSeconds = data['timeSpentSeconds'] as int;
        final reflectionText = data['reflectionText'] as String?;
        await _api.completeQuizSession(
          sessionId: sessionId,
          chosenChoiceId: chosenChoiceId,
          timeSpentSeconds: timeSpentSeconds,
          reflectionText: reflectionText,
        );
        developer.log('Quiz completion synced: $sessionId', name: 'OfflineSyncNotifier');
        break;
      default:
        developer.log('Unknown sync type: $type', name: 'OfflineSyncNotifier');
    }
  }

  Future<void> refresh() async {
    await _loadPendingCount();
    state = state.copyWith(status: SyncStatus.idle);
  }
}

final offlineSyncProvider =
    StateNotifierProvider<OfflineSyncNotifier, OfflineSyncState>((ref) {
  // Shared authenticated ApiService — token is kept in sync by story_provider
  final api = ref.watch(apiServiceProvider);
  return OfflineSyncNotifier(HiveService(), api);
});
