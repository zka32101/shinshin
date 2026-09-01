# 秘密情報管理監査

## 概要
小学コレ！道徳アプリのシークレット・認証情報管理を監査したレポートです。

## Firebase 秘密情報の確認

### 実装状況

- [x] .gitignore に Firebase 認証ファイルが含まれている
  - `google-services.json` (Android) - 含まれている
  - `GoogleService-Info.plist` (iOS) - 含まれている
  - `firebase*.json` - パターンマッチで除外

- [x] firebase_config.dart のプレースホルダー化
  - **実装**: `lib/config/firebase_config.dart:6-12`
  - **状態**: YOUR_API_KEY など開発者向けプレースホルダー使用
  - **評価**: ⚠️ 本番環境設定が未定義

### 問題点

1. **firebase_options.dart の機械生成**
   - Firebase CLI で自動生成されるファイル
   - 実環境での初期化に必須
   - **推奨**: firebase_options.dart を .gitignore に追加してから、環境別に分離

2. **API キーの環境変数化が未実装**
   - **現状**: `firebase_config.dart` にハードコード
   - **推奨**: .env ファイルから読み込み

## API キーの管理方法

### バックエンド設定

- [x] .env ファイルが .gitignore に含まれている
  - `backend/.gitignore:10` で `.env` を除外

- [ ] Firebase credentials path が設定可能
  - **実装**: `backend/app/config.py:17`
  - **状態**: 環境変数 `FIREBASE_CREDENTIALS_PATH` で指定可能
  - **推奨**: JSON キーファイルは環境変数として BASE64 エンコードで渡すことを検討

### 環境変数の確認

**backend/app/config.py:**
```python
# JWT
secret_key: str = "dev-secret-change-in-production"  # ⚠️ 警告

# Firebase
firebase_project_id: str = ""
firebase_credentials_path: Optional[str] = None
```

**問題:**
- secret_key が「開発環境用」と明記されているが、本番切り替えが自動化されていない
- firebase_credentials_path が未設定の場合のフォールバック処理がない

## 環境別設定（dev/staging/prod）

### 現状

- [x] 開発用 .env.development.local が git から除外
- [ ] Staging / Production 用の .env 管理が未実装

### 推奨実装

```bash
# ルートディレクトリの構成
.env.development
.env.staging
.env.production
```

各環境ごとに以下を分離:
- JWT secret_key
- Firebase project_id
- API base URL
- Sentry DSN
- CORS allowed_origins

## .gitignore の完全性確認

### ✓ 適切に設定されている項目

```gitignore
# Firebase & API keys
google-services.json
GoogleService-Info.plist
firebase*.json

# SSH/SSL Keys
*.pem, *.p8, *.key, *.p12, *.keystore

# Credentials
credentials.json
*-creds.json

# Secrets
*secret*, *token*

# Environment
.env, .env.local, .env.*.local
```

### ⚠️ 追加推奨項目

```gitignore
# Firebase options
firebase_options.dart

# API keys in code
lib/config/api_keys.dart
lib/config/firebase_secrets.dart

# IDE secrets
.vscode/settings.local.json
.idea/vcs.xml
```

## シークレット管理の推奨事項

### 高優先度

1. **環境別 .env ファイルの分離**
   ```bash
   # backend/.env ファイルテンプレート
   ENVIRONMENT=development
   SECRET_KEY=your-secret-key-here
   FIREBASE_PROJECT_ID=shougaku-kore-doutoku
   FIREBASE_CREDENTIALS_PATH=/path/to/firebase-key.json
   SENTRY_DSN=https://...
   API_BASE_URL=http://localhost:8000
   CORS_ORIGINS=["http://localhost:3000"]
   DEBUG=true
   ```

2. **Firebase Admin SDK キーの .gitignore 化**
   - `firebase-key.json` を .gitignore に追加
   - CI/CD で環境変数から構築

3. **secret_key の本番化**
   - `backend/app/config.py` で環境変数から読み込み
   - 最小32文字の強力な値を設定

### 中優先度

1. **API キーの環境変数化（フロントエンド）**
   ```dart
   // lib/config/api_config.dart
   String get apiBaseUrl =>
       dotenv.env['API_BASE_URL'] ?? 'https://api.shougaku-kore.jp';
   ```
   - **現状**: 既に dotenv で実装済み ✓

2. **Firebase キーのローテーション**
   - 定期的（6ヶ月ごと）にキーを更新

3. **Sentry DSN の非公開化**
   - Sentry Dashboard の DSN は非公開設定に

## セキュリティ監査チェックリスト

| 項目 | 完了 | 優先度 | 対策 |
|------|------|--------|------|
| .env が git から除外 | ✓ | - | - |
| Firebase JSON が除外 | ✓ | - | - |
| API キー環境変数化 | ✓ | - | - |
| Secret key を環境変数化 | ✗ | 高 | 実装 |
| 環境別 .env 分離 | ✗ | 高 | 実装 |
| firebase_options.dart 除外 | ✗ | 中 | .gitignore 追加 |
| キーローテーション計画 | ✗ | 中 | ポリシー策定 |

## 参考資料

- 12 Factor App: https://12factor.net/config
- Firebase Security Best Practices: https://firebase.google.com/docs/database/security
