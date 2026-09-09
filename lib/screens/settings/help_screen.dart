import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';

/// ヘルプ画面 — よくある質問（FAQ）と使い方ガイド
/// 商用利用OK画像を多数統合
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプ'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // アプリの使い方セクション
          _SectionHeader(
            title: '🎯 アプリの使い方',
            imagePath: 'assets/images/help/app_usage_guide.png',
          ),
          _FaqTile(
            question: 'アプリの目的は何ですか？',
            answer:
                '「小学コレ！道徳」は、小学3〜4年生のお子さんが日常のジレンマを題材にした選択肢型ストーリーを通じて、'
                '道徳的な判断力を楽しく育てるアプリです。お子さんの学習記録は月次レポートにまとめられ、'
                '保護者の方が成長を確認できます。',
            iconPath: 'assets/images/icons/help_icon_purpose.png',
          ),
          _FaqTile(
            question: 'ストーリーはどのように進みますか？',
            answer:
                '① ストーリーを読む → ② 選択肢（A〜D）から1つ選ぶ → ③ 選んだ理由を振り返る、の3ステップです。'
                '選択肢によってポイントや徳目スコアが変わります。正解・不正解はなく、考える過程が大切です。',
            iconPath: 'assets/images/icons/help_icon_story_steps.png',
            illustrationPath: 'assets/images/illustrations/story_flow.png',
          ),
          _FaqTile(
            question: '音声ナレーション機能はどう使いますか？',
            answer:
                'ストーリー読解画面の右上にあるスピーカーアイコンをタップするとナレーションのオン/オフを切り替えられます。'
                '設定画面の「オーディオ」からナレーション速度や音量も調整できます。',
            iconPath: 'assets/images/icons/help_icon_audio.png',
          ),

          const SizedBox(height: 8),
          // ポイントと徳目セクション
          _SectionHeader(
            title: '📊 ポイントと徳目',
            imagePath: 'assets/images/help/points_virtues_guide.png',
          ),
          _FaqTile(
            question: 'ポイントとは何ですか？',
            answer:
                'ストーリーを完了するとポイントが付与されます。ポイントを貯めるとレベルが上がります。'
                'レベルは成長画面で確認できます。',
            iconPath: 'assets/images/icons/help_icon_points.png',
          ),
          _FaqTile(
            question: '6つの徳目（徳目スコア）とは？',
            answer:
                '思いやり・正直・責任・勇気・尊重・協力の6つが徳目です。'
                '選んだ選択肢に応じてスコアが変動し、成長画面のレーダーチャートで可視化されます。',
            iconPath: 'assets/images/icons/help_icon_virtues.png',
            illustrationPath: 'assets/images/illustrations/virtues_radar.png',
          ),
          _FaqTile(
            question: 'レベルはどのように上がりますか？',
            answer: 'ポイントを一定量貯めるごとにレベルが上がります。'
                '成長画面でレベルと次のレベルまでのポイント数を確認できます。',
            iconPath: 'assets/images/icons/help_icon_level.png',
          ),

          const SizedBox(height: 8),
          // 保護者向け機能セクション
          _SectionHeader(
            title: '👨‍👩‍👧 保護者向け機能',
            imagePath: 'assets/images/help/parental_features_guide.png',
          ),
          _FaqTile(
            question: '月次レポートはいつ作られますか？',
            answer:
                'レポート画面の「AIレポートを生成」ボタンをタップすると、その月の学習データを元にAIがレポートを作成します。'
                '毎月1回の生成を推奨します。',
            iconPath: 'assets/images/icons/help_icon_monthly_report.png',
            illustrationPath: 'assets/images/illustrations/report_generation.png',
          ),
          _FaqTile(
            question: '子どもを複数登録できますか？',
            answer:
                'はい。設定 → 子どものプロフィール から複数のお子さんを登録・切り替えできます。'
                '兄弟姉妹それぞれの成長記録を個別に管理できます。',
            iconPath: 'assets/images/icons/help_icon_multiple_children.png',
          ),
          _FaqTile(
            question: 'デイリーリマインダーの時刻を変えるには？',
            answer:
                '設定 → 通知 → 学習リマインダー のトグルを有効にした後、「リマインダー時刻」をタップして時刻を設定してください。',
            iconPath: 'assets/images/icons/help_icon_reminder.png',
          ),

          const SizedBox(height: 8),
          // オフライン・通信セクション
          _SectionHeader(
            title: '🌐 オフライン・通信',
            imagePath: 'assets/images/help/offline_connectivity_guide.png',
          ),
          _FaqTile(
            question: 'オフラインでも使えますか？',
            answer:
                'はい。一度読み込んだストーリーと進捗データはデバイスに保存されるので、'
                'インターネット接続なしでも学習を続けられます。'
                '通信が回復した際に自動的にデータが同期されます。',
            iconPath: 'assets/images/icons/help_icon_offline.png',
            illustrationPath: 'assets/images/illustrations/offline_mode.png',
          ),
          _FaqTile(
            question: '同期が失敗しています。どうすればよいですか？',
            answer:
                '設定 → アカウント・その他 の「オフライン同期」セクションに未送信件数が表示されます。'
                '「今すぐ同期」ボタンをタップすると手動で再送できます。',
            iconPath: 'assets/images/icons/help_icon_sync.png',
          ),

          const SizedBox(height: 8),
          // アカウント・セキュリティセクション
          _SectionHeader(
            title: '🔒 アカウント・セキュリティ',
            imagePath: 'assets/images/help/security_guide.png',
          ),
          _FaqTile(
            question: 'パスワードを忘れた場合は？',
            answer:
                'ログイン画面の「メールでログイン」→「パスワードをお忘れですか？」（Firebaseの標準パスワードリセット機能）'
                'からメールアドレスを入力してください。リセットメールが届きます。',
            iconPath: 'assets/images/icons/help_icon_password_reset.png',
          ),
          _FaqTile(
            question: 'アカウントを削除したい場合は？',
            answer:
                '現在はアプリ内でのアカウント削除機能は準備中です。'
                '削除をご希望の場合は、アプリについて欄のサポートメールよりご連絡ください。',
            iconPath: 'assets/images/icons/help_icon_account_deletion.png',
          ),

          const SizedBox(height: 8),
          // お問い合わせセクション
          _SectionHeader(
            title: '📮 お問い合わせ',
            imagePath: 'assets/images/help/contact_guide.png',
          ),
          _ContactTile(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── 小パーツ ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? imagePath;

  const _SectionHeader({
    required this.title,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションイメージ（あれば表示）
        if (imagePath != null)
          Container(
            width: double.infinity,
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: _buildImageWithFallback(imagePath!),
          ),
        // セクションタイトル
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9B59B6),
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  final String? iconPath;
  final String? illustrationPath;

  const _FaqTile({
    required this.question,
    required this.answer,
    this.iconPath,
    this.illustrationPath,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // アイコン（あれば表示）
                  if (widget.iconPath != null)
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: _buildImageWithFallback(widget.iconPath!),
                    )
                  else
                    const Text('Q ', style: TextStyle(
                      color: Color(0xFF9B59B6),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF9B59B6),
                    ),
                  ),
                ],
              ),
              // 展開時の内容
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // イラスト（あれば表示）
                            if (widget.illustrationPath != null)
                              Container(
                                width: double.infinity,
                                height: 150,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[100],
                                ),
                                child: _buildImageWithFallback(
                                  widget.illustrationPath!,
                                ),
                              ),
                            // 回答テキスト
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('A ', style: TextStyle(
                                  color: Color(0xFF27AE60),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                )),
                                Expanded(
                                  child: Text(
                                    widget.answer,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF555555),
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: const Color(0xFFF3E8FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サポートアイコン
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: _buildImageWithFallback(
                'assets/images/icons/help_icon_contact.png',
              ),
            ),
            const Text(
              'サポートへのお問い合わせ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B59B6),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'アプリに関するご質問・ご要望は、アプリ内の「このアプリについて」に'
              '記載のサポートメールまでご連絡ください。通常2〜3営業日以内に返信いたします。',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ヘルパー関数 ───────────────────────────────────────────────────────────

/// 画像を表示するヘルパー関数（フォールバック付き）
Widget _buildImageWithFallback(String imagePath) {
  return Image.asset(
    imagePath,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      // 画像が見つからない場合はプレースホルダーを表示
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: Colors.grey[400],
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Image',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
