# 本番デプロイ準備 完了サマリー

小学コレ！道徳アプリの本番環境デプロイ準備が完了しました。

## 実装内容

### 1. Firebase Security Rules デプロイ準備 ✓

**ファイル:**
- `/home/user/shinshin/firebase/firestore.rules` - Firestore セキュリティルール
  - ユーザー認証検証
  - ロールベースアクセス制御
  - COPPA準拠の子ども情報保護
  - 入力データ検証関数群

- `/home/user/shinshin/firebase/storage.rules` - Firebase Storage セキュリティルール
  - ファイルサイズ制限（5MB以下）
  - MIME タイプ検証
  - アップロード・ダウンロード権限管理

**スクリプト:**
- `/home/user/shinshin/scripts/deploy-firebase.sh` - Firebase デプロイメントスクリプト
  - `backup` - Firestore バックアップ実行
  - `restore [ファイル]` - バックアップから復元
  - `rules` - セキュリティルールをデプロイ
  - `deploy-all` - 完全デプロイ（バックアップ+ルール）

使用方法:
```bash
# ルールをデプロイ
./scripts/deploy-firebase.sh rules

# バックアップを実行
./scripts/deploy-firebase.sh backup

# 完全デプロイ
./scripts/deploy-firebase.sh deploy-all
```

### 2. 本番環境設定ファイル ✓

**ファイル:**
- `/home/user/shinshin/.env.production.template` - 本番環境設定テンプレート
  - データベース設定（PostgreSQL）
  - JWT 認証設定
  - Firebase設定
  - Google Cloud / Vertex AI設定
  - SendGrid メール設定
  - Apple App Store / Google Play設定
  - セキュリティ設定
  - ロギング設定

使用方法:
```bash
# テンプレートをコピーして本番設定を作成
cp .env.production.template .env.production

# 秘密情報を入力
# - DATABASE_URL
# - SECRET_KEY（最低64文字のランダム値）
# - FIREBASE_PROJECT_ID
# - FIREBASE_CREDENTIALS_PATH
# - その他のサービスの認証情報
```

**重要:** `.env.production` は Git にコミットしないこと

### 3. セキュリティ高リスク項目の修正実装 ✓

#### JWT Secret_key の環境変数化

**ファイル:** `/home/user/shinshin/backend/app/config.py`

修正内容:
- `secret_key` を `Settings` に環境変数から読み込み
- 本番環境で自動検証（64文字以上）
- デフォルト値がない（必須値化）

#### CORS 設定の修正

**ファイル:** `/home/user/shinshin/backend/app/main.py`

修正内容:
- `allow_origins` を `config.allowed_origins` から読み込み
- 開発環境: `*` (すべて許可)
- 本番環境: ホワイトリスト（`shougaku-kore.jp` のみ）
- メソッド制限: GET, POST, PUT, DELETE, OPTIONS のみ
- ヘッダー制限: Content-Type, Authorization のみ

#### Firebase Analytics の匿名化

**ファイル:** `/home/user/shinshin/backend/app/services/analytics_service.py`

実装内容:
- `child_id` を SHA256 ハッシュで匿名化
- 個人情報（名前、メール、生年月日など）の自動削除
- COPPA準拠の イベント検証
- 許可されたデータのみを Analytics に送信

使用例:
```python
from app.services.analytics_service import AnalyticsService

# 学習イベントをログに記録（child_id は匿名化される）
AnalyticsService.log_learning_event(
    child_id="child123",
    story_id="story456",
    choice_id="choice789",
    choice_sentiment="優しい",
    learning_score=85.0,
    session_duration_seconds=120
)
```

#### 親の同意記録の実装

**ファイル:** `/home/user/shinshin/backend/app/services/parental_consent_service.py`

実装内容:
- 親の明示的な同意を取得・記録
- 同意内容: データ処理、第三者共有、Analytics追跡
- 同意の有効期限管理（1年）
- 同意撤回機能
- Audit ログの記録（GDPR・COPPA対応）

使用例:
```python
from app.services.parental_consent_service import ParentalConsentService

# 親の同意を作成
consent = await ParentalConsentService.create_parental_consent(
    db=db,
    parent_uid="parent_uid_123",
    child_email="child@example.com",
    privacy_policy_version="1.0.0",
    consent_to={
        "dataProcessing": True,
        "thirdPartySharing": False,
        "analyticsTracking": False,
    }
)

# 同意を確認
has_consent = await ParentalConsentService.check_consent_for_operation(
    db=db,
    parent_uid="parent_uid_123",
    operation_type="analyticsTracking"
)
```

#### セキュリティミドルウェアの実装

**ファイル:** `/home/user/shinshin/backend/app/middleware/security.py`

実装内容:
- **SecurityHeadersMiddleware**: セキュリティヘッダー追加
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY
  - X-XSS-Protection
  - Strict-Transport-Security (HSTS)
  - Content-Security-Policy (CSP)
  - Referrer-Policy
  - Permissions-Policy

