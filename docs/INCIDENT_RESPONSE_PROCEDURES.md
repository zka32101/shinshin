# インシデント対応プロセス

**小学コレ！道徳** - インシデント管理・根本原因分析

**最終更新**: 2026年9月1日

---

## 概要

本ドキュメントは、本番環境で発生するインシデント（サービス断、重大バグ、セキュリティ問題など）を効率的に検出・対応・分析するプロセスを定めています。

---

## インシデント分類

### 1. インシデント定義と優先度

#### P1 - 緊急（即対応、1-2時間以内）

**定義**: サービス全体またはユーザー大多数に影響

**例**:
- アプリが起動時に 100% クラッシュ
- ログインが完全に不可
- 課金機能が全く動作しない
- セキュリティ侵害が検出された

**SLA**: 1-2時間以内にホットフィックスリリース

#### P2 - 高（24時間以内）

**定義**: 一部機能が使用不可、または大幅なパフォーマンス低下

**例**:
- クラッシュレート 0.5-2%
- 特定 OS でのみ問題
- API レスポンスタイム が 10 倍に増加
- 親向けレポートが表示されない

**SLA**: 24時間以内に修正リリース

#### P3 - 低（通常リリースサイクル）

**定義**: 軽微な UI の問題、機能に支障なし

**例**:
- テキストが重なっている
- アイコンが表示されない
- 音声ナレーションの一部が再生されない

**SLA**: 次回定期リリース時に修正

---

## インシデント対応フロー

### フェーズ 1: 検出・報告（0-15分）

#### 1.1 自動検出

**Slack ボット が自動で通知**:

```
Slack #critical:

🚨 [CRITICAL] Firebase Crashlytics Alert
App Version: 1.0.0
Crash Rate: 5.2% (↑ 4.7% from baseline)
Affected Users: ~200
Crash Type: IOException
First Detected: 2026-09-01 14:30:02 JST

Stack Trace: 
java.io.IOException: Connection refused
  at com.example.api.ApiClient.fetchStories()

View in Console: https://console.firebase.google.com/project/[id]/crashlytics
```

#### 1.2 手動報告テンプレート

**ユーザーからの報告**:

```
【インシデント報告】

【発見者】
zkaz83@gmail.com

【発見日時】
2026-09-01 14:30 JST

【優先度】
P1 / P2 / P3

【症状】
子どもがアプリを起動したら "アプリが停止しました" が表示される

【再現手順】
1. アプリを削除
2. Google Play から再度インストール
3. Google でログイン
4. → クラッシュ

【環境】
- OS: Android 10
- Device: Samsung Galaxy A10
- App Version: 1.0.0
- Network: Wi-Fi

【スクリーンショット】
(添付)

【その他】
複数ユーザーから報告あり
```

#### 1.3 報告チャネル

- **自動**: Firebase Crashlytics ↔ Slack #critical
- **メール**: ops@example.com（オンコール担当）
- **Slack**: 直接 DM（緊急の場合）
- **GitHub**: Issue 作成（`label: incident`）

### フェーズ 2: 初期対応（15-30分）

#### 2.1 インシデント確認

**チェックリスト**:

```
□ インシデント内容を理解したか
□ 優先度を判定したか（P1/P2/P3）
□ 影響範囲を把握したか
□ 再現可能か
□ 既知の問題か
□ サービス継続可能か
```

#### 2.2 インシデント オンコール対応チーム

**P1 対応チーム**:
```
- Incident Commander (IC): CTO / テックリード
- Comms Lead: プロダクトマネージャー
- Technical Lead: シニアエンジニア
- Support Lead: サポートリード
- QA Lead: テスト リード
```

**P2 対応チーム**:
```
- Incident Commander: テックリード
- Technical Lead: エンジニア 1-2 名
- Support Lead: サポート
```

#### 2.3 Slack インシデント スレッド開始

```
Slack #critical:

【インシデント - P1】
件名: iOS でのアプリ起動時クラッシュ

Status: 🔴 OPEN

Timeline:
- 14:30: 初報告
- 14:35: IC assigned
- 14:40: 対応チーム集合

Incident Commander: @alice
Technical Lead: @bob
Support Lead: @charlie

このスレッドで進捗報告をお願いします。
```

### フェーズ 3: 原因特定・初期対応（30-60分）

#### 3.1 デバッグ開始

```bash
# Firebase Crashlytics でスタックトレース確認
open https://console.firebase.google.com/project/[id]/crashlytics

# Sentry でエラー詳細確認
open https://sentry.io/organizations/shougaku-kore/

# Cloud Logging でバックエンド ログ確認
open https://console.cloud.google.com/logs

# Cloud Run サービスステータス確認
gcloud run services describe shougaku-kore-backend --region asia-northeast1

# ローカルで再現試行
flutter run -d ios  # 対象デバイス
```

#### 3.2 原因の仮説立案

