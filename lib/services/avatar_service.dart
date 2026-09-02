import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/avatar.dart';
import 'logger_service.dart';

/// アバターサービス
/// アバターデータの管理、購入履歴、ユーザーのアバター選択を統括
class AvatarService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  final LoggerService _logger = LoggerService();

  // デフォルトアバターのID（最初の4つ）
  static const List<String> DEFAULT_AVATAR_IDS = [
    'avatar_001', // かわいい子犬
    'avatar_002', // 元気な男の子
    'avatar_003', // やさしい女の子
    'avatar_004', // かしこいふくろう
  ];

  // すべてのアバターマスターデータ
  static const List<Map<String, dynamic>> AVATARS = [
    {
      'id': 'avatar_001',
      'name': 'かわいい子犬',
      'description': '元気いっぱいの子犬。学習をサポートします',
      'imagePath': 'assets/images/avatars/avatar_001.png',
      'isDefault': true,
      'price': null,
      'order': 1,
    },
    {
      'id': 'avatar_002',
      'name': '元気な男の子',
      'description': 'いつも明るく応援してくれる男の子',
      'imagePath': 'assets/images/avatars/avatar_002.png',
      'isDefault': true,
      'price': null,
      'order': 2,
    },
    {
      'id': 'avatar_003',
      'name': 'やさしい女の子',
      'description': 'あたたかく見守ってくれる女の子',
      'imagePath': 'assets/images/avatars/avatar_003.png',
      'isDefault': true,
      'price': null,
      'order': 3,
    },
    {
      'id': 'avatar_004',
      'name': 'かしこいふくろう',
      'description': '物知りで頼りになるふくろう',
      'imagePath': 'assets/images/avatars/avatar_004.png',
      'isDefault': true,
      'price': null,
      'order': 4,
    },
    {
      'id': 'avatar_005',
      'name': '宇宙人パルル',
      'description': 'エイリアンの友達。未来からやってきた',
      'imagePath': 'assets/images/avatars/avatar_005.png',
      'isDefault': false,
      'price': 120,
      'order': 5,
    },
    {
      'id': 'avatar_006',
      'name': 'ロボット太郎',
      'description': 'いつも正確にサポートするロボット',
      'imagePath': 'assets/images/avatars/avatar_006.png',
      'isDefault': false,
      'price': 120,
      'order': 6,
    },
    {
      'id': 'avatar_007',
      'name': '恐竜ティラ',
      'description': '力強く応援する、やさしい恐竜',
      'imagePath': 'assets/images/avatars/avatar_007.png',
      'isDefault': false,
      'price': 120,
      'order': 7,
    },
    {
      'id': 'avatar_008',
      'name': '魔法少女ミア',
      'description': '魔法で不可能を可能にする',
      'imagePath': 'assets/images/avatars/avatar_008.png',
      'isDefault': false,
      'price': 150,
      'order': 8,
    },
  ];

  AvatarService() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  /// すべてのアバターを取得
  Future<List<Avatar>> getAllAvatars() async {
    try {
      final avatars = AVATARS
          .map((data) => Avatar(
                id: data['id'],
                name: data['name'],
                description: data['description'],
                imagePath: data['imagePath'],
                isDefault: data['isDefault'],
                price: data['price'],
                order: data['order'],
              ))
          .toList();

      avatars.sort((a, b) => a.order.compareTo(b.order));
      return avatars;
    } catch (e) {
      _logger.logError('Failed to get avatars', e);
      rethrow;
    }
  }

  /// デフォルトアバターを取得
  Future<List<Avatar>> getDefaultAvatars() async {
    try {
      final allAvatars = await getAllAvatars();
      return allAvatars.where((a) => a.isDefault).toList();
    } catch (e) {
      _logger.logError('Failed to get default avatars', e);
      rethrow;
    }
  }

  /// 購入可能なアバターを取得
  Future<List<Avatar>> getPurchasableAvatars() async {
    try {
      final allAvatars = await getAllAvatars();
      return allAvatars.where((a) => a.isPurchasable).toList();
    } catch (e) {
      _logger.logError('Failed to get purchasable avatars', e);
      rethrow;
    }
  }

  /// ユーザーのアバター情報を初期化（新規ユーザー）
  Future<void> initializeUserAvatarInfo(String userId) async {
    try {
      final userAvatarInfo = UserAvatarInfo(
        userId: userId,
        selectedAvatarId: DEFAULT_AVATAR_IDS[0], // 最初のデフォルトアバターを選択
        purchasedAvatarIds: [], // デフォルトは自動的に購入済み扱い
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('avatar')
          .set(userAvatarInfo.toJson());

      _logger.log('Avatar info initialized for user: $userId');
    } catch (e) {
      _logger.logError('Failed to initialize avatar info for user: $userId', e);
      rethrow;
    }
  }

  /// ユーザーのアバター情報を取得
  Future<UserAvatarInfo?> getUserAvatarInfo(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('avatar')
          .get();

      if (!doc.exists) {
        return null;
      }

      return UserAvatarInfo.fromJson(doc.data()!);
    } catch (e) {
      _logger.logError('Failed to get avatar info for user: $userId', e);
      rethrow;
    }
  }

  /// ユーザーのアバター情報をストリーム取得
  Stream<UserAvatarInfo?> getUserAvatarInfoStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('avatar')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }
      return UserAvatarInfo.fromJson(doc.data()!);
    });
  }

  /// アバターを選択
  Future<void> selectAvatar(String userId, String avatarId) async {
    try {
      final userAvatarInfo = await getUserAvatarInfo(userId);

      if (userAvatarInfo == null) {
        _logger.logError('User avatar info not found', Exception());
        throw Exception('ユーザーアバター情報が見つかりません');
      }

      // 選択したアバターが所持しているかチェック
      final avatar = (await getAllAvatars()).firstWhere(
        (a) => a.id == avatarId,
        orElse: () => throw Exception('アバターが見つかりません'),
      );

      if (!userAvatarInfo.isOwnedAvatar(avatar)) {
        throw Exception('このアバターはまだ購入していません');
      }

      final updatedInfo = UserAvatarInfo(
        userId: userId,
        selectedAvatarId: avatarId,
        purchasedAvatarIds: userAvatarInfo.purchasedAvatarIds,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('avatar')
          .update(updatedInfo.toJson());

      _logger.log('Avatar selected: $avatarId for user: $userId');
    } catch (e) {
      _logger.logError('Failed to select avatar', e);
      rethrow;
    }
  }

  /// アバターを購入
  Future<void> purchaseAvatar(
    String userId,
    String avatarId,
    String transactionId,
    int amount,
  ) async {
    try {
      final userAvatarInfo = await getUserAvatarInfo(userId);

      if (userAvatarInfo == null) {
        throw Exception('ユーザーアバター情報が見つかりません');
      }

      // すでに購入済みかチェック
      if (userAvatarInfo.purchasedAvatarIds.contains(avatarId)) {
        throw Exception('このアバターはすでに購入済みです');
      }

      // アバターの存在確認
      final avatar = (await getAllAvatars()).firstWhere(
        (a) => a.id == avatarId,
        orElse: () => throw Exception('アバターが見つかりません'),
      );

      if (avatar.isDefault) {
        throw Exception('デフォルトアバターは購入できません');
      }

      // 購入トランザクションを記録
      final transaction = AvatarPurchaseTransaction(
        transactionId: transactionId,
        userId: userId,
        avatarId: avatarId,
        amount: amount,
        purchasedAt: DateTime.now(),
        receiptVerified: false, // バックエンドで検証待ち
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('avatar_purchases')
          .doc(transactionId)
          .set(transaction.toJson());

      // ユーザーのアバター情報を更新
      final updatedPurchasedIds = [
        ...userAvatarInfo.purchasedAvatarIds,
        avatarId,
      ];

      final updatedInfo = UserAvatarInfo(
        userId: userId,
        selectedAvatarId: userAvatarInfo.selectedAvatarId,
        purchasedAvatarIds: updatedPurchasedIds,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('avatar')
          .update(updatedInfo.toJson());

      _logger.log('Avatar purchased: $avatarId for user: $userId');
    } catch (e) {
      _logger.logError('Failed to purchase avatar', e);
      rethrow;
    }
  }

  /// 購入履歴を取得
  Future<List<AvatarPurchaseTransaction>> getPurchaseHistory(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('avatar_purchases')
          .orderBy('purchasedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AvatarPurchaseTransaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.logError('Failed to get purchase history for user: $userId', e);
      rethrow;
    }
  }
}
