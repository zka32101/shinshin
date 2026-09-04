import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_features.dart';
import '../../providers/ai_features_provider.dart';
import '../../services/api_service.dart';

// ③ りゆう記録分析ウィジェット（親レポート用）
class ReasonAnalysisWidget extends ConsumerWidget {
  final String userId;
  final String month;

  const ReasonAnalysisWidget({
    Key? key,
    required this.userId,
    required this.month,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(
      reasonAnalysisProvider((userId, month)),
    );

    return analysisAsync.when(
      data: (analysis) {
        if (analysis == null) {
          return _buildNotSelected(context);
        }
        return _buildAnalysis(context, analysis);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  // 抽出対象外ユーザー向け（全国傾向ベース）
  Widget _buildNotSelected(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 全国のこどもたちの傾向',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '今月は 全国 ${500}人のデータから 傾向を分析しました。\n'
                'お子さんと おなじ学年の こどもたちは\n'
                '「友人関係」のじれんまで 特に悩んでいるようです。',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 抽出対象ユーザー向け（個別AI分析）
  Widget _buildAnalysis(BuildContext context, ReasonAnalysis analysis) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🧠 お子さんの 成長分析',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AI分析',
                    style: TextStyle(fontSize: 10, color: Colors.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                analysis.headline,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '🌟 成長のポイント',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...analysis.observations.map((obs) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(obs, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )).toList(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      analysis.parentMessage,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ⑤ 創作フィード — 入力フォームウィジェット（子ども用）
class CreationInputWidget extends ConsumerStatefulWidget {
  final String userId;
  final String storyId;
  final String storyTitle;

  const CreationInputWidget({
    Key? key,
    required this.userId,
    required this.storyId,
    required this.storyTitle,
  }) : super(key: key);

  @override
  ConsumerState createState() => _CreationInputWidgetState();
}

class _CreationInputWidgetState extends ConsumerState<CreationInputWidget> {
  late TextEditingController _controller;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildSubmittedState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 きみなら どんな おわりに する？',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'きみの そうさくは、つきの おわりに コメントが つくよ。',
                  style: TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'きみが かんがえた つづきを かいてみよう…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('おくる'),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittedState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Text('✅ そうさくを おくりました！', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'つきの おわりに コメントが とどくよ。たのしみに まっていてね。',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.submitCreation(
        widget.userId,
        widget.storyId,
        widget.storyTitle,
        _controller.text.trim(),
      );
      setState(() {
        _isSubmitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }
}

// ⑤ 創作フィード — 月次フィードバック（親レポート用）
class CreationFeedbackWidget extends ConsumerWidget {
  final String userId;
  final String month;

  const CreationFeedbackWidget({
    Key? key,
    required this.userId,
    required this.month,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(
      creationFeedbackProvider((userId, month)),
    );

    return feedbackAsync.when(
      data: (feedback) {
        if (feedback == null) return const SizedBox.shrink();
        return _buildFeedback(context, feedback);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildFeedback(BuildContext context, CreationFeedback feedback) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📝 そうさくの 成長',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AI分析',
                    style: TextStyle(fontSize: 10, color: Colors.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'このつきは ${feedback.creationCount}つの そうさくに チャレンジしました',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🌟 成長のポイント',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...feedback.observations.map((obs) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(obs, style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      feedback.parentTip,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
