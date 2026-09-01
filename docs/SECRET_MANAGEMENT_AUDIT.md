# 秘密情報管理監査レポート

**対象アプリ**: 小学コレ！道徳  
**実施日**: 2026年9月1日  
**対象範囲**: API キー、トークン、認証情報、環境変数  
**評価**: ⚠️ **改善が必要**

---

## 1. 秘密情報管理の現状

### 1.1 発見された問題点

#### 🔴 CRITICAL: デフォルト秘密キーがハードコードされている

**ファイル**: `backend/app/config.py` (13行目)

```python
secret_key: str = "dev-secret-change-in-production"
```

**問題**:
- JWT トークン署名用の秘密キーがコードに埋め込まれている
- 環境変数から読み込まれていない
- 本番環境でもこのデフォルト値が使用される可能性がある
- リポジトリ履歴に永続的に記録されている

**リスク**:
- 🔴 **CRITICAL**: JWT トークンの完全性が損なわれる
- 🔴 **CRITICAL**: 誰でもトークンを改ざんできる
- 🔴 **CRITICAL**: 親と子どものアカウント乗っ取り可能

**対応方法**:

1. **環境変数化**
```python
from pydantic import Field

class Settings(BaseSettings):
    secret_key: str = Field(...)  # 必須フィールド
    
    class Config:
        env_file = ".env"
```

2. **デフォルト値の廃止**
```bash
# .env ファイル
SECRET_KEY=your-production-secret-key-generate-a-random-long-string
```

3. **本番環境のみ設定**
```bash
# GitHub Actions 環境変数として注入
SECRET_KEY: ${{ secrets.PRODUCTION_SECRET_KEY }}
```

**優先度**: 🔴 **CRITICAL** - 本番デプロイ前に対応必須

---

#### 🔴 CRITICAL: 環境ファイルが Git に含まれている

**ファイル**:
- `.env.development`
- `.env.staging`
- `.env.production`

**問題**:
- 環境ファイルがGitリポジトリに含まれている
- GitHub の履歴に永続的に記録されている
- リポジトリをクローンすると、環境設定が公開される
- 秘密情報管理のベストプラクティスに違反

**確認コマンド**:
```bash
# リポジトリに含まれている環境ファイル確認
git ls-files | grep "\.env"
# 出力: .env.development, .env.staging, .env.production
```

**対応方法**:

1. **.gitignore に追加**
```
.env
.env.*
!.env.example
```

2. **Git 履歴から削除**
```bash
# 重要: 本番情報がない場合でも履歴から削除
git rm --cached .env.production .env.staging .env.development
git commit -m "Remove environment files from version control"

# Git-filter-branch で履歴から完全削除（推奨）
git filter-branch --tree-filter 'rm -f .env.production .env.staging' HEAD
```

3. **.env.example を共有**
```
# .env.example
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_API_KEY=your_firebase_api_key
API_BASE_URL=https://api.shougaku-kore.jp
SECRET_KEY=your_secret_key_here
```

**優先度**: 🔴 **CRITICAL** - 即座に対応

---

### 1.2 秘密情報の分類と管理方法

| 秘密情報 | 用途 | 管理方法 | 現状 | 評価 |
|---------|------|--------|------|------|
| Firebase API Key | API 認証 | `.env` | ✅ プレースホルダー | ✅ |
| JWT Secret Key | トークン署名 | `config.py` | 🔴 ハードコード | 🔴 |
| Database Password | DB 接続 | `config.py` | 🔴 デフォルト値 | 🔴 |
| Sentry DSN | エラーログ | `.env` | ✅ 環境変数化 | ✅ |
| SendGrid API Key | メール送信 | GitHub Secrets | ✅ Secrets化 | ✅ |
| Keystore Password | APK 署名 | GitHub Secrets | ✅ Secrets化 | ✅ |
| Firebase Credentials | Firebase SDK | サーバー環境 | ✅ 環境変数化 | ✅ |
| Google Cloud 鍵 | GCP API | サーバー環境 | ✅ JSON キーファイル | ✅ |

