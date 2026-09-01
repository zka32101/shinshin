# 小学コレ！道徳 — ステージング環境セットアップガイド

## 概要
このドキュメントは、本番前テストのための Staging Firebase Project とバックエンド環境の設定方法を定義します。

## ステージング環境アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│         Staging Development Environment                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐         ┌──────────────────┐   │
│  │ Flutter App      │◄───────►│ Staging Backend  │   │
│  │ (dev variant)    │         │ (FastAPI)        │   │
│  └──────────────────┘         └──────────────────┘   │
│           ▲                             ▲             │
│           │                             │             │
│           ▼                             ▼             │
│  ┌──────────────────┐         ┌──────────────────┐   │
│  │ Staging Firebase │         │ Staging DB       │   │
│  │ - Authentication │         │ (PostgreSQL)     │   │
│  │ - Firestore      │         └──────────────────┘   │
│  │ - Cloud Storage  │                                │
│  └──────────────────┘                                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Staging Firebase プロジェクト設定

### 1. Firebase プロジェクト作成

#### 1.1 Firebase Console でプロジェクト作成
```bash
# Firebase CLI でログイン
firebase login

# プロジェクト一覧表示
firebase projects:list

# Staging プロジェクトの情報を確認
firebase projects:describe shougaku-kore-doutoku-staging
```

#### 1.2 Staging 用設定ファイルの生成

**Android**
```bash
# Firebase Console > Project Settings > Download google-services.json
# android/app/google-services.json の Staging バージョン
mkdir -p android/app/staging
cp android/app/google-services.json android/app/staging/google-services.json
```

**iOS**
```bash
# Firebase Console > Project Settings > Download GoogleService-Info.plist
# ios/config/Staging/GoogleService-Info.plist に配置
mkdir -p ios/config/Staging
cp GoogleService-Info.plist ios/config/Staging/GoogleService-Info.plist
```

### 2. Authentication 設定

#### 2.1 メール認証の有効化
```bash
# Firebase Console > Authentication > Sign-in method
# ✓ Email/Password を有効化
firebase auth:import data/staging-users.json --hash-algo=scrypt
```

#### 2.2 テストユーザー作成
```json
{
  "users": [
    {
      "uid": "staging-parent-001",
      "email": "parent@staging.test",
      "emailVerified": true,
      "passwordHash": "...",
      "customClaims": {
        "role": "parent",
        "trialActive": true
      }
    },
    {
      "uid": "staging-parent-002",
      "email": "parent-premium@staging.test",
      "emailVerified": true,
      "passwordHash": "...",
      "customClaims": {
        "role": "parent",
        "subscriptionActive": true
      }
    }
  ]
}
```

#### 2.3 Google Sign-In 設定（オプション）
```bash
# Firebase Console > Authentication > Google
# OAuth 2.0 クライアント ID を設定
```

### 3. Firestore データベース設定

#### 3.1 データベース作成
```bash
# Staging Firestore を作成
firebase firestore:create --location=asia-northeast1

# セキュリティルールのデプロイ
firebase deploy --only firestore:rules
```

#### 3.2 Firestore セキュリティルール（Staging 用）
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Staging 環境でのテスト用ルール
    // 本番環境より緩いルールを設定可能
    
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /children/{childId} {
        allow read, write: if request.auth.uid == userId;
        
        match /progress/{progressId} {
          allow read, write: if request.auth.uid == userId;
        }
        
        match /sessions/{sessionId} {
          allow read, write: if request.auth.uid == userId;
        }
      }
    }
    
    // テスト用コレクション（Staging のみ）
    match /test_data/{document=**} {
      allow read, write: if true;
    }
  }
}
```

#### 3.3 初期データ投入
```bash
# テスト用ストーリー、プロフィールなどを投入
firebase firestore:import data/staging-firestore-dump.json

