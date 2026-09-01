# 本番監視ダッシュボード設定ガイド

**小学コレ！道徳** - リリース後の監視体制

**最終更新**: 2026年9月1日

---

## 概要

本ドキュメントは、本番環境におけるアプリ、API、インフラストラクチャの監視ダッシュボードを構築・運用する方法を定めています。

**目的**:
- ユーザーへの影響を最小化
- パフォーマンス低下を早期発見
- セキュリティ脆弱性を即座に検出
- データドリブンな改善実施

---

## 1. Firebase Console ダッシュボード

### 1.1 ユーザー行動分析ダッシュボード

**アクセス**: https://console.firebase.google.com/project/[project-id]/analytics

#### 1.1.1 リアルタイムダッシュボード

```
【設定】
Analytics > ダッシュボード > "リアルタイム"

【表示項目】
- リアルタイムアクティブユーザー（1分更新）
- 過去30分のセッション
- 主要なイベント
```

**監視項目**:

| 項目 | 目標値 | アラート閾値 |
|------|-------|-----------|
| DAU (日次 Active Users) | - | 20% 以上の低下 |
| セッション数 | - | 30% 以上の低下 |
| セッション継続時間 | > 5分 | < 3分 |
| クラッシュレート | < 0.5% | > 1% |

#### 1.1.2 カスタムダッシュボード作成

```
【手順】
1. Firebase Console > Analytics > ダッシュボード
2. "新しいダッシュボード"をクリック
3. "小学コレ！道徳 - 本番監視"と命名

【ウィジェット】
- 画面別セッション数
- ユーザー獲得（新規 vs 既存）
- トップイベント
- エラーレート
- セッション継続時間
```

**カスタム イベント設定**:

```
イベント名: story_completed
パラメータ:
  - story_id: 話のID
  - character_type: キャラクターのタイプ
  - selected_choice: ユーザーが選んだ選択肢
  - completion_time: 完了までの時間

イベント名: trial_to_purchase
パラメータ:
  - user_segment: ユーザーセグメント
  - trial_days: トライアル日数
  - purchase_amount: 購入金額
```

### 1.2 Firebase Crashlytics ダッシュボード

**アクセス**: https://console.firebase.google.com/project/[project-id]/crashlytics

#### 1.2.1 クラッシュレート監視

```
【表示項目】
- クラッシュレート（%）
- 影響を受けたセッション数
- ユーザー数
- 最後のクラッシュ時刻

【目標値】
- クラッシュレート < 0.5% (本番)
- ANR レート < 0.1%
```

**設定**:
```
Crashlytics > 設定

[ ] クラッシュレポート自動送信
  → Firebase Analytics から自動送信

[ ] セッションログレポート
  → クラッシュ前のログをキャプチャ

[ ] スタックトレース詳細
  → デバッグシンボルをアップロード
```

#### 1.2.2 トップクラッシュ監視

```
【画面】Crashlytics > Issues

【表示内容】
- クラッシュの種類（Exception, Crash, ANR）
- 影響を受けたユーザー数
- 発生頻度
- 最初の検出時刻
- 最後の検出時刻

【詳細表示】
- スタックトレース
- ユーザーデバイス情報
- OS バージョン
- App バージョン

【フィルター】
Platform: Android / iOS
Severity: All / Moderate / Critical
First Seen: Last 7 days
```

#### 1.2.3 デバッグシンボルアップロード

```bash
# Android デバッグシンボル
flutter build appbundle --release

# Google Play Console から自動ダウンロード
# または Crashlytics へ手動アップロード

# iOS デバッグシンボル
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/runner.xcarchive

# Xcode の Organizer から Crashlytics へアップロード
open /Applications/Xcode.app/Contents/Developer/Applications/Organizer.app
```

### 1.3 Firebase Performance Monitoring

**アクセス**: https://console.firebase.google.com/project/[project-id]/performance

#### 1.3.1 主要なパフォーマンス メトリクス

```
【アプリ起動時間】
- Cold Start: < 3秒（目標値）
- Hot Start: < 1秒（目標値）

【画面読み込み時間】
- 平均: < 1秒
- 95th percentile: < 2秒

【API レスポンス時間】
- 平均: < 500ms
- 95th percentile: < 1000ms

【フレームレート】
- 平均FPS: > 50
- 遅いフレームの割合: < 10%

【メモリ使用量】
- 平均: < 150MB
- ピーク: < 200MB
```

#### 1.3.2 カスタムメトリクス設定

