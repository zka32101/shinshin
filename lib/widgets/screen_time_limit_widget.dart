import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/screen_time_provider.dart';
import '../utils/parental_gate_helper.dart';

/// 1日の利用時間上限に達した際に表示する全画面オーバーレイ。
///
/// `shared_core` の `ScreenTimeLimitReachedWidget`
/// （`lib/widgets/screen_time_limit_screen.dart`）を参考に、本アプリの
/// トーン（道徳教育・内省型）に合わせて軽量移植したもの。
///
/// 「今日はここまで」を叱るのではなく、今日学んだことをねぎらい、また明日
/// 会えることを楽しみにしてもらうような、やさしい言葉づかいにしている。
///
/// ホーム画面などのルート付近で
/// `ref.watch(screenTimeProvider).isLimitReached` を監視し、true になったら
/// このウィジェットを表示する想定。
class ScreenTimeLimitReachedWidget extends ConsumerWidget {
  /// 一時解除で追加される分数（保護者ゲート通過後に加算）。
  final int extraMinutesOnOverride;

  /// 一時解除ボタンを表示するか。子ども向け端末では非表示にしたい場合は false に。
  final bool allowParentalOverride;

  const ScreenTimeLimitReachedWidget({
    super.key,
    this.extraMinutesOnOverride = 15,
    this.allowParentalOverride = true,
  });

  Future<void> _handleOverride(BuildContext context, WidgetRef ref) async {
    final passedGate = await requireParentalGate(
      context,
      description: 'これは大人の方が行う操作です。\n下の計算の答えを入力してください。',
    );
    if (!passedGate || !context.mounted) return;

    final notifier = ref.read(screenTimeProvider.notifier);
    final current = ref.read(screenTimeProvider).settings.dailyLimitMinutes;
    if (current != null) {
      await notifier.setDailyLimit(current + extraMinutesOnOverride);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 20),
                  const Text(
                    '今日のこころのレッスンは、ここまで',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '今日もよく考えたね。えらいよ。\n'
                    'ゆっくり休んで、また明日、\n'
                    '新しいお話で会おうね😊',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (allowParentalOverride) ...[
                    const SizedBox(height: 36),
                    TextButton(
                      onPressed: () => _handleOverride(context, ref),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: const Text(
                        '保護者の方はこちら（もう少しだけ）',
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 設定画面に組み込むための、利用時間制限の設定ウィジェット。
///
/// ON/OFF切り替えと、上限時間のスライダーを提供する。呼び出し側の画面は
/// `requireParentalGate()` を通した後にこのウィジェットへ遷移する想定
/// （このウィジェット自体はゲート処理を行わない）。
class ScreenTimeSettingsWidget extends ConsumerWidget {
  /// スライダーの下限（分）。
  final int minMinutes;

  /// スライダーの上限（分）。
  final int maxMinutes;

  /// スライダーの刻み幅（分）。
  final int stepMinutes;

  const ScreenTimeSettingsWidget({
    super.key,
    this.minMinutes = 15,
    this.maxMinutes = 180,
    this.stepMinutes = 15,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screenTimeProvider);
    final notifier = ref.read(screenTimeProvider.notifier);
    final settings = state.settings;
    final currentLimit = settings.dailyLimitMinutes ?? minMinutes;
    final divisions = ((maxMinutes - minMinutes) / stepMinutes).round();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: SwitchListTile(
            title: const Text(
              '利用時間を制限する',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('1日の利用時間に上限を設定できます'),
            value: settings.enabled,
            activeColor: AppColors.primary,
            onChanged: (value) => notifier.setEnabled(value),
          ),
        ),
        if (settings.enabled) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1日の利用上限',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentLimit 分',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Slider(
                    value: currentLimit.toDouble().clamp(
                        minMinutes.toDouble(), maxMinutes.toDouble()),
                    min: minMinutes.toDouble(),
                    max: maxMinutes.toDouble(),
                    divisions: divisions > 0 ? divisions : null,
                    activeColor: AppColors.primary,
                    label: '$currentLimit 分',
                    onChanged: (value) =>
                        notifier.setDailyLimit(value.round()),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$minMinutes分',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text('$maxMinutes分',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: const Icon(Icons.today, color: AppColors.textSecondary),
              title: const Text('今日の利用時間'),
              trailing: Text(
                '${state.usage.usedMinutes} 分',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
