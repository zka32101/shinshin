import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show missionProvider, coinProvider, RewardType;

/// デイリーミッション一覧画面（Phase 4.5）
///
/// ユーザーが本日達成できるミッションを表示し、
/// 完了したミッションから報酬（コイン・バッジ）を獲得できる。
class MissionScreen extends ConsumerWidget {
  const MissionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionState = ref.watch(missionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('デイリーミッション'),
        elevation: 0,
      ),
      body: missionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : missionState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('エラーが発生しました: ${missionState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // ミッションを再読み込み
                          ref.read(missionProvider.notifier).initializeMissions('current_user');
                        },
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                )
              : missionState.missions.isEmpty
                  ? const Center(child: Text('ミッションがありません'))
                  : _MissionList(missions: missionState.missions, totalCoins: missionState.totalCoinsToday),
    );
  }
}

/// ミッション一覧ウィジェット
class _MissionList extends ConsumerWidget {
  final List<dynamic> missions;
  final int totalCoins;

  const _MissionList({
    required this.missions,
    required this.totalCoins,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ミッションを難易度別にグループ化
    final easyMissions = missions.where((m) => m.mission.difficulty.toString().contains('easy')).toList();
    final normalMissions = missions.where((m) => m.mission.difficulty.toString().contains('normal') && !m.mission.difficulty.toString().contains('hard')).toList();
    final hardMissions = missions.where((m) => m.mission.difficulty.toString().contains('hard')).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 本日獲得可能コイン表示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[300]!, Colors.orange[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('本日獲得可能', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        '$totalCoins コイン',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 簡単ミッション
          if (easyMissions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '簡単',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ..._buildMissionTiles(easyMissions, ref),
            const SizedBox(height: 16),
          ],

          // 普通ミッション
          if (normalMissions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '普通',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ..._buildMissionTiles(normalMissions, ref),
            const SizedBox(height: 16),
          ],

          // 難しいミッション
          if (hardMissions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '難しい',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ..._buildMissionTiles(hardMissions, ref),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMissionTiles(List<dynamic> missionList, WidgetRef ref) {
    return missionList.map((item) => _MissionTile(missionItem: item, ref: ref)).toList();
  }
}

/// ミッション個別タイルウィジェット
class _MissionTile extends ConsumerWidget {
  final dynamic missionItem;
  final WidgetRef ref;

  const _MissionTile({required this.missionItem, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mission = missionItem.mission;
    final progress = missionItem.progress;
    final isCompleted = missionItem.progressPercentage >= 100.0 && progress?.completed == true;
    final progressPercentage = missionItem.progressPercentage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.grey[300]!,
            width: isCompleted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isCompleted ? Colors.green[50] : Colors.white,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ミッションタイトルと報酬
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mission.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                  ),
                ),
                // 報酬表示
                ..._buildRewardBadges(mission.rewards),
              ],
            ),
            const SizedBox(height: 8),

            // ミッション説明
            Text(
              mission.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),

            // 進捗バー
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressPercentage / 100.0,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${progress?.currentValue ?? 0}/${mission.targetValue}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 達成ボタン
            Align(
              alignment: Alignment.centerRight,
              child: isCompleted
                  ? ElevatedButton.icon(
                      onPressed: () => _claimReward(ref),
                      icon: const Icon(Icons.check),
                      label: const Text('達成！'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: null,
                      child: Text(
                        '進行中 (${(progressPercentage).toStringAsFixed(0)}%)',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _claimReward(WidgetRef ref) async {
    final mission = missionItem.mission;
    final rewards = await ref.read(missionProvider.notifier).awardMissionRewards(
          userId: 'current_user',
          missionId: mission.missionId,
        );

    // コイン報酬があればコインプロバイダーに追加
    if (rewards.containsKey('coins')) {
      ref.read(coinProvider.notifier).addCoins(rewards['coins']!);
    }

    // ユーザーにフィードバック
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text('ミッション達成！${rewards['coins'] ?? 0}コイン獲得しました'),
        duration: const Duration(seconds: 2),
      ),
    );

    // ミッション状態を再読み込み
    ref.read(missionProvider.notifier).initializeMissions('current_user');
  }

  List<Widget> _buildRewardBadges(List<dynamic> rewards) {
    return rewards.map((reward) {
      IconData iconData = Icons.card_giftcard;
      String label = '';

      if (reward.type == RewardType.coins) {
        iconData = Icons.monetization_on;
        label = '${reward.amount}';
      } else if (reward.type == RewardType.badges) {
        iconData = Icons.star;
        label = 'バッジ';
      } else if (reward.type == RewardType.characterExp) {
        iconData = Icons.favorite;
        label = '経験値';
      }

      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Tooltip(
          message: label,
          child: Icon(iconData, size: 20, color: Colors.amber),
        ),
      );
    }).toList();
  }
}
