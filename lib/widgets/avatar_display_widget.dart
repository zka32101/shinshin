import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/avatar_provider.dart';

/// アバター表示ウィジェット
/// ホーム画面やプロフィール画面で使用
class AvatarDisplayWidget extends ConsumerWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showName;

  const AvatarDisplayWidget({
    Key? key,
    this.size = 80,
    this.onTap,
    this.showName = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAvatarAsync = ref.watch(selectedAvatarProvider);

    return selectedAvatarAsync.when(
      data: (selectedAvatar) {
        if (selectedAvatar == null) {
          return _buildPlaceholder();
        }

        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size / 2),
                  color: Colors.grey[200],
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: AssetImage(selectedAvatar.imagePath),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Image not found, show placeholder
                    },
                  ),
                ),
                child: selectedAvatar.imagePath.isNotEmpty
                    ? null
                    : const Center(
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
              ),
              if (showName) ...[
                const SizedBox(height: 8),
                Text(
                  selectedAvatar.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: Colors.grey[200],
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// アバター選択ボタン
/// 設定画面で使用
class AvatarSelectionButton extends ConsumerWidget {
  const AvatarSelectionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('アバター'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).pushNamed('/avatar_selection');
      },
    );
  }
}

/// アバター表示パネル
/// ホーム画面のヘッダーで使用
class AvatarPanel extends ConsumerWidget {
  final String? userName;

  const AvatarPanel({
    Key? key,
    this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AvatarDisplayWidget(
            size: 64,
            onTap: () {
              Navigator.of(context).pushNamed('/avatar_selection');
            },
            showName: false,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userName != null) ...[
                  Text(
                    'こんにちは、$userName！',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                const Text(
                  'アバターを選ぶ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
