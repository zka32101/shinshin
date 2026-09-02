import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/avatar_display_widget.dart';
import '../../utils/sound_effects_utils.dart';
import '../../utils/accessibility_utils.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';
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
    final menuItems = [
      (icon: '📖', title: 'ストーリー', subtitle: '道徳の学習', screen: const LibraryScreen()),
      (icon: '🏆', title: 'ランキング', subtitle: '成績を確認', screen: const RankingScreen()),
      (icon: '📈', title: 'ダッシュボード', subtitle: '学習統計', screen: const DashboardScreen()),
      (icon: '🎖️', title: 'バッジ図鑑', subtitle: 'バッジを集める', screen: const BadgeShowcaseScreen()),
      (icon: '📊', title: 'レポート', subtitle: '成長を分析', screen: const ReportScreen()),
      (icon: '⚙️', title: '設定', subtitle: 'アプリ設定', screen: const SettingsScreen()),
      (icon: '🎹', title: 'ピアノ', subtitle: '音の学習', screen: const PianoLearningScreen()),
      (icon: '🎨', title: 'お絵かき', subtitle: '創意表現', screen: const DrawingScreen()),
      (icon: '⛹️', title: '体育', subtitle: '運動の学習', screen: const PhysicalEducationScreen()),
      (icon: '🎨', title: '色選び', subtitle: '色の学習', screen: const ColorLearningScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('小学コレ！道徳'),
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: AnimatedFadeInScale(
        duration: AnimationDurations.medium,
        beginScale: 0.95,
        endScale: 1.0,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Avatar panel in header
                AnimatedSlideIn(
                  direction: SlideDirection.fromBottom,
                  duration: AnimationDurations.medium,
                  delay: Duration(milliseconds: 100),
                  child: const AvatarPanel(
                    userName: 'ユーザー',
                  ),
                ),
                const SizedBox(height: 32),

                // Main menu grid
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return AnimatedSlideIn(
                      direction: SlideDirection.fromBottom,
                      duration: AnimationDurations.medium,
                      delay: Duration(milliseconds: 200 + (index * 75)),
                      child: _MenuCard(
                        icon: item.icon,
                        title: item.title,
                        subtitle: item.subtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => item.screen),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ホーム画面のメニューカード
class _MenuCard extends ConsumerStatefulWidget {
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
  ConsumerState<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends ConsumerState<_MenuCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationDurations.short,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.snappyEasing),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    _handleTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    // メニュー選択音を再生
    SoundEffectsUtils(ref).playButtonTapSound();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AccessibilityUtils.semanticButton(
          label: widget.title,
          hint: widget.subtitle,
          onPressed: _handleTap,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.icon,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: AppStyles.paddingMedium),
                  Text(
                    widget.title,
                    style: AppStyles.headingSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppStyles.paddingSmall),
                  Text(
                    widget.subtitle,
                    style: AppStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
