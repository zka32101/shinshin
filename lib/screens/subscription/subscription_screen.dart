import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subscription_provider.dart';
import '../../services/analytics_service.dart';
import '../../utils/parental_gate_helper.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isProcessing = false;
  String? _selectedPlan; // 'monthly' or 'yearly'

  @override
  Widget build(BuildContext context) {
    final monthlyProduct = ref.watch(monthlyProductProvider);
    final yearlyProduct = ref.watch(yearlyProductProvider);
    final analyticsService = AnalyticsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('サブスクリプション'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'プランを選択',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'すべてのコンテンツをご利用いただけます',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              // Monthly Plan Card
              monthlyProduct.when(
                data: (product) {
                  if (product == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildPlanCard(
                    context,
                    title: '月額プラン',
                    price: product.price,
                    priceText: product.price,
                    period: '月額',
                    description: '毎月自動更新',
                    planId: 'monthly',
                    isSelected: _selectedPlan == 'monthly',
                    onSelect: () {
                      setState(() => _selectedPlan = 'monthly');
                    },
                    onBuy: () => _buyMonthly(),
                    isProcessing: _isProcessing,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('エラー: $error'),
              ),
              const SizedBox(height: 16),
              // Yearly Plan Card (Recommended)
              yearlyProduct.when(
                data: (product) {
                  if (product == null) {
                    return const SizedBox.shrink();
                  }
                  return Stack(
                    children: [
                      _buildPlanCard(
                        context,
                        title: '年額プラン',
                        price: product.price,
                        priceText: product.price,
                        period: '年額',
                        description: '毎年自動更新',
                        planId: 'yearly',
                        isSelected: _selectedPlan == 'yearly',
                        onSelect: () {
                          setState(() => _selectedPlan = 'yearly');
                        },
                        onBuy: () => _buyYearly(),
                        isProcessing: _isProcessing,
                      ),
                      Positioned(
                        top: 0,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'お得',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('エラー: $error'),
              ),
              const SizedBox(height: 40),
              // Restore button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isProcessing ? null : () => _restorePurchases(),
                  child: const Text(
                    '前に購入した内容を復元',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              // Terms and Privacy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _openTerms(),
                    child: const Text(
                      '利用規約',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const Text('・'),
                  TextButton(
                    onPressed: () => _openPrivacy(),
                    child: const Text(
                      'プライバシーポリシー',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'キャンセルはいつでも可能です',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String priceText,
    required String period,
    required String description,
    required String planId,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onBuy,
    required bool isProcessing,
  }) {
    return GestureDetector(
      onTap: isProcessing ? null : onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.blue,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  priceText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.blue : Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: isProcessing ? null : onBuy,
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '購入する',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyMonthly() async {
    // 課金操作の前に保護者ゲートを表示し、子どもが誤って課金しないようにする
    final passedGate = await requireParentalGate(
      context,
      description: 'これはアプリ内課金の操作です。\n下の計算の答えを入力してください。',
    );
    if (!passedGate || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final result = await ref.read(purchaseMonthlyProvider.future);
      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('購入が完了しました')),
          );
          AnalyticsService().logEvent(
            name: 'subscription_purchased',
            parameters: {'plan_type': 'monthly'},
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _buyYearly() async {
    // 課金操作の前に保護者ゲートを表示し、子どもが誤って課金しないようにする
    final passedGate = await requireParentalGate(
      context,
      description: 'これはアプリ内課金の操作です。\n下の計算の答えを入力してください。',
    );
    if (!passedGate || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final result = await ref.read(purchaseYearlyProvider.future);
      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('購入が完了しました')),
          );
          AnalyticsService().logEvent(
            name: 'subscription_purchased',
            parameters: {'plan_type': 'yearly'},
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(restorePurchasesProvider.future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入内容を復元しました')),
        );
        AnalyticsService().logEvent(name: 'restore_purchases');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _openTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('利用規約ページへ移動します')),
    );
  }

  void _openPrivacy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('プライバシーポリシーページへ移動します')),
    );
  }
}
