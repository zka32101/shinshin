import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_preferences.dart';

// 親向け通知設定の取得（キャッシュ付き）
final notificationPreferencesProvider =
    FutureProvider.autoDispose.family<NotificationPreferences, String>(
  (ref, userId) async {
    final firestoreService = ref.watch(firestoreServiceProvider);

    try {
      return await firestoreService.getNotificationPreferences(userId);
    } catch (e) {
      // デフォルト設定を返す
      return NotificationPreferences.defaultPreferences();
    }
  },
);

// 通知設定更新（fire-and-forget）
final updateNotificationPreferencesProvider =
    FutureProvider.autoDispose.family<void,
        ({String userId, NotificationPreferences prefs})>(
  (ref, params) async {
    final firestoreService = ref.watch(firestoreServiceProvider);

    try {
      await firestoreService.saveNotificationPreferences(
        params.userId,
        params.prefs,
      );
      // キャッシュを無効化して再取得
      ref.invalidate(notificationPreferencesProvider(params.userId));
    } catch (e) {
      // エラーをサイレント処理（fire-and-forget）
      debugPrint('Failed to save notification preferences: $e');
    }
  },
);
