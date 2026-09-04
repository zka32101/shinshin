import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kindness_mission.dart';
import '../../providers/kindness_provider.dart';
import '../../services/api_service.dart';

class KindnessMissionWidget extends ConsumerWidget {
  final String userId;

  const KindnessMissionWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(currentKindnessMissionProvider(userId));

    return missionAsync.when(
      data: (mission) => _buildMission(context, ref, mission),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => SizedBox.shrink(),
    );
  }

  Widget _buildMission(
    BuildContext context,
    WidgetRef ref,
    KindnessMission mission,
  ) {
    final progress = mission.completedCount / mission.targetCount;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌟 やさしさ さがし',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '今週、だれかの「やさしいな」を ${mission.targetCount} つ さがそう',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '${mission.completedCount}/${mission.targetCount}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (mission.completedCount < mission.targetCount)
              ElevatedButton(
                onPressed: () => _showRecordDialog(context, ref),
                child: const Text('やさしさを きろくする'),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '✅ ミッション完了！',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRecordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => KindnessRecordDialog(userId: userId),
    );
  }
}

class KindnessRecordDialog extends ConsumerStatefulWidget {
  final String userId;

  const KindnessRecordDialog({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState createState() => _KindnessRecordDialogState();
}

class _KindnessRecordDialogState extends ConsumerState<KindnessRecordDialog> {
  late TextEditingController _descriptionController;
  String? _selectedPerson;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('やさしさを きろく'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'だれが どんなやさしさを してくれた？',
                hintText: '例：おにいちゃんが ぼくの分も おかし のこしてくれた',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPerson,
              decoration: const InputDecoration(labelText: 'だれですか？'),
              items: [
                '家族の人',
                '先生',
                'ともだち',
                'その他'
              ]
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedPerson = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () async {
            final apiService = ref.read(apiServiceProvider);
            try {
              await apiService.recordKindness(
                widget.userId,
                _descriptionController.text,
                _selectedPerson,
                null,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('きろく しました！')),
              );
              ref.refresh(currentKindnessMissionProvider(widget.userId));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('エラー: $e')),
              );
            }
          },
          child: const Text('きろく'),
        ),
      ],
    );
  }
}

class KindnessMapWidget extends ConsumerWidget {
  final String userId;
  final String month;

  const KindnessMapWidget({
    Key? key,
    required this.userId,
    required this.month,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(kindnessMapProvider((userId, month)));

    return mapAsync.when(
      data: (map) => _buildMap(context, map),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
    );
  }

  Widget _buildMap(BuildContext context, KindnessMap map) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$month の やさしさ',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '合わせて ${map.totalFindings} つ のやさしさを さがしました',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        ...map.byCategory.entries.map((entry) =>
            KindnessCategoryCard(
              category: entry.key,
              findings: entry.value,
            )),
      ],
    );
  }
}

class KindnessCategoryCard extends StatelessWidget {
  final String category;
  final List<KindnessFinding> findings;

  const KindnessCategoryCard({
    Key? key,
    required this.category,
    required this.findings,
  }) : super(key: key);

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'family':
        return '👨‍👩‍👧';
      case 'school':
        return '🏫';
      case 'community':
        return '🌍';
      default:
        return '✨';
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'family':
        return '家族';
      case 'school':
        return '学校';
      case 'community':
        return 'その他';
      default:
        return 'カテゴリ';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getCategoryEmoji(category)} ${_getCategoryName(category)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...findings.map((f) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.description, style: const TextStyle(fontSize: 12)),
                            if (f.person != null)
                              Text(
                                '（${f.person}）',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
          ],
        ),
      ),
    );
  }
}
