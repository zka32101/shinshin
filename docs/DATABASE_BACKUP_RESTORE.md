# データベース バックアップ・リストア 手順書

小学コレ！道徳アプリの本番環境におけるデータベースの備品・復元手順を説明しています。

## 概要

### バックアップ対象

1. **PostgreSQL データベース**（ユーザー・子ども・進捗情報など）
2. **Firestore**（ストーリー・選択履歴・レポートなど）
3. **Firebase Storage**（プロフィール画像・ストーリー画像など）

### バックアップ戦略

| 対象 | 頻度 | 保持期間 | 目的 |
|------|------|----------|------|
| PostgreSQL フル | 日次 | 30日 | 定期バックアップ |
| PostgreSQL 増分 | 6時間ごと | 7日 | 高速復元用 |
| Firestore | 日次 | 90日 | コンテンツ保護 |
| Storage | 週次 | 30日 | ユーザーコンテンツ保護 |

---

## 第1部: PostgreSQL バックアップ・リストア

### 1.1 フル バックアップ（日次）

#### オンラインバックアップ

```bash
#!/bin/bash
# backup-postgresql-full.sh
# PostgreSQL フルバックアップスクリプト

BACKUP_DIR="/backups/postgresql"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/full_backup_${TIMESTAMP}.sql.gz"

# ディレクトリ確認
mkdir -p "$BACKUP_DIR"

# バックアップ実行
echo "PostgreSQL フルバックアップ開始: $(date)"
pg_dump \
  -h $DB_HOST \
  -U $DB_USER \
  -d shougaku \
  -F c \
  -b \
  --verbose \
  | gzip > "$BACKUP_FILE"

# ファイルサイズ確認
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "バックアップ完了: $SIZE"

# 古いバックアップを削除（30日より古い）
find "$BACKUP_DIR" -name "full_backup_*.sql.gz" -mtime +30 -delete

echo "バックアップファイル: $BACKUP_FILE"
```

#### スケジュール設定（cron）

```bash
# 毎日午前2時にバックアップ実行
0 2 * * * /scripts/backup-postgresql-full.sh >> /var/log/postgresql_backup.log 2>&1

# 毎日午前3時にS3にアップロード
0 3 * * * aws s3 cp /backups/postgresql/full_backup_*.sql.gz s3://my-backup-bucket/postgresql/
```

#### AWS RDS を使用している場合

```bash
# RDS スナップショット作成
aws rds create-db-snapshot \
  --db-instance-identifier shougaku-kore-db-prod \
  --db-snapshot-identifier shougaku-kore-snapshot-$(date +%Y%m%d-%H%M%S)

# 既存スナップショットを確認
aws rds describe-db-snapshots \
  --db-instance-identifier shougaku-kore-db-prod \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,SnapshotType]' \
  --output table
```

### 1.2 増分 バックアップ（6時間ごと）

```bash
#!/bin/bash
# backup-postgresql-incremental.sh
# WAL（Write-Ahead Logging）を使用した増分バックアップ

BACKUP_DIR="/backups/postgresql/incremental"
mkdir -p "$BACKUP_DIR"

# WAL ファイルのアーカイブ（PostgreSQL の archiver で自動実行）
# postgresql.conf に以下を設定:
# wal_level = replica
# archive_mode = on
# archive_command = 'cp %p /backups/postgresql/wal/%f'
```

### 1.3 PostgreSQL 復元

#### 環境準備

```bash
# 復元対象のデータベースを確認
psql -U postgres -h $DB_HOST -l

# 既存データベースを削除（本当に必要な場合のみ）
psql -U postgres -h $DB_HOST -d postgres -c "DROP DATABASE IF EXISTS shougaku;"

# 新規データベース作成
psql -U postgres -h $DB_HOST -d postgres -c "CREATE DATABASE shougaku;"
```

#### フルバックアップから復元

```bash
#!/bin/bash
# restore-postgresql-full.sh
# PostgreSQL フルバックアップから復元

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
  echo "使用方法: $0 <backup_file>"
  echo "例: $0 /backups/postgresql/full_backup_20240901_020000.sql.gz"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "エラー: バックアップファイルが見つかりません: $BACKUP_FILE"
  exit 1
fi

echo "復元開始: $(date)"
echo "ファイル: $BACKUP_FILE"
echo ""
echo "警告: 既存データは上書きされます"
read -p "続行しますか？ (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "キャンセルしました"
  exit 0
fi

# データベース削除・作成
psql -U postgres -h $DB_HOST -d postgres << EOF
DROP DATABASE IF EXISTS shougaku;
CREATE DATABASE shougaku;
EOF

# 復元実行
zcat "$BACKUP_FILE" | pg_restore \
  -h $DB_HOST \
  -U $DB_USER \
  -d shougaku \
  -v

echo ""
echo "復元完了: $(date)"

# 復元後の確認
echo ""
echo "=== 復元確認 ==="
psql -U postgres -h $DB_HOST -d shougaku << EOF
SELECT COUNT(*) as user_count FROM users;
SELECT COUNT(*) as children_count FROM children;
SELECT COUNT(*) as learning_record_count FROM learning_records;
EOF
```

