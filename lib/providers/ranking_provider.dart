import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ranking.dart';
import '../providers/auth_provider.dart';
import '../services/ranking_service.dart';

// Service provider
final rankingServiceProvider = Provider((ref) {
  return RankingService();
});

// Get user's ranking settings
final rankingSettingsProvider = FutureProvider.autoDispose((ref) async {
  final auth = ref.watch(userAuthStateProvider);
  final rankingService = ref.watch(rankingServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    return null;
  }

  return await rankingService.getRankingSettings(userId);
});

// Get user's ranking statistics in real-time
final userRankingStatsProvider = StreamProvider.autoDispose((ref) async* {
  final auth = ref.watch(userAuthStateProvider);
  final rankingService = ref.watch(rankingServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    yield null;
    return;
  }

  yield* rankingService.getUserRankingStatsStream(userId);
});

// Get ranking entries by type
final rankingEntriesProvider =
    FutureProvider.autoDispose.family<List<RankingEntry>, RankingTypeParams>(
  (ref, params) async {
    final rankingService = ref.watch(rankingServiceProvider);
    return await rankingService.getRankingByType(
      params.type,
      limit: params.limit,
    );
  },
);

// Get ranking entries by type in real-time
final rankingEntriesStreamProvider =
    StreamProvider.autoDispose.family<List<RankingEntry>, RankingTypeParams>(
  (ref, params) {
    final rankingService = ref.watch(rankingServiceProvider);
    return rankingService.getRankingByTypeStream(
      params.type,
      limit: params.limit,
    );
  },
);

// Get user's rank in a specific ranking type
final userRankInTypeProvider = FutureProvider.autoDispose
    .family<int?, RankingType>((ref, rankingType) async {
  final auth = ref.watch(userAuthStateProvider);
  final rankingService = ref.watch(rankingServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    return null;
  }

  return await rankingService.getUserRankInType(userId, rankingType);
});

// Get nearby ranking entries (user's position ±5)
final nearbyRankingEntriesProvider = FutureProvider.autoDispose
    .family<List<RankingEntry>, RankingType>((ref, rankingType) async {
  final auth = ref.watch(userAuthStateProvider);
  final rankingService = ref.watch(rankingServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    return [];
  }

  return await rankingService.getNearbyRankingEntries(userId, rankingType);
});

// Update ranking settings action
final updateRankingSettingsProvider = FutureProvider.family.autoDispose<
    void,
    UpdateRankingSettingsParams>((ref, params) async {
  final auth = ref.watch(userAuthStateProvider);
  final rankingService = ref.watch(rankingServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    throw Exception('ユーザーが見つかりません');
  }

  await rankingService.updateRankingSettings(
    userId,
    isNamePublic: params.isNamePublic,
    participateInRanking: params.participateInRanking,
  );

  // Refresh ranking settings after update
  ref.invalidate(rankingSettingsProvider);
});

// Get monthly ranking by group type
final monthlyRankingProvider =
    FutureProvider.autoDispose.family<List<RankingEntry>, RankingGroupType>(
  (ref, groupType) async {
    final rankingService = ref.watch(rankingServiceProvider);
    return await rankingService.getMonthlyRanking(groupType);
  },
);

// Get friends-only monthly ranking (group_value = 自分の child_id が必須)
final friendsRankingProvider =
    FutureProvider.autoDispose.family<List<RankingEntry>, String>(
  (ref, childId) async {
    final rankingService = ref.watch(rankingServiceProvider);
    return await rankingService.getMonthlyRanking(
      RankingGroupType.friends,
      groupValue: childId,
    );
  },
);

// Parameters for ranking type and limit
class RankingTypeParams {
  final RankingType type;
  final int limit;

  RankingTypeParams({
    required this.type,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankingTypeParams &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          limit == other.limit;

  @override
  int get hashCode => type.hashCode ^ limit.hashCode;
}

// Parameters for updating ranking settings
class UpdateRankingSettingsParams {
  final bool isNamePublic;
  final bool participateInRanking;

  UpdateRankingSettingsParams({
    required this.isNamePublic,
    required this.participateInRanking,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateRankingSettingsParams &&
          runtimeType == other.runtimeType &&
          isNamePublic == other.isNamePublic &&
          participateInRanking == other.participateInRanking;

  @override
  int get hashCode =>
      isNamePublic.hashCode ^ participateInRanking.hashCode;
}
