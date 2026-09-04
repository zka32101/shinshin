import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/subscription_provider.dart';
import '../../services/analytics_service.dart';

class TrialStatusScreen extends ConsumerWidget {
  const TrialStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionInfoProvider);
    final analyticsService = AnalyticsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('トライアル状態'),
        centerTitle: true,
      ),
      body: subscriptionAsync.when(
        data: (subscription) {
          if (subscription == null) {
            return const Center(
              child: Text('サブスクリプション情報が見つかりません'),
            );
          }

          if (!subscription.isInTrial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'サブスクリプション有効',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (subscription.subscriptionEndDate != null)
                    Text(
                      '有効期限: ${subscription.subscriptionEndDate!.year}年${subscription.subscriptionEndDate!.month}月${subscription.subscriptionEndDate!.day}日',
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            );
          }

          final daysRemaining = subscription.daysRemainingInTrial ?? 0;
          unawaited(analyticsService.logTrialStatusViewed(daysRemaining: daysRemaining));

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Large countdown display
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue,
                        width: 4,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$daysRemaining',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          '日',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'トライアル期間中',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'すべてのコンテンツと機能が無料で利用できます',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'トライアル終了予定日',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (subscription.trialEndDate != null)
                          Text(
                            '${subscription.trialEndDate!.year}年${subscription.trialEndDate!.month}月${subscription.trialEndDate!.day}日',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/subscription',
                        );
                      },
                      child: const Text(
                        'サブスクリプションを購入',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Open terms
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('利用規約ページへ移動します'),
                            ),
                          );
                        },
                        child: const Text('利用規約'),
                      ),
                      const Text('・'),
                      TextButton(
                        onPressed: () {
                          // Open privacy policy
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('プライバシーポリシーページへ移動します'),
                            ),
                          );
                        },
                        child: const Text('プライバシーポリシー'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}
