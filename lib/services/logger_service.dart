import 'package:flutter/foundation.dart';

/// ログレベル
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  critical(4, 'CRITICAL');

  final int value;
  final String label;

  const LogLevel(this.value, this.label);
}

/// ロギングサービス
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal();

  static const String _prefix = '[ShougakuKore]';
  static final LogLevel _minLevel =
      kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// デバッグログ
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// 情報ログ
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// 警告ログ
  static void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  /// エラーログ
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// クリティカルログ
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(
      LogLevel.critical,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Instance method: log (general purpose)
  void log(String message, {String? tag}) {
    info(message, tag: tag);
  }

  /// Instance method: logError
  void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    LoggerService.error(message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// 内部ログ出力
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // ログレベルのチェック
    if (level.value < _minLevel.value) {
      return;
    }

    // タグの処理
    final tagString = tag != null ? '[$tag]' : '';

    // メッセージの構築
    final logMessage = '$_prefix ${level.label} $tagString $message';

    // コンソール出力
    if (kDebugMode) {
      print(logMessage);
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }

    // TODO: Sentry への送信（本番環境）
    // TODO: ローカルストレージへの保存
  }

  /// ログファイルをクリア
  static Future<void> clearLogs() async {
    // TODO: ローカルストレージのログファイルをクリア
  }

  /// ログファイルを取得
  static Future<String?> getLogs() async {
    // TODO: ローカルストレージのログファイルを取得
    return null;
  }
}
