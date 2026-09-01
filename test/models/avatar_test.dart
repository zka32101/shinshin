import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/avatar.dart';

void main() {
  group('Avatar Model', () {
    test('Avatar creation with default values', () {
      final avatar = Avatar(
        id: 'avatar_001',
        name: 'かわいい子犬',
        description: '元気いっぱいの子犬',
        imagePath: 'assets/images/avatars/avatar_001.png',
        isDefault: true,
        order: 1,
      );

      expect(avatar.id, 'avatar_001');
      expect(avatar.name, 'かわいい子犬');
      expect(avatar.isDefault, isTrue);
      expect(avatar.isPurchasable, isFalse); // Default avatar is not purchasable
    });

    test('Avatar creation as purchasable', () {
      final avatar = Avatar(
        id: 'avatar_005',
        name: '宇宙人パルル',
        description: 'エイリアンの友達',
        imagePath: 'assets/images/avatars/avatar_005.png',
        isDefault: false,
        price: 120,
        order: 5,
      );

      expect(avatar.isDefault, isFalse);
      expect(avatar.price, 120);
      expect(avatar.isPurchasable, isTrue);
    });

    test('Avatar JSON serialization', () {
      final avatar = Avatar(
        id: 'avatar_001',
        name: 'かわいい子犬',
        description: '元気いっぱいの子犬',
        imagePath: 'assets/images/avatars/avatar_001.png',
        isDefault: true,
        order: 1,
      );

      final json = avatar.toJson();
      expect(json['id'], 'avatar_001');
      expect(json['name'], 'かわいい子犬');
      expect(json['isDefault'], isTrue);
    });

    test('Avatar JSON deserialization', () {
      final json = {
        'id': 'avatar_001',
        'name': 'かわいい子犬',
        'description': '元気いっぱいの子犬',
        'imagePath': 'assets/images/avatars/avatar_001.png',
        'isDefault': true,
        'price': null,
        'order': 1,
      };

      final avatar = Avatar.fromJson(json);
      expect(avatar.id, 'avatar_001');
      expect(avatar.name, 'かわいい子犬');
      expect(avatar.isDefault, isTrue);
    });
  });

  group('UserAvatarInfo Model', () {
    test('UserAvatarInfo creation', () {
      final info = UserAvatarInfo(
        userId: 'user_123',
        selectedAvatarId: 'avatar_001',
        purchasedAvatarIds: ['avatar_005', 'avatar_006'],
        lastUpdated: DateTime(2024, 1, 1),
      );

      expect(info.userId, 'user_123');
      expect(info.selectedAvatarId, 'avatar_001');
      expect(info.purchasedAvatarIds.length, 2);
    });

    test('UserAvatarInfo isOwnedAvatar for default avatar', () {
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

    test('UserAvatarInfo isOwnedAvatar for purchased avatar', () {
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

    test('UserAvatarInfo isOwnedAvatar for unpurchased avatar', () {
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
  });

  group('AvatarPurchaseTransaction Model', () {
    test('AvatarPurchaseTransaction creation', () {
      final now = DateTime.now();
      final transaction = AvatarPurchaseTransaction(
        transactionId: 'txn_001',
        userId: 'user_123',
        avatarId: 'avatar_005',
        amount: 120,
        purchasedAt: now,
        receiptVerified: true,
      );

      expect(transaction.transactionId, 'txn_001');
      expect(transaction.amount, 120);
      expect(transaction.receiptVerified, isTrue);
    });

    test('AvatarPurchaseTransaction JSON serialization', () {
      final transaction = AvatarPurchaseTransaction(
        transactionId: 'txn_001',
        userId: 'user_123',
        avatarId: 'avatar_005',
        amount: 120,
        purchasedAt: DateTime(2024, 1, 1),
        receiptVerified: false,
      );

      final json = transaction.toJson();
      expect(json['transactionId'], 'txn_001');
      expect(json['amount'], 120);
      expect(json['receiptVerified'], isFalse);
    });
  });
}