---

## 2. API キー管理

### 2.1 Firebase API Key

**保存方法**: `lib/firebase_options.dart`

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  appId: '1:000000000000:android:aaaaaaaaaaaaaaaa',
  messagingSenderId: '000000000000',
  projectId: 'shougaku-kore-doutoku',
  ...
);
```

**評価**: ✅ **安全**

**理由**:
- プレースホルダー値を使用
- Firebase API Key は公開可能（クライアント側）
- Firebaseセキュリティルールで保護
- Android/iOS には API Key が埋め込まれる（公開情報）

**Firebaseセキュリティルール**で API Key の悪用を防止:
```firestore
// 認証なしでは読み書き不可
allow read, write: if request.auth != null;
```

---

### 2.2 Sentry DSN

**保存方法**: `.env.production`

```env
SENTRY_DSN=https://your_production_sentry_dsn@sentry.io/project_id
```

**評価**: ✅ **安全**

**理由**:
- 環境変数化
- DSN は公開可能（エラーログ送信用）
- Sentry で rate limiting 設定可能

---

### 2.3 SendGrid API Key

**保存方法**: GitHub Secrets → 環境変数

**コード** (`backend/app/api/parent_coaching.py`):

```python
sendgrid_api_key = os.getenv("SENDGRID_API_KEY")
if not sendgrid_api_key:
    raise ValueError("SENDGRID_API_KEY not set")
```

**評価**: ✅ **安全**

**理由**:
- GitHub Secrets に保存（暗号化）
- 本番環境で環境変数として注入
- ログに出力されない

---

## 3. データベース認証情報

### 3.1 PostgreSQL Connection

**ファイル**: `backend/app/config.py` (8行目)

```python
database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/shougaku"
```

**問題**:
- ❌ デフォルトユーザー/パスワードが使用されている
- ❌ ローカルホストに限定
- ⚠️ 本番環境でも同じ設定が使用される可能性

**対応方法**:

```python
database_url: str = Field(default=None)  # 必須フィールド

# または

database_url: str = Field(
    default="postgresql://user:password@localhost/db"
)
```

**本番環境の設定**:
```bash
# GitHub Actions - デプロイ時
DATABASE_URL=postgresql://prod_user:strong_password@prod-host:5432/production_db
```

---

## 4. JWT トークン秘密キー

### 4.1 現在の実装

**ファイル**: `backend/app/security.py` (29行目)

```python
return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
```

**秘密キーのソース**: `backend/app/config.py`

```python
secret_key: str = "dev-secret-change-in-production"
```

**問題**:
- 🔴 **すべてのトークンが同じ秘密で署名される**
- 🔴 **秘密が変更されると、既存のすべてのトークンが無効化される**
- 🔴 **コード履歴に記録されている**

### 4.2 安全な実装方法

**ステップ1: 環境変数から秘密キーを読み込む**

```python
from pydantic import BaseSettings, Field
from functools import lru_cache
import secrets

class Settings(BaseSettings):
    # JWT 秘密キー（本番環境で必須）
    secret_key: str = Field(
        default=None,  # 本番環境では必須
        description="JWT token signing secret"
    )
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    
    class Config:
        env_file = ".env"
```

**ステップ2: 秘密キーが設定されていることを確認**

```python
def validate_secret_key():
    settings = get_settings()
    if not settings.secret_key or settings.secret_key == "dev-secret-change-in-production":
        raise ValueError("SECRET_KEY not properly configured")
```

**ステップ3: GitHub Actions で注入**

```yaml
- name: Deploy to Production
  env:
    DATABASE_URL: ${{ secrets.PROD_DATABASE_URL }}
    SECRET_KEY: ${{ secrets.PROD_SECRET_KEY }}
    SENTRY_DSN: ${{ secrets.PROD_SENTRY_DSN }}
```

---

## 5. 秘密キーのローテーション

### 5.1 秘密キーのローテーション戦略

**タイミング**:
- 🔴 漏洩時: 直ちに
- 🟡 定期的: 6ヶ月ごと
- 🟡 従業員離職時: 直ちに

**実装方法**:

```python
# 新しい秘密キーを生成
import secrets
new_secret_key = secrets.token_urlsafe(32)

