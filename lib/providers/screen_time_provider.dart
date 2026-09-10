import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/screen_time.dart';
import '../services/hive_service.dart';

/// 利用時間制限（スクリーンタイム管理）の Provider。
///
/// `shared_core` の `BaseScreenTimeNotifier`
/// （`lib/providers/screen_time_provider.dart`）を参考に、本アプリの
/// StateNotifier / HiveService 規約に合わせて軽量移植したもの
/// （shared_core非依存のため独自実装。`parental_gate_dialog.dart` と同じ方針）。

// ── 設定キー ──────────────────────────────────────────────────────────────
const _kEnabled = 'screen_time_enabled';
const _kDailyLimitMinutes = 'screen_time_daily_limit_minutes';
const _kUsageDate = 'screen_time_usage_date';
const _kUsageMinutes = 'screen_time_usage_minutes';

class ScreenTimeState {
  final ScreenTimeSettings settings;
  final ScreenTimeUsage usage;

  const ScreenTimeState({
    this.settings = const ScreenTimeSettings(),
    this.usage = const ScreenTimeUsage(date: ''),
  });

  ScreenTimeState copyWith({
    ScreenTimeSettings? settings,
    ScreenTimeUsage? usage,
  }) =>
      ScreenTimeState(
        settings: settings ?? this.settings,
        usage: usage ?? this.usage,
      );

  /// 現在の利用時間が1日の上限を超えているかどうか。
  /// 機能がOFF、または上限未設定（無制限）の場合は常に false。
  bool get isLimitReached {
    final limit = settings.dailyLimitMinutes;
    if (!settings.enabled || limit == null) return false;
    return usage.usedMinutes >= limit;
  }

  /// 残り利用可能時間（分）。無制限またはOFFの場合は null。
  int? get remainingMinutes {
    final limit = settings.dailyLimitMinutes;
    if (!settings.enabled || limit == null) return null;
    final remaining = limit - usage.usedMinutes;
    return remaining > 0 ? remaining : 0;
  }
}

String _todayKey() {
  final now = DateTime.now();
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '${now.year}-$m-$d';
}

/// 利用時間制限を管理する StateNotifier。
///
/// アプリがフォアグラウンドにある間、1分ごとに利用時間を加算する。
/// バックグラウンドに回っている間はカウントを止める（[WidgetsBindingObserver]
/// でライフサイクルを監視）。日付が変わった場合は自動的にリセットされる。
///
/// 保護者ゲート（`requireParentalGate`）を通すかどうかは呼び出し元の責務。
/// このクラス自体はゲートの存在を知らない。
class ScreenTimeNotifier extends StateNotifier<ScreenTimeState>
    with WidgetsBindingObserver {
  final _hive = HiveService();
  Timer? _ticker;
  bool _loaded = false;

  ScreenTimeNotifier() : super(const ScreenTimeState()) {
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      await _load();
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
        _startTicker();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      if (_loaded) _checkDateRollover();
      _startTicker();
    } else {
      _stopTicker();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final enabled = await _hive.getSetting<bool>(_kEnabled) ?? false;
    final dailyLimitMinutes = await _hive.getSetting<int>(_kDailyLimitMinutes);
    final settings = ScreenTimeSettings(
      enabled: enabled,
      dailyLimitMinutes: dailyLimitMinutes,
    );

    final storedDate = await _hive.getSetting<String>(_kUsageDate);
    final storedMinutes = await _hive.getSetting<int>(_kUsageMinutes) ?? 0;
    var usage = storedDate != null
        ? ScreenTimeUsage(date: storedDate, usedMinutes: storedMinutes)
        : ScreenTimeUsage(date: _todayKey());

    if (usage.date != _todayKey()) {
      usage = ScreenTimeUsage(date: _todayKey());
      await _persistUsage(usage);
    }

    if (mounted) {
      state = state.copyWith(settings: settings, usage: usage);
    }
    _loaded = true;
  }

  void _checkDateRollover() {
    final today = _todayKey();
    if (state.usage.date != today) {
      final usage = ScreenTimeUsage(date: today);
      state = state.copyWith(usage: usage);
      unawaited(_persistUsage(usage));
    }
  }

  void _startTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _tick() async {
    if (!_loaded || !mounted) return;
    _checkDateRollover();
    final usage =
        state.usage.copyWith(usedMinutes: state.usage.usedMinutes + 1);
    state = state.copyWith(usage: usage);
    await _persistUsage(usage);
  }

  Future<void> _persistSettings(ScreenTimeSettings settings) async {
    await _hive.saveSetting(_kEnabled, settings.enabled);
    if (settings.dailyLimitMinutes == null) {
      await _hive.saveSetting(_kDailyLimitMinutes, null);
    } else {
      await _hive.saveSetting(_kDailyLimitMinutes, settings.dailyLimitMinutes);
    }
  }

  Future<void> _persistUsage(ScreenTimeUsage usage) async {
    await _hive.saveSetting(_kUsageDate, usage.date);
    await _hive.saveSetting(_kUsageMinutes, usage.usedMinutes);
  }

  /// 1日の利用上限を設定する（分単位、null で無制限）。
  ///
  /// 保護者確認（`requireParentalGate` 等）は呼び出し元で完了させてから
  /// 呼ぶこと。このメソッド自体はゲート処理を行わない。
  Future<void> setDailyLimit(int? minutes) async {
    if (!_loaded) await _load();
    final settings = state.settings.copyWith(
      dailyLimitMinutes: minutes,
      clearDailyLimitMinutes: minutes == null,
    );
    state = state.copyWith(settings: settings);
    await _persistSettings(settings);
  }

  /// 機能そのもののON/OFFを切り替える。
  Future<void> setEnabled(bool enabled) async {
    if (!_loaded) await _load();
    final settings = state.settings.copyWith(enabled: enabled);
    state = state.copyWith(settings: settings);
    await _persistSettings(settings);
  }

  /// 今日の利用時間をリセットする（保護者による一時解除等に使用）。
  Future<void> resetTodayUsage() async {
    if (!_loaded) await _load();
    final usage = ScreenTimeUsage(date: _todayKey());
    state = state.copyWith(usage: usage);
    await _persistUsage(usage);
  }
}

final screenTimeProvider =
    StateNotifierProvider<ScreenTimeNotifier, ScreenTimeState>(
  (ref) => ScreenTimeNotifier(),
);
