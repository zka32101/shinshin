import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/avatar.dart';
import '../../providers/avatar_provider.dart';

/// アバター選択画面
class AvatarSelectionScreen extends ConsumerWidget {
  const AvatarSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAvatarsAsync = ref.watch(allAvatarsProvider);
    final userAvatarInfoAsync = ref.watch(userAvatarInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('アバターを選ぶ'),
      ),
      body: allAvatarsAsync.when(
        data: (avatars) {
          return userAvatarInfoAsync.when(
            data: (userAvatarInfo) {
              if (userAvatarInfo == null) {
                return const Center(
                  child: Text('アバター情報が見つかりません'),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // デフォルトアバター セクション
                      const Text(
                        'デフォルトアバター',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.0,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: avatars
                            .where((a) => a.isDefault)
                            .toList()
                            .length,
                        itemBuilder: (context, index) {
                          final avatar = avatars
                              .where((a) => a.isDefault)
                              .toList()[index];
                          final isSelected =
                              userAvatarInfo.selectedAvatarId == avatar.id;

                          return _buildAvatarCard(
                            context,
                            ref,
                            avatar,
                            isSelected,
                            true, // isOwned (all defaults are owned)
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      // 購入済みアバター セクション
                      if (userAvatarInfo.purchasedAvatarIds.isNotEmpty) ...[
                        const Text(
                          '購入済みアバター',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.0,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: avatars
                              .where((a) =>
                                  userAvatarInfo.purchasedAvatarIds
                                      .contains(a.id))
                              .toList()
                              .length,
                          itemBuilder: (context, index) {
                            final avatar = avatars
                                .where((a) =>
                                    userAvatarInfo.purchasedAvatarIds
                                        .contains(a.id))
                                .toList()[index];
                            final isSelected =
                                userAvatarInfo.selectedAvatarId == avatar.id;

                            return _buildAvatarCard(
                              context,
                              ref,
                              avatar,
                              isSelected,
                              true, // isOwned
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                      // ショップへのボタン
                      const Text(
                        'もっとアバターを探す',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/avatar_shop');
                        },
                        icon: const Icon(Icons.shopping_bag),
                        label: const Text('アバターショップを開く'),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildAvatarCard(
    BuildContext context,
    WidgetRef ref,
    Avatar avatar,
    bool isSelected,
    bool isOwned,
  ) {
    return GestureDetector(
      onTap: isOwned
          ? () async {
              try {
                await ref.read(selectAvatarProvider(avatar.id).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${avatar.name}に変更しました'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('エラー: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          : null,
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(
                  color: Colors.blue,
                  width: 3,
                )
              : BorderSide.none,
        ),
        child: Stack(
          children: [
            // Avatar image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
                image: DecorationImage(
                  image: AssetImage(avatar.imagePath),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Image not found, show placeholder
                  },
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (avatar.imagePath.isEmpty) ...[
                      const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      avatar.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Selected indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            // Locked indicator
            if (!isOwned)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black54,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

