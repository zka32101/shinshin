import 'package:json_annotation/json_annotation.dart';

part 'ai_features.g.dart';

@JsonSerializable()
class ReasonAnalysis {
  final String userId;
  final String month;
  final String headline;
  final List<String> observations;
  final String improvementLevel;
  final String parentMessage;

  ReasonAnalysis({
    required this.userId,
    required this.month,
    required this.headline,
    required this.observations,
    required this.improvementLevel,
    required this.parentMessage,
  });

  factory ReasonAnalysis.fromJson(Map<String, dynamic> json) =>
      _$ReasonAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$ReasonAnalysisToJson(this);
}

@JsonSerializable()
class CreationFeedback {
  final String userId;
  final String month;
  final int creationCount;
  final String headline;
  final List<String> observations;
  final String parentTip;

  CreationFeedback({
    required this.userId,
    required this.month,
    required this.creationCount,
    required this.headline,
    required this.observations,
    required this.parentTip,
  });

  factory CreationFeedback.fromJson(Map<String, dynamic> json) =>
      _$CreationFeedbackFromJson(json);
  Map<String, dynamic> toJson() => _$CreationFeedbackToJson(this);
}

@JsonSerializable()
class CreationRecord {
  final String storyId;
  final String storyTitle;
  final String userCreatedEnding;
  final DateTime createdAt;

  CreationRecord({
    required this.storyId,
    required this.storyTitle,
    required this.userCreatedEnding,
    required this.createdAt,
  });

  factory CreationRecord.fromJson(Map<String, dynamic> json) =>
      _$CreationRecordFromJson(json);
  Map<String, dynamic> toJson() => _$CreationRecordToJson(this);
}
