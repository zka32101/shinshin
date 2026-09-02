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
@JsonSerializable()
class StoryContent {
  /// Introduction paragraph (first page)
  final String introduction;

  /// Main narrative pages (middle pages before dilemma)
  final List<String> mainNarrative;

  /// The dilemma scene where the child must make a choice
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
@JsonSerializable()
class StoryChoice {
  /// Unique identifier for this choice
  final String id;

  /// The choice text displayed to the child (e.g., "友達を助ける")
  final String text;

  /// Virtue value represented by this choice: "kindness", "honesty", etc.
  /// Note: Can be null from some API versions
  final String? value;

  /// The story continuation that results from choosing this option
  final String branchContent;

  /// Reflection/learning point explaining why this choice was good or what it teaches
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
