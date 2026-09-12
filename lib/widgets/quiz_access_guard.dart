import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/quiz_access_override_provider.dart';
import '../screens/paywall_screen.dart';

/// クイズアクセス制御ウィジェット
/// 無料期間終了またはサブスク未購読の場合、ペイウォール表示
class QuizAccessGuard extends ConsumerWidget {
  /// ラップするウィジェット（ストーリースクリーン）
  final Widget child;

  /// ペイウォール表示時のコールバック
  final VoidCallback? onPaywallShown;

  const QuizAccessGuard({
    required this.child,
    this.onPaywallShown,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // アクセス可否をチェック
    final accessAsync =
        ref.watch(canAccessShinShinStoriesProvider);

    return accessAsync.when(
      data: (canAccess) {
        // アクセス可 → ストーリー画面を表示
        if (canAccess) {
          return child;
        }

        // アクセス不可 → ペイウォール表示
        onPaywallShown?.call();
        return const PaywallScreen();
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('読み込み中...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: Center(
          child: Text('エラーが発生しました: $err'),
        ),
      ),
    );
  }
}

/// 無料期間ウォーニングウィジェット
/// 無料期間がもうすぐ終わる場合に表示
class FreeDaysWarning extends ConsumerWidget {
  /// 警告を表示する日数（例：3日以下なら警告）
  final int warningDays;

  const FreeDaysWarning({
    this.warningDays = 3,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAsync =
        ref.watch(remainingShinShinFreeDaysProvider);

    return remainingAsync.when(
      data: (remainingDays) {
        // 無料期間内 且つ 警告日数以下 → 表示
        if (remainingDays > 0 && remainingDays <= warningDays) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              border: Border.all(color: Colors.amber.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '無料期間がもうすぐ終わります',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        '残り $remainingDays 日',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // 表示不要
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
