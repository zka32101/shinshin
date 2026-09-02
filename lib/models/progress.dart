import 'package:json_annotation/json_annotation.dart';

part 'progress.g.dart';

/// User progress record for tracking learning activities
/// Tracks story completions, badge earnings, and other progress events
@JsonSerializable()
class Progress {
  /// Unique identifier for this progress record
  final String id;

  /// Child ID associated with this progress
  final String childId;

  /// Story ID if this progress is related to a story completion
  final String? storyId;

  /// Action type: "story_completed", "badge_earned", etc.
  final String action;

  /// Virtue value learned: "kindness", "honesty", "courage", etc.
  final String? virtue;

  /// Points earned from this action
  final int pointsDelta;

  /// Number of times this virtue has been completed
  final int completionCount;

  /// Timestamp when this progress was recorded
  final DateTime recordedAt;

  Progress({
    required this.id,
    required this.childId,
    this.storyId,
    required this.action,
    this.virtue,
    this.pointsDelta = 0,
    this.completionCount = 0,
    required this.recordedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) =>
      _$ProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressToJson(this);
}
