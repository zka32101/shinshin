# Google Play Console アップロード設定ガイド

## 概要

このガイドは、署名付き AAB を GitHub Actions から Google Play Console に自動アップロードするための設定手順です。

**状態**: 🚧 準備中（v1.0.2 でサポート予定）

## 前提条件

- Google Play Developer アカウント
- アプリが Google Play Console で登録済み
- Service Account（サービスアカウント）キー

## 1. Google Play Developer Account の準備

### 1.1 アカウント設定

1. https://play.google.com/console にアクセス
2. "小学コレ！道徳" アプリを選択
3. **すべてのアプリ** > **小学コレ！道徳** > **設定** を開く

### 1.2 Service Account キーの生成

1. **ユーザーとアクセス権** に移動
2. **サービスアカウント** セクションから新規作成
3. または Google Cloud Console で生成（推奨）

## 2. GitHub Secrets への登録

Service Account キーを GitHub Secrets に追加：

1. https://github.com/zka32101/shinshin/settings/secrets/actions
2. `PLAY_CONSOLE_SERVICE_ACCOUNT_JSON` を新規作成
3. Service Account キーの JSON 全体をペースト

## 3. Workflow の設定

`deploy.yml` に以下を追加（今後実装予定）：

```yaml
- name: Upload AAB to Google Play Console
  if: startsWith(github.ref, 'refs/tags/')
  uses: r0adkll/upload-google-play@v1
  with:
    serviceAccountJsonPlainText: ${{ secrets.PLAY_CONSOLE_SERVICE_ACCOUNT_JSON }}
    packageName: com.example.shinshin
    releaseFile: build/app/outputs/bundle/release/app-release.aab
    track: internal  # internal, alpha, beta, or production
    status: inProgress
```

## 実装スケジュール

- **v1.0**: 手動 Release
- **v1.1** 以降: 自動アップロード対応予定

---

**最終更新**: 2026-09-10
