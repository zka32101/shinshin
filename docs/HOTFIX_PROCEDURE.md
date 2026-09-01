# ホットフィックス手順

## 小学コレ！道徳 - 緊急パッチリリース手順

**適用対象**: v1.0.0 以上の本番環境

---

## 概要

ホットフィックスは、本番環境で発見された **重大なバグ・セキュリティ脆弱性** に対応するための緊急リリースです。

### ホットフィックスが必要な例

```
✅ クラッシュを引き起こすバグ
✅ データ損失につながるバグ
✅ セキュリティ脆弱性
✅ COPPA 非準拠の機能
❌ UI の細かい修正（次のバージョンで対応）
❌ テキストの誤字（次のバージョンで対応）
```

---

## ホットフィックスの優先度

### P1（極度に緊急）
```
【応答時間】: 1 時間以内
【リリース時間】: 3 時間以内

例:
- セキュリティ脆弱性
- ユーザーデータ損失
- 多数のクラッシュ（> 10%）
```

### P2（高優先度）
```
【応答時間】: 4 時間以内
【リリース時間】: 24 時間以内

例:
- 特定のデバイスでのクラッシュ（5-10%）
- 主要機能の不具合
- ユーザー認証の問題
```

### P3（通常）
```
【応答時間】: 営業日内
【リリース時間】: 1-3 日

例:
- UI の不具合（機能は継続可能）
- パフォーマンス低下（軽微）
```

---

## ホットフィックスプロセス

### Step 1: 問題検証・優先度決定（30分以内）

```bash
# 1. 問題の重大性を評価
   - ユーザーへの影響度
   - 再現性
   - 緊急度

# 2. 優先度を決定（P1/P2/P3）

# 3. 対応者を割り当て
   - エンジニア
   - テスター
   - デプロイメント担当

# 4. Slack/メールで通知
   - #incidents チャネル
   - 関係者に直接通知
```

### Step 2: ホットフィックスブランチを作成

```bash
# 現在のブランチを確認
git branch

# 最新の本番ブランチを確認
git fetch origin main
git log origin/main --oneline | head -3

# ホットフィックスブランチを作成
# パターン: hotfix/v1.0.1-<issue-description>
git checkout -b hotfix/v1.0.1-crash-fix

# または、より具体的に
git checkout -b hotfix/v1.0.1-firebase-auth-crash
```

### Step 3: バグを修正

```bash
# 1. 問題を特定・ローカライズ
   - 関連するコードを特定
   - テストケースを作成
   - 修正のスコープを定義

# 2. 修正を実装
vim lib/screens/home/home_screen.dart
# （必要な修正を実施）

# 3. テストを実施
flutter test --coverage

# 4. ローカルでビルド・実行
flutter run --release
```

### Step 4: コミット・プッシュ

```bash
# 変更をステージ
git add .

# コミットメッセージは明確に
git commit -m "Fix: Firebase 認証でのクラッシュを修正

- Issue: ユーザーがログイン直後にアプリがクラッシュ
- 原因: Firebase.initializeApp() の非同期処理が完了前にアクセス
- 修正: async/await で適切に待機
- 影響: v1.0.0 のみ
- テスト: ユニットテスト・統合テスト追加

Fixes #123"

# ホットフィックスブランチをプッシュ
git push origin hotfix/v1.0.1-firebase-auth-crash
```

### Step 5: レビュー・テスト

```bash
# GitHub で Pull Request を作成
# ベースブランチ: main
# 比較ブランチ: hotfix/v1.0.1-firebase-auth-crash

# PR テンプレート:
---
## ホットフィックス概要

**Issue**: #123
**優先度**: P1
**推定修正時間**: 30 分

## 問題の説明

ユーザーがログイン直後にアプリがクラッシュします。

## 修正内容

Firebase.initializeApp() の完了を待つ await キーワードを追加

## テスト項目

- [ ] ログイン → ホーム画面遷移（クラッシュなし）
- [ ] 複数回の起動確認
- [ ] 別デバイスでも検証

## リリース予定

2026-09-01 15:00 JST
```

