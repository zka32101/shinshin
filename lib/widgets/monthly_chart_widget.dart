import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics_model.dart';
import '../theme/app_theme.dart';

class MonthlyChartWidget extends StatelessWidget {
  final List<MonthlyStats> monthlyStatsList;
  final String title;

  const MonthlyChartWidget({
    super.key,
    required this.monthlyStatsList,
    this.title = '月ごと学力推移',
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyStatsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('データがありません'),
        ),
      );
    }

    // Sort by month (newest first)
    final sorted = List<MonthlyStats>.from(monthlyStatsList)
        ..sort((a, b) => b.month.compareTo(a.month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sorted.length) {
                          return const SizedBox();
                        }
                        final month = sorted[index].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            month.split('-')[1], // Show only month (MM)
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      sorted.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        sorted[index].accuracyRate.clamp(0, 1),
                      ),
                    ),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor,
                        kPrimaryColor.withOpacity(0.3),
                      ],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: kPrimaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryColor.withOpacity(0.3),
                          kPrimaryColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MonthlyBarChartWidget extends StatelessWidget {
  final List<MonthlyStats> monthlyStatsList;
  final String title;
  final String metric; // 'quests', 'minutes', 'coins'

  const MonthlyBarChartWidget({
    super.key,
    required this.monthlyStatsList,
    this.title = '月ごと学習量',
    this.metric = 'quests',
  });

  double _getMetricValue(MonthlyStats stats) {
    switch (metric) {
      case 'minutes':
        return stats.totalStudyMinutes.toDouble();
      case 'coins':
        return stats.totalCoinsEarned.toDouble();
      default:
        return stats.totalQuestsCompleted.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyStatsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('データがありません'),
        ),
      );
    }

    // Sort by month (newest first)
    final sorted = List<MonthlyStats>.from(monthlyStatsList)
        ..sort((a, b) => b.month.compareTo(a.month));

    final maxValue = sorted.map(_getMetricValue).fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sorted.length) {
                          return const SizedBox();
                        }
                        final month = sorted[index].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            month.split('-')[1],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                barGroups: List.generate(
                  sorted.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _getMetricValue(sorted[index]),
                        color: kPrimaryColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                maxY: maxValue * 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