#### AWS RDS スナップショットから復元

```bash
# スナップショットから新しいインスタンスを作成
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier shougaku-kore-db-prod-restored \
  --db-snapshot-identifier shougaku-kore-snapshot-20240901-020000 \
  --db-instance-class db.t3.small

# ステータス確認
aws rds describe-db-instances \
  --db-instance-identifier shougaku-kore-db-prod-restored \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \
  --output table
```

### 1.4 バックアップ検証

```bash
#!/bin/bash
# verify-postgresql-backup.sh
# バックアップファイルの整合性を検証

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
  echo "使用方法: $0 <backup_file>"
  exit 1
fi

echo "バックアップ検証: $BACKUP_FILE"

# ファイルの存在確認
if [ ! -f "$BACKUP_FILE" ]; then
  echo "エラー: ファイルが見つかりません"
  exit 1
fi

# ファイルサイズ確認
SIZE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null || stat -c%s "$BACKUP_FILE")
echo "ファイルサイズ: $SIZE bytes"

if [ $SIZE -lt 1000000 ]; then
  echo "警告: ファイルサイズが異常に小さい可能性があります"
fi

# gzip ファイルの整合性を検証
gzip -t "$BACKUP_FILE"
if [ $? -eq 0 ]; then
  echo "✓ gzip ファイルは正常です"
else
  echo "✗ gzip ファイルが破損しています"
  exit 1
fi

echo "検証完了"
```

---

## 第2部: Firestore バックアップ・リストア

### 2.1 Firestore エクスポート（GCS）

#### 定期的なエクスポート

```bash
#!/bin/bash
# backup-firestore.sh
# Firestore をGCSにエクスポート

PROJECT_ID="your-firebase-project"
BUCKET="gs://${PROJECT_ID}-firestore-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EXPORT_PATH="${BUCKET}/firestore_export_${TIMESTAMP}"

echo "Firestore エクスポート開始: $(date)"

# エクスポート実行
gcloud firestore export "$EXPORT_PATH" \
  --project="$PROJECT_ID" \
  --async

echo "エクスポート開始: $EXPORT_PATH"
echo "ステータス確認:"
echo "  gcloud firestore operations list --project=$PROJECT_ID"
```

#### Cloud Scheduler で定期実行

```bash
# Cloud Scheduler ジョブを作成
gcloud scheduler jobs create app-engine backup-firestore \
  --schedule "0 2 * * *" \
  --http-method POST \
  --uri "https://region-project.cloudfunctions.net/backup-firestore" \
  --message-body '{}'

# または Cloud Functions で直接実行
cat > backup-firestore.py << 'EOF'
from google.cloud import firestore
from google.cloud import storage
import functions_framework
from datetime import datetime

@functions_framework.http
def backup_firestore(request):
    project_id = "your-firebase-project"
    client = firestore.Client(project=project_id)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    export_path = f"gs://{project_id}-firestore-backups/firestore_export_{timestamp}"
    
    # エクスポート実行
    operation = client.export_documents(
        collection_ids=[],  # すべてのコレクション
        output_uri_prefix=export_path
    )
    
    return f"Backup started: {export_path}\nOperation: {operation.name}"
EOF
```

### 2.2 Firestore インポート（復元）

#### 本番環境への復元（注意深く実行）

```bash
#!/bin/bash
# restore-firestore.sh
# Firestore をバックアップからインポート

PROJECT_ID="your-firebase-project"
IMPORT_PATH=$1

if [ -z "$IMPORT_PATH" ]; then
  echo "使用方法: $0 <import_path>"
  echo "例: $0 gs://project-backups/firestore_export_20240901_020000"
  exit 1
fi

echo "警告: 本番 Firestore に上書きします"
echo "インポートパス: $IMPORT_PATH"
echo ""
read -p "本当にインポートしますか？ (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "キャンセルしました"
  exit 0
fi

# バックアップ作成
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="gs://${PROJECT_ID}-firestore-backups/backup_before_restore_${BACKUP_TIMESTAMP}"

echo "事前バックアップ作成: $BACKUP_PATH"
gcloud firestore export "$BACKUP_PATH" \
  --project="$PROJECT_ID" \
  --async

# インポート実行
echo "インポート実行..."
gcloud firestore import "$IMPORT_PATH" \
  --project="$PROJECT_ID" \
  --async

echo "インポート開始"
echo "ステータス確認:"
echo "  gcloud firestore operations list --project=$PROJECT_ID"
```

