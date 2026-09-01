# ホットフィックス対応体制

**小学コレ！道徳** - 本番環境の緊急対応

**最終更新**: 2026年9月1日

---

## 概要

本ドキュメントは、本番環境で重大なバグやセキュリティ脆弱性が検出された場合のホットフィックス対応体制を定めています。

**目標**: 検出から修正リリースまで **1-2営業日以内**

---

## ホットフィックス対象の判定基準

### P1 - 緊急対応が必要（即日リリース）

**対象**:
- クラッシュレート > 2% が継続
- セキュリティ脆弱性（認証・支払い）
- ユーザーデータ喪失のリスク
- 支払い処理の失敗
- App Store/Google Play ポリシー違反の可能性

**例**:
- アプリ起動時に常にクラッシュ
- ログイン機能が完全に不可
- In-App Purchase が処理されない
- 個人情報がローカルに平文保存

**対応時間**: 検出から 2-4時間以内にリリース

### P2 - 高優先度（24時間以内）

**対象**:
- クラッシュレート 0.5-2%
- 特定ユーザー層（OS バージョン等）の大幅な影響
- パフォーマンス著しく低下（> 10秒起動時間）
- UI が不正に表示される（ユーザー操作不可）

**例**:
- iOS 15.x でのみクラッシュ
- 特定の話では常にクラッシュ
- セッション継続時間が 1秒未満
- レーダーチャートが表示されない

**対応時間**: 検出から 24時間以内にリリース

### P3 - 低優先度（通常のリリースサイクル）

**対象**:
- クラッシュレート < 0.5%
- UI 表示のわずかなズレ（ユーザー操作可能）
- 音声機能の不具合（メイン機能に影響なし）

**例**:
- 親向けレポートの表示ズレ
- 音声ナレーションが再生されない（テキストは表示）
- 特定のフォントが表示されない

**対応時間**: 通常のリリースサイクルで対応

---

## ホットフィックス対応フロー

### フェーズ 1: 検出・報告（0-15分）

#### 1.1 問題検出

**検出方法**:
1. Firebase Crashlytics アラート
2. Sentry アラート
3. ユーザーレビュー監視
4. App Store/Google Play コンソール通知
5. メール・Slack 通報

#### 1.2 問題報告テンプレート

```
【ホットフィックス レポート】

【検出日時】
2026-09-01 14:30 JST

【優先度】
P1 / P2 / P3

【タイトル】
iOS 15.x でアプリがクラッシュ

【詳細】
- OS: iOS 15.0-15.7
- App: v1.0.0
- クラッシュレート: 5.2%
- 影響ユーザー: 約 150
- クラッシュ発生場所: StoryLearningScreen での選択肢タップ時

【スタックトレース】
(Firebase Crashlytics から)
...

【再現手順】
1. アプリを起動
2. 3番目のストーリーを選択
3. 最初の選択肢をタップ
→ クラッシュ

【報告者】
zkaz83@gmail.com

【GitHub Issue】
#123
```

#### 1.3 報告チャンネル

- **Slack**: #critical（直接 @channel で通知）
- **GitHub**: 緊急 Issue を作成（ラベル: `hotfix`, `P1`）
- **メール**: ops@example.com（CC: 全エンジニア）

### フェーズ 2: 対応チーム確認（15-30分）

#### 2.1 オンコール担当者が対応を開始

```
【確認事項】
- [ ] 優先度判定が正しいか
- [ ] 再現可能か
- [ ] 原因の特定可能か
- [ ] リソース（人・時間）が確保できるか
- [ ] P1 の場合、上司に報告したか
```

#### 2.2 対応チーム構成

**P1 対応チーム**:
- リード（シニアエンジニア）
- Android 開発者
- iOS 開発者
- QA（テスト）
- DevOps（ビルド・リリース）

**P2 対応チーム**:
- エンジニア 1-2 名
- QA 1 名

#### 2.3 Slack スレッド開始

```
Slack #critical で:

@channel

【ホットフィックス - P1】
iOS 15.x でのクラッシュ対応開始

対応チーム:
- @alice (リード)
- @bob (iOS)
- @charlie (QA)

進捗: このスレッドで報告

詳細: #123
```

