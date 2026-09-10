import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ranking.dart';
import '../../providers/child_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';
import '../friend/friend_list_screen.dart';

/// 月間ランキング画面
/// 4つのグループ化オプション付きランキング表示
class MonthlyRankingScreen extends ConsumerStatefulWidget {
  const MonthlyRankingScreen({super.key});

  @override
  ConsumerState<MonthlyRankingScreen> createState() => _MonthlyRankingScreenState();
}

class _MonthlyRankingScreenState extends ConsumerState<MonthlyRankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<RankingGroupType> groupTypes = [
    RankingGroupType.overall,
    RankingGroupType.byGrade,
    RankingGroupType.byStartMonth,
    RankingGroupType.combined,
    RankingGroupType.friends,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: groupTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getGroupLabel(RankingGroupType type) {
    switch (type) {
      case RankingGroupType.overall:
        return '全体';
      case RankingGroupType.byGrade:
        return '学年別';
      case RankingGroupType.byStartMonth:
        return '開始月別';
      case RankingGroupType.combined:
        return '複合';
      case RankingGroupType.friends:
        return '友だち';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: '友だち管理',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FriendListScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF9B59B6),
          unselectedLabelColor: const Color(0xFF999999),
          indicatorColor: const Color(0xFF9B59B6),
          tabs: groupTypes.map((type) {
            return Tab(
              text: _getGroupLabel(type),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: groupTypes.map((groupType) {
          return _RankingTabContent(groupType: groupType);
        }).toList(),
      ),
    );
  }
}

/// ランキングタブの内容
class _RankingTabContent extends ConsumerWidget {
  final RankingGroupType groupType;

  const _RankingTabContent({
    required this.groupType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 友だちランキングは自分の child_id を group_value として渡す必要があるため、
    // 選択中の子どもプロフィールを介して別プロバイダーを使用する
    if (groupType == RankingGroupType.friends) {
      final childProfileAsync = ref.watch(currentChildProfileProvider);
      return childProfileAsync.when(
        data: (child) {
          if (child == null) {
            return const Center(
              child: Text(
                '子どもプロフィールが選択されていません',
                style: TextStyle(color: Color(0xFF999999)),
              ),
            );
          }
          final rankings = ref.watch(friendsRankingProvider(child.id));
          return _buildRankingList(context, rankings, isFriends: true);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラーが発生しました: $error')),
      );
    }

    final rankings = ref.watch(
      monthlyRankingProvider(groupType),
    );
    return _buildRankingList(context, rankings, isFriends: false);
  }

  Widget _buildRankingList(
    BuildContext context,
    AsyncValue<List<RankingEntry>> rankings, {
    required bool isFriends,
  }) {
    return rankings.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: Color(0xFFDDDDDD),
                ),
                const SizedBox(height: 16),
                Text(
                  isFriends
                      ? 'ランキング情報がありません\n（友だちを追加すると表示されます）'
                      : 'ランキング情報がありません',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return AnimatedFadeInScale(
          duration: AnimationDurations.medium,
          beginScale: 0.95,
          endScale: 1.0,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 100 + (index * 50)),
                child: _RankingTile(entry: entry),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFDD6B55),
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました: $error',
              style: const TextStyle(
                color: Color(0xFFDD6B55),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ランキングタイル
class _RankingTile extends StatefulWidget {
  final RankingEntry entry;

  const _RankingTile({
    required this.entry,
  });

  @override
  State<_RankingTile> createState() => _RankingTileState();
}

class _RankingTileState extends State<_RankingTile>
    with SingleTickerProviderStateMixin {
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.snappyEasing),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[600]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.orange[600]!;
      default:
        return const Color(0xFF9B59B6);
    }
  }

  String? _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }

  bool _isHighlight(int rank) => rank <= 3;

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(widget.entry.rank);
    final rankIcon = _getRankIcon(widget.entry.rank);
    final isHighlight = _isHighlight(widget.entry.rank);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHighlight ? Colors.amber[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlight
                  ? Colors.amber[200]!
                  : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              // 順位バッジ
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: rankIcon != null
                      ? Text(
                          rankIcon,
                          style: const TextStyle(fontSize: 20),
                        )
                      : Text(
                          '${widget.entry.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // 子ども情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.entry.avatarEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.entry.getDisplayName(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2C2C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '回答数: ${widget.entry.totalAnswers}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              // スコア表示
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.entry.totalGrowthScore}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9B59B6),
                    ),
                  ),
                  const Text(
                    'pt',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