# 2段階ローテーション：古いキーと新しいキーの両方を受け付ける
SECRET_KEYS = [
    settings.new_secret_key,  # 新キー（署名用）
    settings.old_secret_key,  # 旧キー（検証のみ）
]

def decode_token(token: str) -> dict:
    for secret_key in SECRET_KEYS:
        try:
            return jwt.decode(token, secret_key, algorithms=[settings.algorithm])
        except JWTError:
            continue
    raise HTTPException(status_code=401, detail="Invalid token")
```

---

## 6. GitHub Secrets セットアップ

### 6.1 現在の Secrets 設定

**ドキュメント**: `docs/github-secrets-setup.md`

#### ✅ 設定済み Secrets

| Secret | 用途 | 確認 |
|--------|------|------|
| KEYSTORE_BASE64 | Android APK 署名 | ✅ 実装 |
| KEYSTORE_PASSWORD | キーストア パスワード | ✅ 実装 |
| KEYSTORE_ALIAS | キーのエイリアス | ✅ 実装 |
| KEYSTORE_KEY_PASSWORD | キーのパスワード | ✅ 実装 |

#### ⚠️ 推奨する追加 Secrets

| Secret | 用途 | 優先度 |
|--------|------|--------|
| PROD_DATABASE_URL | 本番 DB URL | 🔴 必須 |
| PROD_SECRET_KEY | 本番 JWT キー | 🔴 必須 |
| PROD_SENTRY_DSN | 本番 Sentry DSN | 🟡 推奨 |
| IOS_CERTIFICATE_P12_BASE64 | iOS 証明書 | 🟡 推奨 |
| IOS_PROVISIONING_PROFILE_BASE64 | iOS プロビジョン | 🟡 推奨 |
| SENDGRID_API_KEY | メール API | 🔴 必須 |
| GEMINI_API_KEY | Google Gemini API | 🟡 推奨 |

### 6.2 Secrets 設定手順

```bash
# リポジトリディレクトリで実行
cd /path/to/shinshin

# 秘密キー生成
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
# 出力: z_LvjK9dXf4h2mK3pQ7rT5uV8wX9yZ0a1

# GitHub CLI で設定
gh secret set PROD_SECRET_KEY
# 秘密キーをペースト

# 確認
gh secret list
```

---

## 7. コードレビューチェックリスト

### 7.1 秘密情報が含まれていないかの確認

| チェック項目 | 方法 | 実施状況 |
|------------|------|--------|
| ハードコードされたパスワード | grep + 手動確認 | ⚠️ 部分的 |
| API キー | Gitleaks 自動スキャン | ✅ 実装 |
| 秘密トークン | Secret Detection | ✅ 実装 |
| DB 接続文字列 | Bandit（Python） | ✅ 実装 |
| .env ファイル | .gitignore 確認 | ❌ 未実施 |

### 7.2 Git Secrets スキャン

**CI/CD 実装**: `.github/workflows/security-scan.yml`

```yaml
- name: Run Gitleaks Secret Scan
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**評価**: ✅ **実装済み**

**スキャン対象**:
- API キー
- 秘密トークン
- プライベートキー
- AWS キー
- GCP キー

---

## 8. Firebase 秘密情報管理

### 8.1 Firebase Credentials

**管理方法**: サーバー環境変数

**ファイル**: `FIREBASE_CREDENTIALS_PATH` 環境変数で指定

```python
firebase_credentials_path: Optional[str] = None
```

**本番環境の設定**:
```bash
# Google Cloud Secret Manager で管理
FIREBASE_CREDENTIALS=$(gcloud secrets versions access latest --secret=firebase-credentials)
```

### 8.2 Firebase Security Rules

**Firestore ルール**: `firebase/firestore.rules`
**Storage ルール**: `firebase/storage.rules`

**評価**: ✅ **安全**

