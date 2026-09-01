import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import '../widgets/monthly_chart_widget.dart';
import '../widgets/learning_stats_card.dart';
import '../providers/analytics_provider.dart';

class LearningAnalyticsScreen extends ConsumerWidget {
  final String userId;

  const LearningAnalyticsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('学習分析'),
          backgroundColor: Colors.blue,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: '📊 統計'),
              Tab(text: '📅 月別学力'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStatisticsTab(),
            _buildMonthlyAnalyticsTab(ref),
          ],
        ),
      ),
    );
  }

  /// 統計タブ
  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '学習統計',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text('学習統計情報がここに表示されます'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 月別学力タブ
  Widget _buildMonthlyAnalyticsTab(WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);

    if (analytics == null || analytics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.analytics, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('月ごとのデータがまだありません'),
            ],
          ),
        ),
      );
    }

    // Convert DailyStats to MonthlyStats
    final monthlyList = _calculateMonthlyStats(analytics);

    if (monthlyList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.analytics, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('月ごとのデータがまだありません'),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 正答率推移グラフ
          MonthlyChartWidget(
            monthlyStatsList: monthlyList,
            title: '📊 月ごと正答率推移',
          ),
          const SizedBox(height: 24),

          // 学習量グラフ
          MonthlyBarChartWidget(
            monthlyStatsList: monthlyList,
            title: '📝 月ごと問題数',
            metric: 'quests',
          ),
          const SizedBox(height: 24),

          // 学習時間グラフ
          MonthlyBarChartWidget(
            monthlyStatsList: monthlyList,
            title: '⏱️ 月ごと学習時間',
            metric: 'minutes',
          ),
          const SizedBox(height: 24),

          // 月別統計カード
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '月別統計',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          ...monthlyList.map((stats) => LearningStatsCard(monthlyStats: stats)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<MonthlyStats> _calculateMonthlyStats(List<DailyStats> dailyStats) {
    final monthlyMap = <String, MonthlyStats>{};

    for (final daily in dailyStats) {
      final date = DateTime.parse(daily.date);
      final monthStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (monthlyMap.containsKey(monthStr)) {
        final existing = monthlyMap[monthStr]!;
        monthlyMap[monthStr] = MonthlyStats(
          month: monthStr,
          totalQuestsCompleted: existing.totalQuestsCompleted + daily.questsCompleted,
          totalCorrectAnswers: existing.totalCorrectAnswers + daily.correctAnswers,
          totalAnswers: existing.totalAnswers + daily.totalAnswers,
          accuracyRate: 0, // Will be calculated below
          totalStudyMinutes: existing.totalStudyMinutes + daily.studyMinutes,
          totalCoinsEarned: existing.totalCoinsEarned + daily.coinsEarned,
          studyDaysCount: existing.studyDaysCount + 1,
          categoryStats: existing.categoryStats,
        );
      } else {
        monthlyMap[monthStr] = MonthlyStats(
          month: monthStr,
          totalQuestsCompleted: daily.questsCompleted,
          totalCorrectAnswers: daily.correctAnswers,
          totalAnswers: daily.totalAnswers,
          accuracyRate: daily.totalAnswers > 0 ? daily.correctAnswers / daily.totalAnswers : 0,
          totalStudyMinutes: daily.studyMinutes,
          totalCoinsEarned: daily.coinsEarned,
          studyDaysCount: 1,
          categoryStats: daily.categoryStats,
        );
      }
    }

    // Recalculate accuracy rates
    final result = monthlyMap.values.map((m) {
      final accuracy = m.totalAnswers > 0 ? m.totalCorrectAnswers / m.totalAnswers : 0.0;
      return MonthlyStats(
        month: m.month,
        totalQuestsCompleted: m.totalQuestsCompleted,
        totalCorrectAnswers: m.totalCorrectAnswers,
        totalAnswers: m.totalAnswers,
        accuracyRate: accuracy,
        totalStudyMinutes: m.totalStudyMinutes,
        totalCoinsEarned: m.totalCoinsEarned,
        studyDaysCount: m.studyDaysCount,
        categoryStats: m.categoryStats,
      );
    }).toList();

    // Sort by month descending
    result.sort((a, b) => b.month.compareTo(a.month));
    return result;
  }
}
