import 'package:json_annotation/json_annotation.dart';

part 'parent_child_comparison.g.dart';

@JsonSerializable()
class ParentChildComparison {
  final String storyId;
  final String storyTitle;
  final String childChoiceLetter;
  final String childChoiceText;
  final String parentChoiceLetter;
  final String parentChoiceText;
  final String guidance;
  final DateTime answeredAt;

  ParentChildComparison({
    required this.storyId,
    required this.storyTitle,
    required this.childChoiceLetter,
    required this.childChoiceText,
    required this.parentChoiceLetter,
    required this.parentChoiceText,
    required this.guidance,
    required this.answeredAt,
  });

  factory ParentChildComparison.fromJson(Map<String, dynamic> json) =>
      _$ParentChildComparisonFromJson(json);
  Map<String, dynamic> toJson() => _$ParentChildComparisonToJson(this);
}

@JsonSerializable()
class ParentAnswerResponse {
  final String parentChoice;
  final String? childChoice;
  final bool isBothAnswered;
  final String? guidance;

  ParentAnswerResponse({
    required this.parentChoice,
    this.childChoice,
    required this.isBothAnswered,
    this.guidance,
  });

  factory ParentAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$ParentAnswerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ParentAnswerResponseToJson(this);
}
