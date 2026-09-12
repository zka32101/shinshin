// Phase 4.21: Parental Dashboard 統合
// 各アプリでカスタマイズして使用

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class ParentalDashboardScreen extends StatelessWidget {
  final String appId;

  const ParentalDashboardScreen({
    super.key,
    required this.appId,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColors = {
      'eigo': const Color(0xFF4A90E2),
      'sansu': const Color(0xFFE94B3C),
      'kokugo': const Color(0xFF9B59B6),
      'newrepo': const Color(0xFF00BCD4),
      'social': const Color(0xFF4CAF50),
      'shinshin': const Color(0xFFFF6B9D),
      'programming': const Color(0xFFFFA500),
      'yourwish': const Color(0xFFFFD700),
    };

    final primaryColor = primaryColors[appId] ?? const Color(0xFF4A90E2);

    return ParentalDashboard(
      childName: '学習者さん',
      primaryColor: primaryColor,
    );
  }
}
