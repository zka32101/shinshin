// Phase 4.21: 親管理機能統一化 - 時間帯制限設定画面
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class ScreenTimeSettingsScreen extends StatelessWidget {
  const ScreenTimeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏰ 利用時間の詳細設定'),
        backgroundColor: const Color(0xFFFF6B9D), // shinshin primary color
      ),
      body: const TimeSlotSettingsWidget(
        primaryColor: Color(0xFFFF6B9D),
      ),
    );
  }
}
