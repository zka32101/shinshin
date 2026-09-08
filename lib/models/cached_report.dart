/// キャッシュ用の月次レポートモデル
/// 親向けレポートをオフラインで表示するための情報を保持
class CachedReport {
  final String id;
  final String childId;
  final int month;
  final int year;

  // 学習統計
  final int storiesCompleted;
  final int totalStudyMinutes;
  final int totalPointsEarned;

  // 徳目スコア
  final double kindnessScore;
  final double honestyScore;
  final double courageScore;
  final double respectScore;
  final double cooperationScore;
  final double responsibilityScore;

  // AI コメント
  final String? highlightComment;
  final String? growthComment;
  final String? adviceComment;
  final String? parentMessage;

  final DateTime cachedAt;
  final DateTime generatedAt;

  const CachedReport({
    required this.id,
    required this.childId,
    required this.month,
    required this.year,
    this.storiesCompleted = 0,
    this.totalStudyMinutes = 0,
    this.totalPointsEarned = 0,
    this.kindnessScore = 50.0,
    this.honestyScore = 50.0,
    this.courageScore = 50.0,
    this.respectScore = 50.0,
    this.cooperationScore = 50.0,
    this.responsibilityScore = 50.0,
    this.highlightComment,
    this.growthComment,
    this.adviceComment,
    this.parentMessage,
    required this.cachedAt,
    required this.generatedAt,
  });

  /// Hive 保存用に JSON 形式に変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'month': month,
    'year': year,
    'storiesCompleted': storiesCompleted,
    'totalStudyMinutes': totalStudyMinutes,
    'totalPointsEarned': totalPointsEarned,
    'kindnessScore': kindnessScore,
    'honestyScore': honestyScore,
    'courageScore': courageScore,
    'respectScore': respectScore,
    'cooperationScore': cooperationScore,
    'responsibilityScore': responsibilityScore,
    'highlightComment': highlightComment,
    'growthComment': growthComment,
    'adviceComment': adviceComment,
    'parentMessage': parentMessage,
    'cachedAt': cachedAt.toIso8601String(),
    'generatedAt': generatedAt.toIso8601String(),
  };

  /// JSON から復元
  factory CachedReport.fromJson(Map<String, dynamic> json) => CachedReport(
    id: json['id'] as String,
    childId: json['childId'] as String,
    month: json['month'] as int,
    year: json['year'] as int,
    storiesCompleted: json['storiesCompleted'] as int? ?? 0,
    totalStudyMinutes: json['totalStudyMinutes'] as int? ?? 0,
    totalPointsEarned: json['totalPointsEarned'] as int? ?? 0,
    kindnessScore: (json['kindnessScore'] as num?)?.toDouble() ?? 50.0,
    honestyScore: (json['honestyScore'] as num?)?.toDouble() ?? 50.0,
    courageScore: (json['courageScore'] as num?)?.toDouble() ?? 50.0,
    respectScore: (json['respectScore'] as num?)?.toDouble() ?? 50.0,
    cooperationScore: (json['cooperationScore'] as num?)?.toDouble() ?? 50.0,
    responsibilityScore: (json['responsibilityScore'] as num?)?.toDouble() ?? 50.0,
    highlightComment: json['highlightComment'] as String?,
    growthComment: json['growthComment'] as String?,
    adviceComment: json['adviceComment'] as String?,
    parentMessage: json['parentMessage'] as String?,
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    generatedAt: DateTime.parse(json['generatedAt'] as String),
  );

  /// キャッシュが有効かどうか（90日以内なら有効）
  bool isValid() {
    final ttl = Duration(days: 90);
    return DateTime.now().difference(cachedAt) < ttl;
  }
}
