import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/avatar_display_widget.dart';
import '../../utils/sound_effects_utils.dart';
import '../../utils/accessibility_utils.dart';
import '../ranking/ranking_screen.dart';
import '../settings/settings_screen.dart';
import '../library/library_screen.dart';
import '../report/report_screen.dart';
import '../learning/piano_learning_screen.dart';
import '../learning/drawing_screen.dart';
import '../learning/physical_education_screen.dart';
import '../learning/color_learning_screen.dart';
import '../badge/badge_showcase_screen.dart';
import '../dashboard/dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小学コレ！道徳'),
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Avatar panel in header
              const AvatarPanel(
                userName: 'ユーザー',
              ),
              const SizedBox(height: 32),

              // Main menu grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _MenuCard(
                    icon: '📖',
                    title: 'ストーリー',
                    subtitle: '道徳の学習',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LibraryScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '🏆',
                    title: 'ランキング',
                    subtitle: '成績を確認',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RankingScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '📈',
                    title: 'ダッシュボード',
                    subtitle: '学習統計',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '🎖️',
                    title: 'バッジ図鑑',
                    subtitle: 'バッジを集める',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BadgeShowcaseScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '📊',
                    title: 'レポート',
                    subtitle: '成長を分析',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ReportScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '⚙️',
                    title: '設定',
                    subtitle: 'アプリ設定',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '🎹',
                    title: 'ピアノ',
                    subtitle: '音の学習',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PianoLearningScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '🎨',
                    title: 'お絵かき',
                    subtitle: '創意表現',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DrawingScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '⛹️',
                    title: '体育',
                    subtitle: '運動の学習',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PhysicalEducationScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: '🎨',
                    title: '色選び',
                    subtitle: '色の学習',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ColorLearningScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// ホーム画面のメニューカード
class _MenuCard extends ConsumerWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AccessibilityUtils.semanticButton(
      label: title,
      hint: subtitle,
      onPressed: () {
        // メニュー選択音を再生
        SoundEffectsUtils(ref).playButtonTapSound();
        onTap();
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          onTap: () {
            // メニュー選択音を再生
            SoundEffectsUtils(ref).playButtonTapSound();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.paddingMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: AppStyles.paddingMedium),
                Text(
                  title,
                  style: AppStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyles.paddingSmall),
                Text(
                  subtitle,
                  style: AppStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
