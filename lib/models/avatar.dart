import 'package:json_annotation/json_annotation.dart';

part 'avatar.g.dart';

/// アバターアイコン
@JsonSerializable()
class Avatar {
  /// アバターID (unique)
  final String id;

  /// アバター名
  final String name;

  /// アバターの説明
  final String description;

  /// アバター画像ファイル名（assets/images/avatars/）
  final String imagePath;

  /// デフォルトで購入済みかどうか（最初の4つがデフォルト）
  final bool isDefault;

  /// 購入価格（¥）
  final int? price;

  /// ソート順序
  final int order;

  const Avatar({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.isDefault,
    this.price,
    required this.order,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) => _$AvatarFromJson(json);

  Map<String, dynamic> toJson() => _$AvatarToJson(this);

  /// アバターが購入可能かチェック（デフォルトでない場合）
  bool get isPurchasable => !isDefault && price != null && price! > 0;

  @override
  String toString() => 'Avatar(id: $id, name: $name, isDefault: $isDefault)';
}

/// ユーザーのアバター情報
@JsonSerializable()
class UserAvatarInfo {
  /// ユーザーID
  final String userId;

  /// 選択中のアバターID
  final String selectedAvatarId;

  /// 購入済みアバターID一覧（デフォルトは除外）
  final List<String> purchasedAvatarIds;

  /// 最後に更新された日時
  final DateTime? lastUpdated;

  const UserAvatarInfo({
    required this.userId,
    required this.selectedAvatarId,
    this.purchasedAvatarIds = const [],
    this.lastUpdated,
  });

  factory UserAvatarInfo.fromJson(Map<String, dynamic> json) =>
      _$UserAvatarInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserAvatarInfoToJson(this);

  /// アバターが購入済みかチェック（デフォルトまたは購入済みリストに含まれる）
  bool isOwnedAvatar(Avatar avatar) {
    return avatar.isDefault || purchasedAvatarIds.contains(avatar.id);
  }

  @override
  String toString() =>
      'UserAvatarInfo(userId: $userId, selectedAvatarId: $selectedAvatarId, '
      'purchasedCount: ${purchasedAvatarIds.length})';
}

/// アバター購入トランザクション
@JsonSerializable()
class AvatarPurchaseTransaction {
  /// トランザクションID
  final String transactionId;

  /// ユーザーID
  final String userId;

  /// 購入したアバターID
  final String avatarId;

  /// 購入金額（¥）
  final int amount;

  /// 購入日時
  final DateTime purchasedAt;

  /// レシート検証済みか（Apple/Google）
  final bool receiptVerified;

  const AvatarPurchaseTransaction({
    required this.transactionId,
    required this.userId,
    required this.avatarId,
    required this.amount,
    required this.purchasedAt,
    this.receiptVerified = false,
  });

  factory AvatarPurchaseTransaction.fromJson(Map<String, dynamic> json) =>
      _$AvatarPurchaseTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$AvatarPurchaseTransactionToJson(this);

  @override
  String toString() =>
      'AvatarPurchaseTransaction(avatarId: $avatarId, amount: $amount, '
      'receiptVerified: $receiptVerified)';
}
