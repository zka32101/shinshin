import 'package:flutter/foundation.dart';
import 'logging_utils.dart';

/// パフォーマンス計測データ
class PerformanceMetrics {
  final String name;
  final int durationMs;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetrics({
    required this.name,
    required this.durationMs,
    required this.timestamp,
    this.metadata,
  });

  bool get isSlow => durationMs > 100; // 100ms以上は遅い
  bool get isVerySlow => durationMs > 500; // 500ms以上は非常に遅い

  @override
  String toString() {
    return 'PerformanceMetrics($name: ${durationMs}ms)';
  }
}

/// パフォーマンス監視・最適化ユーティリティ
class PerformanceUtils {
  static final List<PerformanceMetrics> _metrics = [];
  static const int _maxMetrics = 100; // メモリ節約

  /// パフォーマンス計測を開始
  static Stopwatch startMeasure(String name) {
    final sw = Stopwatch()..start();
    LoggingUtils.debug('PERF', 'パフォーマンス計測開始: $name');
    return sw;
  }

  /// パフォーマンス計測を終了してメトリクスを記録
  static PerformanceMetrics endMeasure(
    String name,
    Stopwatch sw, {
    Map<String, dynamic>? metadata,
  }) {
    sw.stop();
    final metric = PerformanceMetrics(
      name: name,
      durationMs: sw.elapsedMilliseconds,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _recordMetric(metric);

    if (metric.isVerySlow) {
      LoggingUtils.warning(
        'PERF',
        '$name: 非常に遅い (${metric.durationMs}ms)',
        metadata: metadata,
      );
    } else if (metric.isSlow) {
      LoggingUtils.info(
        'PERF',
        '$name: やや遅い (${metric.durationMs}ms)',
        metadata: metadata,
      );
    } else {
      LoggingUtils.debug(
        'PERF',
        '$name: ${metric.durationMs}ms',
        metadata: metadata,
      );
    }

    return metric;
  }

  static void _recordMetric(PerformanceMetrics metric) {
    if (_metrics.length >= _maxMetrics) {
      _metrics.removeAt(0);
    }
    _metrics.add(metric);
  }

  /// メトリクスを取得
  static List<PerformanceMetrics> getMetrics([String? filterName]) {
    if (filterName == null) return List.from(_metrics);
    return _metrics.where((m) => m.name.contains(filterName)).toList();
  }

  /// 平均実行時間を計算
  static int getAverageDuration(String name) {
    final matches = _metrics.where((m) => m.name == name).toList();
    if (matches.isEmpty) return 0;
    return matches.map((m) => m.durationMs).reduce((a, b) => a + b) ~/ matches.length;
  }

  /// 遅いメトリクスを取得
  static List<PerformanceMetrics> getSlowMetrics() {
    return _metrics.where((m) => m.isSlow).toList();
  }

  /// メトリクスをクリア
  static void clearMetrics() {
    _metrics.clear();
    LoggingUtils.debug('PERF', 'パフォーマンスメトリクスをクリア');
  }

  /// メモリ使用量を取得（概算）
  static String getMemoryUsageInfo() {
    // 実際のメモリ使用量取得は ios_system_info などのパッケージが必要
    return '詳細なメモリ情報は external package が必要です';
  }

  /// FPS監視（デバッグ用）
  static void monitorFrameTime() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        final duration = timings.totalSpan.inMilliseconds;
        if (duration > 16) { // 60 FPS の時間枠
          LoggingUtils.warning(
            'FRAME_TIME',
            'フレーム時間が長い: ${duration}ms',
          );
        }
      });
    }
  }

  /// 非同期操作のパフォーマンス計測
  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final sw = startMeasure(name);
    try {
      return await operation();
    } finally {
      endMeasure(name, sw, metadata: metadata);
    }
  }

  /// 同期操作のパフォーマンス計測
  static T measureSync<T>(
    String name,
    T Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    final sw = startMeasure(name);
    try {
      return operation();
    } finally {
      endMeasure(name, sw, metadata: metadata);
    }
  }

  /// パフォーマンスレポートを出力
  static String generateReport() {
    if (_metrics.isEmpty) return 'パフォーマンスデータなし';

    final buffer = StringBuffer();
    buffer.writeln('=== パフォーマンスレポート ===');
    buffer.writeln('記録数: ${_metrics.length}');

    // 遅いメトリクス
    final slowMetrics = getSlowMetrics();
    if (slowMetrics.isNotEmpty) {
      buffer.writeln('\n遅い処理:');
      for (final m in slowMetrics.take(10)) {
        buffer.writeln('  - ${m.name}: ${m.durationMs}ms');
      }
    }

    // 処理別の平均時間
    final uniqueNames = _metrics.map((m) => m.name).toSet();
    if (uniqueNames.isNotEmpty) {
      buffer.writeln('\n平均実行時間:');
      for (final name in uniqueNames) {
        final avg = getAverageDuration(name);
        buffer.writeln('  - $name: ${avg}ms');
      }
    }

    return buffer.toString();
  }
}
