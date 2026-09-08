import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offline_provider.dart';

/// オフラインモード表示バナー
/// アプリがオフライン状態の場合、画面上部に警告バナーを表示
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFE082),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFF856404),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'オフラインモード - キャッシュされたデータを表示しています',
              style: TextStyle(
                color: Color(0xFF856404),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// オフラインモード状態を示すステータスチップ
class OfflineStatusChip extends ConsumerWidget {
  const OfflineStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Chip(
      avatar: const Icon(Icons.cloud_off, size: 16),
      label: const Text('オフライン'),
      backgroundColor: const Color(0xFFFFF3CD),
      labelStyle: const TextStyle(
        color: Color(0xFF856404),
        fontSize: 12,
      ),
    );
  }
}

/// オフラインモード詳細表示ダイアログ
void showOfflineModeInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('オフラインモード'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'このアプリはオフライン状態です。インターネット接続時にキャッシュされたデータを表示しています。',
          ),
          const SizedBox(height: 12),
          const Text(
            '新しいコンテンツの読み込みやデータの更新は、オンラインに戻った後に行われます。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
