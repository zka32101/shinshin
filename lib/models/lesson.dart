// ──────────────────────────────────────────────────────────────────────────────
// Lesson — 「学ぶ」メニューで表示する解説記事のマスタデータ
// ──────────────────────────────────────────────────────────────────────────────
//
// バッジ定義（badge.dart の BadgeDefinition）と同じ考え方で、記事本文はアプリ
// バンドル内に静的に持つ（lib/data/lesson_data.dart）。Firestore には保存せず、
// 「読んだかどうか」だけを端末のローカルストレージで管理する
// （lib/providers/lesson_provider.dart 参照）。

/// 1つの解説記事を構成するセクション（見出し＋本文の組）。
/// 見出しなしの導入文だけのセクションも作れるよう heading は省略可能。
class LessonSection {
  final String? heading;
  final String body;

  const LessonSection({this.heading, required this.body});
}

/// 解説記事1本分のマスタ定義。
class Lesson {
  final String id;
  final String title;

  /// 対象の徳目テーマ（badge.dart の BadgeDefinition.theme と同じ語彙）
  /// "kindness", "honesty", "courage", "respect", "cooperation", "responsibility"
  final String theme;
  final String emoji;

  /// 記事一覧でのひとことリード文
  final String summary;

  /// 読了目安（分）
  final int estimatedReadMinutes;
  final List<LessonSection> sections;

  const Lesson({
    required this.id,
    required this.title,
    required this.theme,
    required this.emoji,
    required this.summary,
    required this.estimatedReadMinutes,
    required this.sections,
  });
}

/// 徳目テーマの日本語ラベル（badge_showcase_screen.dart の themeLabels と揃える）
const Map<String, String> kLessonThemeLabels = {
  'kindness': '思いやり',
  'honesty': '正直',
  'courage': '勇気',
  'respect': '礼儀',
  'cooperation': '協力',
  'responsibility': '責任',
};

/// レッスン ID からマスタ定義を検索するヘルパー。見つからない場合は null を返す。
Lesson? findLesson(String lessonId, List<Lesson> lessons) {
  try {
    return lessons.firstWhere((l) => l.id == lessonId);
  } catch (_) {
    return null;
  }
}
