import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/badge.dart';
import '../../providers/child_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common_states.dart';
import '../../utils/logging_utils.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';

/// ダッシュボード画面 — 子どもの学習進捗を視覚的に表示
/// 統計情報、バッジ、アクティビティ、成長トレンドを表示
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimization: Only watch specific needed values, not full provider objects
    final childId = ref.watch(currentChildIdProvider);

    if (childId == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('ダッシュボード'),
          backgroundColor: AppColors.bgSecondary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: CommonEmptyState(
          message: '子どもを選択してください',
          icon: Icons.person_outline,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('ダッシュボード'),
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _DashboardContent(childId: childId),
    );
  }
}

/// Extracted to reduce rebuild frequency and isolate provider dependencies
/// Handles loading/error states with RefreshIndicator for data refresh
class _DashboardContent extends ConsumerWidget {
  final String childId;

  const _DashboardContent({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the full profile for state handling
    final childProfile = ref.watch(currentChildProfileProvider);

    return childProfile.when(
      data: (profile) => RefreshIndicator(
        onRefresh: () async {
          // ダッシュボード関連データの再取得
          ref.invalidate(currentChildProfileProvider);
          ref.invalidate(userProgressProvider(childId));
          ref.invalidate(earnedBadgesProvider(childId));
          ref.invalidate(rankingProvider);
          // リフレッシュ完了待ち
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: AnimatedFadeInScale(
          duration: AnimationDurations.medium,
          beginScale: 0.95,
          endScale: 1.0,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // グリーティング
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: Duration(milliseconds: 100),
                    child: _GreetingSection(childName: profile?.name ?? 'ユーザー'),
                  ),
                  const SizedBox(height: 24),

                  // 統計カード
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: Duration(milliseconds: 200),
                    child: _StatsSection(childId: childId),
                  ),
                  const SizedBox(height: 24),

                  // 学習進捗
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: Duration(milliseconds: 300),
                    child: _ProgressSection(childId: childId),
                  ),
                  const SizedBox(height: 24),

                  // 獲得バッジ
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: Duration(milliseconds: 400),
                    child: _BadgesSection(childId: childId),
                  ),
                  const SizedBox(height: 24),

                  // 徳目別スコア
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: Duration(milliseconds: 500),
                    child: _VirtueScoresSection(childId: childId),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      loading: () => const CommonLoadingState(),
      error: (error, _) => CommonErrorState(error: error.toString()),
    );
  }
}

// ─── グリーティングセクション ─────────────────────────

class _GreetingSection extends StatelessWidget {
  final String childName;

  const _GreetingSection({required this.childName});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = _getGreeting(hour);

    return AnimatedBounce(
      duration: AnimationDurations.long,
      scale: 1.0,
      delay: Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$childNameさん',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '今日も頑張ろう！',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < AppConstants.morningBoundary) {
      return '🌅 おはよう';
    } else if (hour < AppConstants.afternoonBoundary) {
      return '☀️ こんにちは';
    } else {
      return '🌙 こんばんは';
    }
  }
}

// ─── 統計セクション ────────────────────────────────

class _StatsSection extends ConsumerWidget {
  final String childId;

