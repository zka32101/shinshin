import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

// ── 設定キー ──────────────────────────────────────────────────────────────
const _kDailyReminder = 'notif_daily_reminder';
const _kReportReady = 'notif_report_ready';
const _kReminderHour = 'notif_reminder_hour';
const _kReminderMinute = 'notif_reminder_minute';

class NotificationSettings {
  final bool dailyReminder;
  final bool reportReady;
  final int reminderHour;
  final int reminderMinute;

  const NotificationSettings({
    this.dailyReminder = true,
    this.reportReady = true,
    this.reminderHour = 19,
    this.reminderMinute = 0,
  });

  NotificationSettings copyWith({
    bool? dailyReminder,
    bool? reportReady,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      NotificationSettings(
        dailyReminder: dailyReminder ?? this.dailyReminder,
        reportReady: reportReady ?? this.reportReady,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final NotificationService _notificationService;
  final _hive = HiveService();

  NotificationSettingsNotifier(this._notificationService)
      : super(const NotificationSettings()) {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    final dailyReminder =
        await _hive.getSetting<bool>(_kDailyReminder) ?? true;
    final reportReady =
        await _hive.getSetting<bool>(_kReportReady) ?? true;
    final reminderHour =
        await _hive.getSetting<int>(_kReminderHour) ?? 19;
    final reminderMinute =
        await _hive.getSetting<int>(_kReminderMinute) ?? 0;
    if (mounted) {
      state = NotificationSettings(
        dailyReminder: dailyReminder,
        reportReady: reportReady,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
      );
    }
  }

  Future<void> _persist() async {
    await _hive.saveSetting(_kDailyReminder, state.dailyReminder);
    await _hive.saveSetting(_kReportReady, state.reportReady);
    await _hive.saveSetting(_kReminderHour, state.reminderHour);
    await _hive.saveSetting(_kReminderMinute, state.reminderMinute);
  }

  void setDailyReminder(bool value) {
    state = state.copyWith(dailyReminder: value);
    unawaited(_persist());
    if (value) {
      _notificationService.scheduleDailyReminder(
        hour: state.reminderHour,
        minute: state.reminderMinute,
        title: '今日の道徳レッスン',
        body: '今日も心のレッスンをしよう！',
      );
    } else {
      _notificationService.cancelAll();
    }
  }

  void setReportReady(bool value) {
    state = state.copyWith(reportReady: value);
    unawaited(_persist());
  }

  void setReminderTime(int hour, int minute) {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    unawaited(_persist());
    if (state.dailyReminder) {
      _notificationService.scheduleDailyReminder(
        hour: hour,
        minute: minute,
        title: '今日の道徳レッスン',
        body: '今日も心のレッスンをしよう！',
      );
    }
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier(NotificationService()),
);
