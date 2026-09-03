import 'package:flutter/foundation.dart';

/// ログレベルの定義
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  critical(4);

  final int level;
  const LogLevel(this.level);
}

/// 統一ログング・エラーハンドリングユーティリティ
class LoggingUtils {
  static LogLevel _minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// ログレベルを設定
  static void setMinimumLogLevel(LogLevel level) {
    _minimumLevel = level;
  }

  /// デバッグログ出力
  static void debug(String tag, String message, {Object? error, StackTrace? stack, Map<String, dynamic>? metadata}) {
    _log(LogLevel.debug, tag, message, error, stack, metadata);
  }

  /// 情報ログ出力
  static void info(String tag, String message, {Object? error, StackTrace? stack, Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, tag, message, error, stack, metadata);
  }

  /// 警告ログ出力
  static void warning(String tag, String message, {Object? error, StackTrace? stack, Map<String, dynamic>? metadata}) {
    _log(LogLevel.warning, tag, message, error, stack, metadata);
  }

  /// エラーログ出力
  static void error(String tag, String message, {Object? error, StackTrace? stack, Map<String, dynamic>? metadata}) {
    _log(LogLevel.error, tag, message, error, stack, metadata);
  }

  /// クリティカルエラーログ出力
  static void critical(String tag, String message, {Object? error, StackTrace? stack, Map<String, dynamic>? metadata}) {
    _log(LogLevel.critical, tag, message, error, stack, metadata);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message,
    Object? error,
    StackTrace? stack,
    Map<String, dynamic>? metadata,
  ) {
    if (level.level < _minimumLevel.level) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    final logMessage = '[$timestamp] [$levelName] [$tag] $message';

    debugPrint(logMessage);

    if (metadata != null) {
      debugPrint('Metadata: $metadata');
    }
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stack != null) {
      debugPrint('Stack trace:\n$stack');
    }
  }

  /// パフォーマンス計測を開始
  static Stopwatch startTimer(String tag) {
    final sw = Stopwatch()..start();
    debug(tag, 'パフォーマンス計測開始');
    return sw;
  }

  /// パフォーマンス計測を終了してログ出力
  static void stopTimer(String tag, Stopwatch sw) {
    sw.stop();
    info(tag, 'パフォーマンス計測終了: ${sw.elapsedMilliseconds}ms');
  }

  /// APIコール結果をログ
  static void logApiCall(
    String endpoint,
    String method,
    int statusCode,
    int durationMs,
  ) {
    info(
      'API',
      '$method $endpoint - Status: $statusCode (${durationMs}ms)',
    );
  }

  /// エラーをログして再スロー
  static void logAndRethrow(
    String tag,
    String message,
    Object error,
    StackTrace stack,
  ) {
    LoggingUtils.error(tag, message, error, stack);
    rethrow;
  }

  /// ユーザーアクションをログ
  static void logUserAction(
    String screen,
    String action, {
    Map<String, dynamic>? params,
  }) {
    final paramStr = params != null ? ' - ${params.toString()}' : '';
    info('USER_ACTION', '$screen: $action$paramStr');
  }

  /// 画面遷移をログ
  static void logNavigation(String from, String to) {
    info('NAVIGATION', '$from → $to');
  }

  /// UI構築パフォーマンスをログ
  static void logBuildTime(String widgetName, int durationMs) {
    if (durationMs > 16) {
      // 16msは60FPSの1フレーム
      warning('BUILD_TIME', '$widgetName: ${durationMs}ms (フレームドロップの可能性)');
    } else {
      debug('BUILD_TIME', '$widgetName: ${durationMs}ms');
    }
  }
}
