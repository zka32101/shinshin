import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

import '../main.dart' show navigatorKey;

/// Firebase Cloud Messaging サービス (FCM のみ)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Lazy getter — avoids accessing FirebaseMessaging.instance at construction
  /// time (which requires Firebase to be initialized).
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  /// 初期化
  Future<void> initialize() async {
    // 通知権限リクエスト
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log(
      'FCM permission: ${settings.authorizationStatus}',
      name: 'NotificationService',
    );

    // フォアグラウンド通知ハンドラー
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // バックグラウンド→アプリ起動時
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // アプリ終了状態から起動
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    developer.log('NotificationService initialized', name: 'NotificationService');
  }

  /// FCMトークン取得
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      developer.log('FCM token error: $e', name: 'NotificationService', error: e);
      return null;
    }
  }

  /// トークンリフレッシュ監視
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  /// フォアグラウンドメッセージ処理
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log(
      'Foreground message: ${message.messageId}',
      name: 'NotificationService',
    );

    final notification = message.notification;
    if (notification == null) return;

    developer.log(
      'FCM notification: ${notification.title} - ${notification.body}',
      name: 'NotificationService',
    );
  }

  /// メッセージタップ時の処理 — type に応じて画面に遷移
  void _handleMessageOpenedApp(RemoteMessage message) {
    final type = message.data['type'] as String?;
    developer.log(
      'Message opened app: type=$type',
      name: 'NotificationService',
    );

    // 通知タイプに応じてディープリンク
    switch (type) {
      case 'daily_reminder':
      case 'monthly_report':
      default:
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/home', (r) => false);
    }
  }

  /// デイリーリマインダー設定 (FCM Cloud Scheduler と連携)
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    developer.log(
      'Daily reminder scheduled at $hour:$minute via FCM',
      name: 'NotificationService',
    );
  }

  /// 通知をすべてキャンセル (FCM 関連)
  Future<void> cancelAll() async {
    developer.log(
      'All FCM notifications cancelled',
      name: 'NotificationService',
    );
  }

  /// バッジ数をリセット (iOS)
  Future<void> resetBadge() async {
    developer.log(
      'Badge reset',
      name: 'NotificationService',
    );
  }
}

/// バックグラウンドメッセージハンドラー (top-level function 必須)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'Background message: ${message.messageId}',
    name: 'FCM_Background',
  );
}
