# バックアップ・ロールバック確認

**プロジェクト**: 小学コレ！道徳  
**リリース版**: 1.0.0  
**実施日**: _______________  
**実施者**: _______________ （署名: _______________）  

---

## 概要

本番リリース前にバックアップ取得とロールバック手順を検証します。

---

## 1. バックアップ手順テスト

### 1.1 Firebase Realtime Database バックアップ

**手順**:
```bash
# コマンドラインで Firebase バックアップ
firebase database:get / > backup_rtdb_$(date +%Y%m%d_%H%M%S).json
```

**テスト結果**:

| 項目 | 状態 | 実行日時 | 備考 |
|-----|------|--------|------|
| バックアップコマンド実行 | [ ] | _______________ | |
| ファイルサイズ確認 | [ ] | _______________ | ___MB |
| ファイル整合性確認 | [ ] | _______________ | JSON パース OK |
| バックアップ転送完了 | [ ] | _______________ | Google Cloud Storage |

### 1.2 Firestore バックアップ

**手順**:
```bash
# Firestore エクスポート
gcloud firestore export gs://backup-bucket/firestore_backup_$(date +%Y%m%d)
```

**テスト結果**:

| 項目 | 状態 | 実行日時 | ファイルパス |
|-----|------|--------|---------|
| エクスポート実行 | [ ] | _______________ | |
| メタデータ確認 | [ ] | _______________ | |
| ストレージ保存確認 | [ ] | _______________ | |

### 1.3 ユーザーデータベース（PostgreSQL）バックアップ

**手順**:
```bash
# PostgreSQL ダンプ
pg_dump -U postgres shougaku_kore_doutoku \
  > backup_postgres_$(date +%Y%m%d_%H%M%S).sql

# 圧縮・転送
gzip backup_postgres_*.sql
gsutil cp backup_postgres_*.sql.gz gs://backup-bucket/
```

**テスト結果**:

| 項目 | 状態 | 実行日時 | ファイルサイズ |
|-----|------|--------|-----------|
| ダンプコマンド実行 | [ ] | _______________ | |
| ファイル圧縮 | [ ] | _______________ | ___MB |
| クラウド転送 | [ ] | _______________ | |
| 整合性検証 | [ ] | _______________ | |

### 1.4 ストレージ（App Engine）バックアップ

**手順**:
```bash
# アプリケーションファイルバックアップ
gsutil -m cp -r gs://shougaku-kore-prod/app/* \
  gs://backup-bucket/app_backup_$(date +%Y%m%d)/
```

**テスト結果**:

| 項目 | 状態 | 実行日時 |
|-----|------|--------|
| ファイル一覧取得 | [ ] | _______________ |
| バックアップコピー | [ ] | _______________ |
| 整合性確認 | [ ] | _______________ |

---

## 2. ロールバック手順テスト

### 2.1 Firebase Realtime Database ロールバック

**前提条件**: テスト環境で実施、本番リリース前に実行

**手順**:
```bash
# 1. バックアップデータ確認
firebase database:get / > current_state.json

# 2. バックアップからリストア
firebase database:set / < backup_rtdb_YYYYMMDD_HHMMSS.json

# 3. データ整合性確認
firebase database:get / > restored_state.json
diff current_state.json restored_state.json
```

**テスト結果**:

| ステップ | 状態 | 実行日時 | 復旧時間 |
|---------|------|--------|--------|
| バックアップデータ確認 | [ ] | _______________ | ___秒 |
| リストア実行 | [ ] | _______________ | ___秒 |
| 整合性確認 | [ ] | _______________ | ___秒 |
| **合計復旧時間** | [ ] | _______________ | **___秒** |

### 2.2 Firestore ロールバック

**手順**:
```bash
# 1. エクスポート一覧確認
gcloud firestore backups list

# 2. バックアップからリストア
gcloud firestore restore gs://backup-bucket/firestore_backup_YYYYMMDD/

# 3. ドキュメント数確認
# Firestore コンソールで doc count 確認
```

**テスト結果**:

| ステップ | 状態 | 実行日時 | 復旧時間 |
|---------|------|--------|--------|
| バックアップリスト確認 | [ ] | _______________ | ___秒 |
| リストア実行 | [ ] | _______________ | ___分 |
| データ整合性確認 | [ ] | _______________ | ___秒 |
| **合計復旧時間** | [ ] | _______________ | **___分** |

