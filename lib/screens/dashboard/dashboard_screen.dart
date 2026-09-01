import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/badge.dart';
import '../../providers/child_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/ranking_provider.dart';

const _primaryColor = Color(0xFF9B59B6);
const _bgColor = Color(0xFFFAF9FF);
const _textPrimary = Color(0xFF2C2C2C);
const _textSecondary = Color(0xFF888888);

/// ダッシュボード画面 — 子どもの学習進捗を視覚的に表示
/// 統計情報、バッジ、アクティビティ、成長トレンドを表示
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = ref.watch(currentChildIdProvider);
    final childProfile = ref.watch(currentChildProfileProvider);

    if (childId == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: const Text('ダッシュボード'),
          backgroundColor: Colors.white,
          foregroundColor: _textPrimary,
          elevation: 0,
        ),
        body: const Center(
          child: Text('子どもを選択してください'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('ダッシュボード'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
      ),
      body: childProfile.when(
        data: (profile) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // グリーティング
                _GreetingSection(childName: profile?.name ?? 'ユーザー'),
                const SizedBox(height: 24),

                // 統計カード
                _StatsSection(childId: childId),
                const SizedBox(height: 24),

                // 学習進捗
                _ProgressSection(childId: childId),
                const SizedBox(height: 24),

                // 獲得バッジ
                _BadgesSection(childId: childId),
                const SizedBox(height: 24),

                // 徳目別スコア
                _VirtueScoresSection(childId: childId),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color(0xFF8E44AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return '🌅 おはよう';
    } else if (hour < 18) {
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
            .where((p) => p.action == 'story_completed')
            .length;

        return earnedBadges.when(
          data: (badges) {
            return GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                _StatCard(
                  icon: '⭐',
                  label: 'ポイント',
                  value: '$totalPoints',
                  color: Colors.amber,
                ),
                _StatCard(
                  icon: '📖',
                  label: 'ストーリー',
                  value: '$completedStories',
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: '🎖️',
                  label: 'バッジ',
                  value: '${badges.length}',
                  color: Colors.pink,
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

class _StatCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
        ],
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
            final maxCount = counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b) : 1;
            final dayLabels = ['月', '火', '水', '木', '金', '土', '日'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 週間学習活動',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int i = 0; i < counts.length; i++)
                        _BarChartItem(
                          day: dayLabels[i],
                          count: counts[i],
                          maxCount: maxCount,
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
    final height = (count / (maxCount > 0 ? maxCount : 1)) * 100;

    return Column(
      children: [
        if (count > 0)
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          )
        else
          const SizedBox(height: 16),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            color: _textSecondary,
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
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFEEEEEE)),
                ),
                child: const Center(
                  child: Text(
                    'ストーリーを完了してバッジを獲得しよう！',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
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
                    color: _textPrimary,
                  ),
                ),
                Text(
                  '全${badges.length}個',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
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

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _primaryColor.withAlpha(100),
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
                              color: _textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 徳目別学習進捗',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...virtueColors.entries.map((entry) {
              final virtue = entry.key;
              final color = entry.value;
              final count = progressList.fold<int>(
                0,
                (sum, p) => sum + (p.virtue == virtue ? 1 : 0),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFEEEEEE)),
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
                                color: _textPrimary,
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