**ルールの特徴**:
- ✅ 認証チェック実装
- ✅ 所有権検証実装
- ✅ 親権確認実装
- ✅ 管理者限定操作実装

---

## 9. ローカル開発環境での秘密情報管理

### 9.1 開発用 .env ファイル

**ファイル**: `.env.development`

**現在の内容**:
```env
FIREBASE_PROJECT_ID=shougaku-kore-doutoku-dev
FIREBASE_API_KEY=YOUR_DEV_FIREBASE_API_KEY
API_BASE_URL=http://localhost:8000
SECRET_KEY=dev-secret-change-in-production
```

**評価**: ⚠️ **開発環境用としては許可可能**

**推奨**:
- `.env.development` は Git に含めない
- `.env.development.example` を共有
- 各開発者が自分の `.env.development` を作成

### 9.2 Firebase Emulator

**設定**: `USE_FIREBASE_EMULATOR=false`

**ローカル開発での使用**:
```bash
# Firebase Emulator Suite 起動
firebase emulators:start

# .env.development で有効化
USE_FIREBASE_EMULATOR=true
FIREBASE_EMULATOR_HOST=localhost
FIREBASE_AUTH_EMULATOR_PORT=9099
FIRESTORE_EMULATOR_PORT=8080
```

---

## 10. 秘密情報の監査ログ

### 10.1 GitHub Actions でのログ

**⚠️ 注意**: GitHub Actions のログに秘密情報が出力されないようにする

**実装例**:
```yaml
- name: Test Secret
  run: |
    if [ -z "${{ secrets.PROD_SECRET_KEY }}" ]; then
      echo "Secret not set"
    else
      echo "Secret is set"  # 秘密の値は出力しない
    fi
```

### 10.2 アプリケーションログ

**ログレベル管理**: `backend/app/main.py`

```python
logging.basicConfig(level=logging.DEBUG if settings.debug else logging.INFO)
```

**本番環境では**:
- ✅ `DEBUG` レベルログなし
- ✅ 秘密情報がログに出力されない
- ✅ エラーメッセージに詳細情報なし

---

## 11. 秘密情報漏洩時の対応

### 11.1 緊急対応フロー

**秘密情報が漏洩した場合**:

1. **直ちに秘密キーをローテーション**
   ```bash
   # 新しい秘密キーを生成
   python3 -c "import secrets; print(secrets.token_urlsafe(32))"
   
   # GitHub Actions Secrets を更新
   gh secret set PROD_SECRET_KEY
   ```

2. **既存のトークンを無効化**
   ```python
   # 古い秘密キーをリストから削除
   SECRET_KEYS = [
       settings.new_secret_key,  # 新キーのみ
   ]
   ```

3. **全ユーザーに再認証を促す**
   - メール通知送信
   - アプリ内通知表示
   - トークンの有効期限を短縮

4. **インシデント報告書を作成**
   - 漏洩内容
   - 対応措置
   - 今後の予防策

---

## 12. セキュリティベストプラクティス

### 12.1 環境別の秘密情報管理

| 環境 | 保存方法 | アクセス | 更新頻度 |
|------|--------|--------|--------|
| **ローカル開発** | `.env.development` | 開発者のみ | 自由 |
| **ステージング** | GitHub Secrets | CI/CD | 月1回 |
| **本番** | GitHub Secrets / Google Cloud Secret Manager | 制限アクセス | 6ヶ月ごと |

### 12.2 秘密キーの生成方法

```python
import secrets

# 安全な秘密キーを生成
def generate_secret_key(length: int = 32) -> str:
    return secrets.token_urlsafe(length)

# 使用例
secret_key = generate_secret_key()
# 出力: 例 z_LvjK9dXf4h2mK3pQ7rT5uV8wX9yZ0a1b
```

### 12.3 秘密情報の配布禁止

❌ **してはいけないこと**:
- Slack/メール で秘密情報を送信
- 秘密情報を GitHub Issue に記載
- パスワード管理ツールなしで共有
- 平文で保存

