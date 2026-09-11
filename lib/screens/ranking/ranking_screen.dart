import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show globalRankingProvider, subjectRankingStreamProvider;

import '../../models/ranking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../services/ranking_service.dart';
import 'ranking_settings_screen.dart';

/// グローバルランキング画面
/// 3タブで構成：グローバル、教科別（道徳）、フレンド
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
              Tab(text: 'グローバル'),
              Tab(text: '道徳'),
              Tab(text: 'フレンド'),
            ],
            labelColor: Colors.pink,
            unselectedLabelColor: Color(0xFF999999),
            indicatorColor: Colors.pink,
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalRankingTab(),
            _MoralityRankingTab(),
            _FriendRankingTab(),
          ],
        ),
      ),
    );
  }
}

/// グローバルランキングタブ
class _GlobalRankingTab extends ConsumerWidget {
  const _GlobalRankingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(globalRankingProvider); // 初期読み込み時に自動取得

    return FutureBuilder<void>(
      future: ref.read(globalRankingProvider.notifier).fetchGlobalRanking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final state = ref.watch(globalRankingProvider);
        if (state.error != null) {
          return Center(child: Text('エラー: ${state.error}'));
        }

        if (state.entries.isEmpty) {
          return const Center(child: Text('ランキングデータがありません'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.entries.length,
          itemBuilder: (context, index) {
            final entry = state.entries[index];
            final rank = index + 1;
            return _GlobalRankEntryCard(rank: rank, entry: entry);
          },
        );
      },
    );
  }
}

/// 道徳ランキングタブ（教科別）
///
/// Phase 4.3: subjectRankingStreamProvider('doutoku') でリアルタイム教科別ランキングを表示
class _MoralityRankingTab extends ConsumerWidget {
  const _MoralityRankingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectRanking = ref.watch(subjectRankingStreamProvider('doutoku'));

    return subjectRanking.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('教科別ランキングデータがありません'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;
            return _SubjectRankEntryCard(rank: rank, entry: entry);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('エラー: $err'),
      ),
    );
  }
}

/// フレンドランキングタブ
class _FriendRankingTab extends ConsumerWidget {
  const _FriendRankingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingService = ref.watch(rankingServiceProvider);
    final auth = ref.watch(userAuthStateProvider);

    final userId = auth.maybeWhen(
      data: (user) => user?.uid,
      orElse: () => null,
    );

    if (userId == null) {
      return const Center(child: Text('ユーザーが見つかりません'));
    }

    return FutureBuilder<List<RankingEntry>>(
      future: rankingService.getMonthlyRanking(
        RankingGroupType.friends,
        groupValue: userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(child: Text('フレンドがまだ追加されていません'));
        }
        return _buildFriendRankingList(entries);
      },
    );
  }
}

/// グローバルランキングエントリカード（Phase 4.3）
class _GlobalRankEntryCard extends StatelessWidget {
  final int rank;
  final dynamic entry; // GlobalRankingEntry

  const _GlobalRankEntryCard({
    required this.rank,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    String rankMedal = '';
    if (rank == 1) {
      rankMedal = '🥇';
    } else if (rank == 2) {
      rankMedal = '🥈';
    } else if (rank == 3) {
      rankMedal = '🥉';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (rankMedal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  rankMedal,
                  style: const TextStyle(fontSize: 24),
                ),
              )
            else
              SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username ?? 'Player',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.totalScore} pt',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '${entry.totalScore}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.pink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 教科別ランキングエントリカード（Phase 4.3）
class _SubjectRankEntryCard extends StatelessWidget {
  final int rank;
  final dynamic entry; // SubjectRankingEntry

  const _SubjectRankEntryCard({
    required this.rank,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    String rankMedal = '';
    if (rank == 1) {
      rankMedal = '🥇';
    } else if (rank == 2) {
      rankMedal = '🥈';
    } else if (rank == 3) {
      rankMedal = '🥉';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (rankMedal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  rankMedal,
                  style: const TextStyle(fontSize: 24),
                ),
              )
            else
              SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username ?? 'Player',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.score} pt',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '${entry.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.pink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
