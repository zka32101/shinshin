import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/services/avatar_service.dart';
import 'package:shougaku_kore_doutoku/models/avatar.dart';

void main() {
  group('AvatarService', () {
    late AvatarService avatarService;

    setUp(() {
      avatarService = AvatarService();
    });

    test('getAllAvatars returns all avatars sorted by order', () async {
      final avatars = await avatarService.getAllAvatars();

      expect(avatars, isNotEmpty);
      expect(avatars.length, 8);

      // Check sorting by order
      for (int i = 0; i < avatars.length - 1; i++) {
        expect(avatars[i].order, lessThanOrEqualTo(avatars[i + 1].order));
      }
    });

    test('getAllAvatars includes default avatars', () async {
      final avatars = await avatarService.getAllAvatars();
      final defaultAvatars = avatars.where((a) => a.isDefault).toList();

      expect(defaultAvatars.length, 4);
      expect(defaultAvatars.every((a) => a.price == null), isTrue);
    });

    test('getAllAvatars includes purchasable avatars', () async {
      final avatars = await avatarService.getAllAvatars();
      final purchasableAvatars = avatars.where((a) => a.isPurchasable).toList();

      expect(purchasableAvatars.length, 4);
      expect(purchasableAvatars.every((a) => !a.isDefault), isTrue);
      expect(purchasableAvatars.every((a) => a.price! > 0), isTrue);
    });

    test('getDefaultAvatars returns only default avatars', () async {
      final defaultAvatars = await avatarService.getDefaultAvatars();

      expect(defaultAvatars.length, 4);
      expect(defaultAvatars.every((a) => a.isDefault), isTrue);
    });

    test('getPurchasableAvatars returns only purchasable avatars', () async {
      final purchasableAvatars = await avatarService.getPurchasableAvatars();

      expect(purchasableAvatars.length, 4);
      expect(purchasableAvatars.every((a) => a.isPurchasable), isTrue);
    });

    test('Avatar ids match DEFAULT_AVATAR_IDS constant', () async {
      final avatars = await avatarService.getAllAvatars();
      final defaultAvatars = avatars.where((a) => a.isDefault).toList();
      final defaultIds = defaultAvatars.map((a) => a.id).toList();

      expect(
        defaultIds,
        AvatarService.DEFAULT_AVATAR_IDS,
      );
    });

    test('Purchasable avatars have valid prices', () async {
      final purchasableAvatars = await avatarService.getPurchasableAvatars();

      for (final avatar in purchasableAvatars) {
        expect(avatar.price, isNotNull);
        expect(avatar.price, greaterThan(0));
      }
    });

    test('All avatars have unique IDs', () async {
      final avatars = await avatarService.getAllAvatars();
      final ids = avatars.map((a) => a.id).toList();
      final uniqueIds = ids.toSet();

      expect(ids.length, uniqueIds.length);
    });

    test('All avatars have valid names and descriptions', () async {
      final avatars = await avatarService.getAllAvatars();

      for (final avatar in avatars) {
        expect(avatar.name, isNotEmpty);
        expect(avatar.description, isNotEmpty);
      }
    });

    test('All avatars have valid image paths', () async {
      final avatars = await avatarService.getAllAvatars();

      for (final avatar in avatars) {
        expect(
          avatar.imagePath,
          startsWith('assets/images/avatars/'),
        );
        expect(avatar.imagePath, endsWith('.png'));
      }
    });

    test('Avatar order values are unique and sequential', () async {
      final avatars = await avatarService.getAllAvatars();
      final orders = avatars.map((a) => a.order).toList();
      final uniqueOrders = orders.toSet();

      expect(orders.length, uniqueOrders.length);
      expect(orders.first, 1);
      expect(orders.last, 8);
    });
  });

  group('Avatar Model', () {
    test('Default avatar is not purchasable', () {
      final avatar = Avatar(
        id: 'avatar_001',
        name: 'かわいい子犬',
        description: '元気いっぱいの子犬',
        imagePath: 'assets/images/avatars/avatar_001.png',
        isDefault: true,
        order: 1,
      );

      expect(avatar.isPurchasable, isFalse);
    });

    test('Purchasable avatar with price is purchasable', () {
      final avatar = Avatar(
        id: 'avatar_005',
        name: '宇宙人パルル',
        description: 'エイリアンの友達',
        imagePath: 'assets/images/avatars/avatar_005.png',
        isDefault: false,
        price: 120,
        order: 5,
      );

      expect(avatar.isPurchasable, isTrue);
    });

    test('Non-default avatar without price is not purchasable', () {
      final avatar = Avatar(
        id: 'avatar_005',
        name: '宇宙人パルル',
        description: 'エイリアンの友達',
        imagePath: 'assets/images/avatars/avatar_005.png',
        isDefault: false,
        price: null,
        order: 5,
      );

      expect(avatar.isPurchasable, isFalse);
    });

    test('Avatar toString includes id and name', () {
      final avatar = Avatar(
        id: 'avatar_001',
        name: 'かわいい子犬',
        description: '元気いっぱいの子犬',
        imagePath: 'assets/images/avatars/avatar_001.png',
        isDefault: true,
        order: 1,
      );

      expect(
        avatar.toString(),
        contains('avatar_001'),
      );
      expect(
        avatar.toString(),
        contains('かわいい子犬'),
      );
    });
  });

  group('UserAvatarInfo Model', () {
    test('isOwnedAvatar returns true for default avatar', () {
      final info = UserAvatarInfo(
        userId: 'user_123',
        selectedAvatarId: 'avatar_001',
        purchasedAvatarIds: [],
      );

      final defaultAvatar = Avatar(
        id: 'avatar_001',
        name: 'かわいい子犬',
        description: '元気いっぱいの子犬',
        imagePath: 'assets/images/avatars/avatar_001.png',
        isDefault: true,
        order: 1,
      );

      expect(info.isOwnedAvatar(defaultAvatar), isTrue);
    });

    test('isOwnedAvatar returns true for purchased avatar', () {
      final info = UserAvatarInfo(
        userId: 'user_123',
        selectedAvatarId: 'avatar_001',
        purchasedAvatarIds: ['avatar_005'],
      );

      final purchasedAvatar = Avatar(
        id: 'avatar_005',
        name: '宇宙人パルル',
        description: 'エイリアンの友達',
        imagePath: 'assets/images/avatars/avatar_005.png',
        isDefault: false,
        price: 120,
        order: 5,
      );

      expect(info.isOwnedAvatar(purchasedAvatar), isTrue);
    });

    test('isOwnedAvatar returns false for unpurchased avatar', () {
      final info = UserAvatarInfo(
        userId: 'user_123',
        selectedAvatarId: 'avatar_001',
        purchasedAvatarIds: [],
      );

      final unpurchasedAvatar = Avatar(
        id: 'avatar_005',
        name: '宇宙人パルル',
        description: 'エイリアンの友達',
        imagePath: 'assets/images/avatars/avatar_005.png',
        isDefault: false,
        price: 120,
        order: 5,
      );

      expect(info.isOwnedAvatar(unpurchasedAvatar), isFalse);
    });

    test('UserAvatarInfo toString includes user id and selected avatar', () {
      final info = UserAvatarInfo(
        userId: 'user_123',
        selectedAvatarId: 'avatar_001',
        purchasedAvatarIds: ['avatar_005', 'avatar_006'],
      );

      expect(info.toString(), contains('user_123'));
      expect(info.toString(), contains('avatar_001'));
    });
  });

  group('AvatarPurchaseTransaction Model', () {
    test('Purchase transaction has correct properties', () {
      final now = DateTime.now();
      final transaction = AvatarPurchaseTransaction(
        transactionId: 'txn_001',
        userId: 'user_123',
        avatarId: 'avatar_005',
        amount: 120,
        purchasedAt: now,
        receiptVerified: false,
      );

      expect(transaction.transactionId, 'txn_001');
      expect(transaction.userId, 'user_123');
      expect(transaction.avatarId, 'avatar_005');
      expect(transaction.amount, 120);
      expect(transaction.purchasedAt, now);
      expect(transaction.receiptVerified, isFalse);
    });

    test('Purchase transaction default receipt verified is false', () {
      final transaction = AvatarPurchaseTransaction(
        transactionId: 'txn_001',
        userId: 'user_123',
        avatarId: 'avatar_005',
        amount: 120,
        purchasedAt: DateTime.now(),
      );

      expect(transaction.receiptVerified, isFalse);
    });

    test('Purchase transaction toString includes avatar id and amount', () {
      final transaction = AvatarPurchaseTransaction(
        transactionId: 'txn_001',
        userId: 'user_123',
        avatarId: 'avatar_005',
        amount: 120,
        purchasedAt: DateTime.now(),
      );

      expect(transaction.toString(), contains('avatar_005'));
      expect(transaction.toString(), contains('120'));
    });
  });
}