### 2.3 Firestore バックアップ検証

```bash
#!/bin/bash
# verify-firestore-backup.sh
# Firestore バックアップの整合性を確認

PROJECT_ID="your-firebase-project"
EXPORT_PATH=$1

if [ -z "$EXPORT_PATH" ]; then
  echo "使用方法: $0 <export_path>"
  exit 1
fi

echo "Firestore バックアップ検証: $EXPORT_PATH"

# GCS ファイル確認
echo "GCS ファイル確認..."
gsutil ls "$EXPORT_PATH/"

# メタデータファイル確認
if gsutil -q stat "$EXPORT_PATH/firestore_export.json"; then
  echo "✓ メタデータファイル: OK"
else
  echo "✗ メタデータファイル: 見つかりません"
  exit 1
fi

# Firestore 統計情報をダウンロード
gsutil cp "$EXPORT_PATH/firestore_export.json" - | jq .

echo "検証完了"
```

---

## 第3部: Firebase Storage バックアップ

### 3.1 Storage のバックアップ

```bash
#!/bin/bash
# backup-storage.sh
# Firebase Storage を GCS にバックアップ

PROJECT_ID="your-firebase-project"
BUCKET="${PROJECT_ID}.appspot.com"
BACKUP_BUCKET="${PROJECT_ID}-storage-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PREFIX="storage_backup_${TIMESTAMP}"

echo "Firebase Storage バックアップ開始"

# プロフィール画像
gsutil -m cp -r \
  "gs://${BUCKET}/profile_images/*" \
  "gs://${BACKUP_BUCKET}/${BACKUP_PREFIX}/profile_images/"

# ストーリー画像
gsutil -m cp -r \
  "gs://${BUCKET}/story_images/*" \
  "gs://${BACKUP_BUCKET}/${BACKUP_PREFIX}/story_images/"

# バッジ画像
gsutil -m cp -r \
  "gs://${BUCKET}/badges/*" \
  "gs://${BACKUP_BUCKET}/${BACKUP_PREFIX}/badges/"

echo "バックアップ完了: gs://${BACKUP_BUCKET}/${BACKUP_PREFIX}/"
```

### 3.2 Storage の復元

```bash
#!/bin/bash
# restore-storage.sh
# Firebase Storage をバックアップから復元

PROJECT_ID="your-firebase-project"
BUCKET="${PROJECT_ID}.appspot.com"
BACKUP_BUCKET="${PROJECT_ID}-storage-backups"
BACKUP_PREFIX=$1

if [ -z "$BACKUP_PREFIX" ]; then
  echo "使用方法: $0 <backup_prefix>"
  echo "例: $0 storage_backup_20240901_020000"
  exit 1
fi

echo "警告: Firebase Storage に上書きします"
read -p "続行しますか？ (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  exit 0
fi

# 復元実行
gsutil -m cp -r \
  "gs://${BACKUP_BUCKET}/${BACKUP_PREFIX}/*" \
  "gs://${BUCKET}/"

echo "復元完了"
```

---

## 第4部: 統合バックアップ・復元スクリプト

### 4.1 全体バックアップ

```bash
#!/bin/bash
# backup-all.sh
# PostgreSQL + Firestore + Storage の全体バックアップ

set -e  # エラーで停止

BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_SESSION="${BACKUP_DIR}/session_${TIMESTAMP}"

mkdir -p "$BACKUP_SESSION"

echo "========================================="
echo "全体バックアップ開始: $(date)"
echo "セッション: $BACKUP_SESSION"
echo "========================================="

# PostgreSQL バックアップ
echo ""
echo "1. PostgreSQL バックアップ..."
pg_dump \
  -h $DB_HOST \
  -U $DB_USER \
  -d shougaku \
  -F c \
  | gzip > "${BACKUP_SESSION}/postgresql.sql.gz"
echo "✓ PostgreSQL バックアップ完了"

# Firestore エクスポート
echo ""
echo "2. Firestore バックアップ..."
gcloud firestore export "${BACKUP_SESSION}/firestore" \
  --project="$FIREBASE_PROJECT_ID" \
  --async
echo "✓ Firestore バックアップ開始"

# Storage バックアップ
echo ""
echo "3. Firebase Storage バックアップ..."
gsutil -m cp -r \
  "gs://${FIREBASE_PROJECT_ID}.appspot.com/profile_images/" \
  "${BACKUP_SESSION}/profile_images/" || true
gsutil -m cp -r \
  "gs://${FIREBASE_PROJECT_ID}.appspot.com/story_images/" \
  "${BACKUP_SESSION}/story_images/" || true
echo "✓ Firebase Storage バックアップ完了"

# バックアップ情報をログに記録
cat > "${BACKUP_SESSION}/backup_info.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "database": "PostgreSQL",
  "firebase_project": "$FIREBASE_PROJECT_ID",
  "backup_location": "$BACKUP_SESSION",
  "components": [
    "postgresql",
    "firestore",
    "storage"
  ]
}
EOF

echo ""
echo "========================================="
echo "全体バックアップ完了"
echo "バックアップ場所: $BACKUP_SESSION"
echo "========================================="
```

