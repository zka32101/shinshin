import 'package:flutter/material.dart';
import '../../widgets/avatar_display_widget.dart';
import '../ranking/ranking_screen.dart';
import '../settings/settings_screen.dart';
import '../library/library_screen.dart';
import '../report/report_screen.dart';
import '../learning/piano_learning_screen.dart';
import '../learning/drawing_screen.dart';
import '../learning/physical_education_screen.dart';
import '../learning/color_learning_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小学コレ！道徳'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
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
class _MenuCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
