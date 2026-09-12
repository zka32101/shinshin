import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show CoachingDashboard;

import '../../../constants/theme_colors.dart';
import '../../providers/child_provider.dart';

/// AI コーチング ダッシュボード画面
///
/// ユーザーの学習パターンを分析し、個別のコーチングアドバイスを表示します。
class AiCoachingDashboardScreen extends ConsumerWidget {
  const AiCoachingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = ref.watch(currentChildIdProvider);

    if (childId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI コーチング'),
          backgroundColor: ThemeColors.lightColorScheme.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'プロフィールが未選択です',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI コーチング'),
        backgroundColor: ThemeColors.lightColorScheme.primary,
        elevation: 0,
      ),
      body: CoachingDashboard(
        userId: childId,
        primaryColor: ThemeColors.lightColorScheme.primary,
      ),
    );
  }
}
