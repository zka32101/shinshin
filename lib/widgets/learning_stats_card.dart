import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../theme/app_theme.dart';

class LearningStatsCard extends StatelessWidget {
  final MonthlyStats monthlyStats;

  const LearningStatsCard({
    super.key,
    required this.monthlyStats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Row(
              children: [
                Text(
                  monthlyStats.month,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '正答率: ${monthlyStats.accuracyPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _StatsTile(
                  icon: '📝',
                  title: '問題数',
                  value: monthlyStats.totalQuestsCompleted.toString(),
                  subtitle: '${monthlyStats.totalAnswers}問',
                ),
                _StatsTile(
                  icon: '✅',
                  title: '正解数',
                  value: monthlyStats.totalCorrectAnswers.toString(),
                  subtitle: '${((monthlyStats.totalCorrectAnswers / monthlyStats.totalAnswers.clamp(1, double.maxFinite)) * 100).toStringAsFixed(0)}%',
                ),
                _StatsTile(
                  icon: '⏱️',
                  title: '学習時間',
                  value: '${(monthlyStats.totalStudyMinutes / 60).toStringAsFixed(1)}h',
                  subtitle: '${monthlyStats.totalStudyMinutes}分',
                ),
                _StatsTile(
                  icon: '🪙',
                  title: 'コイン',
                  value: monthlyStats.totalCoinsEarned.toString(),
                  subtitle: '${monthlyStats.studyDaysCount}日',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Study days info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: kSecondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '学習日数: ${monthlyStats.studyDaysCount}日',
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTile extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final String subtitle;

  const _StatsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
