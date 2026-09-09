import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_card.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/avatar.dart';
import '../../providers/avatar_provider.dart';

/// アバターショップ画面
class AvatarShopScreen extends ConsumerWidget {
  const AvatarShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasableAvatarsAsync = ref.watch(purchasableAvatarsProvider);
    final userAvatarInfoAsync = ref.watch(userAvatarInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('アバターショップ'),
      ),
      body: purchasableAvatarsAsync.when(
        data: (purchasableAvatars) {
          return userAvatarInfoAsync.when(
            data: (userAvatarInfo) {
              if (purchasableAvatars.isEmpty) {
                return const Center(
                  child: Text('購入可能なアバターはありません'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: purchasableAvatars.length,
                itemBuilder: (context, index) {
                  final avatar = purchasableAvatars[index];
                  final isPurchased = userAvatarInfo?.purchasedAvatarIds
                          .contains(avatar.id) ??
                      false;

                  return _buildAvatarShopCard(
                    context,
                    ref,
                    avatar,
                    isPurchased,
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Text('エラー: $error'),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildAvatarShopCard(
    BuildContext context,
    WidgetRef ref,
    Avatar avatar,
    bool isPurchased,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: DecorationImage(
                      image: AssetImage(avatar.imagePath),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Image not found, show placeholder
                      },
                    ),
                  ),
                  child: avatar.imagePath.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Avatar info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avatar.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        avatar.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Price and purchase button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPurchased ? '購入済み' : '¥${avatar.price}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPurchased ? Colors.green : Colors.blue,
                  ),
                ),
                if (!isPurchased)
                  AppButton(
                    onPressed: () {
                      _showPurchaseConfirmation(
                        context,
                        ref,
                        avatar,
                      );
                    },
                    label: '購入する',
                  )
                else
                  AppButton(
                    onPressed: null,
                    label: '購入済み',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseConfirmation(
    BuildContext context,
    WidgetRef ref,
    Avatar avatar,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${avatar.name}を購入しますか？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('価格: ¥${avatar.price}'),
              const SizedBox(height: 16),
              Text(avatar.description),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              label: 'キャンセル',
            ),
            AppButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performPurchase(context, ref, avatar);
              },
              label: '購入する',
            ),
          ],
        );
      },
    );
  }

  void _performPurchase(
    BuildContext context,
    WidgetRef ref,
    Avatar avatar,
  ) {
    // TODO: Implement actual In-App Purchase integration
    // This would integrate with payment_service.dart and in_app_purchase package
    // For now, we'll show a mock purchase flow

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('購入手続き中...'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('In-App Purchaseと連携してください'),
            ],
          ),
        );
      },
    );

    // Simulate purchase completion
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      // Here we would call the actual purchase provider
      // and update the user's avatar info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${avatar.name}を購入しました！'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}
