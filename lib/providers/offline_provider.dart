import 'package:flutter_riverpod/flutter_riverpod.dart';

/// オンライン/オフラインの状態を管理するプロバイダー
/// デフォルトはオンライン（true）。APIエラー時にオフラインに設定される
final isOnlineProvider = StateProvider<bool>((ref) => true);

/// キャッシュの使用可否を判断するプロバイダー
final shouldUseCacheProvider = Provider<bool>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  return !isOnline; // オフラインの場合キャッシュを使用
});

/// 最後の同期時刻を記録するプロバイダー
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

/// オフラインモードの詳細情報
class OfflineModeInfo {
  final bool isOffline;
  final DateTime? lastSyncTime;
  final int pendingSyncCount;

  const OfflineModeInfo({
    required this.isOffline,
    this.lastSyncTime,
    this.pendingSyncCount = 0,
  });
}

/// オフラインモード情報プロバイダー
final offlineModeInfoProvider = FutureProvider<OfflineModeInfo>((ref) async {
  final isOnline = ref.watch(isOnlineProvider);
  final lastSyncTime = ref.watch(lastSyncTimeProvider);

  // TODO: HiveService から pendingSyncCount を取得
  // final hiveService = ref.read(hiveServiceProvider);
  // final pendingCount = await hiveService.getPendingSyncCount();

  return OfflineModeInfo(
    isOffline: !isOnline,
    lastSyncTime: lastSyncTime,
    pendingSyncCount: 0,
  );
});
