# 自動ビルド・デプロイガイド

## 概要

shinshin （小学コレ！道徳）は GitHub Actions を使用した完全自動化されたビルド・デプロイシステムを採用しています。

**主な機能**:
- ✅ タグプッシュ時の自動ビルド
- ✅ 署名付き AAB/APK 自動生成
- ✅ GitHub Releases への自動公開
- ✅ workflow_dispatch による手動トリガー
- ✅ Branch Protection + 自動マージ
- ✅ CI/CD パイプライン統合

## ワークフロー構成

```
┌─────────────────────┐
│  タグプッシュ       │  git push origin v1.0.0
│  または             │
│  workflow_dispatch  │
└──────────┬──────────┘
           │
    ┌──────▼──────────┐
    │   Setup Flutter │
    └──────┬──────────┘
           │
    ┌──────▼──────────────┐
    │ Restore Keystore    │  GitHub Secrets から署名鍵復元
    │ from Secrets        │
    └──────┬──────────────┘
           │
    ┌──────▼──────────────┐
    │ Build AAB & APK     │
    │ (signed release)    │
    └──────┬──────────────┘
           │
    ┌──────▼──────────────┐
    │ Upload Artifacts    │  Actions & Releases に保存
    │ Create Release      │  （30日間保持）
    └─────────────────────┘
```

## セットアップ手順

### ステップ 1: GitHub Secrets 登録（初回のみ）

[ANDROID_RELEASE_SETUP.md](./ANDROID_RELEASE_SETUP.md) に従って、以下の Secrets を登録：

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

### ステップ 2: Branch Protection 設定（オプション）

本番リリース前に必ずテストを通すようにするため、Branch Protection を設定：

1. https://github.com/zka32101/shinshin/settings/branches
2. **Add rule** をクリック
3. **Branch name pattern** に `main` または `release/*` を入力
4. 以下をチェック:
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Require code review before merging（2 approvals）

### ステップ 3: バージョン管理

`pubspec.yaml` で現在のバージョンを確認：

```yaml
version: 1.0.0+1  # 1.0.0 = SemVer / +1 = build code
```

## ビルド実行方法

### 方法 1: タグプッシュ（推奨）

```bash
# ローカル環境
git tag v1.0.0
git push origin v1.0.0

# GitHub 画面でビルド進捗を確認
# Actions → "Build Signed Android App Bundle" をクリック
```

### 方法 2: GitHub UI からの手動トリガー

1. https://github.com/zka32101/shinshin/actions
2. **Build Signed Android App Bundle** ワークフローをクリック
3. **Run workflow** > **workflow_dispatch** をクリック

### 方法 3: GitHub CLI（gh コマンド）

```bash
# ログイン（初回のみ）
gh auth login

# ワークフローをトリガー
gh workflow run deploy.yml
```

### 方法 4: curl でのトリガー

```bash
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/zka32101/shinshin/actions/workflows/deploy.yml/dispatches \
  -d '{"ref":"main"}'
```

## ビルド成果物の確認

### GitHub Actions から

1. https://github.com/zka32101/shinshin/actions
2. ワークフロー実行を選択
3. **Artifacts** セクションで以下をダウンロード:
   - `app-release-aab` — Google Play Console 用
   - `app-release-apk` — テスト・直接インストール用

### GitHub Releases から（タグプッシュの場合）

1. https://github.com/zka32101/shinshin/releases
2. 対応するバージョンをクリック
3. ドラフト Release から確認

**注**: Release は自動で **Draft** 状態で作成されます。  
リリース準備完了後に **Publish** してください。

## 自動マージワークフロー

Branch Protection + `auto-merge.yml` により、以下の PR が自動マージされます：

- `fix/*` ブランチからの PR（全 CI パス時）
- `chore/*` ブランチからの PR（全 CI パス時）
- dependabot PR

```yaml
# 例：自動マージ対象
fix/v1.0-firebase-dependency-resolution → main ✅ 自動マージ
chore/update-dependencies → main ✅ 自動マージ
feature/new-feature → main ❌ 手動マージ（レビュー必須）
```

## CI/CD パイプライン

### 実行されるチェック

1. **Flutter Linting & Analysis** (`ci.yml`)
   - lint チェック
   - analyze チェック
   - 成功時間: 1-2 分

2. **Flutter Tests** (`ci.yml`)
   - ユニットテスト
   - ウィジェットテスト
   - 成功時間: 3-5 分

3. **Security Scan** (`security-scan.yml`)
   - 依存関係の脆弱性チェック
   - コードスキャン
   - 成功時間: 2-3 分

### ステータス確認

https://github.com/zka32101/shinshin/actions で全ワークフロー実行状況を確認

## トラブルシューティング

### ビルド失敗時の確認ポイント

1. **GitHub Secrets の確認**
   ```bash
   gh secret list  # ローカルで確認不可
   # GitHub UI から https://github.com/zka32101/shinshin/settings/secrets/actions で確認
   ```

2. **ログを確認**
   - Actions ワークフロー実行ページで、失敗ステップを展開
   - エラーメッセージを確認

3. **Flutter バージョン確認**
   ```bash
   flutter --version
   # 現在: Flutter 3.47.3 / Dart 3.13.3
   ```

4. **ローカルでのテストビルド**
   ```bash
   flutter build appbundle --release  # AAB 生成テスト
   flutter build apk --release         # APK 生成テスト
   ```

### よくある問題と解決方法

| 問題 | 原因 | 解決策 |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64 not found` | Secrets 未登録 | ANDROID_RELEASE_SETUP.md を参照 |
| `Gradle build failed` | パスワード incorrect | Secrets を再確認 |
| `Flutter not found` | Flutter アクションの問題 | workflow で Flutter バージョンを確認 |
| `APK/AAB ファイルが見つからない` | ビルド失敗 | ログの Gradle エラーを確認 |

## 他プロジェクトへの展開

このワークフローを他プロジェクトに導入する場合：

### チェックリスト

- [ ] `pubspec.yaml` のバージョン確認
- [ ] `.github/workflows/deploy.yml` をコピー
- [ ] `docs/ANDROID_RELEASE_SETUP.md` をコピー
- [ ] Flutter バージョンを `deploy.yml` で指定
- [ ] GitHub Secrets を登録
- [ ] タグプッシュでテストビルド実行
- [ ] AAB/APK が正常に生成されたか確認

### カスタマイズポイント

```yaml
# deploy.yml で変更可能な項目
flutter-version: '3.47.3'        # Flutter バージョン
retention-days: 30                # アーティファクト保持期間
release_name: 'Release v1.0.0'    # Release 名前
```

## GitHub Releases への完全自動デプロイ

Google Play Console への自動アップロードを設定する場合：

→ [PLAY_CONSOLE_UPLOAD_SETUP.md](./PLAY_CONSOLE_UPLOAD_SETUP.md)（近日公開）

## サポート情報

問題が発生した場合：

1. GitHub Issues で報告: https://github.com/zka32101/shinshin/issues
2. Actions ログを添付
3. 以下を記載:
   - ワークフロー名（例: Build Signed Android App Bundle）
   - タグ/トリガー方法
   - エラーメッセージ

---

**最終更新**: 2026-09-10  
**ステータス**: ✅ v1.0 自動化対応済み  
**参考**: [GitHub Actions ドキュメント](https://docs.github.com/en/actions)
