import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_card.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ranking.dart';
import '../../providers/ranking_provider.dart';
import '../../services/ranking_service.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';

/// ランキング表示画面
/// ユーザーのランキング順位と周辺のプレイヤーを表示
class RankingListScreen extends ConsumerStatefulWidget {
  final RankingType rankingType;

  const RankingListScreen({
    super.key,
    required this.rankingType,
  });

  @override
  ConsumerState<RankingListScreen> createState() => _RankingListScreenState();
}

class _RankingListScreenState extends ConsumerState<RankingListScreen> {
  @override
  Widget build(BuildContext context) {
    final nearbyEntries = ref.watch(
      nearbyRankingEntriesProvider(widget.rankingType),
    );

    final userRank = ref.watch(
      userRankInTypeProvider(widget.rankingType),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(RankingService.getRankingTypeLabel(widget.rankingType)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: AnimatedFadeInScale(
        duration: AnimationDurations.medium,
        beginScale: 0.95,
        endScale: 1.0,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ユーザーの順位表示
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: userRank.when(
                    data: (rank) => _buildUserRankCard(rank),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stackTrace) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'エラーが発生しました: $error',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ),
                ),
              ),
              // 周辺ランキングエントリ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: nearbyEntries.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        child: const Text(
                          'ランキング情報がありません',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        AnimatedSlideIn(
                          direction: SlideDirection.fromBottom,
                          duration: AnimationDurations.medium,
                          delay: const Duration(milliseconds: 200),
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'あなたの周辺ランキング',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9B59B6),
                              ),
                            ),
                          ),
                        ),
                        ...entries
                            .asMap()
                            .entries
                            .map((e) => AnimatedSlideIn(
                              direction: SlideDirection.fromBottom,
                              duration: AnimationDurations.medium,
                              delay: Duration(milliseconds: 250 + (e.key * 75)),
                              child: _buildRankingTile(e.value),
                            ))
                            .toList(),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'エラーが発生しました: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// ユーザーの現在の順位カード
  Widget _buildUserRankCard(int? rank) {
    if (rank == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Text(
              'ランキング参加中',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9B59B6),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ランキング情報がまだ取得されていません',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9B59B6),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'あなたの現在の順位',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '第 $rank 位',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9B59B6),
            ),
          ),
        ],
      ),
    );
  }

  /// ランキングエントリタイル
  Widget _buildRankingTile(RankingEntry entry) {
    return _RankingTile(entry: entry, getRankColor: _getRankColor, getRankIcon: _getRankIcon);
  }

  /// 順位に応じた色を取得
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

  /// 順位に応じたアイコンを取得
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
}

// ─── ランキングタイル ──────────────────────

class _RankingTile extends StatefulWidget {
  final RankingEntry entry;
  final Color Function(int) getRankColor;
  final String? Function(int) getRankIcon;

  const _RankingTile({
    required this.entry,
    required this.getRankColor,
    required this.getRankIcon,
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

  @override
  Widget build(BuildContext context) {
    final isHighlight = widget.entry.rank == 1 ||
        widget.entry.rank == 2 ||
        widget.entry.rank == 3;
    final rankColor = widget.getRankColor(widget.entry.rank);
    final rankIcon = widget.getRankIcon(widget.entry.rank);

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
              color: isHighlight ? Colors.amber[200]! : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              // 順位アイコン
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: rankIcon != null
                      ? Text(
                          rankIcon,
                          style: const TextStyle(fontSize: 18),
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
              // ユーザー情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.getDisplayName(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.entry.score} ポイント',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              // スコア表示
              Text(
                '${widget.entry.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