### Step 6: 品質保証（QA）

```
【最小テスト項目】:
- [ ] 修正したコンポーネント単体テスト
- [ ] 関連機能の統合テスト
- [ ] リグレッション（既存機能への影響）テスト
- [ ] 複数デバイス・OS バージョンでの確認
- [ ] パフォーマンス確認
```

### Step 7: バージョン更新

修正がマージされたら、バージョンを更新：

```bash
# main ブランチに切り替え
git checkout main
git pull origin main

# ホットフィックスをマージ
git merge hotfix/v1.0.1-firebase-auth-crash --ff-only

# またはマージコミット（推奨）
git merge --no-ff hotfix/v1.0.1-firebase-auth-crash -m "Merge hotfix/v1.0.1"
```

バージョン情報を更新：

```bash
# pubspec.yaml
- version: 1.0.0+1
+ version: 1.0.1+2

# android/app/build.gradle.kts
- versionCode = 1
+ versionCode = 2

# CHANGELOG.md に追加
### [1.0.1] - 2026-09-01

#### 🔧 Bug Fixes
- Firebase 認証でのクラッシュを修正 (#123)

#### 🔒 Security
- N/A

#### ⚙️ Technical Changes
- async/await による正確な初期化待機
```

### Step 8: ホットフィックスタグを作成・プッシュ

```bash
# タグを作成
git tag -a v1.0.1 -m "Hotfix v1.0.1 - Firebase auth crash fix"

# またはサイン付きタグ（推奨）
git tag -s -a v1.0.1 -m "Hotfix v1.0.1 - Firebase auth crash fix"

# タグをプッシュ（GitHub Actions トリガー）
git push origin v1.0.1
```

### Step 9: GitHub Actions ビルドを監視

```bash
# ビルド実行を確認
gh run list --workflow=build-release.yml --limit 1

# ビルドログをリアルタイムで監視
gh run watch <RUN_ID>

# ビルド完了を待機（通常 15-20 分）
```

### Step 10: ストアにアップロード

#### Google Play

```bash
# ビルド成果物をダウンロード
gh run download <RUN_ID> -n android-aab-release

# Google Play Console にアップロード
# （RELEASE_GUIDE.md の「Google Play へのアップロード」を参照）

# ロールアウト戦略:
# ホットフィックスの場合は通常 100% 即座リリース
# （ただし、段階的ロールアウト 5%-25%-100% も可）

【予想リリース時間】
Google Play 審査: 1-3 時間（優先扱い可能）
```

#### App Store

```bash
# Transporter で IPA をアップロード
# （RELEASE_GUIDE.md の「App Store へのアップロード」を参照）

# 優先審査をリクエスト
# App Store Connect → 質問 → 「優先審査をリクエスト」

【予想リリース時間】
App Store 審査: 2-4 時間（優先扱い）
```

### Step 11: リリース確認・監視

```bash
# ストア掲載ページで確認
- Google Play: 利用可能か確認
- App Store: 配信中か確認

# リアルタイム監視を開始
- Firebase Console
- Sentry（エラートラッキング）
- Google Play/App Store Console

【監視項目】
- クラッシュレート
- インストール数
- 新しいエラーの発生
- ユーザーレビュー
```

### Step 12: ホットフィックスブランチをクリーンアップ

```bash
# ローカルブランチを削除
git branch -d hotfix/v1.0.1-firebase-auth-crash

# リモートブランチを削除
git push origin --delete hotfix/v1.0.1-firebase-auth-crash
```

---

## ホットフィックス例

### 例 1: クラッシュバグの修正