```dart
// Firebase Performance SDK

import 'package:firebase_performance/firebase_performance.dart';

// カスタムトレースの開始
final trace = FirebasePerformance.instance.newTrace('story_load');
trace.start();

// メトリクスの記録
trace.putAttribute('story_id', storyId);
trace.putAttribute('connection_type', 'wifi');

// カウンターメトリクス
trace.incrementCounter('api_calls');

// トレース完了
await trace.stop();
```

### 1.4 Firebase Authentication 監視

```
【Authentiation > Sign-in providers】
- メール/パスワード: ❌ (Google Sign-in のみ)
- Google: ✅

【メトリクス】
- ログイン成功率: > 99%
- ログイン失敗レート: < 1%
- サインアップ→ロイン変換: > 50%
```

---

## 2. Google Cloud Logging ダッシュボード

**アクセス**: https://console.cloud.google.com/logs

### 2.1 バックエンド API ログ監視

#### 2.1.1 ログシンク設定

```bash
# Cloud Run ログをキャプチャ
gcloud logging sinks create cloud-run-logs \
  logging.googleapis.com/logs/cloud-run \
  --log-filter='resource.type="cloud_run_revision"'
```

#### 2.1.2 ログクエリ例

**API エラー検出**:
```sql
resource.type="cloud_run_revision"
severity="ERROR"
timestamp>="2026-09-01T00:00:00Z"

# レスポンス時間が遅い
httpRequest.latency>"1s"
```

**デプロイメント監視**:
```sql
resource.type="cloud_run_revision"
labels.service_name="shougaku-kore-backend"
severity >= "WARNING"
```

#### 2.1.3 カスタム ダッシュボード

```
【Firebase Cloud Logging ダッシュボード】

ウィジェット 1: API エラーレート
- メトリクス: severity="ERROR" の件数
- グループ: api_endpoint
- 期間: 直近 24時間

ウィジェット 2: レスポンスタイム
- メトリクス: httpRequest.latency
- グループ: httpRequest.requestUrl
- 統計: 平均, 95th percentile

ウィジェット 3: Cloud Run 利用度
- メトリクス: Cloud Run インスタンス数
- グループ: なし
- 期間: 直近 7日
```

---

## 3. Cloud Monitoring (Stackdriver) ダッシュボード

**アクセス**: https://console.cloud.google.com/monitoring

### 3.1 インフラストラクチャ監視

#### 3.1.1 Cloud Run 監視

```
【メトリクス】
- リクエスト数
- エラー率
- レイテンシ（p50, p95, p99）
- メモリ使用率
- CPU 使用率
```

**ダッシュボード作成**:
```yaml
displayName: "Cloud Run - Backend"
dashboardFilters: []

gridLayout:
  widgets:
    - title: "リクエスト/分"
      xyChart:
        dataSets:
          - timeSeriesQuery:
              timeSeriesFilter:
                filter: 'resource.type="cloud_run_revision"'
                aggregation:
                  alignmentPeriod: "60s"
                  perSeriesAligner: "ALIGN_RATE"

    - title: "エラー率（%）"
      xyChart:
        dataSets:
          - timeSeriesQuery:
              timeSeriesFilter:
                filter: 'resource.type="cloud_run_revision" AND metric.response_code_class="5xx"'

    - title: "レイテンシ（ms）"
      xyChart:
        dataSets:
          - timeSeriesQuery:
              timeSeriesFilter:
                filter: 'resource.type="cloud_run_revision"'
                aggregation:
                  alignmentPeriod: "60s"
                  perSeriesAligner: "ALIGN_PERCENTILE_95"
```

#### 3.1.2 Cloud Firestore 監視

```
【メトリクス】
- 読み取り数（/分）
- 書き込み数（/分）
- 削除数（/分）
- ドキュメント数
- 保存容量（GB）

【アラート閾値】
- 読み取り > 100,000/分
- 書き込み > 10,000/分
- 保存容量 > 10GB
```

**クエリ例**:
```
firestore.googleapis.com|Database|network_billable_read_operations
firestore.googleapis.com|Database|network_billable_write_operations
firestore.googleapis.com|Database|billable_delete_operations
```

### 3.2 アラート ポリシー

#### 3.2.1 重大度別アラート設定

**P1 - 緊急** (即対応):
```
条件:
- クラッシュレート > 1% (1時間以上)
- API エラー率 > 5% (15分以上)
- Cloud Firestore 読み取り > 100,000/分

通知:
- Slack #critical（毎分通知）
- メール（CC: オンコール担当者）
- SMS（携帯）
```

**P2 - 重要** (1時間以内に対応):
```
条件:
- クラッシュレート > 0.5% (30分以上)
- API レスポンスタイム (p95) > 1秒
- DAU 20% 以上の低下

通知:
- Slack #alerts
- メール
```

