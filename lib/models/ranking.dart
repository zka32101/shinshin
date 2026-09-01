import 'package:json_annotation/json_annotation.dart';

part 'ranking.g.dart';

/// ランキングエントリ
@JsonSerializable()
class RankingEntry {
  /// ユーザーID
  final String userId;

  /// ユーザー名
  final String userName;

  /// スコア（ポイント数など）
  final int score;

  /// 順位
  final int rank;

  /// 更新日時
  final DateTime updatedAt;

  /// 名前を公表するか
  final bool isNamePublic;

  const RankingEntry({
    required this.userId,
    required this.userName,
    required this.score,
    required this.rank,
    required this.updatedAt,
    this.isNamePublic = false,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) =>
      _$RankingEntryFromJson(json);

  Map<String, dynamic> toJson() => _$RankingEntryToJson(this);

  /// 表示用の名前を取得（プライバシー設定に従う）
  String getDisplayName() => isNamePublic ? userName : 'ユーザー';

  @override
  String toString() =>
      'RankingEntry(rank: $rank, score: $score, isNamePublic: $isNamePublic)';
}

/// ランキングタイプ
enum RankingType {
  /// 総ポイント
  totalPoints,

  /// 月間ポイント
  monthlyPoints,

  /// 徳目別ランキング（思いやり）
  virtueCompassion,

  /// 徳目別ランキング（正直）
  virtueHonesty,

  /// 徳目別ランキング（責任）
  virtueResponsibility,

  /// 徳目別ランキング（勇気）
  virtueCourage,

  /// 徳目別ランキング（尊重）
  virtueRespect,

  /// 徳目別ランキング（協力）
  virtueCooperation,
}

/// ランキング表示設定
@JsonSerializable()
class RankingSettings {
  /// ユーザーID
  final String userId;

  /// 名前を公表するか
  bool isNamePublic;

  /// ランキングに参加するか
  bool participateInRanking;

  /// 更新日時
  final DateTime updatedAt;

  RankingSettings({
    required this.userId,
    this.isNamePublic = false,
    this.participateInRanking = true,
    required this.updatedAt,
  });

  factory RankingSettings.fromJson(Map<String, dynamic> json) =>
      _$RankingSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$RankingSettingsToJson(this);

  @override
  String toString() =>
      'RankingSettings(isNamePublic: $isNamePublic, participateInRanking: $participateInRanking)';
}

/// ランキング統計
@JsonSerializable()
class RankingStats {
  /// ユーザーID
  final String userId;

  /// 総ポイントランキングでの順位
  final int? totalPointsRank;

  /// 総ポイント
  final int totalScore;

  /// 月間ポイントランキングでの順位
  final int? monthlyPointsRank;

  /// 月間ポイント
  final int monthlyScore;

  /// 各徳目のスコア
  final Map<String, int> virtueScores;

  /// 最終更新日時
  final DateTime updatedAt;

  RankingStats({
    required this.userId,
    this.totalPointsRank,
    required this.totalScore,
    this.monthlyPointsRank,
    required this.monthlyScore,
    this.virtueScores = const {},
    required this.updatedAt,
  });

  factory RankingStats.fromJson(Map<String, dynamic> json) =>
      _$RankingStatsFromJson(json);

  Map<String, dynamic> toJson() => _$RankingStatsToJson(this);

  @override
  String toString() =>
      'RankingStats(totalPointsRank: $totalPointsRank, monthlyPointsRank: $monthlyPointsRank)';
}