### フェーズ 3: 原因特定・修正（30分-1時間）

#### 3.1 デバッグ開始

```bash
# Crashlytics でスタックトレース確認
open https://console.firebase.google.com/project/[id]/crashlytics

# Sentry でエラー詳細確認
open https://sentry.io/organizations/shougaku-kore/

# ローカルで再現
flutter devices
flutter run -d ios  # iOS 15.x デバイス

# デバッグ情報出力
flutter run -d ios -v --debug-port 9221
```

#### 3.2 修正実装

**修正ブランチを作成**:

```bash
# main から修正ブランチを作成
git fetch origin
git checkout -b hotfix/ios-15-crash origin/main

# 修正を実装
# ... コード修正 ...

# コミット（タイトルに Issue 番号）
git commit -m "Fix: iOS 15.x クラッシュ (#123)

- UIView 配置の問題を修正
- iOS 15.0+ での互換性確認

Fixes #123"
```

**修正の品質確認**:

```bash
# コードレビュー（リード確認）
git push origin hotfix/ios-15-crash
# GitHub で PR を作成

# 簡易テスト実行
flutter test lib/screens/story/story_learning_screen_test.dart

# 対象デバイスでテスト
flutter run -d ios
# 再現手順を複数回実行
```

#### 3.3 進捗報告

```
Slack スレッド:

@alice @bob @charlie

【進捗】
13:45: 原因特定 - iOS 15.x での UIView 配置バグ
13:50: 修正実装完了（hotfix/ios-15-crash）
14:00: PR #124 作成、レビュー中
```

### フェーズ 4: ビルド・署名・テスト（1-1.5時間）

#### 4.1 バージョン番号更新

```yaml
# pubspec.yaml
version: 1.0.1+2  # パッチバージョンアップ
```

**バージョニングルール**:
```
通常リリース: v1.0.0 → v1.1.0 (マイナー)
ホットフィックス: v1.0.0 → v1.0.1 (パッチ)
```

#### 4.2 ビルド

```bash
# 依存関係更新
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Android AAB ビルド
flutter build appbundle \
  --release \
  --build-number=2

# iOS ビルド
flutter build ios --release \
  --build-number=2

# ビルド成功確認
ls -lh build/app/outputs/bundle/release/app-release.aab
```

**ビルド環境設定**:

```bash
# GitHub Actions を使用する場合
# .github/workflows/hotfix.yml

name: Hotfix Build
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Hotfix version (e.g., 1.0.1)'
        required: true

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Build & Sign
        run: |
          flutter pub get
          flutter build appbundle --release
          flutter build ios --release
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: release-builds
          path: |
            build/app/outputs/bundle/release/
            build/ios/
```

#### 4.3 QA による確認テスト

**テスト項目** (P1 の場合):

```
【機能テスト】
- [ ] 問題が再現しないか
- [ ] 新しくクラッシュしていないか
- [ ] 主要機能が正常か

【リグレッションテスト】
- [ ] ログイン機能
- [ ] ストーリー表示
- [ ] 課金機能
- [ ] 親向けレポート

【パフォーマンスチェック】
- [ ] 起動時間 < 3秒
- [ ] フレームレート 60FPS
- [ ] メモリ使用量 < 150MB

【署名・セキュリティ】
- [ ] リリース署名が正しいか
- [ ] デバッグ証明書ではないか
- [ ] Privacy ポリシーが正常か
```

**テスト実施**:

```bash
# 統合テスト実行
flutter test integration_test/hotfix_test.dart

# デバイステスト
flutter devices
flutter run -d <device_id>

# テスト結果を Slack に報告
# ✅ テスト成功 / ❌ テスト失敗 / ⚠️ 要追加調査
```

#### 4.4 Google Play & App Store での署名確認

```bash
# Android AAB 署名確認
zipalign -v 4 app-release.aab app-release-aligned.aab

# iOS ipa 署名確認
codesign -dv build/ios/ipa/runner.ipa

# 署名が正しいことを確認
# Issuer: Apple Distribution: Petitworks Inc.
```