- **HTTPSRedirectMiddleware**: HTTP → HTTPS リダイレクト
- **RateLimitMiddleware**: DDoS 対策（1分あたりのリクエスト制限）
- **RequestLoggingMiddleware**: すべてのリクエストをログに記録

**ファイル:** `/home/user/shinshin/backend/app/main.py`

修正内容:
- セキュリティミドルウェアを登録
- 本番環境設定に基づいて自動有効化

### 4. バックエンド本番環境準備 ✓

**ファイル:** `/home/user/shinshin/backend/app/config.py`

追加設定:
- `gcp_project_id` - Vertex AI 用 GCP プロジェクトID
- `vertex_ai_location` - Vertex AI ロケーション（asia-northeast1）
- `gemini_model_id` - Gemini モデルID
- `sendgrid_api_key` - SendGrid API キー
- `apple_team_id`, `apple_key_id`, `apple_issuer_id` - Apple In-App Purchase 検証
- `google_play_credentials_path` - Google Play API 認証
- `log_level`, `log_file` - ロギング設定
- `force_https` - HTTPS 強制
- `security_headers_enabled` - セキュリティヘッダー有効化
- `rate_limit_per_minute` - レート制限

**ヘルスチェックエンドポイント:**
```
GET /api/health
```

レスポンス:
```json
{
  "status": "ok",
  "version": "1.0.0",
  "env": "production"
}
```

### 5. データベースマイグレーション ✓

**ドキュメント:** `/home/user/shinshin/docs/DATABASE_BACKUP_RESTORE.md`

内容:
- PostgreSQL フル・増分バックアップ手順
- AWS RDS スナップショット操作
- Firestore エクスポート・インポート手順
- Firebase Storage バックアップ・復元
- バックアップ自動化スクリプト
- リストア前チェックリスト
- 統合バックアップ・復元スクリプト
- トラブルシューティング

### 6. デプロイチェックリスト作成 ✓

**ドキュメント:** `/home/user/shinshin/docs/DEPLOYMENT_CHECKLIST.md`

内容:
- フェーズ 1: 事前準備（デプロイ1週間前）
  - インフラストラクチャ準備
  - セキュリティ設定
  - 監視・ログ設定

- フェーズ 2: 設定ファイル準備（デプロイ3日前）
  - 環境変数設定
  - 設定ファイル検証
  - 秘密情報の安全な保管

- フェーズ 3: コード・ルール確認（デプロイ2日前）
  - セキュリティルール検証
  - COPPA準拠確認
  - エンドポイント確認

- フェーズ 4: テスト実行（デプロイ1日前）
  - ユニットテスト
  - 統合テスト
  - セキュリティテスト
  - パフォーマンステスト

- フェーズ 5: デプロイ準備（デプロイ当日朝）
  - 最終確認
  - デプロイメント
  - デプロイ後確認

- フェーズ 6: 本番監視（デプロイ後）
  - 24時間監視
  - ロールバック計画

### 追加ドキュメント

**ファイル:** `/home/user/shinshin/docs/FIREBASE_DEPLOYMENT_GUIDE.md`

内容:
- Firebase プロジェクト設定
- セキュリティルール検証
- デプロイ手順
- 本番環境設定
- 監視・ロギング
- トラブルシューティング
- セキュリティベストプラクティス

---

## ファイル一覧

### 新規作成ファイル

| ファイル | 説明 |
|---------|------|
| `/scripts/deploy-firebase.sh` | Firebase デプロイメントスクリプト（実行可能） |
| `/.env.production.template` | 本番環境設定テンプレート |
| `/backend/app/middleware/security.py` | セキュリティミドルウェア |
| `/backend/app/middleware/__init__.py` | ミドルウェアパッケージ |
| `/backend/app/services/analytics_service.py` | 匿名化 Analytics サービス |
| `/backend/app/services/parental_consent_service.py` | 親同意管理サービス |
| `/docs/DEPLOYMENT_CHECKLIST.md` | デプロイメントチェックリスト |
| `/docs/DATABASE_BACKUP_RESTORE.md` | バックアップ・リストア手順書 |
| `/docs/FIREBASE_DEPLOYMENT_GUIDE.md` | Firebase デプロイメントガイド |
| `/docs/PRODUCTION_DEPLOYMENT_SUMMARY.md` | このファイル |

### 修正ファイル

| ファイル | 修正内容 |
|---------|---------|
| `/backend/app/config.py` | 本番環境設定追加、環境変数検証 |
| `/backend/app/main.py` | セキュリティミドルウェア登録、CORS修正 |

---

## 本番デプロイ前のチェック項目

### セキュリティチェック

- [ ] Secret_key が 64文字以上のランダムな値に設定されている
- [ ] DEBUG = false（本番環境）
- [ ] CORS allowed_origins が本番ドメインのみに設定されている
- [ ] Firebase Security Rules が適切に設定されている
- [ ] Storage Rules でファイルサイズ制限がある（5MB以下）
- [ ] 子どもの個人情報（生年月日など）を保存していない
- [ ] Analytics で child_id が匿名化されている
- [ ] 親の同意記録が保存されている

