import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import 'story_provider.dart'; // apiServiceProvider / hiveServiceProvider を再利用

// Named record型でmonthlyReportProviderのキーを定義
typedef MonthlyReportKey = ({String childId, int year, int month});

/// 月次レポート取得プロバイダー（Hive オフラインキャッシュ付き）
final monthlyReportProvider = FutureProvider.autoDispose
    .family<MonthlyReport?, MonthlyReportKey>(
  (ref, key) async {
    final apiService = ref.watch(apiServiceProvider);
    final hive = ref.read(hiveServiceProvider);
    try {
      final report = await apiService.fetchMonthlyReport(
        childId: key.childId,
        year: key.year,
        month: key.month,
      );
      if (report != null) {
        unawaited(hive.cacheMonthlyReport(report));
      }
      return report;
    } catch (_) {
      // オフライン → キャッシュを返す
      return hive.getCachedMonthlyReport(key.childId, key.year, key.month);
    }
  },
);

/// 月次レポート生成プロバイダー
final generateMonthlyReportProvider = FutureProvider.autoDispose
    .family<MonthlyReport, MonthlyReportKey>(
  (ref, key) async {
    final apiService = ref.watch(apiServiceProvider);
    final hive = ref.read(hiveServiceProvider);
    final report = await apiService.generateMonthlyReport(
      childId: key.childId,
      year: key.year,
      month: key.month,
    );
    unawaited(hive.cacheMonthlyReport(report));
    // Invalidate the cached report so it shows the new one
    ref.invalidate(monthlyReportProvider(key));
    return report;
  },
);
