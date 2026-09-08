/// キャッシュ用のバッジモデル
/// 獲得済みバッジ情報をオフラインで表示するために保持
class CachedBadge {
  final String badgeId;
  final DateTime earnedAt;

  const CachedBadge({
    required this.badgeId,
    required this.earnedAt,
  });

  /// Hive 保存用に JSON 形式に変換
  Map<String, dynamic> toJson() => {
    'badgeId': badgeId,
    'earnedAt': earnedAt.toIso8601String(),
  };

  /// JSON から復元
  factory CachedBadge.fromJson(Map<String, dynamic> json) => CachedBadge(
    badgeId: json['badgeId'] as String,
    earnedAt: DateTime.parse(json['earnedAt'] as String),
  );
}

/// 子どものバッジ情報をキャッシュするモデル
class CachedBadgeData {
  final String id;
  final String childId;
  final List<CachedBadge> earned;
  final DateTime cachedAt;

  const CachedBadgeData({
    required this.id,
    required this.childId,
    required this.earned,
    required this.cachedAt,
  });

  /// Hive 保存用に JSON 形式に変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'earned': (earned).map((b) => b.toJson()).toList(),
    'cachedAt': cachedAt.toIso8601String(),
  };

  /// JSON から復元
  factory CachedBadgeData.fromJson(Map<String, dynamic> json) {
    final List<CachedBadge> earned = [];
    if (json['earned'] is List) {
      for (final item in json['earned'] as List) {
        if (item is Map<String, dynamic>) {
          earned.add(CachedBadge.fromJson(item));
        }
      }
    }
    return CachedBadgeData(
      id: json['id'] as String,
      childId: json['childId'] as String,
      earned: earned,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  /// キャッシュが有効かどうか（30日以内なら有効）
  bool isValid() {
    final ttl = Duration(days: 30);
    return DateTime.now().difference(cachedAt) < ttl;
  }
}