```
Issue: ユーザーがログイン直後にアプリがクラッシュ
Priority: P1
ETA: 2 時間

【対応】
1. ホットフィックスブランチ作成
   git checkout -b hotfix/v1.0.1-auth-crash

2. バグを修正
   - Firebase 初期化を await で待機

3. テスト実行
   flutter test
   flutter run --release

4. コミット・プッシュ
   git commit -m "Fix: Firebase auth crash on login"
   git push origin hotfix/v1.0.1-auth-crash

5. PR 作成・マージ

6. タグ作成・プッシュ
   git tag v1.0.1
   git push origin v1.0.1

7. ビルド監視・ストア配信
```

### 例 2: セキュリティ脆弱性の修正

```
Issue: API キーが平文でログに出力されている
Priority: P1
ETA: 1 時間

【対応】
1. セキュリティチーム に報告（社内）
   - security@shougaku-kore.jp

2. 修正実装
   - ログ出力から API キーを除外
   - 過去ログを削除（Firebase Console）

3. 迅速なテスト・リリース
   - ビルド: 15 分
   - ストア配信: 1-3 時間

4. セキュリティ報告
   - 外部に報告（必要な場合）
   - ユーザー通知（必要な場合）
```

### 例 3: UI バグの修正

```
Issue: ボタンがタップできなくなった（軽微）
Priority: P3
ETA: 営業日内

【対応】
1. 修正実装
2. テスト
3. 通常のバッチリリール（v1.0.2）に含める
   （ホットフィックスでは対応しない）
```

---

## チェックリスト

### ホットフィックス前

- [ ] 問題を再現可能か確認
- [ ] 優先度を決定（P1/P2/P3）
- [ ] 修正のスコープを定義
- [ ] 関係者に通知
- [ ] ホットフィックスブランチを作成

### ホットフィックス中

- [ ] バグを修正
- [ ] ユニットテストを追加
- [ ] ローカルで動作確認
- [ ] 関連コンポーネントで リグレッション テスト
- [ ] コミットメッセージを明確に記載

### ホットフィックス後

- [ ] PR をレビュー・承認
- [ ] main ブランチにマージ
- [ ] バージョン情報を更新
- [ ] CHANGELOG.md を更新
- [ ] タグを作成・プッシュ
- [ ] GitHub Actions ビルドを監視
- [ ] ストアでビルドを確認
- [ ] ストア申請・配信
- [ ] 本番環境を監視（24 時間）
- [ ] ホットフィックスブランチをクリーンアップ

---

## よくある質問（FAQ）

### Q: ホットフィックスの命名規則は？

**A**: 
```
v1.0.1, v1.0.2, ... と連番で増加
CHANGELOG.md で理由を記載
```

### Q: ホットフィックスをリリースした後、本バージョン計画に影響はあるか？

**A**: 
```
次のバージョン: v1.1.0 予定のままでOK
ホットフィックス: v1.0.1, v1.0.2, ... は枝番
```

### Q: ホットフィックスをキャンセルできるか？

**A**: 
```
【キャンセルのタイミング】
- ストア配信前: GitHub で PR を閉じる
- ストア配信後: 不可（新しいホットフィックスで対応）
```

### Q: 複数のホットフィックスが同時に必要な場合？

**A**: 
```
優先度 P1 から順に対応
または、複数の修正を1つのホットフィックスに統合
（QA 期間は短く、24 時間以内の完了を目指す）
```

---

## サポート連絡先

### ホットフィックス関連

```
Slack: #incidents チャネル
Email: devops@shougaku-kore.jp
On-Call: Google Meet での緊急会議
```

### セキュリティホットフィックス

```
Email: security@shougaku-kore.jp
Severity: Critical
Response SLA: 1 時間以内
```

---

## 関連ドキュメント

- [RELEASE_GUIDE.md](RELEASE_GUIDE.md) - 通常リリース手順
- [MONITORING.md](MONITORING.md) - 本番環境監視
- [docs/security.md](docs/security.md) - セキュリティ情報

---

**最後更新**: 2026-09-01  
**バージョン**: 1.0