### フェーズ 5: ストア申請（1.5-2時間）

#### 5.1 Google Play へのアップロード

**重要**: 通常の段階的ロールアウトではなく、**緊急配布**を使用

```
Google Play Console > テスト > 本番環境

【新しいリリースを作成】
AAB をアップロード: build/app/outputs/bundle/release/app-release.aab

【リリース情報】
バージョン: 1.0.1
リリースノート:
"【緊急修正】
iOS 15.x でのクラッシュ問題を修正しました。
本修正により、iOS 15.0-15.7 ユーザーの安定性が向上します。
アップグレードをお願いいたします。"

【リリース方法】
☐ 段階的なロールアウト（通常）
☑ 自動的にリリース（P1 ホットフィックス）
  → 選択: 「できるだけ早くリリース」
```

**確認ポイント**:
```
- [ ] AAB がアップロードされた
- [ ] 署名が正しい
- [ ] アプリケーション ID が正しい
- [ ] バージョン番号が正しい
```

#### 5.2 App Store への提出

```bash
# ipa をアップロード
cd build/ios/ipa
open /Applications/Transporter.app

# GUI で runner.ipa を Transporter にドラッグ&ドロップ
# または CLI:

xcrun altool --upload-app \
  --type ios \
  --file runner.ipa \
  --username apple_id@example.com \
  --password app_specific_password
```

**App Store Connect での設定**:

```
My Apps > 小学コレ！道徳 > iOS App

【バージョン情報】
バージョン番号: 1.0.1
ビルド番号: 2（Google Play と同じ）

【リリースノート】
このリリースの内容:
"【緊急修正】
iOS でのクラッシュ問題を修正いたしました。

詳細な内容:
- ストーリー選択時のクラッシュを修正
- パフォーマンスの改善

ご迷惑をおかけして申し訳ございませんでした。
本修正をお願いいたします。"

【リリース方法】
☑ 自動的にリリース（App Store Review 完了後）
```

**App Store の審査対応**:

```
【審査が却下された場合】
1. 審査担当者のコメントを確認
2. 修正内容を説明する回答を作成
3. "審査に対する回答"セクションで返信
4. 新しいビルドをアップロード（オプション）

【通常は P1 ホットフィックスは加速審査される】
- App Store Review Guidelines 準拠の場合、通常 24-48時間以内に審査完了
```

### フェーズ 6: リリース監視（リリース後 4-6時間）

#### 6.1 即時監視

```bash
# Firebase Console で監視
open https://console.firebase.google.com/project/[id]/analytics

# 監視項目
- [ ] クラッシュレートが低下したか
- [ ] DAU に大幅な低下がないか
- [ ] 新しいクラッシュが発生していないか
```

**監視スケジュール**:
```
リリース直後: 15分ごと
1時間経過: 30分ごと
3時間経過: 1時間ごと
6時間経過: 通常の監視に戻す
```

#### 6.2 ロールバック手順（もし新しい問題が発生した場合）

```bash
# Google Play でロールアウトを中止
# Play Console > 本番環境 > "ロールアウト中止"

# App Store でリリースを取り下げ
# App Store Connect > このバージョンを削除

# 前のバージョンを再度リリース
git checkout v1.0.0
flutter build appbundle --release
# Google Play にアップロード

# Slack で報告
# @channel ロールバック実施しました。原因調査中です。
```

#### 6.3 最終報告

```
Slack #critical:

【ホットフィックス 完了】

バージョン: 1.0.1
リリース時刻: 2026-09-01 15:30 JST

【結果】
✅ Google Play で公開
✅ App Store で審査中（予定: 24時間以内）
✅ クラッシュレート低下を確認

【監視状況】
- クラッシュレート: 0.3% (ホットフィックス前: 5.2%)
- ユーザー反応: ポジティブ

【次のステップ】
- App Store 審査完了待ち（自動リリース）
- 48時間の監視継続

対応ありがとうございました。
```

---

## ホットフィックス優先度判定マトリックス

