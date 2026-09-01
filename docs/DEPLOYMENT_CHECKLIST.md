# 本番デプロイメント チェックリスト

小学コレ！道徳アプリの本番環境へのデプロイ前に確認するべき項目をリストアップしています。

## フェーズ 1: 事前準備（デプロイ1週間前）

### 1.1 インフラストラクチャ準備

- [ ] Firebase プロジェクトを本番用に作成
  - [ ] Firebase コンソールで新規プロジェクトを作成
  - [ ] Firestore データベースを有効化（本番モード）
  - [ ] Firebase Storage を有効化
  - [ ] Firebase Authentication を有効化
  - [ ] Backup location を設定

- [ ] Google Cloud Project を準備
  - [ ] Project ID を確認
  - [ ] Vertex AI API を有効化
  - [ ] Cloud Scheduler を有効化

- [ ] データベースサーバーを準備（PostgreSQL）
  - [ ] 本番 RDS インスタンスを作成
  - [ ] バックアップ設定を確認
  - [ ] 複製（レプリケーション）設定を確認
  - [ ] スナップショット設定を確認

- [ ] SSL/TLS 証明書を取得
  - [ ] 本番ドメイン用の証明書を取得
  - [ ] Certificate Authority を確認
  - [ ] 有効期限を確認（3年以上を推奨）

### 1.2 セキュリティ設定

- [ ] OAuth 2.0 認証情報を作成
  - [ ] Google OAuth 2.0 credentials を作成
  - [ ] Apple Sign In 認証情報を取得
  - [ ] Redirect URIs を設定

- [ ] サービスアカウントを作成
  - [ ] Firebase Admin SDK 用サービスアカウント
  - [ ] Google Cloud API アクセス用サービスアカウント
  - [ ] Google Play API 用サービスアカウント

- [ ] 秘密管理サービスを設定
  - [ ] AWS Secrets Manager / GCP Secret Manager を有効化
  - [ ] 秘密ローテーションポリシーを設定

- [ ] VPN / ネットワークセキュリティ
  - [ ] VPC を構成
  - [ ] Firewall rules を設定
  - [ ] WAF (Web Application Firewall) を有効化

### 1.3 監視・ログ設定

- [ ] Sentry 本番アカウントを作成
  - [ ] Organization を作成
  - [ ] Project を作成
  - [ ] DSN を取得

- [ ] ロギングシステムを設定
  - [ ] Cloud Logging を有効化
  - [ ] ログ保持期間を設定（推奨: 90日以上）
  - [ ] ログアラートを設定

- [ ] 監視ダッシュボードを準備
  - [ ] Prometheus / Grafana をセットアップ
  - [ ] メトリクス収集を確認

---

## フェーズ 2: 設定ファイル準備（デプロイ3日前）

### 2.1 環境変数設定

- [ ] `.env.production` を作成
  - [ ] テンプレートから `.env.production` をコピー
  - [ ] DATABASE_URL を本番RDSに更新
  - [ ] SECRET_KEY を生成（最低64文字）
    ```bash
    openssl rand -hex 32
    ```
  - [ ] FIREBASE_PROJECT_ID を設定
  - [ ] FIREBASE_CREDENTIALS_PATH を設定
  - [ ] SENTRY_DSN を設定

- [ ] ファイルパーミッションを設定
  - [ ] `.env.production` を 600 (所有者のみ読み取り可能)
  - [ ] Firebase サービスアカウント JSON を 400

### 2.2 設定ファイル検証

- [ ] `lib/config/firebase_config.dart` を確認
  - [ ] Firebase Project ID が正しい
  - [ ] App ID が正しい
  - [ ] Database URL が正しい

- [ ] `firebase.json` を確認
  - [ ] プロジェクト ID が正しい
  - [ ] デプロイ対象リソースが正しい

- [ ] `docker-compose.prod.yml` を確認
  - [ ] ポート設定が正しい
  - [ ] リソース制限が設定されている
  - [ ] ヘルスチェック設定がある

### 2.3 秘密情報の安全な保管

- [ ] すべての秘密情報をシークレット管理に登録
  - [ ] AWS Secrets Manager / GCP Secret Manager に登録
  - [ ] ローテーションポリシーを設定
  - [ ] アクセス権限を制限

- [ ] SSH キーの生成
  - [ ] デプロイ用 SSH キーを生成
  - [ ] 本番サーバーに登録
  - [ ] 開発環境から削除

---

## フェーズ 3: コード・ルール確認（デプロイ2日前）

### 3.1 セキュリティルール検証

