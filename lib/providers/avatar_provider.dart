import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/avatar_service.dart';
import '../models/avatar.dart';
import '../providers/auth_provider.dart';

// Service provider
final avatarServiceProvider = Provider((ref) {
  return AvatarService();
});

// Get all avatars
final allAvatarsProvider = FutureProvider.autoDispose((ref) async {
  final avatarService = ref.watch(avatarServiceProvider);
  return await avatarService.getAllAvatars();
});

// Get default avatars
final defaultAvatarsProvider = FutureProvider.autoDispose((ref) async {
  final avatarService = ref.watch(avatarServiceProvider);
  return await avatarService.getDefaultAvatars();
});

// Get purchasable avatars
final purchasableAvatarsProvider = FutureProvider.autoDispose((ref) async {
  final avatarService = ref.watch(avatarServiceProvider);
  return await avatarService.getPurchasableAvatars();
});

// Get user's avatar info stream
final userAvatarInfoProvider = StreamProvider.autoDispose((ref) async* {
  final auth = ref.watch(userAuthStateProvider);
  final avatarService = ref.watch(avatarServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    yield null;
    return;
  }

  yield* avatarService.getUserAvatarInfoStream(userId);
});

// Get currently selected avatar
final selectedAvatarProvider = FutureProvider.autoDispose((ref) async {
  final userAvatarInfo = await ref.watch(userAvatarInfoProvider.future);
  final allAvatars = await ref.watch(allAvatarsProvider.future);

  if (userAvatarInfo == null) {
    return null;
  }

  return allAvatars.firstWhere(
    (a) => a.id == userAvatarInfo.selectedAvatarId,
    orElse: () => allAvatars.first,
  );
});

// Get purchase history
final avatarPurchaseHistoryProvider =
    FutureProvider.autoDispose((ref) async {
  final auth = ref.watch(userAuthStateProvider);
  final avatarService = ref.watch(avatarServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    return [];
  }

  return await avatarService.getPurchaseHistory(userId);
});

// Select avatar action
final selectAvatarProvider =
    FutureProvider.family.autoDispose<void, String>((ref, avatarId) async {
  final auth = ref.watch(userAuthStateProvider);
  final avatarService = ref.watch(avatarServiceProvider);

  final userId = auth.maybeWhen(
    data: (user) => user?.uid,
    orElse: () => null,
  );

  if (userId == null) {
    throw Exception('ユーザーが見つかりません');
  }

  await avatarService.selectAvatar(userId, avatarId);
  // Refresh user avatar info after selection
  ref.invalidate(userAvatarInfoProvider);
});

// Purchase avatar action
final purchaseAvatarProvider =
    FutureProvider.family.autoDispose<void, AvatarPurchaseParams>(
  (ref, params) async {
    final auth = ref.watch(userAuthStateProvider);
    final avatarService = ref.watch(avatarServiceProvider);

    final userId = auth.maybeWhen(
      data: (user) => user?.uid,
      orElse: () => null,
    );

    if (userId == null) {
      throw Exception('ユーザーが見つかりません');
    }

    await avatarService.purchaseAvatar(
      userId,
      params.avatarId,
      params.transactionId,
      params.amount,
    );
    // Refresh user avatar info and purchase history after purchase
    ref.invalidate(userAvatarInfoProvider);
    ref.invalidate(avatarPurchaseHistoryProvider);
  },
);

// Parameters for avatar purchase
class AvatarPurchaseParams {
  final String avatarId;
  final String transactionId;
  final int amount;

  AvatarPurchaseParams({
    required this.avatarId,
    required this.transactionId,
    required this.amount,
  });
}

// Check if avatar is owned by user
final isAvatarOwnedProvider =
    FutureProvider.family.autoDispose<bool, String>((ref, avatarId) async {
  final userAvatarInfo = await ref.watch(userAvatarInfoProvider.future);
  final allAvatars = await ref.watch(allAvatarsProvider.future);

  if (userAvatarInfo == null) {
    return false;
  }

  final avatar =
      allAvatars.firstWhere((a) => a.id == avatarId, orElse: () => null as Avatar);

  if (avatar == null) {
    return false;
  }

  return userAvatarInfo.isOwnedAvatar(avatar);
});
