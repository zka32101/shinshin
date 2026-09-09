import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ranking.dart';
import '../../services/ranking_service.dart';
import 'ranking_list_screen.dart';
import 'ranking_settings_screen.dart';

/// ランキング画面 — ランキングタイプ選択画面
/// 各種ランキングタイプを選択できるメイン画面
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ランキング'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2C2C2C),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RankingSettingsScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'スコア'),
              Tab(text: '徳目'),
            ],
            labelColor: Color(0xFF9B59B6),
            unselectedLabelColor: Color(0xFF999999),
            indicatorColor: Color(0xFF9B59B6),
          ),
        ),
        body: TabBarView(
          children: [
            // スコアランキングタブ
            _ScoreRankingTab(),
            // 徳目ランキングタブ
            _VirtueRankingTab(),
          ],
        ),
      ),
    );
  }
}

/// スコアランキングタブ
class _ScoreRankingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 1,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      children: [
        _RankingTypeCard(
          title: '総ポイントランキング',
          description: '全体でのスコアを競うランキング',
          icon: '🏆',
          rankingType: RankingType.totalPoints,
        ),
        _RankingTypeCard(
          title: '月間ランキング',
          description: '今月のスコアを競うランキング',
          icon: '📅',
          rankingType: RankingType.monthlyPoints,
        ),
      ],
    );
  }
}

/// 徳目ランキングタブ
class _VirtueRankingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _RankingTypeCard(
          title: '思いやり',
          description: 'compassion',
          icon: '❤️',
          rankingType: RankingType.virtueCompassion,
          isSmall: true,
        ),
        _RankingTypeCard(
          title: '正直',
          description: 'honesty',
          icon: '💬',
          rankingType: RankingType.virtueHonesty,
          isSmall: true,
        ),
        _RankingTypeCard(
          title: '責任',
          description: 'responsibility',
          icon: '⚡',
          rankingType: RankingType.virtueResponsibility,
          isSmall: true,
        ),
        _RankingTypeCard(
          title: '勇気',
          description: 'courage',
          icon: '💪',
          rankingType: RankingType.virtueCourage,
          isSmall: true,
        ),
        _RankingTypeCard(
          title: '尊重',
          description: 'respect',
          icon: '🤝',
          rankingType: RankingType.virtueRespect,
          isSmall: true,
        ),
        _RankingTypeCard(
          title: '協力',
          description: 'cooperation',
          icon: '👥',
          rankingType: RankingType.virtueCooperation,
          isSmall: true,
        ),
      ],
    );
  }
}

/// ランキングタイプ選択カード
class _RankingTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final RankingType rankingType;
  final bool isSmall;

  const _RankingTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.rankingType,
    this.isSmall = false,
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
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RankingListScreen(
                rankingType: rankingType,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isSmall
              ? _buildSmallCardContent()
              : _buildLargeCardContent(),
        ),
      ),
    );
  }

  Widget _buildSmallCardContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF999999),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Color(0xFF9B59B6),
        ),
      ],
    );
  }

  Widget _buildLargeCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9B59B6),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}