**P3 - 軽微** (当日中に対応):
```
条件:
- API レスポンスタイム > 500ms
- メモリ使用率 > 80%
- 低いレート制限エラー

通知:
- Slack #ops
```

#### 3.2.2 アラート設定の実装

```yaml
# alerting_policy.yaml
displayName: "クラッシュレート > 1%"
conditions:
  - displayName: "Crashlytics - クラッシュレート"
    conditionThreshold:
      filter: 'resource.type="mobile_app" AND metric.name="firebase.crashlytics|crash_free_sessions|percent"'
      comparison: COMPARISON_LT  # クラッシュフリーセッション率が低い
      thresholdValue: 99  # 99% 以下 = クラッシュレート 1% 以上
      duration: 3600s  # 1時間継続

notificationChannels:
  - "projects/[project]/notificationChannels/[channel-id]"
  
alertStrategy:
  autoClose: 86400s  # 24時間で自動クローズ
  notificationRateLimit:
    period: 3600s  # 1時間に1回まで通知
```

---

## 4. Sentry エラー監視

**アクセス**: https://sentry.io/organizations/shougaku-kore

### 4.1 Sentry 統合

**SDKセットアップ**:
```dart
// main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = const String.fromEnvironment('APP_ENV');
      options.tracesSampleRate = 1.0;
      options.enableNativeCrashHandling = true;
      options.maxResponseBodyLength = 100000;
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

### 4.2 ダッシュボード設定

```
【Sentry Issues ページ】

フィルター:
- Status: Unresolved
- Environment: production
- Level: error, fatal

表示項目:
- エラータイプ
- 影響を受けたユーザー数
- イベント数
- 最初の検出時刻
- 最後の検出時刻

【ソート】
- 最新のエラーから
- ユーザー数が多い順
- イベント数が多い順
```

### 4.3 Alert ルール

```
【Sentry > Alerts > Create Alert Rule】

トリガー:
- Error rate > 5% for 10 minutes
- New issue detected
- Regression detected

通知先:
- Slack #critical
- メール
```

---

## 5. Slack 統合 & アラート通知

### 5.1 Slack チャンネル設定

**チャンネル構成**:
```
#critical          → P1 アラート（全員 @channel）
#alerts            → P2 アラート（自動通知）
#ops               → P3 アラート + 運用情報
#analytics         → 日次レポート
#release           → リリース情報
#security          → セキュリティアラート
```

### 5.2 Firebase → Slack 統合

**Firebase Cloud Pub/Sub → Cloud Functions → Slack**

```javascript
// functions/notify_slack.js
const functions = require("firebase-functions");
const axios = require("axios");

const SLACK_WEBHOOK = process.env.SLACK_WEBHOOK_URL;

exports.alertToSlack = functions.pubsub
  .topic("firebase-alerts")
  .onPublish(async (message) => {
    const alert = JSON.parse(
      Buffer.from(message.data, "base64").toString()
    );

    const severity =
      alert.crashlyticsMetrics.crashFreeSessionsPercentage < 0.99
        ? "🚨 CRITICAL"
        : "⚠️ WARNING";

    const payload = {
      text: `${severity} - Firebase Alert`,
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: `*${severity}* - Crashlytics Alert\n\nCrash-Free Sessions: ${alert.crashlyticsMetrics.crashFreeSessionsPercentage.toFixed(2)}%\nAffected Users: ${alert.crashlyticsMetrics.affectedSessionsCount}`,
          },
        },
        {
          type: "actions",
          elements: [
            {
              type: "button",
              text: {
                type: "plain_text",
                text: "View in Console",
              },
              url: `https://console.firebase.google.com/project/[project]/crashlytics`,
            },
          ],
        },
      ],
    };

    await axios.post(SLACK_WEBHOOK, payload);
  });
```

### 5.3 Google Cloud Monitoring → Slack

**Cloud Monitoring ノーティフィケーション チャネル**:

```bash
# 通知チャネル作成
gcloud alpha monitoring channels create \
  --display-name="Slack #critical" \
  --type=slack \
  --channel-labels=url="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# アラートポリシーに関連付け
gcloud alpha monitoring policies create \
  --notification-channels=[channel-id]
```

---

## 6. Google Analytics ダッシュボード

### 6.1 ビジネス メトリクス監視

**アクセス**: https://analytics.google.com

**ダッシュボード項目**:

| メトリクス | 目標値 | 監視頻度 |
|----------|-------|--------|
| ダウンロード数 | - | 日次 |
| アクティブユーザー | - | 日次 |
| トライアル → 購入変換率 | > 10% | 日次 |
| 1-Day リテンション | > 30% | 週次 |
| 7-Day リテンション | > 15% | 週次 |
| 平均セッション継続時間 | > 5分 | 日次 |
| App Rating | > 4.0 | 週次 |

---

## 7. 日次運用レポート

### 7.1 自動レポート生成

**毎日 9:00 JST に自動送信**

```bash
# Cloud Scheduler ジョブ
gcloud scheduler jobs create pubsub daily-report \
  --location=asia-northeast1 \
  --schedule="0 0 * * *" \
  --topic=daily-report \
  --time-zone=Asia/Tokyo
