import 'package:json_annotation/json_annotation.dart';

part 'distribution_response.g.dart';

@JsonSerializable()
class DistributionOption {
  final String option;
  final String text;
  final int count;
  final double percentage;
  final String color;

  DistributionOption({
    required this.option,
    required this.text,
    required this.count,
    required this.percentage,
    required this.color,
  });

  factory DistributionOption.fromJson(Map<String, dynamic> json) =>
      _$DistributionOptionFromJson(json);
  Map<String, dynamic> toJson() => _$DistributionOptionToJson(this);
}

@JsonSerializable()
class DistributionResponse {
  final String storyId;
  final String? title;
  final List<DistributionOption> options;
  final int totalResponses;
  final DateTime? lastUpdated;

  DistributionResponse({
    required this.storyId,
    this.title,
    required this.options,
    required this.totalResponses,
    this.lastUpdated,
  });

  factory DistributionResponse.fromJson(Map<String, dynamic> json) =>
      _$DistributionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DistributionResponseToJson(this);
}
