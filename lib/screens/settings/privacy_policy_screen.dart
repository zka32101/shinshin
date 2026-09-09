import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_card.dart';
import 'package:shared_core/widgets/components/app_button.dart';

/// プライバシーポリシー画面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
          _PolicyHeading(text: 'プライバシーポリシー'),
          _PolicyParagraph(
            text: '当アプリ「小学コレ！道徳」（以下「本アプリ」）は、お子さんのプライバシー保護を最優先に運営しています。'
                '本ポリシーは、本アプリが収集する情報・利用目的・保護措置について説明します。',
          ),

          _PolicySection(title: '1. 収集する情報'),
          _PolicyParagraph(text: '本アプリは以下の情報を収集します。'),
          _BulletList(items: [
            '保護者のメールアドレス（アカウント登録に使用）',
            'お子さんのニックネームと学年（学習記録の管理に使用）',
            '学習進捗データ（完了ストーリー、選択内容、ポイント）',
            'デバイストークン（学習リマインダー通知に使用）',
            'アプリ利用状況（クラッシュレポート・改善目的）',
          ]),
          _PolicyParagraph(
            text: '本アプリはお子さんの氏名・住所・電話番号・写真等の個人特定情報は一切収集しません。',
          ),

          _PolicySection(title: '2. 情報の利用目的'),
          _BulletList(items: [
            'ユーザー認証・アカウント管理',
            '学習進捗の記録と月次レポート生成',
            'パーソナライズされたストーリーの推薦',
            'プッシュ通知（学習リマインダー・レポート完成通知）',
            'アプリの品質向上・バグ修正',
          ]),

          _PolicySection(title: '3. 情報の共有'),
          _PolicyParagraph(
            text: '本アプリは以下の場合を除き、第三者にお客様の情報を共有・販売しません。',
          ),
          _BulletList(items: [
            '法令・裁判所命令等による開示が必要な場合',
            'お客様の明示的な同意がある場合',
            'サービス運営上必要なインフラ事業者（Firebase / Google Cloud）',
          ]),
          _PolicyParagraph(
            text: 'Firebase（Google LLC）は本アプリの認証・分析・通知に利用されており、'
                'Googleのプライバシーポリシー（https://policies.google.com/privacy）が適用されます。',
          ),

          _PolicySection(title: '4. 子どものプライバシー（COPPA対応）'),
          _PolicyParagraph(
            text: '本アプリは13歳未満のお子さんを対象とするコンテンツを含みます。'
                '保護者が代理で登録を行い、お子さんの学習管理を担う設計です。'
                '本アプリはお子さんから直接の個人情報収集を行いません。'
                'お子さんのデータを第三者に販売・マーケティング利用することはありません。',
          ),

          _PolicySection(title: '5. データの保存と削除'),
          _BulletList(items: [
            'データはGoogle Cloud（東京リージョン）に暗号化して保存されます。',
            '学習データはアカウント有効期間中保持されます。',
            'アカウント削除のご要望はサポートメールまでご連絡ください。最大30日以内に対応します。',
            'デバイスのローカルキャッシュはアプリのアンインストールにより削除されます。',
          ]),

          _PolicySection(title: '6. セキュリティ'),
          _PolicyParagraph(
            text: '通信はTLS（HTTPS）で暗号化されています。パスワードは業界標準のハッシュ化処理を施して保存します。'
                'ただし、インターネット通信や電子的保存に完全なセキュリティを保証することはできません。',
          ),

          _PolicySection(title: '7. Cookie・トラッキング'),
          _PolicyParagraph(
            text: '本アプリはモバイルアプリのため、従来のCookieは使用しません。'
                'Firebaseによる匿名化された利用統計データを収集しますが、'
                '個人を特定する目的では使用しません。',
          ),

          _PolicySection(title: '8. ポリシーの変更'),
          _PolicyParagraph(
            text: '本ポリシーを改定する場合、アプリ内の通知または登録メールアドレスへの連絡でお知らせします。'
                '重要な変更については、再度同意を求める場合があります。',
          ),

          _PolicySection(title: '9. お問い合わせ'),
          _PolicyParagraph(
            text: 'プライバシーに関するご質問・データ削除のご要望は、アプリ内「このアプリについて」に'
                '記載のサポートメールまでご連絡ください。',
          ),

          _PolicyFooter(),
          SizedBox(height: 32),
        ],
      ),
      ),
    );
  }
}

// ── 小パーツ ───────────────────────────────────────────────────────────────

class _PolicyHeading extends StatelessWidget {
  final String text;
  const _PolicyHeading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C2C2C),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  const _PolicySection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF9B59B6),
        ),
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  final String text;
  const _PolicyParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF444444),
          height: 1.7,
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF9B59B6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF444444),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PolicyFooter extends StatelessWidget {
  const _PolicyFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '制定日：2024年1月1日\n最終更新：2024年6月1日\n運営：小学コレ！道徳 開発チーム',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF888888),
          height: 1.8,
        ),
      ),
    );
  }
}
