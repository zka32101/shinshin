import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show matchmakingHandlersProvider, matchHandlersProvider;

import '../services/morality_matchmaking_service.dart';
import 'profile_provider.dart';

final List<Override> moralityMultiplayerProviderOverrides = [
  matchmakingHandlersProvider.overrideWithValue(MoralityMatchmakingService.matchmakingHandlers),
  matchHandlersProvider.overrideWithValue(MoralityMatchmakingService.matchHandlers),
];

/// マルチプレイで使う自分の userId / displayName。
///
/// 既存のマルチプレイ以外の機能と同じく
/// `profileProvider` の現在のプロフィール（[UserProfile.id] / [UserProfile.name]）を
/// そのまま使う。プロフィール未選択時は null。
class MoralityPlayerIdentity {
  final String userId;
  final String displayName;
  final int grade;

  const MoralityPlayerIdentity({
    required this.userId,
    required this.displayName,
    required this.grade,
  });
}

final moralityPlayerIdentityProvider = Provider<MoralityPlayerIdentity?>((ref) {
  final profile = ref.watch(profileProvider).currentProfile;
  if (profile == null) return null;
  return MoralityPlayerIdentity(
    userId: profile.id,
    displayName: profile.name,
    grade: profile.grade,
  );
});
