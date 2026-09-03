import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/badge.dart';
import '../../providers/progress_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/badge_provider.dart';
import '../../utils/sound_effects_utils.dart';
import '../../utils/animation_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/common_states.dart';
import '../../widgets/animations/index.dart';

/// バッジ図鑑画面 — 獲得可能なすべてのバッジと進捗を表示
class BadgeShowcaseScreen extends ConsumerWidget {
  const BadgeShowcaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = ref.watch(currentChildIdProvider);

    if (childId == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('バッジ図鑑'),
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
        title: const Text('バッジ図鑑'),
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: AnimatedFadeInScale(
        duration: AnimationDurations.medium,
        beginScale: 0.95,
        endScale: 1.0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'バッジ図鑑へようこそ！',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ストーリーを完了してバッジを集めよう',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BadgeStatsSummary(childId: childId),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // バッジカテゴリ
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: const Duration(milliseconds: 200),
                child: _BadgeCategorySection(
                  title: 'すべてのバッジ',
                  description: 'ストーリー完了で獲得',
                  badges: kDoutokuBadges,
                  childId: childId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── バッジ統計概要 ────────────────────────────────

class _BadgeStatsSummary extends ConsumerWidget {
  final String childId;

  const _BadgeStatsSummary({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider(childId));

    return progress.when(
      data: (progressList) {
        // 獲得済みバッジをカウント
        final earnedBadgesSet = <String>{};
        for (final p in progressList) {
          for (final badge in kDoutokuBadges) {
            if (badge.theme == 'all' || badge.theme == p.virtue) {
              if (p.completionCount >= badge.requiredCompletions) {
                earnedBadgesSet.add(badge.id);
              }
            }
          }
        }

        final totalBadges = kDoutokuBadges.length;
        final earnedCount = earnedBadgesSet.length;

        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$earnedCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '獲得済み',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white30,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$totalBadges',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '全バッジ',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('エラー: $error'),
    );
  }
}

// ─── バッジカテゴリセクション ──────────────────────

class _BadgeCategorySection extends ConsumerWidget {
  final String title;
  final String description;
  final List<BadgeDefinition> badges;
  final String childId;

  const _BadgeCategorySection({
    required this.title,
    required this.description,
    required this.badges,
    required this.childId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider(childId));

    return progress.when(
      data: (progressList) {
        // 徳目別にグループ化
        final themeGroups = <String, List<BadgeDefinition>>{};
        for (final badge in badges) {
          themeGroups.putIfAbsent(badge.theme, () => []).add(badge);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // 徳目ごとにバッジを表示
            ..._buildBadgesByTheme(themeGroups, progressList),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('エラー: $error'),
    );
  }

  List<Widget> _buildBadgesByTheme(
    Map<String, List<BadgeDefinition>> themeGroups,
    List progressList,
  ) {
    final widgets = <Widget>[];
    const themeLabels = {
      'all': '全テーマ',
      'kindness': '思いやり',
      'honesty': '正直',
      'courage': '勇気',
      'respect': '礼儀',
      'cooperation': '協力',
      'responsibility': '責任',
    };

    int badgeIndex = 0;

    for (final theme in ['all', 'kindness', 'honesty', 'courage', 'respect', 'cooperation', 'responsibility']) {
      if (!themeGroups.containsKey(theme) || themeGroups[theme]!.isEmpty) {
        continue;
      }

      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (theme != 'all')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  themeLabels[theme] ?? theme,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: themeGroups[theme]!.length,
              itemBuilder: (context, index) {
                final badge = themeGroups[theme]![index];
                return AnimatedSlideIn(
                  direction: SlideDirection.fromBottom,
                  duration: AnimationDurations.medium,
                  delay: Duration(milliseconds: 100 + (badgeIndex * 50)),
                  child: _BadgeCard(
                    badge: badge,
                    childId: childId,
                    progressList: progressList,
                  ),
                );
              },
            ),
          ],
        ),
      );
      badgeIndex += themeGroups[theme]!.length;
    }

    return widgets;
  }
}

// ─── バッジカード ──────────────────────────────────

class _BadgeCard extends ConsumerStatefulWidget {
  final BadgeDefinition badge;
  final String childId;
  final List progressList;

  const _BadgeCard({
    required this.badge,
    required this.childId,
    required this.progressList,
  });

  @override
  ConsumerState<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends ConsumerState<_BadgeCard>
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
    final earnedBadges = ref.read(earnedBadgesProvider(widget.childId));
    earnedBadges.whenData((badges) {
      final isEarned = badges.any((eb) => eb.badgeId == widget.badge.id);
      final earnedDate = isEarned
          ? badges.firstWhere((eb) => eb.badgeId == widget.badge.id).earnedAt
          : null;

      // 進捗を計算
      double progress = 0;
      if (widget.badge.theme != 'all') {
        try {
          final virtueProgress = widget.progressList.firstWhere(
            (p) => p.virtue == widget.badge.theme,
            orElse: () => null,
          );
          if (virtueProgress != null && virtueProgress.completionCount != null) {
            final completionCount = virtueProgress.completionCount is int
                ? virtueProgress.completionCount as int
                : (virtueProgress.completionCount as num).toInt();
            progress = (completionCount / widget.badge.requiredCompletions).clamp(0, 1).toDouble();
          }
        } catch (e) {
          progress = 0;
        }
      } else {
        try {
          final totalCompleted = widget.progressList.fold<int>(
            0,
            (sum, p) {
              if (p.completionCount == null) return sum;
              final count = p.completionCount is int
                  ? p.completionCount as int
                  : (p.completionCount as num).toInt();
              return sum + count;
            },
          );
          progress = (totalCompleted / widget.badge.requiredCompletions).clamp(0, 1).toDouble();
        } catch (e) {
          progress = 0;
        }
      }

      // バッジをタップした際の音声効果
      if (isEarned) {
        SoundEffectsUtils(ref).playBadgeUnlockSound();
      } else {
        SoundEffectsUtils(ref).playButtonTapSound();
      }
      showDialog(
        context: context,
        builder: (ctx) => _BadgeDetailDialog(
          badge: widget.badge,
          isEarned: isEarned,
          earnedDate: earnedDate,
          progress: progress,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final earnedBadges = ref.watch(earnedBadgesProvider(widget.childId));

    return earnedBadges.when(
      data: (badges) {
        final isEarned = badges.any((eb) => eb.badgeId == widget.badge.id);

        // 進捗を計算
        double progress = 0;
        if (widget.badge.theme != 'all') {
          try {
            final virtueProgress = widget.progressList.firstWhere(
              (p) => p.virtue == widget.badge.theme,
              orElse: () => null,
            );
            if (virtueProgress != null && virtueProgress.completionCount != null) {
              final completionCount = virtueProgress.completionCount is int
                  ? virtueProgress.completionCount as int
                  : (virtueProgress.completionCount as num).toInt();
              progress = (completionCount / widget.badge.requiredCompletions).clamp(0, 1).toDouble();
            }
          } catch (e) {
            progress = 0;
          }
        } else {
          try {
            final totalCompleted = widget.progressList.fold<int>(
              0,
              (sum, p) {
                if (p.completionCount == null) return sum;
                final count = p.completionCount is int
                    ? p.completionCount as int
                    : (p.completionCount as num).toInt();
                return sum + count;
              },
            );
            progress = (totalCompleted / widget.badge.requiredCompletions).clamp(0, 1).toDouble();
          } catch (e) {
            progress = 0;
          }
        }

        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              decoration: BoxDecoration(
                color: isEarned ? Colors.white : Colors.white70,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEarned ? AppColors.primary.withAlpha(100) : Color(0xFFDDDDDD),
                  width: 2,
                ),
                boxShadow: [
                  if (isEarned)
                    BoxShadow(
                      color: AppColors.primary.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.badge.emoji,
                        style: TextStyle(
                          fontSize: isEarned ? 36 : 28,
                          opacity: isEarned ? 1.0 : 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          widget.badge.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isEarned ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // 進捗インジケーター（未取得の場合）
                  if (!isEarned)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3,
                              backgroundColor: Color(0xFFEEEEEE),
                              valueColor: AlwaysStoppedAnimation(AppColors.primary.withAlpha(150)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // 獲得済みチェックマーク
                  if (isEarned)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('エラー: $error'),
    );
  }
}

// ─── バッジ詳細ダイアログ ──────────────────────────

class _BadgeDetailDialog extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isEarned;
  final DateTime? earnedDate;
  final double progress;

  const _BadgeDetailDialog({
    required this.badge,
    required this.isEarned,
    required this.earnedDate,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(
        child: Text(
          badge.emoji,
          style: const TextStyle(fontSize: 48),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            badge.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (isEarned && earnedDate != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    '✅ 獲得済み',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ゲットした日: ${earnedDate!.year}年${earnedDate!.month}月${earnedDate!.day}日',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    '🎯 あと少し！',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '進捗: ${(progress * 100).toInt()}% (${badge.requiredCompletions}本完了で獲得)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.amber[100],
                      valueColor: AlwaysStoppedAnimation(Colors.amber[700]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
