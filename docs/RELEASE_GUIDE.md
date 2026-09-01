# リリース&デプロイメントガイド

## 小学コレ！道徳 - リリース手順ドキュメント

**対象バージョン**: v1.0.0 以上

---

## 目次

1. [リリース前チェック](#リリース前チェック)
2. [ステージング環境へのデプロイ](#ステージング環境へのデプロイ)
3. [本番リリース](#本番リリース)
4. [Google Play へのアップロード](#google-playへのアップロード)
5. [App Store へのアップロード](#app-storeへのアップロード)
6. [リリース後の監視](#リリース後の監視)
7. [トラブルシューティング](#トラブルシューティング)

---

## リリース前チェック

### ✅ コード品質確認

```bash
# 静的解析
flutter analyze --no-pub

# Lint チェック
dart run lints:main lib

# テスト実行
flutter test --coverage

# テストカバレッジ確認
open coverage/index.html
```

### ✅ バージョン確認

```bash
# pubspec.yaml のバージョンを確認
grep "^version:" pubspec.yaml

# android/app/build.gradle.kts を確認
grep "versionName\|versionCode" android/app/build.gradle.kts

# ios/Runner/Info.plist を確認
cat ios/Runner/Info.plist | grep -A1 "FLUTTER_BUILD_NAME\|FLUTTER_BUILD_NUMBER"
```

### ✅ CHANGELOG の更新

```bash
# 変更内容を CHANGELOG.md に記載
# 形式:
# ### [X.Y.Z] - YYYY-MM-DD
# #### ✨ Features
# - 新機能1
# - 新機能2
```

### ✅ ドキュメント更新

```bash
# 重要なドキュメントが最新か確認
- README.md
- CHANGELOG.md
- docs/security.md
- docs/legal/
```

### ✅ セキュリティスキャン

```bash
# GitHub Actions で実行
gh workflow run security-scan.yml

# 結果を待機
gh workflow view security-scan.yml
```

### ✅ Firebase 設定確認

```bash
# Firebase Console で以下を確認:
- Firestore セキュリティルール (最新版デプロイ済み)
- Storage セキュリティルール (最新版デプロイ済み)
- Authentication 設定
- Cloud Functions (デプロイ済み)
```

### ✅ GitHub Secrets 確認

```bash
# GitHub Secrets が正しく設定されているか確認
gh secret list | grep -i KEYSTORE

# 出力例:
# KEYSTORE_ALIAS
# KEYSTORE_BASE64
# KEYSTORE_KEY_PASSWORD
# KEYSTORE_PASSWORD
```

---

## ステージング環境へのデプロイ

### Step 1: ステージングタグの作成と推送

```bash
# 現在のブランチを確認
git branch

# develop ブランチに切り替え（存在する場合）
git checkout develop
# または main ブランチで実行
git checkout main

# ステージング用タグを作成
git tag v1.0.0-staging.1

# ステージングタグをプッシュ
git push origin v1.0.0-staging.1
```

### Step 2: GitHub Actions ワークフロー確認

```bash
# ワークフロー実行を確認
gh run list --workflow=build-release.yml

# リアルタイムでログを表示
gh run view --log <RUN_ID>
```

### Step 3: ステージング環境でテスト

#### Android
```bash
# ステージング用 APK をダウンロード
gh run download <RUN_ID> -n android-apk-release

# テストデバイスにインストール
adb install -r app-release.apk

# テスト項目:
- 起動確認
- ログイン確認
- ストーリー表示
- 音声ナレーション
- オフラインモード
- 親向けレポート表示
```

#### iOS
```bash
# ステージング用 IPA をダウンロード
gh run download <RUN_ID> -n ios-ipa-release

# TestFlight にアップロード（手動）
# または Xcode 経由でテストデバイスにインストール

# テスト項目:
- 起動確認
- ログイン確認
- 一連の機能テスト（Android と同様）
```

### Step 4: バグ修正（必要な場合）

バグが見つかった場合：

```bash
# 修正ブランチを作成
git checkout -b fix/staging-issue-xxx

# 修正を実施・コミット
git add .
git commit -m "Fix: ステージング環境で見つかったバグを修正"

# main/develop にマージ
git checkout main
git merge fix/staging-issue-xxx

# タグを再作成
git tag -d v1.0.0-staging.1
git tag v1.0.0-staging.2
git push origin v1.0.0-staging.2 --force
```

---

## 本番リリース

### Step 1: リリース準備

```bash
# main ブランチ（最新）を確認
git checkout main
git pull origin main

# リリースするコミットを確認
git log --oneline | head -5
```

### Step 2: バージョン更新

```bash
# バージョン情報を確認・更新
# pubspec.yaml
version: 1.0.0+1

# android/app/build.gradle.kts
versionCode = 1
versionName = "1.0.0"

# CHANGELOG.md
### [1.0.0] - 2026-09-01
```

### Step 3: リリースタグの作成

```bash
# リリースタグを作成
git tag -a v1.0.0 -m "Release v1.0.0 - Initial Production Release"

# サインされたタグを推奨（git config が必要）
git tag -s -a v1.0.0 -m "Release v1.0.0"
```

### Step 4: タグをプッシュしてビルド開始

```bash
# タグをプッシュ（GitHub Actions トリガー）
git push origin v1.0.0

# ビルド進捗を確認
gh run list --workflow=build-release.yml --limit 5

# ビルド完了を待機
gh run watch <RUN_ID>
```

### Step 5: リリースノート作成

```bash
# GitHub Release を自動作成（GitHub Actions）
# または手動作成
gh release create v1.0.0 \
  --title "小学コレ！道徳 v1.0.0" \
  --notes "Initial production release with full feature set" \
  --latest
```

### Step 6: ビルド成果物のダウンロード

```bash
# AAB（Google Play 用）と APK をダウンロード
gh run download <RUN_ID> -n android-aab-release
gh run download <RUN_ID> -n android-apk-release

# ファイルを確認
ls -lh *.aab *.apk
```

---

## Google Play へのアップロード

### 前提条件

```
✅ Google Play Developer Account が有効
✅ アプリが Google Play Console で作成済み
✅ プライベートトラックで初期テスト済み
✅ Google Play ストアの掲載要件を確認
```

### Step 1: Google Play Console にログイン

```
1. https://play.google.com/console にアクセス
2. Google アカウントでログイン
3. 「小学コレ！道徳」アプリを選択
```

### Step 2: AAB をアップロード

```
1. 左メニュー → 「リリース」→「本番」
2. 「新しいリリースを作成」をクリック
3. AAB ファイルをアップロード
   - build/app/outputs/bundle/release/app-release.aab
4. レビューノートを入力
5. 「ロールアウト」を選択
```

### Step 3: ストアメタデータの確認

```
【ストアの掲載情報】
- アプリ説明文
- スクリーンショット（4〜8枚）
- 機能説明
- カテゴリー: 教育
- コンテンツレーティング: 全年齢向け
- プライバシーポリシーリンク
- 利用規約リンク
```

### Step 4: Google Play 事前登録（オプション）

```
リリース1-2週間前に事前登録を開始:
1. 左メニュー → 「事前登録」
2. 「事前登録キャンペーンを作成」
3. マーケティング情報を入力
4. キャンペーンを開始
```

### Step 5: リリース承認・ロールアウト

```
【審査期間】
通常 3-24 時間

【ステータス確認】
Google Play Console → リリース → 本番 → ステータス確認

【ロールアウト段階】
推奨: 段階的なロールアウト
- Day 1: 5% のユーザーに配信
- Day 3: 25% のユーザーに配信
- Day 7: 100% に拡大

【即座リリース】
緊急時のみ 100% リリース
```

---

## App Store へのアップロード

### 前提条件

```
✅ Apple Developer Account が有効
✅ App Store Connect アカウント
✅ 開発用・配布用証明書が準備済み
✅ プロビジョニングプロファイルが準備済み
```

### Step 1: Xcode でビルド・アーカイブ

```bash
# Xcode を開く
open ios/Runner.xcworkspace

# アーカイブの作成
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -derivedDataPath build \
  -archivePath build/Runner.xcarchive \
  archive
```

### Step 2: IPA をエクスポート

```bash
# ExportOptions.plist を準備（あらかじめ作成）
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/Release \
  -exportOptionsPlist ExportOptions.plist
```

### Step 3: App Store Connect へアップロード

#### 方法 1: Xcode Organizer（推奨）

```
1. Xcode → Window → Organizer
2. Archives タブを選択
3. App Store へのアップロードを選択
4. App Store Connect の認証情報を入力
5. アップロード完了を待機
```

#### 方法 2: Transporter

```bash
# Transporter をダウンロード（App Store から）
# または xcrun transporter を使用

xcrun altool --upload-app \
  -f path/to/app.ipa \
  -t ios \
  -u <apple_id> \
  -p <app_password>
```

### Step 4: App Store Connect でリリース準備

```
1. https://appstoreconnect.apple.com にアクセス
2. 「マイ App」→「小学コレ！道徳」を選択
3. 「App Store」タブを選択
4. バージョン情報を入力:
   - リリースノート
   - スクリーンショット
   - プレビュー動画（オプション）
   - キーワード
   - カテゴリー
```

### Step 5: App Store 審査に提出

```
1. 「一般」情報を確認
2. 「App レビュー情報」を入力
3. 「審査のために提出」をクリック
4. 確認ダイアログで「送信」をクリック
```

### Step 6: 審査進捗の監視

```
【審査期間】
通常 1-3 日（最長 2 週間）

【進捗確認】
App Store Connect → 活動 → App Review

【ステータス】
- 審査中
- 待機中（追加情報が必要）
- 承認済み（リリース準備完了）
- リジェクト（修正が必要）
```

### Step 7: リリース

```
【承認後】
1. 「App Store に送信する準備」を確認
2. 「App Store に送信」をクリック
3. リリーススケジュールを選択:
   - 自動リリース（承認後すぐ）
   - 手動リリース（指定日時）

【リリース完了】
24 時間以内にすべてのユーザーに配信
```

---

## リリース後の監視

### 📊 リアルタイムモニタリング

#### Google Play Console

```
【確認項目】
1. インストール数・アンインストール数
2. ユーザーレイティング・レビュー
3. クラッシュレート（< 0.5% が目標）
4. ANR（Application Not Responding）レート
5. デバイス・OS 別のパフォーマンス
```

#### App Store Connect

```
【確認項目】
1. ダウンロード数
2. セッション数
3. ユーザーレイティング
4. クラッシュレート
5. リモート設定の状態
```

### 🔔 アラート設定

#### Firebase Console

```
Performance Monitoring:
- スローアニメーション（> 16.67ms）
- スローレンダリング（> 50ms）
- アプリの起動時間（目標: < 3秒）

Cloud Logging:
- エラーレート監視
- 重大なログメッセージ
```

#### Sentry（エラートラッキング）

```
設定項目:
- 新規エラーの自動通知
- エラーレート閾値（> 5%）
- リリーションの差分追跡
```

### 🎯 KPI 監視

リリース後の最初の 24-72 時間に確認すべき指標：

```
✅ インストール数
   目標: 平日の初日で最低 1,000+

✅ クラッシュレート
   目標: < 0.5%

✅ スター評価
   目標: 4.0 以上

✅ レビューコメント
   目標: 建設的なフィードバックを反映

✅ ユーザーリテンション（1日後）
   目標: > 30%

✅ セッション時間
   目標: > 5 分（子どもユーザー向け）
```

### 🛠️ 初期問題対応

リリース直後の問題発見時：

```
【軽微なバグ】
→ 次のバッチリリース（v1.0.1）に含める

【重大なバグ】
→ ホットフィックス（24時間以内にリリース）
   詳細は HOTFIX_PROCEDURE.md を参照

【セキュリティ脆弱性】
→ 即座にホットフィックス
   security@shougaku-kore.jp に報告
```

---

## トラブルシューティング

### ❌ Google Play でビルドがリジェクトされた

**症状**: 「不正なバイナリ」エラー

**対応**:
```bash
# 1. AAB が正しい署名か確認
bundletool validate --bundle-path=app-release.aab

# 2. 署名情報を確認
jarsigner -verify -verbose -certs app-release.aab

# 3. キーストアが正しいか確認
keytool -list -keystore ~/.shougaku-kore-release.jks
```

### ❌ App Store 審査でリジェクトされた

**一般的な理由**:
- COPPA 準拠不足
- プライバシーポリシーが明記されていない
- 親の同意メカニズムが不十分

**対応**:
```
1. リジェクト理由を詳読
2. 対応方法を修正
3. ビルド番号を増加させて再提出
```

### ❌ ワークフロー失敗

**症状**: GitHub Actions でビルド失敗

**確認項目**:
```bash
# 1. Secrets が正しく設定されているか
gh secret list | grep -i KEYSTORE

# 2. ワークフロー ログを確認
gh run view <RUN_ID> --log

# 3. 問題を特定して修正
# （パスワードなど）
```

---

## ベストプラクティス

### ✅ リリースチェックリスト

- [ ] CHANGELOG.md を更新
- [ ] README.md を確認
- [ ] テストすべてパス
- [ ] セキュリティスキャン完了
- [ ] ステージング環境で検証
- [ ] バージョン情報を更新
- [ ] GitHub Secrets を確認
- [ ] Firebase ルールを最新化
- [ ] ドキュメントをアップデート
- [ ] リリースノートを準備

### ✅ リリース後のチェックリスト

- [ ] ストア掲載ページで確認
- [ ] ユーザーレイティング監視
- [ ] クラッシュレート監視
- [ ] エラーログ確認
- [ ] ユーザーレビュー・質問に対応
- [ ] 初期ユーザーフィードバック収集
- [ ] パフォーマンス測定
- [ ] セキュリティ監視

---

## 関連ドキュメント

- [HOTFIX_PROCEDURE.md](HOTFIX_PROCEDURE.md) - ホットフィックス手順
- [MONITORING.md](MONITORING.md) - 本番環境監視ガイド
- [docs/github-secrets-setup.md](docs/github-secrets-setup.md) - GitHub Secrets 設定
- [docs/security.md](docs/security.md) - セキュリティ情報

---

**最後更新**: 2026-09-01  
**バージョン**: 1.0