### インフラチェック

- [ ] PostgreSQL 本番データベースが準備されている
- [ ] Firebase プロジェクトが本番用に設定されている
- [ ] Google Cloud プロジェクトが有効化されている
- [ ] SSL/TLS 証明書が取得されている
- [ ] バックアップ・リカバリー計画が確認されている

### テストチェック

- [ ] ユニットテスト: 90% 以上のカバレッジ
- [ ] セキュリティテスト: OWASP Top 10 チェック完了
- [ ] 負荷テスト: 目標パフォーマンス達成
- [ ] Firestore Rules テスト: PASSED
- [ ] Storage Rules テスト: PASSED

### ドキュメントチェック

- [ ] DEPLOYMENT_CHECKLIST.md を確認
- [ ] DATABASE_BACKUP_RESTORE.md を確認
- [ ] FIREBASE_DEPLOYMENT_GUIDE.md を確認
- [ ] .env.production テンプレートから設定ファイルを作成
- [ ] リリースノートが完成している

---

## デプロイ実行手順（簡易版）

### 1. 事前準備（デプロイ当日朝）

```bash
# 最新コードをプル
git pull origin main

# バックアップ実行
./scripts/deploy-firebase.sh backup

# PostgreSQL バックアップ
pg_dump -U postgres -d shougaku | gzip > backup_$(date +%Y%m%d).sql.gz
```

### 2. 設定の確認

```bash
# 本番環境設定を確認
cat .env.production

# Firebase ルールの構文チェック
firebase rules:test firebase/firestore.rules
```

### 3. デプロイ実行

```bash
# Firebase ルールをデプロイ
./scripts/deploy-firebase.sh rules

# バックエンドをデプロイ
docker build -t shougaku-kore:1.0.0 .
docker push [registry]/shougaku-kore:1.0.0

# Kubernetes 更新
kubectl apply -f k8s/prod/
```

### 4. デプロイ後確認

```bash
# ヘルスチェック
curl https://api.shougaku-kore.jp/api/health

# ログ確認
kubectl logs -f deployment/shougaku-kore

# エラーモニタリング
# Sentry コンソール -> https://sentry.io/organizations/...
```

---

## COPPA（児童オンラインプライバシー保護法）準拠チェック

- [ ] 子どもから収集するデータ: 名前、学年のみ
- [ ] 生年月日を保存していない
- [ ] メールアドレスを保存していない
- [ ] 親の明示的な同意を取得している
- [ ] 同意内容を明確に表示している
- [ ] 同意撤回機能が実装されている
- [ ] Analytics で個人情報が送信されていない（child_id は匿名化）
- [ ] プライバシーポリシーが完備されている

---

## トラブルシューティングリソース

問題が発生した場合は、以下のドキュメントを参照:

1. **DATABASE_BACKUP_RESTORE.md** - DB 関連の問題
2. **FIREBASE_DEPLOYMENT_GUIDE.md** - Firebase 関連の問題
3. **DEPLOYMENT_CHECKLIST.md** - デプロイ全般の問題

主なエラーと解決方法:
- Firebase 認証エラー → FIREBASE_DEPLOYMENT_GUIDE.md の「トラブルシューティング」
- DB 接続エラー → DATABASE_BACKUP_RESTORE.md の「トラブルシューティング」
- ルールテスト失敗 → FIREBASE_DEPLOYMENT_GUIDE.md の「セキュリティルール検証」

---

## 次のステップ

### デプロイ実行後

1. **監視開始**
   - Sentry エラー監視
   - Cloud Logging を確認
   - Prometheus メトリクス監視

2. **24時間の緊密なモニタリング**
   - エラーレート監視（目標: 0.1% 以下）
   - レスポンスタイム監視
   - ユーザーフィードバック収集

3. **問題発見時の対応**
   - ログで原因を特定
   - 修正実装
   - テスト実施
   - デプロイ実行

4. **ホットフィックスが必要な場合**
   - バージョン: v1.0.1 などのマイナーバージョン
   - スピード優先、品質も重要
   - ロールバック計画を常に準備

---

## サポートリソース

- **Firebase ドキュメント**: https://firebase.google.com/docs
- **Firestore Security Rules**: https://firebase.google.com/docs/firestore/security
- **COPPA ガイド**: https://www.ftc.gov/business-guidance/privacy-security/coppa

---

## 最終確認

本番デプロイ準備は以下の項目がすべて完了しました：

✓ Firebase Security Rules デプロイ準備
✓ 本番環境設定ファイル
✓ セキュリティ高リスク項目の修正実装
✓ バックエンド本番環境準備
✓ データベースマイグレーション準備
✓ デプロイチェックリスト作成
✓ COPPA準拠確認

**本番デプロイの実施は、上記チェックリストをすべて確認・完了してから進めてください。**

---

最終更新: 2024-09-01
バージョン: 1.0.0
準備完了日: 2024-09-01
