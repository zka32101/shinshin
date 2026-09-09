import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/friend.dart';
import '../../providers/child_provider.dart';
import '../../providers/friend_provider.dart';

/// 友だち管理画面
/// 招待コードの表示・入力による友だち追加、一覧表示、削除を行う
class FriendListScreen extends ConsumerWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childProfileAsync = ref.watch(currentChildProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('友だち'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: childProfileAsync.when(
        data: (child) {
          if (child == null) {
            return const Center(
              child: Text(
                '子どもプロフィールが選択されていません',
                style: TextStyle(color: Color(0xFF999999)),
              ),
            );
          }
          return _FriendListBody(childId: child.id, inviteCode: child.inviteCode);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}

class _FriendListBody extends ConsumerWidget {
  final String childId;
  final String? inviteCode;

  const _FriendListBody({required this.childId, required this.inviteCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider(childId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(friendsListProvider(childId)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InviteCodeCard(inviteCode: inviteCode),
          const SizedBox(height: 16),
          _AddFriendCard(childId: childId),
          const SizedBox(height: 24),
          const Text(
            '友だち一覧',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 12),
          friendsAsync.when(
            data: (friends) {
              if (friends.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'まだ友だちがいません。\n招待コードを交換して追加しよう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF999999), fontSize: 13),
                    ),
                  ),
                );
              }
              return Column(
                children: friends
                    .map((friend) => _FriendTile(friend: friend, childId: childId))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'エラーが発生しました: $error',
                  style: const TextStyle(color: Color(0xFFDD6B55)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 自分の招待コード表示カード
class _InviteCodeCard extends StatelessWidget {
  final String? inviteCode;

  const _InviteCodeCard({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF9B59B6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9B59B6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'あなたの招待コード',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  inviteCode ?? '----------',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xFF9B59B6),
                  ),
                ),
              ),
              if (inviteCode != null)
                IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFF9B59B6)),
                  tooltip: 'コピー',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('招待コードをコピーしました')),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'このコードを友だちに教えてもらうと、友だち追加ができます。',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

/// 招待コード入力による友だち追加カード
class _AddFriendCard extends ConsumerStatefulWidget {
  final String childId;

  const _AddFriendCard({required this.childId});

  @override
  ConsumerState<_AddFriendCard> createState() => _AddFriendCardState();
}

class _AddFriendCardState extends ConsumerState<_AddFriendCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(friendActionsProvider.notifier)
          .addFriend(widget.childId, code);
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('友だちを追加しました！')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('友だちを追加できませんでした: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '友だちを追加',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 16,
                  decoration: const InputDecoration(
                    hintText: '招待コードを入力',
                    counterText: '',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B59B6),
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('追加'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 友だち一覧の1件表示
class _FriendTile extends ConsumerWidget {
  final Friend friend;
  final String childId;

  const _FriendTile({required this.friend, required this.childId});

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('友だちを削除しますか？'),
        content: Text('「${friend.name}」を友だちリストから削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(friendActionsProvider.notifier)
          .removeFriend(friend.friendId, childId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Text(friend.avatarEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                Text(
                  friend.gradeDisplayName,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF999999)),
            onPressed: () => _confirmRemove(context, ref),
          ),
        ],
      ),
    );
  }
}
