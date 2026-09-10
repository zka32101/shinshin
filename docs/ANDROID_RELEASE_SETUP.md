# Android リリースビルド設定ガイド

## 概要

このガイドは、shinshin アプリの署名付き AAB/APK ビルドを GitHub Actions で自動化するための設定手順です。

## 前提条件

- Android キーストアファイル（`.jks`）を所有していること
- GitHub リポジトリの管理者アクセス権を持っていること

## 1. Android キーストア（署名鍵）の生成

既に署名鍵がある場合はこのステップをスキップしてください。

### 新規生成の場合

```bash
# キーストアを生成（初回のみ）
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10950 \
  -alias upload

# 対話形式でパスワードと個人情報を入力してください
# - キーストアパスワード（ANDROID_KEYSTORE_PASSWORD）
# - キーパスワード（ANDROID_KEY_PASSWORD）
# - キーエイリアス（ANDROID_KEY_ALIAS）= "upload"
```

**重要**: キーストアファイルと各パスワードは安全に保管してください。

## 2. GitHub Secrets への登録

生成したキーストアを GitHub Secrets に登録します。

### 2.1 キーストアを Base64 エンコード

```bash
# macOS / Linux
base64 -i upload-keystore.jks

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

### 2.2 GitHub Secrets を設定

1. https://github.com/zka32101/shinshin/settings/secrets/actions にアクセス
2. 以下の 4 つの Secret を **New repository secret** で追加：

| Secret Name | 値 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | キーストアを Base64 エンコードした文字列 |
| `ANDROID_KEYSTORE_PASSWORD` | キーストアのパスワード |
| `ANDROID_KEY_ALIAS` | キーエイリアス（通常は `upload`） |
| `ANDROID_KEY_PASSWORD` | キーパスワード |

## 3. ビルド実行

### 3.1 タグプッシュでの自動ビルド

```bash
# バージョンタグをプッシュしてビルド開始
git tag v1.0.0
git push origin v1.0.0
```

**注**: タグは必ず `v*` の形式で作成してください（例: `v1.0.0`, `v1.0.1`）

### 3.2 GitHub Actions UI からの手動トリガー

1. https://github.com/zka32101/shinshin/actions にアクセス
2. **Build Signed Android App Bundle** ワークフローを選択
3. **Run workflow** > **workflow_dispatch** をクリック

## 4. ビルド成果物の確認

ビルド完了後、以下の場所でアーティファクトを確認できます：

### GitHub Actions から直接ダウンロード

1. ワークフロー実行を開く
2. **Artifacts** セクションで以下を確認：
   - `app-release-aab` — Google Play へのアップロード用
   - `app-release-apk` — テスト・直接インストール用

### GitHub Releases での確認（タグプッシュの場合）

1. https://github.com/zka32101/shinshin/releases にアクセス
2. 対応するリリースを確認

## 5. トラブルシューティング

### ビルド失敗: `ANDROID_KEYSTORE_BASE64` が見つからない

**原因**: GitHub Secrets に登録されていない

**解決**: 2.2 のステップを再度実行してください。

### ビルド失敗: `keytool: command not found`

**原因**: Java Development Kit (JDK) がインストールされていない

**解決**:
```bash
# macOS (Homebrew)
brew install openjdk

# Ubuntu/Debian
sudo apt-get install openjdk-11-jdk

# Windows
# JDK をダウンロード: https://www.oracle.com/java/technologies/downloads/
```

### ビルド失敗: `Gradle build failed`

**原因**: 署名鍵のパスワードが incorrect

**解決**: `ANDROID_KEY_PASSWORD` と `ANDROID_KEYSTORE_PASSWORD` を再確認してください。

## 6. 次のステップ

- Google Play Console へのアップロード自動化: [PLAY_CONSOLE_UPLOAD_SETUP.md](./PLAY_CONSOLE_UPLOAD_SETUP.md)
- App Store へのリリース: iOS ビルドガイドを参照

---

**最終更新**: 2026-09-10  
**参考**: [Flutter Official: Preparing an Android App for Release](https://docs.flutter.dev/deployment/android)
