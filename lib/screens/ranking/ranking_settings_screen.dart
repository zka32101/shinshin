import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ranking.dart';
import '../../providers/ranking_provider.dart';

/// ランキング設定画面
/// ユーザーのランキング参加設定とプライバシー設定を管理
class RankingSettingsScreen extends ConsumerStatefulWidget {
  const RankingSettingsScreen({super.key});

  @override
  ConsumerState<RankingSettingsScreen> createState() =>
      _RankingSettingsScreenState();
}

class _RankingSettingsScreenState extends ConsumerState<RankingSettingsScreen> {
  late bool _isNamePublic;
  late bool _participateInRanking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isNamePublic = false;
    _participateInRanking = true;
  }

  @override
  Widget build(BuildContext context) {
    // ランキング設定を取得
    final rankingSettings = ref.watch(rankingSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング設定'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: rankingSettings.when(
        data: (settings) {
          // 初回読み込み時に状態を初期化
          if (settings != null &&
              (_isNamePublic == false &&
                  _participateInRanking == true)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _isNamePublic = settings.isNamePublic;
                _participateInRanking = settings.participateInRanking;
              });
            });
          }

          return _buildSettingsContent(settings);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[300],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'エラーが発生しました',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(RankingSettings? settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ヘッダーセクション
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏆 ランキングについて',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9B59B6),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ランキング機能では、あなたのスコアと順位を他のユーザーと比較できます。'
                'プライバシー設定で、名前を非公表にすることも可能です。',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // プライバシー設定セクション
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '🔒 プライバシー設定',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ランキングに名前を表示する',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'オフの場合、ランキングに「ユーザー」と表示されます',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isNamePublic,
                      onChanged: _isLoading ? null : _handleNamePublicChange,
                      activeColor: const Color(0xFF9B59B6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ランキング参加設定セクション
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '🎯 ランキング参加',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 24),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ランキングに参加する',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'オフにするとランキングに表示されなくなります',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _participateInRanking,
                      onChanged:
                          _isLoading ? null : _handleParticipationChange,
                      activeColor: const Color(0xFF27AE60),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // インフォメーションセクション
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ℹ️ プライバシーについて',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0066CC),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'すべてのランキング設定は即座に反映されます。'
                'あなたの順位は常に非公表です。順位を知りたい場合は、'
                'ランキング画面で確認できます。',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF333333),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleNamePublicChange(bool value) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(updateRankingSettingsProvider(
        UpdateRankingSettingsParams(
          isNamePublic: value,
          participateInRanking: _participateInRanking,
        ),
      ).future);

      setState(() => _isNamePublic = value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '名前がランキングに表示されるようになりました'
                  : '名前がランキングに表示されなくなりました',
            ),
            backgroundColor: const Color(0xFF27AE60),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleParticipationChange(bool value) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(updateRankingSettingsProvider(
        UpdateRankingSettingsParams(
          isNamePublic: _isNamePublic,
          participateInRanking: value,
        ),
      ).future);

      setState(() => _participateInRanking = value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'ランキングに参加するようになりました'
                  : 'ランキングから除外されました',
            ),
            backgroundColor: const Color(0xFF27AE60),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