```
【仮説 1】
Firebase 初期化失敗
- 条件: 初回起動時
- 証拠: "FirebaseException" がスタックトレースに見える
- 確認方法: iOS Simulator で再現試行

【仮説 2】
メモリ不足
- 条件: 古い iOS デバイス
- 証拠: クラッシュが iOS 12-13 のみ
- 確認方法: Instruments で メモリプロファイル

【仮説 3】
パッケージの非互換性
- 条件: 依存パッケージの更新
- 証拠: 最新リリースで新しい パッケージを導入
- 確認方法: pubspec.lock を前回リリースと比較
```

#### 3.3 緊急回避策（Workaround）

**ホットフィックスが完了するまでの応急処置**:

```dart
// Firebase 初期化失敗時の代替パス
void main() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase 初期化失敗 → オフラインモードで起動
    runApp(const OfflineModeApp());
    return;
  }
  runApp(const MyApp());
}

// メモリ不足時の処理
@override
void dispose() {
  imageCache.clear();
  imageCache.clearLiveImages();
  super.dispose();
}
```

**ユーザー向けコミュニケーション**:

```
お客様へ

アプリケーションで一部のユーザーに問題が発生しています。

【対応】
1. アプリを削除
2. 24 時間待機（キャッシュ削除待ち）
3. 再度インストール

ご迷惑をおかけして申し訳ございません。
```

#### 3.4 進捗報告（30分ごと）

```
Slack スレッド:

14:45: 原因候補
- Firebase iOS SDK v10.0.0 で既知の問題あり
- iOS 13.x での互換性問題

15:00: 修正案
- Firebase SDK を v10.1.0 にアップグレード（既に修正版がリリース）
- または ビルド設定を調整

15:15: ホットフィックス開始
```

### フェーズ 4: ホットフィックス実装・テスト（1-2時間）

#### 4.1 修正実装

```bash
# 修正ブランチ作成
git checkout -b incident/p1-ios-crash origin/main

# 修正コード
vi pubspec.yaml
# firebase_core: ^2.13.0 → ^2.14.0

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 4.2 検証テスト

```bash
# ローカルテスト
flutter test
flutter test integration_test/critical_flow_test.dart

# デバイステスト（対象 iOS デバイス）
flutter run -d ios --profile

# 複数回起動確認
# 1回目: 成功 ✅
# 2回目: 成功 ✅
# 3回目: 成功 ✅
```

#### 4.3 修正コミット

```bash
git add -A
git commit -m "Fix: iOS でのアプリ起動時クラッシュ (#456)

Firebase iOS SDK の互換性問題を修正
- firebase_core を v2.14.0 にアップグレード
- iOS 13+ での初期化エラーを解決

Fixes #456"

git push origin incident/p1-ios-crash
```

### フェーズ 5: リリース・デプロイ（30-60分）

#### 5.1 バージョン更新 & ビルド

```yaml
# pubspec.yaml
version: 1.0.1+2
```

```bash
# ビルド
flutter build ios --release --build-number=2
flutter build appbundle --release --build-number=2
```

#### 5.2 App Store / Google Play 申請

（docs/HOTFIX_RESPONSE_PLAN.md の手順に従う）

#### 5.3 リリース監視

```
監視スケジュール:
- リリース直後 (0-1h): 15分ごと
- 1-3時間: 30分ごと
- 3-6時間: 1時間ごと
- 6-24時間: 4時間ごと

監視対象:
- クラッシュレート
- DAU の動向
- ユーザーコメント
```

---

## インシデント根本原因分析（RCA）

### フェーズ 6: RCA ミーティング（インシデント解決後 24-48時間）

#### 6.1 RCA ミーティング参加者

```
- テックリード（主導）
- 対応エンジニア
- QA リード
- プロダクトマネージャー
- デプロイエンジニア
```

#### 6.2 RCA テンプレート

```
【インシデント RCA レポート】

【インシデント概要】
- 件名: iOS でのアプリ起動時クラッシュ
- 開始: 2026-09-01 14:30 JST
- 解決: 2026-09-01 16:45 JST
- 継続時間: 2時間 15分
- 影響ユーザー: ~200 (全ユーザーの 10%)

【タイムライン】
14:30 - 初報告
14:35 - IC assigned
14:40 - 対応チーム集合
14:50 - 原因候補が Firebase SDK
15:10 - SDK v2.14.0 へのアップグレードを決定
15:40 - ホットフィックスビルド完成
16:00 - App Store 申請
16:45 - App Store で公開開始

【直接原因 (Proximate Cause)】
Firebase iOS SDK v2.13.0 の iOS 13+ での初期化バグ
- メモリアクセス エラー（out-of-bounds）
- ローカルストレージファイルの読み込み失敗

【根本原因 (Root Cause)】

5 Why 分析:
1. iOS 13+ で初期化エラーが発生した
   → なぜ？: Firebase SDK のバグ

2. Firebase SDK のバグが本番に入った
   → なぜ？: テストカバレッジが足りなかった

3. iOS 13+ テストカバレッジが足りなかった
   → なぜ？: テスト設定が iOS 14+ のみ

4. テスト設定が iOS 14+ のみだった
   → なぜ？: 古い iOS バージョンはサポート対象外と判断

5. 古い iOS バージョンのサポートが考慮されなかった
   → 根本原因: 要件定義時に最小 iOS バージョンを確認しなかった