- [ ] Firestore Security Rules を確認
  - [ ] `firebase/firestore.rules` を確認
  - [ ] アクセス制御が正しいか確認
  - [ ] 管理者権限の制限を確認
  - [ ] ルールテストを実行
    ```bash
    firebase rules:test firebase/firestore.rules
    ```

- [ ] Storage Security Rules を確認
  - [ ] `firebase/storage.rules` を確認
  - [ ] ファイルサイズ制限が設定されているか
  - [ ] MIME タイプチェックがあるか
  - [ ] ルールテストを実行

- [ ] API エンドポイントのセキュリティを確認
  - [ ] CORS 設定が正しいか（本番ドメインのみ）
  - [ ] 認証チェックが有効か
  - [ ] レート制限が有効か
  - [ ] セキュリティヘッダーが設定されているか

### 3.2 COPPA準拠確認

- [ ] 個人情報の最小化を確認
  - [ ] 子どもから収集するデータ: 名前、学年のみか確認
  - [ ] 生年月日を保存していないか確認
  - [ ] メールアドレスを保存していないか確認

- [ ] 親の同意メカニズム
  - [ ] 同意画面が表示されるか確認
  - [ ] 同意内容が明確か確認
  - [ ] 同意撤回機能が実装されているか確認
  - [ ] 同意記録が保存されているか確認

- [ ] Analytics の匿名化
  - [ ] Analytics Service で child_id が匿名化されているか確認
  - [ ] 個人情報がログに含まれていないか確認
  - [ ] Analytics に個人情報が送信されていないか確認

### 3.3 エンドポイント確認

- [ ] ヘルスチェックエンドポイント
  - [ ] GET `/api/health` が動作するか
  - [ ] 正しい status を返しているか
  - [ ] `curl http://localhost:8000/api/health`

- [ ] 認証エンドポイント
  - [ ] POST `/api/v1/auth/register` が動作するか
  - [ ] POST `/api/v1/auth/login` が動作するか
  - [ ] JWT トークンが発行されるか確認

- [ ] 課金関連エンドポイント
  - [ ] POST `/api/v1/subscriptions/verify-receipt-apple`
  - [ ] POST `/api/v1/subscriptions/verify-receipt-google`

---

## フェーズ 4: テスト実行（デプロイ1日前）

### 4.1 ユニットテスト

- [ ] バックエンドテストを実行
  ```bash
  cd backend
  python -m pytest tests/ -v --cov
  ```

- [ ] テストカバレッジを確認
  - [ ] 主要機能: 90% 以上
  - [ ] セキュリティ関連: 100%

### 4.2 統合テスト

- [ ] ログイン フロー
  - [ ] メール登録 → メール確認 → ログイン
  - [ ] 子どもプロフィール作成
  - [ ] ストーリー学習開始

- [ ] 支払いフロー
  - [ ] Apple In-App Purchase
  - [ ] Google Play Billing

- [ ] レポート生成
  - [ ] 月次レポートが生成されるか
  - [ ] データが正しいか

### 4.3 セキュリティテスト

- [ ] OWASP Top 10 チェック
  - [ ] SQL Injection テスト
  - [ ] XSS テスト
  - [ ] CSRF Protection テスト
  - [ ] 認証・認可テスト

- [ ] 負荷テスト
  ```bash
  # Apache Bench または locust で負荷テスト
  ab -n 1000 -c 100 http://localhost:8000/api/health
  ```

### 4.4 パフォーマンステスト

- [ ] アプリ起動時間
  - [ ] 目標: 3秒以内

- [ ] ストーリー読み込み
  - [ ] 目標: 1秒以内

- [ ] レポート読み込み
  - [ ] 目標: 2秒以内

---

## フェーズ 5: デプロイ準備（デプロイ当日朝）

### 5.1 最終確認

- [ ] データベースバックアップを実行
  ```bash
  # PostgreSQL バックアップ
  pg_dump -U postgres shougaku > backup_prod_$(date +%Y%m%d).sql
  
  # Firestore エクスポート
  gcloud firestore export gs://bucket-name/firestore_backup_$(date +%Y%m%d)
  ```

- [ ] バックアップファイルを確認
  - [ ] ファイルサイズが正常か
  - [ ] ファイルが完全に作成されているか
  - [ ] リストア手順をドライラン

- [ ] Git コミットを確認
  - [ ] すべての変更がコミットされているか
  - [ ] Tags を作成
    ```bash
    git tag -a v1.0.0 -m "Production Release 1.0.0"
    git push origin v1.0.0
    ```

