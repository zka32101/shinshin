import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, List<DailyStats>?>((ref) {
  return AnalyticsNotifier();
});

class AnalyticsNotifier extends StateNotifier<List<DailyStats>?> {
  AnalyticsNotifier() : super(null);

  /// Save daily stats
  Future<void> recordDailyStats({
    required int questsCompleted,
    required int correctAnswers,
    required int totalAnswers,
    required int coinsEarned,
    required int studyMinutes,
    required Map<String, dynamic> categoryStats,
  }) async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final dailyStats = DailyStats(
        date: dateStr,
        questsCompleted: questsCompleted,
        correctAnswers: correctAnswers,
        totalAnswers: totalAnswers,
        coinsEarned: coinsEarned,
        studyMinutes: studyMinutes,
        categoryStats: categoryStats,
      );

      final currentStats = state ?? [];
      state = [...currentStats, dailyStats];
    } catch (e) {
      debugPrint('❌ Error recording daily stats: $e');
      rethrow;
    }
  }

  /// Calculate monthly statistics for a specific month (YYYY-MM)
  MonthlyStats? calculateMonthlyStats(String month) {
    if (state == null || state!.isEmpty) return null;

    final targetYear = int.parse(month.split('-')[0]);
    final targetMonth = int.parse(month.split('-')[1]);

    // Filter daily stats for this month
    final monthlyDailyStats = state!.where((s) {
      final date = DateTime.parse(s.date);
      return date.year == targetYear && date.month == targetMonth;
    }).toList();

    if (monthlyDailyStats.isEmpty) return null;

    int totalQuests = 0;
    int totalCorrect = 0;
    int totalAnswers = 0;
    int totalMinutes = 0;
    int totalCoins = 0;
    final Map<String, dynamic> categoryStats = {};

    for (final daily in monthlyDailyStats) {
      totalQuests += daily.questsCompleted;
      totalCorrect += daily.correctAnswers;
      totalAnswers += daily.totalAnswers;
      totalMinutes += daily.studyMinutes;
      totalCoins += daily.coinsEarned;

      // Aggregate category stats
      daily.categoryStats.forEach((catId, catData) {
        if (!categoryStats.containsKey(catId)) {
          categoryStats[catId] = {'correct': 0, 'total': 0};
        }
        categoryStats[catId]['correct'] += catData['correct'] as int? ?? 0;
        categoryStats[catId]['total'] += catData['total'] as int? ?? 0;
      });
    }

    // Calculate accuracy rate for each category
    categoryStats.forEach((catId, stats) {
      if (stats['total'] > 0) {
        stats['accuracy'] = stats['correct'] / stats['total'];
      } else {
        stats['accuracy'] = 0.0;
      }
    });

    final accuracyRate = totalAnswers > 0 ? totalCorrect / totalAnswers : 0.0;

    return MonthlyStats(
      month: month,
      totalQuestsCompleted: totalQuests,
      totalCorrectAnswers: totalCorrect,
      totalAnswers: totalAnswers,
      accuracyRate: accuracyRate,
      totalStudyMinutes: totalMinutes,
      totalCoinsEarned: totalCoins,
      studyDaysCount: monthlyDailyStats.length,
      categoryStats: categoryStats,
    );
  }

  /// Get monthly stats for last N months
  List<MonthlyStats> getMonthlyStatsList(int months) {
    if (state == null || state!.isEmpty) return [];

    final monthlyStatsList = <MonthlyStats>[];
    final now = DateTime.now();

    for (int i = 0; i < months; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthly = calculateMonthlyStats(monthStr);
      if (monthly != null) {
        monthlyStatsList.add(monthly);
      }
    }

    return monthlyStatsList;
  }
}
