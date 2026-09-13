import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendRequestProvider = StateNotifierProvider<FriendRequestNotifier, List<FriendRequest>>((ref) => FriendRequestNotifier());

class FriendRequestNotifier extends StateNotifier<List<FriendRequest>> {
  FriendRequestNotifier() : super([]);
  void addRequest(String userId, String userName) => state = [...state, FriendRequest(userId: userId, userName: userName, requestedAt: DateTime.now())];
  void acceptRequest(String userId) => state = [for (final req in state) if (req.userId != userId) req];
  void declineRequest(String userId) => state = [for (final req in state) if (req.userId != userId) req];
}

class FriendRequest {
  final String userId, userName;
  final DateTime requestedAt;
  FriendRequest({required this.userId, required this.userName, required this.requestedAt});
}
