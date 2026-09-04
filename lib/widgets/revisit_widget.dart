import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/revisit_schedule.dart';
import '../../providers/revisit_provider.dart';

class RevisitStoriesListWidget extends ConsumerWidget {
  final String userId;

  const RevisitStoriesListWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revisitStoriesAsync = ref.watch(revisitStoriesProvider(userId));

    return revisitStoriesAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return Center(
            child: Text('このつき、さいほうの ストーリーはありません'),
          );
        }
        return ListView.builder(
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return RevisitStoryCard(
              story: story,
              userId: userId,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
    );
  }
}

class RevisitStoryCard extends StatelessWidget {
  final RevisitStory story;
  final String userId;

  const RevisitStoryCard({
    Key? key,
    required this.story,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '3ヶ月前のきみ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              story.preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              '3ヶ月前: ${story.originalAnswer} を えらんだよ',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RevisitStoryDetailScreen(
                      story: story,
                      userId: userId,
                    ),
                  ),
                );
              },
              child: const Text('もういちど かんがえる'),
            ),
          ],
        ),
      ),
    );
  }
}

class RevisitStoryDetailScreen extends ConsumerStatefulWidget {
  final RevisitStory story;
  final String userId;

  const RevisitStoryDetailScreen({
    Key? key,
    required this.story,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState createState() => _RevisitStoryDetailScreenState();
}

class _RevisitStoryDetailScreenState extends ConsumerState<RevisitStoryDetailScreen> {
  String? selectedChoice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('あのときのきみ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange[50],
              child: const Text(
                '3ヶ月前に このストーリーに こたえました！\nもういちど かんがえてみよう。',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.story.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(widget.story.preview),
            const SizedBox(height: 24),
            if (selectedChoice == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'どうしますか？',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => selectedChoice = 'A'),
                    child: const Text('A を えらぶ'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => selectedChoice = 'B'),
                    child: const Text('B を えらぶ'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => selectedChoice = 'C'),
                    child: const Text('C を えらぶ'),
                  ),
                ],
              )
            else
              RevisitResultDisplay(
                story: widget.story,
                currentChoice: selectedChoice!,
              ),
          ],
        ),
      ),
    );
  }
}

class RevisitResultDisplay extends ConsumerWidget {
  final RevisitStory story;
  final String currentChoice;

  const RevisitResultDisplay({
    Key? key,
    required this.story,
    required this.currentChoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(
      revisitResultProvider((story.revisitId, currentChoice)),
    );

    return resultAsync.when(
      data: (result) => _buildResult(context, result),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
    );
  }

  Widget _buildResult(BuildContext context, RevisitResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.isChanged ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3ヶ月前のきみ: ${result.originalChoice}',
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Text(
            'きょうのきみ: $currentChoice',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          if (result.isChanged)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '✨ えらぶときが かわったね！\nきみは いろいろ かんがえて すすんでるよ。',
                style: TextStyle(fontSize: 12),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '✓ 3ヶ月たっても おなじえらぶを する！\nきみの かんがえは ぶれていないんだね。',
                style: TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Text(result.message),
        ],
      ),
    );
  }
}
