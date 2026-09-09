/// 友だち（同じアプリを使う他の子ども）
///
/// バックエンドの `/api/v1/friends` レスポンス（camelCase）をそのまま扱う。
/// JSON 変換は手書きにしている（build_runner のコード生成に依存しない）。
class Friend {
  /// 友だち関係レコードのID（削除時に使用）
  final String friendId;

  /// 友だち側の子どもID
  final String childId;

  /// 友だちの名前
  final String name;

  /// 友だちのアバター絵文字
  final String avatarEmoji;

  /// 友だちの学年
  final int grade;

  /// 友だちのレベル
  final int level;

  /// 友だちになった日時
  final DateTime createdAt;

  const Friend({
    required this.friendId,
    required this.childId,
    required this.name,
    required this.avatarEmoji,
    required this.grade,
    required this.level,
    required this.createdAt,
  });

  /// バックエンド API レスポンスから生成
  ///
  /// フィールドごとにデフォルト値を設定し、仕様変更・欠損フィールドによる
  /// [TypeError] / [FormatException] を防ぐ。
  factory Friend.fromApiJson(Map<String, dynamic> json) {
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['createdAt'] as String? ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }

    return Friend(
      friendId: json['friendId'] as String? ?? '',
      childId: json['childId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarEmoji: json['avatarEmoji'] as String? ?? '🌟',
      grade: (json['grade'] as num?)?.toInt() ?? 3,
      level: (json['level'] as num?)?.toInt() ?? 1,
      createdAt: createdAt,
    );
  }

  /// 学年表示名
  String get gradeDisplayName {
    switch (grade) {
      case 3:
        return '小学3年生';
      case 4:
        return '小学4年生';
      default:
        return '学年未設定';
    }
  }
}
