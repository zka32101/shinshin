import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/providers/premium_provider.dart';
import 'package:shared_core/widgets/premium_gate_widget.dart';

const _primaryColor = Colors.teal;

class ParentAIAnalysisScreen extends ConsumerWidget {
  const ParentAIAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumProvider);

    if (!premiumState.isSubscribed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('成長分析（AI）'),
          centerTitle: true,
          backgroundColor: _primaryColor,
        ),
        body: PremiumGateWidget(
          featureName: '親向けAI成長分析',
          onPremiumAccess: () => _showSubscriptionDialog(context),
        ),
      );
    }

    final analysisAsync = ref.watch(aiGrowthAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成長分析（AI）'),
        centerTitle: true,
        backgroundColor: _primaryColor,
      ),
      body: analysisAsync.when(
        data: (analysis) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 総合成長スコア
            Card(
              elevation: 2,
              color: _primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '総合成長スコア',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${analysis.overallScore}/100',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      analysis.scoreTrend,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AI分析テキスト
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI分析コメント',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      analysis.aiInsight,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 成長エリア別スコア
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '成長エリア別スコア',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...analysis.areaScores.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${entry.value}%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: entry.value / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation(
                                  _primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 推奨アクション
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '推奨するサポート',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: analysis.recommendedActions.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final action = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index <
                                      analysis.recommendedActions.length - 1
                                  ? 12
                                  : 0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 詳細レポート表示ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('詳細レポートページへ移動します'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '詳細レポートを見る',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_primaryColor),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'AI分析データを読み込めません',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'エラー: $err',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSubscriptionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアム機能'),
        content: const Text(
          '親向けAI成長分析は月額¥120のプレミアム会員向けです。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: RevenueCat の購入フロー
            },
            child: const Text('今すぐ購読'),
          ),
        ],
      ),
    );
  }
}

/// AI成長分析プロバイダー
/// Cloud Functions 経由で Claude API を呼び出し
final aiGrowthAnalysisProvider = FutureProvider.autoDispose<AIGrowthAnalysis>(
  (ref) async {
    // TODO: Firebase Cloud Functions で実装
    // final response = await FirebaseFunctions.instance
    //     .httpsCallable('generateGrowthAnalysis')
    //     .call({'userId': userId});
    // return AIGrowthAnalysis.fromJson(response.data);

    // ダミー実装（本来はサーバーから取得）
    await Future.delayed(const Duration(seconds: 2));
    return AIGrowthAnalysis(
      overallScore: 78,
      scoreTrend: '前月比 +8 ポイント (↑ 順調に成長中)',
      aiInsight:
          '今月は特に「他者への思いやり」の領域で大きな成長が見られます。'
          'ストーリーの選択肢を通じて、異なる視点から物事を考える力が育ってきています。'
          '今後は「自分の意見を表現する勇気」を高めるシナリオに積極的に取り組むことをお勧めします。',
      areaScores: {
        '他者への思いやり': 85,
        '責任感': 72,
        '自分の意見の表現': 68,
        '問題解決力': 76,
        '判断力': 79,
      },
      recommendedActions: [
        'お子さんと一緒にストーリーの選択について話し合う時間を持ってください。'
        '異なる観点からの考え方を理解することで、さらに思考の幅が広がります。',
        'すこし難しいシナリオにも挑戦させてみてください。'
        'お子さんが自信を持って判断できるようサポートしましょう。',
        '週に1-2回、定期的に学習することで、成長スピードが上がります。'
        'ゲーム感覚で楽しく続けることが重要です。',
      ],
    );
  },
);

/// AI成長分析データモデル
class AIGrowthAnalysis {
  final int overallScore;
  final String scoreTrend;
  final String aiInsight;
  final Map<String, int> areaScores;
  final List<String> recommendedActions;

  AIGrowthAnalysis({
    required this.overallScore,
    required this.scoreTrend,
    required this.aiInsight,
    required this.areaScores,
    required this.recommendedActions,
  });

  factory AIGrowthAnalysis.fromJson(Map<String, dynamic> json) {
    return AIGrowthAnalysis(
      overallScore: json['overallScore'] as int? ?? 0,
      scoreTrend: json['scoreTrend'] as String? ?? '',
      aiInsight: json['aiInsight'] as String? ?? '',
      areaScores: Map<String, int>.from(json['areaScores'] ?? {}),
      recommendedActions: List<String>.from(json['recommendedActions'] ?? []),
    );
  }
}