| 影響範囲 | ユーザー数 | クラッシュレート | 優先度 |
|---------|----------|----------------|-------|
| アプリ全体 | > 1,000 | > 2% | P1 |
| アプリ全体 | 100-1,000 | 0.5-2% | P2 |
| 特定機能 | > 1,000 | < 0.5% | P2 |
| 特定機能 | < 100 | < 0.5% | P3 |

---

## よくある問題と対応

### "クラッシュレートが低下しない"

```
【確認項目】
1. Firebase Analytics のデータ遅延（最大 24時間）
2. 修正が実際に有効になっているか（バージョン確認）
3. Google Play でのロールアウト % が 100% か
4. キャッシュの問題（ユーザーが新バージョンをダウンロードしているか）

【対応】
- 24-48時間待つ
- "強制更新"メッセージを追加
- Slack で進捗を報告
```

### "App Store の審査が遅い"

```
【対応】
- App Store Review Guidelines を再確認
- "審査に対する回答"を作成
- Apple サポートに問い合わせ
- 加速審査オプションを検討
```

### "ロールバック後も問題が継続"

```
【対応】
1. Sentry で詳細ログを確認
2. ユーザー端末のロジック確認
3. ローカルストレージのデータ破損を確認（Hive, SharedPreferences）
4. キャッシュクリア手順を案内
5. 上司に報告
```

---

## ホットフィックス後の事後対応

### 6.1 根本原因分析（RCA）

```
【実施時期】
ホットフィックス完了 24時間後

【参加者】
- テックリード
- 対応エンジニア
- QA
- プロダクトマネージャー

【確認項目】
1. なぜこのバグは本番環境に入ったのか
2. テストで検出できなかった理由
3. 再発防止策

【出力】
docs/INCIDENT_RESPONSE_PROCEDURES.md に記録
```

### 6.2 顧客コミュニケーション

**メール テンプレート**:

```
件名: アプリの緊急修正について

いつも小学コレ！道徳をご利用いただきありがとうございます。

本日、アプリの安定性に関わる問題を検出し、即座に修正いたしました。

【対応内容】
- バージョン 1.0.1 をリリースしました
- クラッシュ問題が解決されました
- 全ユーザーにアップデートをお勧めしています

【ご対応】
App Store または Google Play からアップデートをお願いいたします。

ご迷惑をおかけして申し訳ございませんでした。
引き続きよろしくお願いいたします。

小学コレ！道徳チーム
```

### 6.3 改善アクション

```
【実装対象外（通常リリース待ち）】
- 既存テストカバレッジ拡大
- 新しい監視アラート設定
- リリース前チェックリスト更新

【GitHub Issues】
#125 - テストを iOS 15.x で実行
#126 - Crashlytics アラートの感度向上
#127 - リリース チェックリストに iOS バージョン互換性テストを追加
```

---

## ホットフィックス オンコール対応

### オンコール担当者の事前準備

```bash
# 環境設定を事前に確認
echo $KEYSTORE_PASSWORD  # 署名パスワード
echo $APPLE_ID           # Apple ID
echo $FASTLANE_PASSWORD  # FastLane パスワード

# 必要なツールをインストール
brew install fastlane
brew install xcodes
flutter upgrade

# リポジトリをクローン
git clone https://github.com/petitworks/shougaku-kore-doutoku.git
cd shougaku-kore-doutoku
flutter pub get
```

### オンコール連絡先

```
【オンコール当番】
月-日: alice@example.com (11:00-23:00)
日-月: bob@example.com (23:00-11:00)

【エスカレーション】
- 2時間以内に解決できない場合 → プロジェクトマネージャーに報告
- リリースが必要な場合 → CTO に報告
```

---

## 参考資料

- [docs/RELEASE_PROCEDURE_FINAL.md](RELEASE_PROCEDURE_FINAL.md)
- [docs/PRODUCTION_MONITORING_SETUP.md](PRODUCTION_MONITORING_SETUP.md)
- [docs/INCIDENT_RESPONSE_PROCEDURES.md](INCIDENT_RESPONSE_PROCEDURES.md)