```

### 7.2 レポート内容

```
【日次運用レポート】
日付: 2026-09-02

【ユーザーアクティビティ】
- DAU: 1,234 (前日比: +5%)
- セッション数: 5,678 (前日比: +3%)
- 新規ユーザー: 89 (前日比: -2%)

【アプリ安定性】
- クラッシュレート: 0.32% ✅ (目標: < 0.5%)
- ANR レート: 0.05% ✅ (目標: < 0.1%)
- トップクラッシュ: なし

【パフォーマンス】
- API 応答時間: 342ms ✅ (目標: < 500ms)
- アプリ起動時間: 2.1秒 ✅ (目標: < 3秒)

【課金】
- トライアル登録: 12
- 購入: 3 (変換率: 25%)
- MRR: ¥45,000

【アラート】
- 警告: なし
- 情報: なし

【推奨アクション】
- なし
```

### 7.3 自動レポート実装

```python
# Cloud Functions - Python
import functions_framework
from datetime import datetime, timedelta
from slack_sdk import WebClient
from firebase_admin import initialize_app, db

@functions_framework.cloud_event
def daily_report(cloud_event):
    """Daily monitoring report to Slack"""
    
    # Firebase からメトリクス取得
    ref = db.reference('metrics/daily')
    metrics = ref.order_by_child('date').limit_to_last(2).get()
    
    yesterday = metrics.val()[0]
    today = metrics.val()[1]
    
    slack_client = WebClient(token=os.environ['SLACK_BOT_TOKEN'])
    
    # レポート作成
    report = {
        "text": "Daily Report",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"Daily Report - {datetime.now().strftime('%Y-%m-%d')}",
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*DAU*\n{today['dau']} ({today['dau_change']:+.0f}%)"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Crash Rate*\n{today['crash_rate']:.2f}%"
                    },
                ]
            }
        ]
    }
    
    slack_client.chat_postMessage(channel='#analytics', **report)
```

---

## 8. ダッシュボード アクセス権限

### 8.1 ロールベースアクセス

```
【Firebase】
- Admin: プロジェクトオーナー
- Editor: リリース・デプロイエンジニア
- Viewer: QA・オペレーション

【Google Cloud】
- Project Editor: DevOps エンジニア
- Monitoring Admin: SRE
- Logs Viewer: サポート

【Sentry】
- Owner: テックリード
- Manager: シニアエンジニア
- Member: 全エンジニア

【Slack】
- #critical: 全メンバー（通知頻度は異なる）
- #alerts: エンジニア
- #analytics: プロダクトマネージャー
```

### 8.2 ダッシュボード URL リスト

```
【本番監視 ダッシュボード】
- Firebase: https://console.firebase.google.com/project/[project-id]/analytics
- Crashlytics: https://console.firebase.google.com/project/[project-id]/crashlytics
- Cloud Monitoring: https://console.cloud.google.com/monitoring/dashboards/custom/prod-monitoring
- Sentry: https://sentry.io/organizations/shougaku-kore/

【Google Play】
- Play Console: https://play.google.com/console/u/0/developers/
- 統計: Play Console > 統計 > ユーザー獲得

【App Store】
- App Store Connect: https://appstoreconnect.apple.com
- Analytics: App Store Connect > My Apps > 分析
```

---

## 9. トラブルシューティング

### アラートが送信されない場合

```
【確認項目】
1. Slack ウェブフック URL が有効か
   - Slack Workspace Settings > Apps > Incoming Webhooks

2. Firebase Pub/Sub トピックが存在するか
   - Cloud Console > Pub/Sub

3. Cloud Functions がデプロイされているか
   - Cloud Console > Cloud Functions

4. 権限設定が正しいか
   - Cloud IAM ロール確認
```

### ダッシュボードが表示されない場合

```
【確認項目】
1. ユーザーが正しいプロジェクトにアクセスしているか
2. ダッシュボード権限が付与されているか
3. ブラウザキャッシュをクリア
4. 別のブラウザで試す
```

---

## 参考資料

- [Firebase Console](https://console.firebase.google.com)
- [Google Cloud Monitoring](https://cloud.google.com/monitoring/kubernetes-engine)
- [Slack API](https://api.slack.com)
