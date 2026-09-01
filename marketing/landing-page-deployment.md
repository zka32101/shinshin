# ランディングページ公開準備ガイド

**対象**: 小学コレ！道徳 公式ランディングページ  
**公開予定日**: 2026-10-01  
**責任者**: マーケティングチーム

---

## 1. ドメイン設定

### 推奨ドメイン
```
本番: shougaku-kore-doutoku.jp
```

### DNS設定手順

#### Step 1: ドメインレジストラに登録
- 推奨: ムームードメイン / お名前.com
- 年間コスト: 1,500-2,500円
- 登録期間: 最低 2 年（ロック防止）

#### Step 2: DNS A レコード設定
```
ホスト名: @ (ルート)
レコード: A
値: [ホスティング先IP]

ホスト名: www
レコード: A
値: [ホスティング先IP]
```

#### Step 3: CNAME レコード設定（ホスティング）
```
ホスト名: @
レコード: CNAME
値: shougaku-kore-doutoku.jp (ホスティングプロバイダー指定)
```

### 推奨ホスティング
| プロバイダー | コスト | 特徴 | 用途 |
|------------|-------|------|------|
| Vercel | 無料 | サーバーレス、CDN自動構成 | 推奨：フロントエンド |
| Netlify | 無料 | CI/CD統合、フォーム対応 | 代替案 |
| AWS S3 + CloudFront | $1-10/月 | スケーラビリティ高 | 大規模向け |

**選定**: Vercel（構築速度・コスト最適）

---

## 2. SSL 証明書設定

### 自動設定（推奨）
```bash
# Vercelの場合：自動設定
# 1. Vercelダッシュボードでドメイン追加
# 2. DNS認証レコード追加
# 3. 自動的にSSL証明書が発行（数分）
```

### SSL検証コマンド
```bash
# SSL証明書確認
curl -I https://shougaku-kore-doutoku.jp

# 出力例：
# HTTP/2 200
# x-frame-options: SAMEORIGIN
# x-content-type-options: nosniff
```

### セキュリティヘッダー設定
```javascript
// vercel.json の設定
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=31536000; includeSubDomains"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "SAMEORIGIN"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        }
      ]
    }
  ]
}
```

---

## 3. Google Analytics 4 設定

### Step 1: GA4アカウント作成
```
1. Google Analytics コンソールアクセス
   https://analytics.google.com/

2. 新しいプロパティ作成
   - プロパティ名: 小学コレ！道徳 LP
   - 業界カテゴリ: 教育・オンライン学習
   - タイムゾーン: Asia/Tokyo
   - 通貨: JPY
   - レポートタイムゾーン: Asia/Tokyo

3. データストリーム作成
   - プラットフォーム: Web
   - URL: https://shougaku-kore-doutoku.jp
   - ストリーム名: LP Main
```

### Step 2: GTM（Google Tag Manager）経由での導入（推奨）
```html
<!-- ランディングページの <head> タグに追加 -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX', {
    'anonymize_ip': true,
    'cookie_flags': 'SameSite=None;Secure'
  });
</script>
```

### Step 3: キーイベント設定
```
GA4 > イベント > カスタムイベント作成

【必須キーイベント】

1. トライアル登録完了
   イベント名: trial_signup_complete
   トリガー: 「無料トライアル登録」ボタン クリック
   パラメータ:
   - signup_method: email / google_account

2. AppStore遷移
   イベント名: app_store_click
   トリガー: 「AppStore」ボタン クリック
   パラメータ:
   - app_store_type: ios

3. GooglePlay遷移
   イベント名: google_play_click
   トリガー: 「GooglePlay」ボタン クリック
   パラメータ:
   - app_store_type: android

4. 資料ダウンロード
   イベント名: brochure_download
   トリガー: 「資料をダウンロード」ボタン クリック
   パラメータ:
   - content_type: pdf

5. お問い合わせ送信
   イベント名: contact_form_submit
   トリガー: お問い合わせフォーム送信
   パラメータ:
   - inquiry_type: general / business / support
```

### Step 4: コンバージョン設定
```
GA4 > コンバージョン設定

【トライアル登録コンバージョン】
イベント: trial_signup_complete
値: 1

【AppStore訪問コンバージョン】
イベント: app_store_click
値: 1

【GooglePlay訪問コンバージョン】
イベント: google_play_click
値: 1
```

---

## 4. Conversion Tracking 設定（App Store・Google Play）

### Apple App Store リンク追跡

#### Step 1: App Analytics ダッシュボード
```
App Store Connect
  > My Apps
    > 小学コレ！道徳
      > Analytics
        > Sources/Referrers
```

