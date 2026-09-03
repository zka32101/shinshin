import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/parent_child_comparison.dart';
import '../../providers/parent_child_provider.dart';

class ParentChildComparisonWidget extends ConsumerWidget {
  final String parentId;
  final String childId;

  const ParentChildComparisonWidget({
    Key? key,
    required this.parentId,
    required this.childId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(
      latestParentChildComparisonProvider((parentId, childId)),
    );

    return latestAsync.when(
      data: (comparison) {
        if (comparison == null) {
          return const SizedBox.shrink();
        }
        return _buildComparison(context, comparison);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildComparison(
    BuildContext context,
    ParentChildComparison comparison,
  ) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'パパ・ママ との じれんま',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // 子どもの選択
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'きみ',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          comparison.childChoiceLetter,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comparison.childChoiceText,
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 親の選択
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'パパ・ママ',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          comparison.parentChoiceLetter,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comparison.parentChoiceText,
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                comparison.guidance,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentChildDialogueHistoryWidget extends ConsumerWidget {
  final String parentId;
  final String childId;

  const ParentChildDialogueHistoryWidget({
    Key? key,
    required this.parentId,
    required this.childId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiesAsync = ref.watch(
      parentChildHistoryProvider((parentId, childId)),
    );

    return historiesAsync.when(
      data: (histories) {
        if (histories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('まだ 親子で かんがえた じれんまは ありません'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: histories.length,
          itemBuilder: (context, index) {
            final history = histories[index];
            return ParentChildHistoryCard(comparison: history);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
    );
  }
}

class ParentChildHistoryCard extends StatelessWidget {
  final ParentChildComparison comparison;

  const ParentChildHistoryCard({
    Key? key,
    required this.comparison,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comparison.storyTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text('きみ: ${comparison.childChoiceLetter}'),
                  backgroundColor: Colors.blue[100],
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('親: ${comparison.parentChoiceLetter}'),
                  backgroundColor: Colors.orange[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comparison.guidance,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
