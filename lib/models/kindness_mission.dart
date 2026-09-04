import 'package:json_annotation/json_annotation.dart';

part 'kindness_mission.g.dart';

@JsonSerializable()
class KindnessMission {
  final String missionId;
  final int targetCount;
  final int completedCount;
  final bool isCompleted;
  final DateTime createdAt;

  KindnessMission({
    required this.missionId,
    required this.targetCount,
    required this.completedCount,
    required this.isCompleted,
    required this.createdAt,
  });

  factory KindnessMission.fromJson(Map<String, dynamic> json) =>
      _$KindnessMissionFromJson(json);
  Map<String, dynamic> toJson() => _$KindnessMissionToJson(this);
}

@JsonSerializable()
class KindnessRecord {
  final String recordId;
  final String description;
  final String? personInvolved;
  final String? context;
  final DateTime recordedAt;

  KindnessRecord({
    required this.recordId,
    required this.description,
    this.personInvolved,
    this.context,
    required this.recordedAt,
  });

  factory KindnessRecord.fromJson(Map<String, dynamic> json) =>
      _$KindnessRecordFromJson(json);
  Map<String, dynamic> toJson() => _$KindnessRecordToJson(this);
}

@JsonSerializable()
class KindnessRecordResponse {
  final bool recorded;
  final String progress;
  final bool isMissionComplete;
  final int rewardPoints;

  KindnessRecordResponse({
    required this.recorded,
    required this.progress,
    required this.isMissionComplete,
    required this.rewardPoints,
  });

  factory KindnessRecordResponse.fromJson(Map<String, dynamic> json) =>
      _$KindnessRecordResponseFromJson(json);
  Map<String, dynamic> toJson() => _$KindnessRecordResponseToJson(this);
}

@JsonSerializable()
class KindnessFinding {
  final String description;
  final String? person;

  KindnessFinding({
    required this.description,
    this.person,
  });

  factory KindnessFinding.fromJson(Map<String, dynamic> json) =>
      _$KindnessFindingFromJson(json);
  Map<String, dynamic> toJson() => _$KindnessFindingToJson(this);
}

@JsonSerializable()
class KindnessMap {
  final String month;
  final int totalFindings;
  final Map<String, List<KindnessFinding>> byCategory;
  final String message;

  KindnessMap({
    required this.month,
    required this.totalFindings,
    required this.byCategory,
    required this.message,
  });

  factory KindnessMap.fromJson(Map<String, dynamic> json) =>
      _$KindnessMapFromJson(json);
  Map<String, dynamic> toJson() => _$KindnessMapToJson(this);
}