#### Step 2: キャンペーンURL生成
```
基本URL: https://apps.apple.com/jp/app/小学コレ道徳/id[APP_ID]

キャンペーンURL（UTM付き）:
https://apps.apple.com/jp/app/小学コレ道徳/id[APP_ID]?pt=123456789&ct=website_lp

パラメータ説明:
- pt: Provider Token
- ct: Campaign Token (e.g., "website_lp")
```

#### Step 3: Apple Search Ads キャンペーン設定
```
Apple Search Ads (https://searchads.apple.com/)

キャンペーン名: LPから App Store へ
日予算: ¥5,000
入札: キーワード「小学 道徳」「子ども 学習」

トラッキング: App Analytics で自動計測
```

### Google Play Store リンク追跡

#### Step 1: Play Console トラッキング設定
```
Google Play Console
  > アプリを選択
    > 成長 > データソース > 参照元追跡
```

#### Step 2: キャンペーンURL生成
```
基本URL: https://play.google.com/store/apps/details?id=com.shougaku_kore.doutoku

キャンペーンURL（UTM付き）:
https://play.google.com/store/apps/details?id=com.shougaku_kore.doutoku&utm_source=website_lp&utm_medium=referral&utm_campaign=launch

パラメータ説明:
- utm_source: website_lp
- utm_medium: referral
- utm_campaign: launch
- utm_content: [トライアル / 購買]
```

#### Step 3: Google App Campaigns
```
Google Ads > App campaigns

キャンペーン名: LP リマーケティング
予算: ¥10,000/日（リリース初月）
ターゲット: 東京都・大阪府・愛知県（大都市圏）

トラッキング: Google Analytics 4 自動計測
```

### Cross-Platform トラッキング（Firebase）
```dart
// Firebase Analytics 統合（アプリ内）
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

// LP からのインストール追跡
Future<void> trackAppStoreVisit() async {
  await analytics.logEvent(
    name: 'app_store_visit',
    parameters: {
      'source': 'website_lp',
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
}
```

---

## 5. A/B テスト実装（2 バージョン）

### テスト目的
**CTA（Call To Action）のコンバージョン最適化**

### テストデザイン

#### Version A: 感情訴求型
```
見出し: 「子どもが考える力を引き出す。親の悩みも解決する。」
サブ見出し: 親も子も成長できる、新しい道徳学習
CTA ボタン: 
  - 色: 青 (#2563EB)
  - テキスト: 「無料で始める」
  - サイズ: 中

メイン画像: 親子で一緒に学ぶシーン
フォーム: メールアドレスのみ（1フィールド）
```

#### Version B: 機能・数値訴求型
```
見出し: 「毎日 5 分で、判断力が育つ。月 1 回のレポートで成長が見える。」
サブ見出し: 小学 3-4 年生向け、道徳スキル診断 & AI 親コーチング
CTA ボタン:
  - 色: 緑 (#10B981)
  - テキスト: 「14 日無料でお試し」
  - サイズ: 大

メイン画像: アプリ画面のスクリーンショット
フォーム: メール + 子どもの学年（2フィールド）
```

### テスト実装

#### Step 1: Vercel のテスト機能を使用
```javascript
// pages/index.js
export async function getServerSideProps() {
  const variant = Math.random() > 0.5 ? 'A' : 'B';
  return {
    props: { variant }
  };
}

export default function Home({ variant }) {
  return variant === 'A' ? <VersionA /> : <VersionB />;
}
```

#### Step 2: GA4 でのトラッキング
```javascript
useEffect(() => {
  gtag('event', 'page_view', {
    'page_variant': variant, // 'A' または 'B'
  });
}, [variant]);
```

### テスト期間・サンプルサイズ
```
テスト期間: 2026-10-01 ~ 2026-10-15（2週間）
目標サンプル: 各バージョン 1,000 セッション以上
統計的有意性: 95% 信頼度（p < 0.05）

計測指標:
- トライアル登録完了率
  Version A: 目標 5%
  Version B: 目標 7%
- フォーム送信率
- 平均セッション時間
```

### テスト結果レビュー
```
テスト終了後: 2026-10-15
結果分析: 2026-10-16
勝者版デプロイ: 2026-10-17
```

---

## 6. デプロイメント チェックリスト

### Pre-Launch（公開前）
- [ ] ドメイン登録完了（DNS設定から 48h 待機）
- [ ] SSL証明書有効（`curl -I https://shougaku-kore-doutoku.jp`）
- [ ] GA4 トラッキング機能テスト
  - [ ] ページビュー計測確認
  - [ ] イベント送信テスト
  - [ ] コンバージョン計測テスト
