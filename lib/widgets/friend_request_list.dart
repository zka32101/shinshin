import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/friend_request_provider.dart';

class FriendRequestList extends ConsumerWidget {
  const FriendRequestList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(friendRequestProvider);
    if (requests.isEmpty) return const Center(child: Text('フレンドリクエストなし'));

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return ListTile(
          title: Text(req.userName),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.check), onPressed: () => ref.read(friendRequestProvider.notifier).acceptRequest(req.userId)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => ref.read(friendRequestProvider.notifier).declineRequest(req.userId)),
          ]),
        );
      },
    );
  }
}
