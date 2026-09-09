import 'package:json_annotation/json_annotation.dart';

part 'child_profile.g.dart';

@JsonSerializable()
class ChildProfile {
  final String id;
  final String parentId;
  final String name;
  final int grade;
  final String avatarEmoji; // 絵文字アバター (例: "🌟")
  final DateTime createdAt;

  /// 友だち追加用の招待コード（8文字の英数字）
  final String? inviteCode;

  // 成長データ
  @JsonKey(defaultValue: 1)
  final int level;
  @JsonKey(defaultValue: 0)
  final int totalPoints;

  // 徳目スコア (0.0 - 100.0)
  @JsonKey(defaultValue: 50.0)
  final double kindnessScore;
  @JsonKey(defaultValue: 50.0)
  final double honestyScore;
  @JsonKey(defaultValue: 50.0)
  final double responsibilityScore;
  @JsonKey(defaultValue: 50.0)
  final double courageScore;
  @JsonKey(defaultValue: 50.0)
  final double respectScore;
  @JsonKey(defaultValue: 50.0)
  final double cooperationScore;

  ChildProfile({
    required this.id,
    required this.parentId,
    required this.name,
    required this.grade,
    this.avatarEmoji = '🌟',
    required this.createdAt,
    this.inviteCode,
    this.level = 1,
    this.totalPoints = 0,
    this.kindnessScore = 50.0,
    this.honestyScore = 50.0,
    this.responsibilityScore = 50.0,
    this.courageScore = 50.0,
    this.respectScore = 50.0,
    this.cooperationScore = 50.0,
  });

  /// 学年表示名
  String get gradeDisplayName {
    switch (grade) {
      case 3: return '小学3年生';
      case 4: return '小学4年生';
      case 5: return '小学5年生';
      case 6: return '小学6年生';
      default: return '学年未設定';
    }
  }

  /// バックエンド API レスポンス（virtueScores ネスト構造）から生成
  ///
  /// API 仕様変更・欠損フィールド・型不一致による [TypeError] / [FormatException] を
  /// 防ぐためフィールドごとにデフォルト値を設定している。
  factory ChildProfile.fromApiJson(Map<String, dynamic> json) {
    final scores = (json['virtueScores'] as Map<String, dynamic>?) ?? {};

    // createdAt が null / 不正文字列の場合は現在時刻にフォールバック
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['createdAt'] as String? ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }

    return ChildProfile(
      id: json['id'] as String? ?? '',
      parentId: json['parentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 3,
      avatarEmoji: json['avatarEmoji'] as String? ?? '🌟',
      createdAt: createdAt,
      inviteCode: json['inviteCode'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      kindnessScore: (scores['kindness'] as num?)?.toDouble() ?? 50.0,
      honestyScore: (scores['honesty'] as num?)?.toDouble() ?? 50.0,
      responsibilityScore: (scores['responsibility'] as num?)?.toDouble() ?? 50.0,
      courageScore: (scores['courage'] as num?)?.toDouble() ?? 50.0,
      respectScore: (scores['respect'] as num?)?.toDouble() ?? 50.0,
      cooperationScore: (scores['cooperation'] as num?)?.toDouble() ?? 50.0,
    );
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) =>
      _$ChildProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ChildProfileToJson(this);
}
