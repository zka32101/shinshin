import 'package:json_annotation/json_annotation.dart';

part 'parental_consent.g.dart';

/// 親の同意記録（COPPA準拠）
@JsonSerializable()
class ParentalConsent {
  /// 同意レコードID
  final String id;

  /// 親のUID
  final String parentUid;

  /// 子どものメールアドレス
  final String childEmail;

  /// 同意時刻
  final DateTime consentedAt;

  /// 同意取り下げ時刻（nullの場合は現在有効）
  final DateTime? revokedAt;

  /// プライバシーポリシーのバージョン
  final String privacyPolicyVersion;

  /// 同意内容
  final ConsentPermissions consentTo;

  ParentalConsent({
    required this.id,
    required this.parentUid,
    required this.childEmail,
    required this.consentedAt,
    this.revokedAt,
    required this.privacyPolicyVersion,
    required this.consentTo,
  });

  /// 同意が有効かどうか（取り下げられていない）
  bool get isActive => revokedAt == null;

  factory ParentalConsent.fromJson(Map<String, dynamic> json) =>
      _$ParentalConsentFromJson(json);

  Map<String, dynamic> toJson() => _$ParentalConsentToJson(this);
}

/// 同意の詳細パーミッション
@JsonSerializable()
class ConsentPermissions {
  /// データ処理に対する同意
  final bool dataProcessing;

  /// 第三者共有に対する同意
  final bool thirdPartySharing;

  /// アナリティクス追跡に対する同意
  final bool analyticsTracking;

  ConsentPermissions({
    required this.dataProcessing,
    required this.thirdPartySharing,
    required this.analyticsTracking,
  });

  factory ConsentPermissions.fromJson(Map<String, dynamic> json) =>
      _$ConsentPermissionsFromJson(json);

  Map<String, dynamic> toJson() => _$ConsentPermissionsToJson(this);
}
