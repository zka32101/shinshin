import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/providers/quiz_access_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subscription_provider.dart';

/// shinshin 用：ユーザー登録日プロバイダー
final userRegisteredAtOverrideProvider =
    FutureProvider<DateTime>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  // SharedPreferences から登録日を取得
  final registeredAtString =
      prefs.getString('shinshin_user_registered_at');

  if (registeredAtString != null) {
    return DateTime.parse(registeredAtString);
  }

  // 初回時は現在時刻を登録日として保存
  final now = DateTime.now();
  await prefs.setString('shinshin_user_registered_at', now.toIso8601String());
  return now;
});

/// shinshin 用：サブスク購読状態プロバイダー
final subscriptionStatusOverrideProvider =
    Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.isSubscribed;
});

/// shinshin 用：クイズアクセス状態を override
final quizAccessOverrideProvider = FutureProvider<
    dynamic>((ref) async {
  // shared_core の quiz_access_provider をオーバーライド
  // より詳細な実装は shared_core の quiz_access_provider を使用

  // 代わりにここで直接ロジックを実装
  final registeredAt =
      await ref.watch(userRegisteredAtOverrideProvider.future);
  final isSubscribed =
      await ref.watch(subscriptionStatusOverrideProvider.future);

  // quiz_access_provider で定義されている QuizAccessLogic を使用
  // (shared_core から import)

  return {
    'registeredAt': registeredAt,
    'isSubscribed': isSubscribed,
    'daysSinceRegistration': DateTime.now()
        .difference(registeredAt)
        .inDays,
  };
});

/// クイズへのアクセス可否（簡略版）
final canAccessShinShinStoriesProvider = FutureProvider<bool>((ref) async {
  final registeredAt =
      await ref.watch(userRegisteredAtOverrideProvider.future);
  final isSubscribed =
      await ref.watch(subscriptionStatusOverrideProvider.future);

  // サブスク購読者は常にアクセス可
  if (isSubscribed) return true;

  // 無料期間（14日）内はアクセス可
  final daysSinceRegistration =
      DateTime.now().difference(registeredAt).inDays;
  return daysSinceRegistration < 14;
});

/// ペイウォール表示が必要か
final shouldShowShinShinPaywallProvider =
    FutureProvider<bool>((ref) async {
  final canAccess =
      await ref.watch(canAccessShinShinStoriesProvider.future);
  return !canAccess;
});

/// 無料期間の残り日数
final remainingShinShinFreeDaysProvider =
    FutureProvider<int>((ref) async {
  final registeredAt =
      await ref.watch(userRegisteredAtOverrideProvider.future);
  final daysSinceRegistration =
      DateTime.now().difference(registeredAt).inDays;
  return (14 - daysSinceRegistration).clamp(0, 14);
});
