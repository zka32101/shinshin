import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'auth_provider.dart';

/// シングルトン HiveService — 全プロバイダーで共有
final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

/// Authenticated ApiService — automatically injects the backend JWT
/// when the Firebase user is signed in, and registers the FCM token.
final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();

  // Watch auth state and keep JWT in sync
  ref.listen(userAuthStateProvider, (_, next) {
    next.whenData((user) async {
      if (user != null) {
        try {
          final idToken = await user.getIdToken();
          if (idToken != null) {
            final result = await service.loginWithFirebase(idToken);
            final jwt = result['accessToken'] as String?;
            if (jwt != null) {
              service.setAuthToken(jwt);
              // FCM トークンをバックグラウンドで登録
              _tryRegisterFcmToken(service, ref);
            }
          }
        } catch (_) {
          // Firebase token exchange failed — clear token so API requests fail cleanly
          service.clearAuthToken();
        }
      } else {
        service.clearAuthToken();
      }
    });
  });

  return service;
});

/// FCM トークンを取得してバックエンドに登録する
/// Properly manages subscription lifecycle to prevent memory leaks
void _tryRegisterFcmToken(ApiService service, Ref ref) {
  FirebaseMessaging.instance.getToken().then((token) {
    if (token != null) {
      service.updateUser(fcmToken: token).catchError((_) {});
    }
  }).catchError((_) {});

  // トークンがローテートされたときも再登録
  // Store subscription so we can cancel it on disposal
  final subscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    service.updateUser(fcmToken: newToken).catchError((_) {});
  });

  // Cancel subscription when provider is disposed to prevent memory leak
  ref.onDispose(() {
    subscription.cancel();
  });
}

// Fetch stories provider with filters — ネットワーク失敗時は Hive キャッシュにフォールバック
final storiesProvider = FutureProvider.autoDispose
    .family<List<Story>, ({String? theme, int? gradeLevel, bool? isPremium})>(
  (ref, filters) async {
    final apiService = ref.watch(apiServiceProvider);
    final hive = ref.read(hiveServiceProvider);
    try {
      final rawStories = await apiService.fetchStories(
        theme: filters.theme,
        gradeLevel: filters.gradeLevel,
      );
      var stories = rawStories.map(Story.fromJson).toList();
      if (filters.isPremium != null) {
        stories = stories.where((s) => s.isPremium == filters.isPremium).toList();
      }
      // キャッシュ更新（ブロックしない）
      unawaited(hive.cacheStories(stories));
      return stories;
    } catch (_) {
      // オフライン or サーバーエラー → キャッシュから返す
      final cached = await hive.getCachedStories(
        theme: filters.theme,
        gradeLevel: filters.gradeLevel,
        isPremium: filters.isPremium,
      );
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  },
);

// Weekly theme provider - returns stories for the current week
final weeklyThemeProvider = FutureProvider.autoDispose.family<List<Story>, int>(
  (ref, weekNumber) async {
    final apiService = ref.watch(apiServiceProvider);
    final result = await apiService.fetchWeeklyTheme();
    final rawStories = result['stories'] as List<dynamic>? ?? [];
    return rawStories
        .map((e) => Story.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

// Story detail provider — ネットワーク失敗時は Hive キャッシュにフォールバック
final storyDetailProvider = FutureProvider.autoDispose
    .family<Story, String>((ref, storyId) async {
  final apiService = ref.watch(apiServiceProvider);
  final hive = ref.read(hiveServiceProvider);
  try {
    final rawStory = await apiService.fetchStoryDetail(storyId);
    final story = Story.fromJson(rawStory);
    // 詳細（content 含む）をキャッシュ更新
    unawaited(hive.cacheStories([story]));
    return story;
  } catch (_) {
    final cached = await hive.getCachedStory(storyId);
    if (cached != null) return cached;
    rethrow;
  }
});