- [ ] リリースノートを確認
  - [ ] すべての機能が記載されているか
  - [ ] セキュリティ修正が記載されているか
  - [ ] 既知の問題が記載されているか

### 5.2 デプロイメント

- [ ] Firebase ルールをデプロイ
  ```bash
  ./scripts/deploy-firebase.sh rules
  ```

- [ ] バックエンドをデプロイ
  ```bash
  # Docker イメージをビルド
  docker build -t shougaku-kore:1.0.0 .
  
  # イメージをレジストリにプッシュ
  docker push [registry]/shougaku-kore:1.0.0
  
  # Kubernetes で更新
  kubectl apply -f k8s/prod/
  ```

- [ ] Flutter アプリをビルド
  ```bash
  flutter build apk --release
  flutter build ios --release
  ```

- [ ] アプリストアに申請
  - [ ] Google Play Console に APK をアップロード
  - [ ] App Store Connect に IPA をアップロード
  - [ ] リリースノートを入力
  - [ ] テスターアカウントで確認

### 5.3 デプロイ後確認

- [ ] ヘルスチェック
  ```bash
  curl https://api.shougaku-kore.jp/api/health
  ```

- [ ] ログを確認
  ```bash
  # ログを確認
  kubectl logs -f deployment/shougaku-kore
  
  # エラーが無いか確認
  grep ERROR /var/log/shougaku-kore/app.log
  ```

- [ ] 本番データベースが動作しているか
  - [ ] コネクションプール接続数を確認
  - [ ] クエリパフォーマンスを確認

- [ ] Sentry エラーを確認
  - [ ] 予期しないエラーが無いか確認

- [ ] 監視ダッシュボードを確認
  - [ ] CPU 使用率が正常か
  - [ ] メモリ使用率が正常か
  - [ ] レスポンスタイムが正常か

---

## フェーズ 6: 本番監視（デプロイ後）

### 6.1 24時間監視

- [ ] エラーレート
  - [ ] 目標: 0.1% 以下

- [ ] レスポンスタイム
  - [ ] P95: 500ms 以下
  - [ ] P99: 1000ms 以下

- [ ] ユーザーレポート
  - [ ] 新しいバグレポートが無いか
  - [ ] パフォーマンス問題が無いか

### 6.2 ロールバック計画

デプロイ直後に重大な問題が発見された場合:

1. **第1段階**: 緊急通知
   ```bash
   # Slack 通知
   # 問題内容を記載
   ```

2. **第2段階**: ロールバック決定
   - [ ] 影響範囲を評価
   - [ ] 修正時間を推定
   - [ ] ロールバック vs 修正を判断

3. **第3段階**: ロールバック実行
   ```bash
   # 前のバージョンに戻す
   kubectl rollout undo deployment/shougaku-kore
   
   # または Firebase ルールを戻す
   ./scripts/deploy-firebase.sh restore backups/firestore_backup_20240901_120000.json
   ```

---

## 注意事項

### セキュリティ
- すべての秘密情報は **git にコミットしないこと**
- 本番環境では **デバッグモードを無効化** すること
- **CORS設定** を本番ドメインのみに制限
- **レート制限** を有効化

### パフォーマンス
- **データベース接続プール** の設定を最適化
- **キャッシング戦略** を実装（Redis など）
- **CDN** でスタティックコンテンツを配信

### 運用
- **自動化されたバックアップ** をスケジュール
- **定期的なセキュリティ監査** を実施
- **ログローテーション** を設定
- **インシデント対応計画** を準備

---

## トラブルシューティング

### よくある問題と解決方法

#### 1. Firebase 認証エラー
```
Error: Authentication is required to access Firestore
```
**解決**: Firebase credentials path が正しいか確認
```bash
cat $FIREBASE_CREDENTIALS_PATH
```

#### 2. データベース接続エラー
```
Error: Connection refused to PostgreSQL server
```
**解決**: DATABASE_URL が正しいか、サーバーが起動しているか確認
```bash
psql -U postgres -h [host] -d shougaku -c "SELECT 1"
```

#### 3. CORS エラー
```
Error: Access to XMLHttpRequest blocked by CORS policy
```
**解決**: ALLOWED_ORIGINS に本番ドメインが含まれているか確認
```bash
echo $ALLOWED_ORIGINS
```

---

## チェックリスト完了後

- [ ] すべてのチェック項目が完了
- [ ] すべてのテストが PASS
- [ ] セキュリティレビューが完了
- [ ] ステークホルダーから承認を得た
- [ ] **デプロイの実施**
- [ ] **デプロイ後の監視を開始**

---

最終更新: 2024-09-01
バージョン: 1.0.0
