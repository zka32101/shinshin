import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/distribution_response.dart';
import '../../providers/distribution_provider.dart';

class DistributionWidget extends ConsumerWidget {
  final String storyId;
  final String userChoice;

  const DistributionWidget({
    Key? key,
    required this.storyId,
    required this.userChoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(distributionProvider(storyId));

    return distributionAsync.when(
      data: (distribution) => _buildContent(context, distribution),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
    );
  }

  Widget _buildContent(BuildContext context, DistributionResponse distribution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ぜんこくの こどもたちは どう えらんだ？',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...distribution.options.map((option) =>
            DistributionBar(
              option: option.option,
              text: option.text,
              percentage: option.percentage,
              count: option.count,
              isUserChoice: option.option == userChoice,
            )).toList(),
        const SizedBox(height: 12),
        Text(
          'ぜんぶで ${distribution.totalResponses} にんの こどもが こたえました',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class DistributionBar extends StatelessWidget {
  final String option;
  final String text;
  final double percentage;
  final int count;
  final bool isUserChoice;

  const DistributionBar({
    Key? key,
    required this.option,
    required this.text,
    required this.percentage,
    required this.count,
    required this.isUserChoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isUserChoice ? Colors.orange : Colors.blue,
                  border: isUserChoice
                      ? Border.all(color: Colors.orange, width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 20,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      isUserChoice ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
