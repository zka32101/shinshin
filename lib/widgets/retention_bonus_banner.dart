import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/retention_provider.dart';

class RetentionBonusBanner extends ConsumerWidget {
  const RetentionBonusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retention = ref.watch(retentionProvider);
    if (retention.bonusCoins == 0 || retention.hasReceivedBonus) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[600]!, Colors.amber[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('おかえりなさい！ 🎉', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${retention.offboardDays}日ぶりのログイン！\n+${retention.bonusCoins} coins をゲット', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () { ref.read(retentionProvider.notifier).claimBonus(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+${retention.bonusCoins} coins 獲得！'))); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.amber[800]),
            child: const Text('ボーナスを受け取る'),
          ),
        ],
      ),
    );
  }
}
