/// 利用時間制限（スクリーンタイム管理）のモデル。
///
/// `shared_core` の `models/screen_time_model.dart` を参考に、本アプリ用に
/// 軽量移植したもの（shared_core非依存のため独自実装）。

/// 保護者が設定する制限内容。
class ScreenTimeSettings {
  /// 1日の利用上限（分）。null の場合は無制限。
  final int? dailyLimitMinutes;

  /// 機能そのもののON/OFF。false の場合は [dailyLimitMinutes] に関わらず
  /// 制限を適用しない。
  final bool enabled;

  const ScreenTimeSettings({
    this.dailyLimitMinutes,
    this.enabled = false,
  });

  ScreenTimeSettings copyWith({
    int? dailyLimitMinutes,
    bool clearDailyLimitMinutes = false,
    bool? enabled,
  }) =>
      ScreenTimeSettings(
        dailyLimitMinutes: clearDailyLimitMinutes
            ? null
            : (dailyLimitMinutes ?? this.dailyLimitMinutes),
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'dailyLimitMinutes': dailyLimitMinutes,
        'enabled': enabled,
      };

  factory ScreenTimeSettings.fromJson(Map<String, dynamic> j) =>
      ScreenTimeSettings(
        dailyLimitMinutes: j['dailyLimitMinutes'] as int?,
        enabled: j['enabled'] as bool? ?? false,
      );
}

/// ある1日の利用実績。
class ScreenTimeUsage {
  /// 'YYYY-MM-DD' 形式の日付文字列（ローカル日付）。
  final String date;

  /// その日の利用済み分数。
  final int usedMinutes;

  const ScreenTimeUsage({
    required this.date,
    this.usedMinutes = 0,
  });

  ScreenTimeUsage copyWith({
    String? date,
    int? usedMinutes,
  }) =>
      ScreenTimeUsage(
        date: date ?? this.date,
        usedMinutes: usedMinutes ?? this.usedMinutes,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'usedMinutes': usedMinutes,
      };

  factory ScreenTimeUsage.fromJson(Map<String, dynamic> j) => ScreenTimeUsage(
        date: j['date'] as String? ?? '',
        usedMinutes: j['usedMinutes'] as int? ?? 0,
      );
}