【要因分析】
- テスト対象 OS バージョンが不十分
- Firebase SDK アップグレード時の互換性テストが不足
- リリース前チェックリストに OS バージョン互換性テストが含まれていない
- 古い iOS デバイスのユーザーが想定以上に多い

【改善アクション】

A. 即座に実施 (1-2週間以内)
  1. リリース前チェックリストに "iOS 最小バージョン（13.x）でテスト" を追加
  2. CI/CD パイプラインに iOS 13.x テストを追加

B. 短期実施 (1か月以内)
  1. Firebase SDK アップグレード時の互換性テスト手順を作成
  2. 外部パッケージアップグレード前レビュープロセスを導入

C. 長期実施 (3か月以内)
  1. デバイスファーム（複数 OS バージョン）の整備
  2. テスト自動化の拡大

D. 組織的対応 (6か月以内)
  1. QA プロセスの見直し
  2. リリース前チェックリストの強化
```

#### 6.3 改善アクション追跡

```
【改善アクション】

#457 - リリース前チェックリスト更新
  - Assignee: QA Lead
  - Due: 2026-09-08
  - 進捗: Open

#458 - CI/CD に iOS 13.x テスト追加
  - Assignee: DevOps
  - Due: 2026-09-15
  - 進捗: Open

#459 - Firebase SDK アップグレード手順ドキュメント
  - Assignee: Tech Lead
  - Due: 2026-09-22
  - 進捗: Open
```

---

## インシデント通知・コミュニケーション

### 1. インシデント初期通知

**対象**: ユーザー、ステークホルダー

```
件名: 【重要】アプリケーション障害についてのお知らせ

いつも小学コレ！道徳をご利用いただきありがとうございます。

本日午後、一部のユーザーでアプリが起動できない問題が発生いたしました。

【影響範囲】
- 対象: iOS ユーザーの一部
- 時間: 14:30-16:45（約 2 時間）
- ユーザー数: 約 200 名

【対応】
緊急修正版（v1.0.1）をアップロードいたしました。
App Store での更新をお願いいたします。

【次のステップ】
更新後、アプリが正常に起動するようになります。

ご迷惑をおかけして申し訳ございませんでした。
ご不明な点はサポート（support@example.com）までお問い合わせください。

小学コレ！道徳チーム
```

### 2. インシデント完了通知

```
件名: 【解決】アプリケーション障害が解決されました

ご報告いただきありがとうございます。

本日発生していたアプリ起動の問題は完全に解決されました。

【対応内容】
- 修正版 v1.0.1 をリリース
- App Store で公開開始（2026-09-01 16:45）
- Google Play では 2026-09-02 に公開予定

【ご対応】
1. App Store から アプリを更新
2. アプリを削除して再度インストール（キャッシュクリア）

ご迷惑をおかけして申し訳ございませんでした。
引き続きよろしくお願いいたします。

小学コレ！道徳チーム
```

---

## インシデント ダッシュボード

### GitHub Issues でインシデント管理

```markdown
【テンプレート: Issue】

## インシデント: [タイトル]

### 優先度
- [ ] P1 (緊急)
- [ ] P2 (高)
- [ ] P3 (低)

### インシデント概要
説明

### 影響範囲
- 対象ユーザー: 
- 影響期間: 
- 影響度: 

### タイムライン
| 時刻 | イベント |
|-----|---------|

### 原因
説明

### 対応
説明

### 改善アクション
- [ ] アクション 1
- [ ] アクション 2

### RCA
[RCA レポートへのリンク]
```

---

## インシデント頻度・分析

### 月次 インシデント サマリー

```
【2026 年 9 月 インシデント サマリー】

【発生数】
- P1: 1 件
- P2: 3 件
- P3: 5 件
- 合計: 9 件

【平均対応時間】
- P1: 2時間 15分 (目標: 2時間)
- P2: 8時間 30分 (目標: 24時間)
- P3: 3日 (目標: 7日)

【原因別】
- ソフトウェアバグ: 6 件 (67%)
- インフラ問題: 2 件 (22%)
- 設定エラー: 1 件 (11%)

【パターン】
- リリース直後: 4 件 → テスト不足の可能性
- 夜間: 2 件 → 監視体制不足の可能性
- 金曜夜: 2 件 → 疲労の可能性
```

### インシデント傾向分析

```
【改善が必要な領域】
1. リリース前テストの充実度（iOS 互換性テスト）
2. 外部パッケージの互換性テスト
3. 監視アラート感度の調整

【成功している領域】
1. インシデント対応速度（P1 は平均 2時間以内）
2. ホットフィックスプロセス（効率的に実施）
3. ユーザーコミュニケーション（透明性が高い）
```

---

## 参考資料

- [docs/HOTFIX_RESPONSE_PLAN.md](HOTFIX_RESPONSE_PLAN.md)
- [docs/PRODUCTION_MONITORING_SETUP.md](PRODUCTION_MONITORING_SETUP.md)
- [Google Cloud Incident Response](https://cloud.google.com/docs/incident-response)
- [Postmortem Culture](https://sre.google/books/)
