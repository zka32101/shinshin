import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/badge.dart';
import '../../providers/progress_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/badge_provider.dart';
import '../../utils/sound_effects_utils.dart';

const _primaryColor = Color(0xFF9B59B6);
const _bgColor = Color(0xFFFAF9FF);
const _textPrimary = Color(0xFF2C2C2C);
const _textSecondary = Color(0xFF888888);

/// バッジ図鑑画面 — 獲得可能なすべてのバッジと進捗を表示
class BadgeShowcaseScreen extends ConsumerWidget {
  const BadgeShowcaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = ref.watch(currentChildIdProvider);

    if (childId == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: const Text('バッジ図鑑'),
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
        title: const Text('バッジ図鑑'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
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

            const SizedBox(height: 24),

            // バッジカテゴリ
            _BadgeCategorySection(
              title: 'すべてのバッジ',
              description: 'ストーリー完了で獲得',
              badges: kDoutokuBadges,
              childId: childId,
            ),
          ],
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
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
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
                    color: _textSecondary,
                  ),
                ),
              ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                for (final badge in themeGroups[theme]!)
                  _BadgeCard(
                    badge: badge,
                    childId: childId,
                    progressList: progressList,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return widgets;
  }
}

// ─── バッジカード ──────────────────────────────────

class _BadgeCard extends ConsumerWidget {
  final BadgeDefinition badge;
  final String childId;
  final List progressList;

  const _BadgeCard({
    required this.badge,
    required this.childId,
    required this.progressList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnedBadges = ref.watch(earnedBadgesProvider(childId));

    return earnedBadges.when(
      data: (badges) {
        final isEarned = badges.any((eb) => eb.badgeId == badge.id);
        final earnedDate = isEarned
            ? badges.firstWhere((eb) => eb.badgeId == badge.id).earnedAt
            : null;

        // 進捗を計算
        double progress = 0;
        if (badge.theme != 'all') {
          // 徳目別バッジの場合
          final virtueProgress = progressList.firstWhere(
            (p) => p.virtue == badge.theme,
            orElse: () => null,
          );
          if (virtueProgress != null) {
            progress = (virtueProgress.completionCount / badge.requiredCompletions).clamp(0, 1).toDouble();
          }
        } else {
          // 全テーマバッジの場合、全体の完了数を数える
          final totalCompleted = progressList.fold<int>(
            0,
            (sum, p) => sum + (p.completionCount as int),
          );
          progress = (totalCompleted / badge.requiredCompletions).clamp(0, 1).toDouble();
        }

        return GestureDetector(
          onTap: () {
            // バッジをタップした際の音声効果
            if (isEarned) {
              SoundEffectsUtils(ref).playBadgeUnlockSound();
            } else {
              SoundEffectsUtils(ref).playButtonTapSound();
            }
            showDialog(
              context: context,
              builder: (ctx) => _BadgeDetailDialog(
                badge: badge,
                isEarned: isEarned,
                earnedDate: earnedDate,
                progress: progress,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isEarned ? Colors.white : Colors.white70,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEarned ? _primaryColor.withAlpha(100) : Color(0xFFDDDDDD),
                width: 2,
              ),
              boxShadow: [
                if (isEarned)
                  BoxShadow(
                    color: _primaryColor.withAlpha(30),
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
                      badge.emoji,
                      style: TextStyle(
                        fontSize: isEarned ? 36 : 28,
                        opacity: isEarned ? 1.0 : 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        badge.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isEarned ? _textPrimary : _textSecondary,
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
                            valueColor: AlwaysStoppedAnimation(_primaryColor.withAlpha(150)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 8,
                            color: _textSecondary,
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
      backgroundColor: Colors.white,
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
              color: _textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            badge.description,
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
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
