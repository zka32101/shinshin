import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_model.freezed.dart';
part 'analytics_model.g.dart';

@freezed
class DailyStats with _$DailyStats {
  const factory DailyStats({
    required String date, // YYYY-MM-DD
    required int questsCompleted,
    required int correctAnswers,
    required int totalAnswers,
    required int coinsEarned,
    required int studyMinutes,
    required Map<String, dynamic> categoryStats, // {categoryId: {correct, total}}
  }) = _DailyStats;

  factory DailyStats.fromJson(Map<String, dynamic> json) =>
      _$DailyStatsFromJson(json);
}

@freezed
class MonthlyStats with _$MonthlyStats {
  const factory MonthlyStats({
    required String month, // YYYY-MM
    required int totalQuestsCompleted,
    required int totalCorrectAnswers,
    required int totalAnswers,
    required double accuracyRate, // 0.0 ~ 1.0
    required int totalStudyMinutes,
    required int totalCoinsEarned,
    required int studyDaysCount, // 学習した日数
    required Map<String, dynamic> categoryStats, // {categoryId: {correct, total, accuracy}}
  }) = _MonthlyStats;

  factory MonthlyStats.fromJson(Map<String, dynamic> json) =>
      _$MonthlyStatsFromJson(json);

  double get accuracyPercentage => accuracyRate * 100;
}
