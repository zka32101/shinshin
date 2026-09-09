import 'package:json_annotation/json_annotation.dart';

part 'story.g.dart';

/// Story model representing a moral education narrative
/// Stories guide children through ethical dilemmas with branching choices
@JsonSerializable()
class Story {
  /// Unique identifier for the story
  final String id;

  /// Story title displayed to the user
  final String title;

  /// Short description/preview (from list endpoint only)
  final String? description;

  /// Virtue theme: "kindness", "honesty", "courage", "respect", "cooperation", "responsibility"
  final String theme;

  /// Grade level: 3 or 4 (小学3-4年生)
  final int gradeLevel;

  /// Difficulty level: 1-3 (1=easy, 3=hard)
  final int difficulty;

  /// Whether this story is premium content
  final bool isPremium;

  /// Full story content (null when loaded from list endpoint, loaded on detail fetch)
  final StoryContent? content;

  /// Estimated reading time in seconds
  final int durationSeconds;

  /// URL to the story's illustration/cover image
  final String? illustrationUrl;

  /// Timestamp when story was created
  final DateTime createdAt;

  /// Timestamp when story was last updated
  final DateTime updatedAt;

  /// Story version number for tracking content updates
  final int version;

  Story({
    required this.id,
    required this.title,
    this.description,
    required this.theme,
    required this.gradeLevel,
    this.difficulty = 1,
    required this.isPremium,
    this.content,
    required this.durationSeconds,
    this.illustrationUrl,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
  Map<String, dynamic> toJson() => _$StoryToJson(this);
}

/// Full content of a story with narrative pages and choices
/// Used by the story learning screen to guide the user through the narrative
///
/// ふりがな対応マークアップ形式: {漢字|ふりがな}
/// 例: "小{学生|がくせい}のゆうたは、{朝|あさ}{学校|がっこう}へ向かった。"
/// UI側で FuriganaText widget を使用してマークアップを解析・表示
@JsonSerializable()
class StoryContent {
  /// Introduction paragraph (first page)
  /// マークアップ例: "{日常|にちじょう}の{ジレンマ|じれんま}"
  final String introduction;

  /// Main narrative pages (middle pages before dilemma)
  /// マークアップ例: ["小{学生|がくせい}の{太郎|たろう}は…"]
  final List<String> mainNarrative;

  /// The dilemma scene where the child must make a choice
  /// マークアップ例: "{友達|ともだち}を{助|たす}けるか、{正直|しょうじき}に{言|い}うか…"
  final String dilemmaScene;

  /// Available choices for how to handle the dilemma (3-4 options)
  final List<StoryChoice> choices;

  /// URL to the story's full illustration
  final String? illustrationUrl;

  StoryContent({
    required this.introduction,
    required this.mainNarrative,
    required this.dilemmaScene,
    required this.choices,
    this.illustrationUrl,
  });

  factory StoryContent.fromJson(Map<String, dynamic> json) =>
      _$StoryContentFromJson(json);
  Map<String, dynamic> toJson() => _$StoryContentToJson(this);
}

/// A choice option in a story's dilemma
/// Each choice leads to different branching content and teaches different virtues
///
/// ふりがな対応マークアップ形式: {漢字|ふりがな}
/// UI側で FuriganaText widget を使用してマークアップを解析・表示
@JsonSerializable()
class StoryChoice {
  /// Unique identifier for this choice
  final String id;

  /// The choice text displayed to the child
  /// マークアップ例: "{勇気|ゆうき}を{出|だ}して{言|い}う"
  /// マークアップ例: "{親切|しんせつ}に{聞|き}く"
  /// マークアップ例: "{正直|しょうじき}に{話|はなし}す"
  final String text;

  /// Virtue value represented by this choice: "kindness", "honesty", etc.
  /// Note: Can be null from some API versions
  final String? value;

  /// The story continuation that results from choosing this option
  /// マークアップ例: "{太郎|たろう}は{勇気|ゆうき}を{出|だ}して…"
  final String branchContent;

  /// Reflection/learning point explaining why this choice was good or what it teaches
  /// マークアップ例: "{勇気|ゆうき}を{出|だ}すことは{大切|たいせつ}です。"
  final String reflection;

  StoryChoice({
    required this.id,
    required this.text,
    this.value,
    required this.branchContent,
    required this.reflection,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) =>
      _$StoryChoiceFromJson(json);
  Map<String, dynamic> toJson() => _$StoryChoiceToJson(this);
}