### 2.3 PostgreSQL ロールバック

**手順**:
```bash
# 1. 現在のバックアップ取得
pg_dump -U postgres shougaku_kore_doutoku > pre_rollback.sql

# 2. データベース復元
gunzip backup_postgres_YYYYMMDD_HHMMSS.sql.gz
psql -U postgres shougaku_kore_doutoku < backup_postgres_YYYYMMDD_HHMMSS.sql

# 3. テーブル数・レコード数確認
psql -U postgres shougaku_kore_doutoku -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';"
```

**テスト結果**:

| ステップ | 状態 | 実行日時 | 復旧時間 |
|---------|------|--------|--------|
| Pre-rollback ダンプ | [ ] | _______________ | ___秒 |
| データベース復元 | [ ] | _______________ | ___分 |
| テーブル数確認 | [ ] | _______________ | ___秒 |
| レコード数確認 | [ ] | _______________ | ___秒 |
| **合計復旧時間** | [ ] | _______________ | **___分** |

### 2.4 App Engine ロールバック

**手順**:
```bash
# 1. 現在のバージョン確認
gcloud app versions list

# 2. 前バージョン（バックアップ）へトラフィック切り替え
gcloud app services set-traffic default --splits 2024-08-01=1.0

# 3. ヘルスチェック
curl -v https://shougaku-kore.app/api/health
```

**テスト結果**:

| ステップ | 状態 | 実行日時 | 復旧時間 |
|---------|------|--------|--------|
| 現在バージョン確認 | [ ] | _______________ | ___秒 |
| トラフィック切り替え | [ ] | _______________ | ___秒 |
| ヘルスチェック | [ ] | _______________ | ___秒 |
| **合計復旧時間** | [ ] | _______________ | **___秒** |

---

## 3. 復旧時間目標確認

| コンポーネント | 目標 | 実測 | 合格 |
|-----------|------|------|------|
| Firebase RTDB | < 5分 | ___分 | [ ] |
| Firestore | < 10分 | ___分 | [ ] |
| PostgreSQL | < 15分 | ___分 | [ ] |
| App Engine | < 2分 | ___秒 | [ ] |
| **全体** | **< 30分** | **___分** | **[ ]** |

---

## 4. 復旧確認チェック

### 復旧後の動作確認

- [ ] API エンドポイント応答確認
- [ ] ユーザーログイン機能確認
- [ ] ストーリー読込確認
- [ ] レポート生成確認
- [ ] In-App Purchase 機能確認
- [ ] プッシュ通知機能確認
- [ ] アナリティクス送信確認

---

## 5. 本番リリース前最終バックアップ

**実施日時**: _______________

```bash
# 1. Firebase RTDB バックアップ
firebase database:get / > FINAL_BACKUP_RTDB_$(date +%Y%m%d_%H%M%S).json

# 2. Firestore バックアップ
gcloud firestore export gs://backup-bucket/FINAL_BACKUP_$(date +%Y%m%d)

# 3. PostgreSQL バックアップ
pg_dump -U postgres shougaku_kore_doutoku | gzip > FINAL_BACKUP_POSTGRES_$(date +%Y%m%d_%H%M%S).sql.gz

# 4. バックアップ統合確認
echo "All backups completed at $(date)" >> backup_log.txt
```

**確認項目**:

- [ ] Firebase RTDB バックアップ完了
- [ ] Firestore バックアップ完了
- [ ] PostgreSQL バックアップ完了
- [ ] すべてのバックアップが Google Cloud Storage に保存確認
- [ ] バックアップログ記録確認

---

## 6. バックアップ保管方針

| バックアップタイプ | 保管場所 | 保管期間 | 確認 |
|----------------|--------|--------|------|
| 日次バックアップ | Google Cloud Storage | 30日 | [ ] |
| 週次バックアップ | Google Cloud Storage | 90日 | [ ] |
| 月次バックアップ | Cloud Archive Storage | 1年 | [ ] |
| リリース時バックアップ | Cloud Archive Storage | 無制限 | [ ] |

---

## 7. 実施後レビュー

**レビュアー**: _______________ （署名: _______________）

**コメント**:

_______________________________________________________________________________

_______________________________________________________________________________

**承認**: [ ] 承認  [ ] 条件付き承認  [ ] 却下

**承認者**: _______________ （署名: _______________）