### 4.2 復元前チェックリスト

```bash
# restore-pre-check.sh
# 復元実行前のチェック

echo "復元前チェック リスト"
echo ""

# 1. バックアップの存在確認
echo "1. バックアップ存在確認"
if [ -f "$BACKUP_FILE" ]; then
  echo "  ✓ バックアップファイルが存在"
else
  echo "  ✗ バックアップファイルが見つかりません"
  exit 1
fi

# 2. ディスク容量確認
echo "2. ディスク容量確認"
REQUIRED_SPACE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null || stat -c%s "$BACKUP_FILE")
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
if [ $AVAILABLE_SPACE -gt $((REQUIRED_SPACE * 3)) ]; then
  echo "  ✓ ディスク容量: 十分"
else
  echo "  ✗ ディスク容量: 不足"
  exit 1
fi

# 3. データベース接続確認
echo "3. データベース接続確認"
if psql -U postgres -h $DB_HOST -d postgres -c "SELECT 1" > /dev/null; then
  echo "  ✓ データベース接続: OK"
else
  echo "  ✗ データベース接続: NG"
  exit 1
fi

# 4. 既存データ確認
echo "4. 既存データ確認"
USER_COUNT=$(psql -U postgres -h $DB_HOST -d shougaku -t -c "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
echo "  既存ユーザー数: $USER_COUNT"

echo ""
echo "すべてのチェックが完了しました"
```

---

## 第5部: ベストプラクティス

### 5.1 バックアップスケジュール

| 時刻 | 処理 | 保持期間 |
|------|------|----------|
| 02:00 | PostgreSQL フルバックアップ | 30日 |
| 03:00 | Firestore エクスポート | 90日 |
| 04:00 | Firebase Storage バックアップ | 30日 |
| 04:30 | S3/GCS に複製 | 90日 |

### 5.2 バックアップの自動テスト

```bash
#!/bin/bash
# test-backup-restore.sh
# 月1回、バックアップからの復元をテスト

TIMESTAMP=$(date +%Y%m%d)
TEST_BACKUP="/backups/test_restore_${TIMESTAMP}.sql.gz"

# テスト用データベース作成
psql -U postgres -h $DB_HOST -d postgres -c "CREATE DATABASE shougaku_test;"

# 本番バックアップから復元
zcat /backups/postgresql/full_backup_recent.sql.gz | \
  pg_restore -U postgres -h $DB_HOST -d shougaku_test -v

# テスト用クエリ実行
psql -U postgres -h $DB_HOST -d shougaku_test << EOF
  SELECT COUNT(*) as users FROM users;
  SELECT COUNT(*) as children FROM children;
  SELECT COUNT(*) as records FROM learning_records;
EOF

# テスト用データベース削除
psql -U postgres -h $DB_HOST -d postgres -c "DROP DATABASE shougaku_test;"

echo "バックアップリストアテスト: 完了"
```

### 5.3 バージョン管理

```json
{
  "backup_version": "1.0.0",
  "created": "2024-09-01T00:00:00Z",
  "components": {
    "postgresql": {
      "version": "14.5",
      "size_gb": 2.5
    },
    "firestore": {
      "collections": 12,
      "documents": 50000
    },
    "storage": {
      "files": 1200,
      "size_gb": 5.0
    }
  }
}
```

---

## トラブルシューティング

### PostgreSQL 復元エラー

**エラー**: `permission denied for schema public`

```bash
# 解決: スキーマのオーナーシップを修正
psql -U postgres -h $DB_HOST -d shougaku << EOF
  REASSIGN OWNED BY postgres TO postgres;
  GRANT ALL PRIVILEGES ON SCHEMA public TO postgres;
EOF
```

### Firestore インポート失敗

**エラー**: `Invalid JSON in firestore.json`

```bash
# 解決: メタデータファイルを確認
gsutil cp gs://bucket/firestore_export.json - | jq .
```

### Storage 復元容量超過

**エラー**: `Quota exceeded`

```bash
# 解決: 古いファイルを削除
gsutil -m rm -r gs://bucket/old_files/
```

---

最終更新: 2024-09-01
バージョン: 1.0.0