- [ ] Conversion Tracking 確認
  - [ ] Apple App Store リンク動作確認
  - [ ] Google Play Store リンク動作確認
  - [ ] UTM パラメータ正確性確認
- [ ] A/B テスト実装確認
  - [ ] Version A 表示確認
  - [ ] Version B 表示確認
  - [ ] GA4 variant パラメータ記録確認
- [ ] セキュリティ確認
  - [ ] HTTPS 強制
  - [ ] セキュリティヘッダー（HSTS, CSP）
  - [ ] GDPR/CCPA コンプライアンス確認
  - [ ] プライバシーポリシー掲載

### Launch（公開時）
- [ ] 15:00 JST に本番環境へデプロイ
- [ ] 公開 5 分後に GA4 でアクセス確認
- [ ] Slack/メールで全チーム通知
- [ ] SNS で公開告知

### Post-Launch（公開後）
- [ ] 初日のアクセス・コンバージョン監視
- [ ] エラーログ確認（Console, Server logs）
- [ ] ユーザーフィードバック収集
- [ ] 1 週間後に A/B テスト結果確認

---

## 7. 本番環境設定

### 環境変数（.env.production）
```bash
# Google Analytics
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX

# Firebase
NEXT_PUBLIC_FIREBASE_PROJECT_ID=shougaku-kore-doutoku
NEXT_PUBLIC_FIREBASE_API_KEY=AIza...

# App Store リンク
NEXT_PUBLIC_APPSTORE_URL=https://apps.apple.com/jp/app/小学コレ道徳/id[APP_ID]

# Google Play リンク
NEXT_PUBLIC_GOOGLEPLAY_URL=https://play.google.com/store/apps/details?id=com.shougaku_kore.doutoku

# メール配信（SignUp フォーム用）
SENDGRID_API_KEY=SG.xxxxx
SENDGRID_FROM_EMAIL=noreply@shougaku-kore-doutoku.jp
```

### パフォーマンス最適化
```javascript
// next.config.js
module.exports = {
  compress: true,
  swcMinify: true,
  images: {
    domains: ['shougaku-kore-doutoku.jp'],
    formats: ['image/avif', 'image/webp'],
  },
  headers: async () => [
    {
      source: '/(.*)',
      headers: [
        {
          key: 'Cache-Control',
          value: 'public, max-age=3600, s-maxage=3600',
        },
      ],
    },
  ],
};
```

---

## 8. トラブルシューティング

### よくある問題

#### DNS が反映されない（48-72時間）
```bash
# DNS 確認コマンド
nslookup shougaku-kore-doutoku.jp
dig shougaku-kore-doutoku.jp

# Vercel DNS チェック
# 推奨: ドメインレジストラで Vercel の NS レコードを設定
```

#### SSL 証明書エラー
```bash
# 証明書確認
openssl s_client -connect shougaku-kore-doutoku.jp:443

# Vercel ダッシュボードで再発行
# Settings > Domains > 再発行
```

#### GA4 計測されない
```
確認項目:
1. GA ストリーム ID が正確か
2. ブロッカーが広告JS をブロックしていないか（incognito で確認）
3. localhost 環境では計測されない（本番環境で確認）
4. 24h 後に GA ダッシュボードでレポート表示
```

#### コンバージョン計測失敗
```bash
# ブラウザコンソールで確認
console.log('GA Event:', window.gtag);

# Network タブで GA エンドポイント確認
# https://www.google-analytics.com/g/collect に POST 送信されているか確認
```

---

## 9. モニタリング・ダッシュボード

### Vercel Analytics
```
Vercel Dashboard > Analytics
- Web Vitals: LCP < 2.5s, FID < 100ms, CLS < 0.1
- Error Rate: < 0.1%
```

### GA4 ダッシュボード（毎日確認）
```
レポート > ユーザー > デバイス別サマリー

観察項目:
1. ユーザー数（新規 / リピート）
2. トライアル登録完了率（目標 5% 以上）
3. App Store 遷移数
4. Google Play 遷移数
5. ユーザー地域分布（東京 > 大阪 > 愛知 期待値）
```

### アラート設定
```
GA4 > 管理 > プロパティ > アラート

1. トラフィック異常（-50% または +200%）
2. コンバージョン 0 件（24h 以上）
3. エラーレート > 5%
```

---

## 10. サポート・連絡先

| 項目 | 担当 | 連絡先 |
|-----|------|--------|
| ドメイン / ホスティング | インフラチーム | infra@company.com |
| GA4 / 分析 | データアナリスト | analytics@company.com |
| アプリリンク | プロダクト | product@company.com |
| 緊急対応 | DevOps | devops-oncall@company.com |

---

**最後確認**: 2026-09-28  
**公開予定**: 2026-10-01 15:00 JST