  const _StatsSection({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider(childId));
    final earnedBadges = ref.watch(earnedBadgesProvider(childId));

    return progress.when(
      data: (progressList) {
        // 総ポイントを計算
        final totalPoints = progressList.fold<int>(
          0,
          (sum, p) => sum + p.pointsDelta,
        );

        // 完了したストーリー数
        final completedStories = progressList
            .where((p) => p.action == AppConstants.actionStoryCompleted)
            .length;

        return earnedBadges.when(
          data: (badges) {
            final statItems = [
              (icon: '⭐', label: 'ポイント', value: '$totalPoints', color: Colors.amber),
              (icon: '📖', label: 'ストーリー', value: '$completedStories', color: Colors.blue),
              (icon: '🎖️', label: 'バッジ', value: '${badges.length}', color: Colors.pink),
            ];

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statItems.length,
              itemBuilder: (context, index) {
                final item = statItems[index];
                return AnimatedSlideIn(
                  direction: SlideDirection.fromBottom,
                  duration: AnimationDurations.medium,
                  delay: Duration(milliseconds: 250 + (index * 100)),
                  child: _StatCard(
                    icon: item.icon,
                    label: item.label,
                    value: item.value,
                    color: item.color,
                  ),
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('エラー: $error'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('エラー: $error'),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(_isPressed ? 30 : AppConstants.alphaLight),
                blurRadius: _isPressed ? 4 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.icon,
                style: const TextStyle(fontSize: AppStyles.fontSizeEmoji),
              ),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: AppStyles.fontSizePageTitle,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: AppStyles.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 学習進捗セクション ────────────────────────────

class _ProgressSection extends ConsumerWidget {
  final String childId;

  const _ProgressSection({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider(childId));

    return progress.when(
      data: (progressList) {
        // 過去7日間の学習件数
        final weeklyActivity = ref.watch(weeklyActivityProvider(childId));

        return weeklyActivity.when(
          data: (counts) {
            final maxCount = counts.isNotEmpty
                ? counts.reduce((a, b) => a > b ? a : b)
                : 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 週間学習活動',
                  style: TextStyle(
                    fontSize: AppStyles.fontSizeTitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppStyles.radiusMedium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int i = 0; i < counts.length; i++)
                        AnimatedSlideIn(
                          direction: SlideDirection.fromBottom,
                          duration: AnimationDurations.medium,
                          delay: Duration(milliseconds: 350 + (i * 75)),
                          child: _BarChartItem(
                            day: AppConstants.dayLabels[i],
                            count: counts[i],
                            maxCount: maxCount,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('エラー: $error'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('エラー: $error'),
    );
  }
}

class _BarChartItem extends StatelessWidget {
  final String day;
  final int count;
  final int maxCount;

  const _BarChartItem({
    required this.day,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final height = (count / (maxCount > 0 ? maxCount : 1)) *
        AppConstants.minBarChartHeight;

    return Column(
      children: [
        if (count > 0)
          Text(
            '$count',
            style: const TextStyle(
              fontSize: AppStyles.fontSizeSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          )
        else
          const SizedBox(height: 16),
        const SizedBox(height: 4),
        Container(
          width: AppConstants.barWidth,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: AppStyles.fontSizeSmall,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── 獲得バッジセクション ──────────────────────────

class _BadgesSection extends ConsumerWidget {
  final String childId;

  const _BadgesSection({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnedBadges = ref.watch(earnedBadgesProvider(childId));

    return earnedBadges.when(
      data: (badges) {
        if (badges.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎖️ 獲得したバッジ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'ストーリーを完了してバッジを獲得しよう！',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }

        // 最新の3つのバッジを表示
        final recentBadges = badges.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎖️ 最近獲得したバッジ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '全${badges.length}個',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentBadges.length,
                itemBuilder: (context, index) {
                  final earnedBadge = recentBadges[index];
                  final badgeDef = findBadge(earnedBadge.badgeId);

                  if (badgeDef == null) return const SizedBox.shrink();

                  return AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: Duration(milliseconds: 450 + (index * 100)),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(AppConstants.alphaHighlight),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            badgeDef.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(
                              badgeDef.name,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('エラー: $error'),
    );
  }
}

// ─── 徳目別スコアセクション ────────────────────────

class _VirtueScoresSection extends ConsumerWidget {
  final String childId;

  const _VirtueScoresSection({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider(childId));

    return progress.when(
      data: (progressList) {
        // 徳目別に完了数をカウント
        final virtueColors = {
          'kindness': Colors.pink,
          'honesty': Colors.blue,
          'courage': Colors.red,
          'respect': Colors.green,
          'cooperation': Colors.orange,
          'responsibility': Colors.purple,
        };

        final virtueLabels = {
          'kindness': '思いやり',
          'honesty': '正直',
          'courage': '勇気',
          'respect': '礼儀',
          'cooperation': '協力',
          'responsibility': '責任',
        };

        final virtueEmojis = {
          'kindness': '💜',
          'honesty': '💛',
          'courage': '❤️',
          'respect': '💚',
          'cooperation': '🧡',
          'responsibility': '💙',
        };

        final virtueEntries = virtueColors.entries.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 徳目別学習進捗',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(virtueEntries.length, (index) {
              final entry = virtueEntries[index];
              final virtue = entry.key;
              final color = entry.value;
              final count = progressList.fold<int>(
                0,
                (sum, p) => sum + (p.virtue == virtue ? 1 : 0),
              );

              return AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 550 + (index * 80)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          virtueEmojis[virtue] ?? '⭐',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                virtueLabels[virtue] ?? virtue,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: (count / (count + 2)).clamp(0, 1),
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$count本',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('エラー: $error'),
    );
  }
}
