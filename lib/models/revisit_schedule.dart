import 'package:json_annotation/json_annotation.dart';

part 'revisit_schedule.g.dart';

@JsonSerializable()
class RevisitStory {
  final String revisitId;
  final String storyId;
  final String title;
  final String originalAnswer;
  final String preview;

  RevisitStory({
    required this.revisitId,
    required this.storyId,
    required this.title,
    required this.originalAnswer,
    required this.preview,
  });

  factory RevisitStory.fromJson(Map<String, dynamic> json) =>
      _$RevisitStoryFromJson(json);
  Map<String, dynamic> toJson() => _$RevisitStoryToJson(this);
}

@JsonSerializable()
class RevisitResult {
  final String originalChoice;
  final String currentChoice;
  final bool isChanged;
  final String message;

  RevisitResult({
    required this.originalChoice,
    required this.currentChoice,
    required this.isChanged,
    required this.message,
  });

  factory RevisitResult.fromJson(Map<String, dynamic> json) =>
      _$RevisitResultFromJson(json);
  Map<String, dynamic> toJson() => _$RevisitResultToJson(this);
}
