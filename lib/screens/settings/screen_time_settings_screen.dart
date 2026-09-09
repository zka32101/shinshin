import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/screen_time_limit_widget.dart';

/// 利用時間制限（スクリーンタイム管理）の設定画面。
///
/// 設定画面から `requireParentalGate()` を通過した保護者のみが
/// 到達する想定（`SettingsScreen` 側でゲート処理を行う）。
class ScreenTimeSettingsScreen extends StatelessWidget {
  const ScreenTimeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用時間の設定'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const ScreenTimeSettingsWidget(),
    );
  }
}