# または Node.js スクリプトで投入
node scripts/setup-staging-data.js
```

### 4. Cloud Storage 設定

#### 4.1 ストレージバケット作成
```bash
# Staging バケット作成
gsutil mb -l asia-northeast1 gs://shougaku-kore-doutoku-staging.appspot.com
```

#### 4.2 Storage セキュリティルール
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Staging テスト用
    match /staging-test/{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 5. Firebase Analytics 設定

#### 5.1 Google Analytics 連携
```bash
# Firebase Console > Project Settings > Google Analytics
# Staging 専用 Google Analytics アカウント作成
```

#### 5.2 カスタムイベント設定
```dart
// Staging 環境では詳細なログ記録
FirebaseAnalytics.instance.logEvent(
  name: 'staging_event',
  parameters: {
    'event_type': 'test',
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

## Staging バックエンド環境設定

### 1. Docker Compose で Staging 環境構築

#### 1.1 docker-compose.staging.yml 作成
```yaml
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: staging_user
      POSTGRES_PASSWORD: ${STAGING_DB_PASSWORD}
      POSTGRES_DB: shougaku_staging
    ports:
      - "5433:5432"
    volumes:
      - staging_db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U staging_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6380:6379"
    volumes:
      - staging_redis_data:/data

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgresql+asyncpg://staging_user:${STAGING_DB_PASSWORD}@db:5432/shougaku_staging
      REDIS_URL: redis://redis:6379/0
      ENVIRONMENT: staging
      SECRET_KEY: ${STAGING_SECRET_KEY}
      FIREBASE_PROJECT_ID: shougaku-kore-doutoku-staging
    ports:
      - "8001:8000"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    volumes:
      - ./backend:/app

volumes:
  staging_db_data:
  staging_redis_data:
```

#### 1.2 環境変数ファイル作成
```bash
# .env.staging ファイル
cat > .env.staging << EOF
STAGING_DB_PASSWORD=secure_staging_password
STAGING_SECRET_KEY=staging_secret_key_$(openssl rand -hex 16)
FIREBASE_CREDENTIALS=/path/to/staging-firebase-key.json
EOF
```

#### 1.3 Staging 環境起動
```bash
# Staging 環境起動
docker-compose -f docker-compose.staging.yml up -d

# ログ確認
docker-compose -f docker-compose.staging.yml logs -f backend

# ヘルスチェック
curl http://localhost:8001/health
```

### 2. Staging API エンドポイント設定

#### 2.1 Flutter アプリの API設定
```dart
// lib/config/api_config.dart
class ApiConfig {
  static String get apiBaseUrl {
    if (kDebugMode && Platform.isIOS) {
      return 'http://localhost:8001'; // ローカル開発
    }
    
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (environment) {
      case 'staging':
        return 'https://api-staging.shougaku-kore-doutoku.jp';
      case 'production':
        return 'https://api.shougaku-kore-doutoku.jp';
      case 'development':
      default:
        return 'http://localhost:8001';
    }
  }
}
```

#### 2.2 Flavor 設定
```bash
# Staging flavor でビルド
flutter run --flavor staging -t lib/main_staging.dart

# または
flutter build apk --flavor staging -t lib/main_staging.dart
flutter build ipa --flavor staging -t lib/main_staging.dart
```

### 3. Staging データベーススキーマ

#### 3.1 初期化スクリプト
```bash
# backend/scripts/init_staging_db.sql
psql -h localhost -p 5433 -U staging_user -d shougaku_staging < scripts/init_staging_db.sql

# または Alembic で実行
cd backend
alembic upgrade head -c alembic_staging.ini
```

#### 3.2 テストデータ投入
```bash
# テストデータ投入
python scripts/populate_staging_data.py

# 確認
psql -h localhost -p 5433 -U staging_user -d shougaku_staging \
  -c "SELECT COUNT(*) as user_count FROM users;"
```

## テストユーザーセット

### テストユーザー一覧

| ユーザーID | メール | パスワード | 説明 | 購読状況 |
|-----------|--------|----------|------|---------|
| staging-parent-001 | parent@staging.test | StrongPass123! | トライアル中 | Free Trial |
| staging-parent-002 | parent-premium@staging.test | StrongPass123! | プレミアム購読 | Active |
| staging-parent-003 | parent-expired@staging.test | StrongPass123! | トライアル期限切れ | Expired |
| staging-child-001 | (N/A) | (N/A) | 子どもプロフィール1 | (Parent 001) |
| staging-child-002 | (N/A) | (N/A) | 子どもプロフィール2 | (Parent 002) |

### テストデータの初期化

```bash
# テストデータリセット
firebase firestore:delete test_data --confirm --token=<token> --project=shougaku-kore-doutoku-staging

# テストデータ投入
python scripts/setup_staging_test_data.py
```

## CI/CD との連携

### GitHub Actions for Staging

```yaml
name: Deploy to Staging

on:
  push:
    branches: [develop]
  workflow_dispatch:

jobs:
  staging-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'

      - name: Install dependencies
        run: flutter pub get

      - name: Run integration tests against staging
        env:
          FIREBASE_PROJECT_ID: shougaku-kore-doutoku-staging
          API_BASE_URL: https://api-staging.shougaku-kore-doutoku.jp
        run: |
          flutter test integration_test/ \
            --dart-define=ENVIRONMENT=staging \
            --verbose

      - name: Build staging APK
        run: |
          flutter build apk \
            --flavor staging \
            --dart-define=ENVIRONMENT=staging

      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          firebaseToken: ${{ secrets.FIREBASE_TOKEN }}
          appId: ${{ secrets.STAGING_APP_ID }}
          file: build/app/outputs/flutter-apk/app-staging-release.apk
          releaseNotesFile: CHANGELOG.md
          testGroups: staging-testers
```

## Staging テスト実行手順

### 1. 環境セットアップ

```bash
# 環境変数確認
echo $ENVIRONMENT
# 出力: staging

# Firebase プロジェクト確認
firebase projects:describe shougaku-kore-doutoku-staging

# API エンドポイント確認
curl https://api-staging.shougaku-kore-doutoku.jp/health
```

### 2. Integration テスト実行

```bash
# Staging Firebase に対して Integration テスト実行
flutter test \
  test/integration_tests/app_flow_test.dart \
  --dart-define=FIREBASE_PROJECT_ID=shougaku-kore-doutoku-staging \
  --verbose
```

### 3. Manual テスト

```bash
# Staging flavor でアプリ起動
flutter run --flavor staging

# テスト手順
# 1. アプリ起動 → ログイン画面表示確認
# 2. parent@staging.test でログイン
# 3. 子どもプロフィール表示確認
# 4. ストーリー読込確認
# 5. クイズ完了確認
# 6. レポート生成確認
```

### 4. パフォーマンステスト

```bash
# Staging 環境でのパフォーマンス測定
flutter test \
  test/performance_test.dart \
  --dart-define=ENVIRONMENT=staging \
  --release
```

## トラブルシューティング

### Firebase 接続エラー

```bash
# 認証情報確認
firebase login
firebase auth:import data/staging-users.json --hash-algo=scrypt

# Firestore 接続テスト
firebase firestore:list-collections
```

### バックエンド接続エラー

```bash
# Docker ログ確認
docker-compose -f docker-compose.staging.yml logs backend

# データベース接続確認
docker-compose -f docker-compose.staging.yml exec db \
  psql -U staging_user -d shougaku_staging -c "SELECT 1"
```

### テストユーザーログイン失敗

```bash
# ユーザー再登録
firebase auth:import data/staging-users.json \
  --hash-algo=scrypt \
  --project=shougaku-kore-doutoku-staging
```

## セキュリティに関する注意

- [ ] Staging 環境のインターネット公開を制限（VPN/IP 制限）
- [ ] テストクレジットカード情報は絶対に使用しない
- [ ] 本番データベースデータを Staging にコピーしない
- [ ] Staging API キーは安全に管理する
- [ ] 定期的にテストアカウントを削除・リセット

## まとめ

Staging 環境は本番環境と同等の設定を保ちながら、テストのための柔軟性を備えています。定期的にテストを実施し、本番リリースの品質を確保してください。
