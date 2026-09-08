/// キャッシュ用のストーリーモデル
/// オフラインで表示するための最小限の情報を保持
class CachedStory {
  final String id;
  final String title;
  final String? content; // JSON文字列で保存
  final String theme;
  final String? illustrationUrl;
  final DateTime cachedAt;
  final int durationSeconds;

  const CachedStory({
    required this.id,
    required this.title,
    this.content,
    required this.theme,
    this.illustrationUrl,
    required this.cachedAt,
    this.durationSeconds = 300,
  });

  /// Hive 保存用に JSON 形式に変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'theme': theme,
    'illustrationUrl': illustrationUrl,
    'cachedAt': cachedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
  };

  /// JSON から復元
  factory CachedStory.fromJson(Map<String, dynamic> json) => CachedStory(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String?,
    theme: json['theme'] as String,
    illustrationUrl: json['illustrationUrl'] as String?,
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    durationSeconds: json['durationSeconds'] as int? ?? 300,
  );

  /// キャッシュが有効かどうか（7日以内なら有効）
  bool isValid() {
    final ttl = Duration(days: 7);
    return DateTime.now().difference(cachedAt) < ttl;
  }
}
