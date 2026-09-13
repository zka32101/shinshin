import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/premium_provider.dart';

class PremiumPaywall extends ConsumerWidget {
  final VoidCallback onPurchase;
  const PremiumPaywall({super.key, required this.onPurchase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumProvider);
    if (premium.isPremium) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[200]!)),
      child: Column(
        children: [
          const Text('✨ プレミアム会員になろう', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          const Text('• 無制限にプレイ\n• 広告なし\n• 限定コンテンツ', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onPurchase, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text('今すぐ登録')),
        ],
      ),
    );
  }
}