✅ **すべき事**:
- GitHub Secrets で管理
- Google Cloud Secret Manager で管理
- 1Password などのパスワード管理ツール
- 必要な人だけにアクセス権を付与

---

## 13. 監査チェックリスト

| # | 項目 | チェック | 対応状況 | 期限 |
|----|------|---------|--------|------|
| 1 | JWT 秘密キーの環境変数化 | 🔴 必須 | ❌ 未対応 | 本番前 |
| 2 | 環境ファイルの Git 除外 | 🔴 必須 | ❌ 未対応 | 本番前 |
| 3 | GitHub Secrets 設定 | 🟡 推奨 | ⚠️ 部分的 | 本番前 |
| 4 | DB パスワードの環境変数化 | 🔴 必須 | ❌ 未対応 | 本番前 |
| 5 | API キーのローテーション戦略 | 🟡 推奨 | ❌ 未実装 | 1ヶ月以内 |
| 6 | 秘密情報漏洩時の対応計画 | 🟡 推奨 | ❌ 未実装 | 3ヶ月以内 |
| 7 | 開発者向けセキュリティ教育 | 🟢 推奨 | ❌ 未実施 | 6ヶ月以内 |
| 8 | Git Secrets CI/CD 統合 | 🟡 推奨 | ✅ 実装済み | - |

---

## 14. 秘密情報管理チートシート

### 14.1 環境変数の設定

```bash
# ローカル開発
export SECRET_KEY="dev-secret-key"
export DATABASE_URL="postgresql://postgres:postgres@localhost/shougaku"

# または .env.development で管理
cat > .env.development << EOF
SECRET_KEY=dev-secret-key
DATABASE_URL=postgresql://postgres:postgres@localhost/shougaku
FIREBASE_PROJECT_ID=shougaku-kore-doutoku-dev
EOF
```

### 14.2 秘密キー生成

```bash
# Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# OpenSSL
openssl rand -base64 32

# Linux
head -c 32 /dev/urandom | base64
```

### 14.3 GitHub Actions でのデバッグ

```bash
# 秘密が正しく設定されているか確認
gh secret list

# 秘密の値を確認（ローカルのみ可能）
gh secret view PROD_SECRET_KEY
```

---

## 15. 改善計画

### 🔴 CRITICAL（本番前）

1. **JWT 秘密キーの環境変数化**
   - 期限: 本番デプロイ前
   - 所有者: バックエンド チーム
   - チェック: テスト環境で動作確認

2. **環境ファイルの Git 除外**
   - 期限: 本番デプロイ前
   - 所有者: DevOps チーム
   - チェック: git ls-files で確認

3. **GitHub Secrets 設定**
   - 期限: 本番デプロイ前
   - 所有者: DevOps チーム
   - チェック: gh secret list で確認

### 🟡 HIGH（1ヶ月以内）

1. **API キーローテーション計画**
   - 実装: 6ヶ月ごと自動ローテーション

2. **秘密情報漏洩時の対応計画**
   - ドキュメント作成
   - チーム教育

### 🟢 MEDIUM（3ヶ月以内）

1. **開発者向けセキュリティ教育**
2. **秘密情報監査スクリーニング**

---

## 16. まとめ

### ✅ 良い点

- ✅ Git Secrets スキャン実装
- ✅ GitHub Secrets 活用
- ✅ Firebase セキュリティルール実装
- ✅ 環境変数化の推進

### ⚠️ 改善が必要

- 🔴 JWT 秘密キーのハードコード
- 🔴 環境ファイルが Git に含まれている
- 🔴 DB パスワードのデフォルト値
- 🟡 秘密キーローテーション計画なし
- 🟡 インシデント対応計画なし

### 総合評価

**秘密情報管理: C+（改善が必須）**

本番環境デプロイ前に CRITICAL 項目をすべて対応してください。

---

**監査実施日**: 2026年9月1日  
**次回監査予定**: 2026年12月1日  
**有効期限**: 3ヶ月

*秘密情報管理は継続的なプロセスです。定期的な見直しと改善を実施してください。*
