# Firebase セキュリティ・デプロイメント ガイド

小学コレ！道徳アプリの Firebase 設定と本番環境へのセキュアなデプロイ方法を説明します。

## 目次

1. [Firebase プロジェクト設定](#firebase-プロジェクト設定)
2. [セキュリティルール検証](#セキュリティルール検証)
3. [デプロイ手順](#デプロイ手順)
4. [本番環境設定](#本番環境設定)
5. [監視・ロギング](#監視ロギング)
6. [トラブルシューティング](#トラブルシューティング)

---

## Firebase プロジェクト設定

### 1.1 プロジェクト初期化

#### Firebase コンソールでの設定

1. **Firebase コンソール** にアクセス
2. **新規プロジェクト** を作成
3. **Firestore Database** を有効化
   - 本番モード を選択（セキュリティルール必須）
   - リージョン: `asia-northeast1` (東京)
4. **Firebase Storage** を有効化
   - ロケーション: `ASIA-NORTHEAST1`

#### ローカル環境での Firebase CLI 設定

```bash
# Firebase CLI をインストール
npm install -g firebase-tools

# Firebase にログイン
firebase login

# プロジェクトを初期化
firebase init

# プロジェクトを選択・設定
firebase use [project_id]

# 確認
firebase projects:list
```

#### firebase.json 設定

```json
{
  "projects": {
    "default": "shougaku-kore-prod"
  },
  "firestore": {
    "rules": "firebase/firestore.rules",
    "indexes": "firebase/firestore.indexes.json"
  },
  "storage": {
    "rules": "firebase/storage.rules"
  }
}
```

### 1.2 Authentication 設定

#### メール認証の有効化

```bash
# Firebase コンソール → Authentication → Sign-in method
# 1. メール・パスワード を有効化
# 2. メール確認を有効化（推奨）
# 3. パスワードリセット を有効化
```

#### CORS 設定（カスタムドメイン用）

```bash
# firebase.json に CORS を設定
# アプリが別ドメインから Firebase API にアクセスする場合に必要
```

---

## セキュリティルール検証

### 2.1 Firestore ルール検証

#### ルールの確認

```bash
# ローカル開発用ルールを確認
cat firebase/firestore.rules

# ルールの構文チェック
firebase rules:test firebase/firestore.rules
```

#### ルール検証テスト

```bash
# テストファイルを作成
cat > firebase/firestore.test.js << 'EOF'
import * as firebase from "@firebase/testing";

describe("Firestore Security Rules", () => {
  // 認証なしのユーザー
  const unauth = firebase
    .initializeTestApp({ projectId: "test-project" })
    .firestore();

  // 認証済みユーザー
  const auth = firebase
    .initializeTestApp({
      projectId: "test-project",
      auth: { uid: "user123" }
    })
    .firestore();

  // テスト: ユーザーは自分のドキュメントにアクセス可能
  it("users can read their own document", async () => {
    const doc = auth.collection("users").doc("user123");
    await firebase.assertSucceeds(doc.get());
  });

  // テスト: ユーザーは他人のドキュメントにアクセス不可
  it("users cannot read others' document", async () => {
    const doc = auth.collection("users").doc("otheruser");
    await firebase.assertFails(doc.get());
  });

  // テスト: 認証なしでは読み取り不可
  it("unauthenticated users cannot read", async () => {
    const doc = unauth.collection("users").doc("user123");
    await firebase.assertFails(doc.get());
  });
});
EOF

# テスト実行
npm test
```

### 2.2 Storage ルール検証

#### ルール確認

```bash
# ローカル開発用ルールを確認
cat firebase/storage.rules

# ルール検証テスト
firebase rules:test firebase/storage.rules
```

#### Storage ルールのベストプラクティス

```javascript
// firebase/storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // プロフィール画像
    match /profile_images/{userId}/{allPaths=**} {
      // 認証ユーザーのみ読み取り可能
      allow read: if request.auth != null;
      
      // 本人のみ書き込み可能
      allow write: if request.auth.uid == userId &&
        request.resource.size <= 5 * 1024 * 1024 &&
        request.resource.contentType.matches('image/.*');
    }

    // その他のパスは全てブロック
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## デプロイ手順

### 3.1 デプロイ前チェック

#### チェックリスト

```bash
#!/bin/bash
# scripts/pre-deploy-check.sh

echo "Firebase デプロイ前チェック"
echo ""

# 1. Firebase ルールの構文チェック
echo "1. ルール構文チェック..."
firebase rules:test firebase/firestore.rules
if [ $? -ne 0 ]; then
  echo "✗ Firestore ルール: エラー"
  exit 1
fi
echo "✓ Firestore ルール: OK"

firebase rules:test firebase/storage.rules
if [ $? -ne 0 ]; then
  echo "✗ Storage ルール: エラー"
  exit 1
fi
echo "✓ Storage ルール: OK"

# 2. Firebase CLI バージョン確認
echo ""
echo "2. Firebase CLI バージョン確認..."
firebase --version

# 3. ログイン状態確認
echo ""
echo "3. ログイン状態確認..."
firebase projects:list | head -5

# 4. デプロイ対象プロジェクト確認
echo ""
echo "4. デプロイ対象プロジェクト確認..."
CURRENT_PROJECT=$(firebase use 2>/dev/null || echo "未設定")
echo "対象プロジェクト: $CURRENT_PROJECT"

if [ "$CURRENT_PROJECT" = "未設定" ]; then
  echo "✗ プロジェクトが設定されていません"
  exit 1
fi

echo ""
echo "✓ すべてのチェックが完了しました"
```

実行:
```bash
./scripts/pre-deploy-check.sh
```

### 3.2 本番環境へのデプロイ

#### Firestore ルールのデプロイ

```bash
#!/bin/bash
# scripts/deploy-firestore-rules.sh

echo "Firestore ルール をデプロイします"
echo ""

# 現在のプロジェクトを確認
PROJECT=$(firebase use 2>/dev/null)
echo "デプロイ対象: $PROJECT"

# 確認
read -p "デプロイを実行しますか？ (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "キャンセルしました"
  exit 0
fi

# バックアップを作成
echo "現在のルール設定をバックアップ..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
firebase deploy --only firestore:rules \
  --backup-path "backups/firestore_rules_${TIMESTAMP}.backup"

# デプロイ実行
echo ""
echo "デプロイ実行..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ デプロイ成功"
else
  echo ""
  echo "✗ デプロイ失敗"
  exit 1
fi
```

実行:
```bash
./scripts/deploy-firestore-rules.sh
```

#### Storage ルールのデプロイ

```bash
#!/bin/bash
# scripts/deploy-storage-rules.sh

echo "Storage ルール をデプロイします"
echo ""

PROJECT=$(firebase use 2>/dev/null)
echo "デプロイ対象: $PROJECT"

read -p "デプロイを実行しますか？ (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  exit 0
fi

firebase deploy --only storage:rules

if [ $? -eq 0 ]; then
  echo "✓ Storage ルール デプロイ成功"
else
  echo "✗ Storage ルール デプロイ失敗"
  exit 1
fi
```

#### 一括デプロイ

```bash
#!/bin/bash
# scripts/deploy-firebase.sh
# Firebase のすべてをデプロイ

firebase deploy \
  --only firestore:rules,storage:rules

# ホスティング（有効な場合）
# firebase deploy --only hosting
```

### 3.3 デプロイ後の検証

```bash
#!/bin/bash
# scripts/post-deploy-verify.sh

echo "デプロイ後検証"
echo ""

# 1. Firestore 接続テスト
echo "1. Firestore 接続テスト..."
curl -X GET \
  "https://firestore.googleapis.com/v1/projects/[PROJECT_ID]/databases/default/documents/stories" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)"

# 2. Storage アクセステスト
echo ""
echo "2. Storage アクセステスト..."
gsutil ls gs://[PROJECT_ID].appspot.com/

# 3. ルールが正しく適用されたか確認
echo ""
echo "3. セキュリティルール確認..."
firebase rules:list
```

---

## 本番環境設定

### 4.1 Firestore インデックス設定

自動生成されたインデックスに加えて、複雑なクエリ用に手動インデックスを作成:

```json
{
  "indexes": [
    {
      "collectionGroup": "learning_records",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "timestamp",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "monthly_reports",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "parentIds",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "month",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

デプロイ:
```bash
firebase deploy --only firestore:indexes
```

### 4.2 Firestore 設定

#### Backup 設定

```bash
# GCS バケット作成
gsutil mb gs://[PROJECT_ID]-firestore-backups

# 定期バックアップをスケジュール（Cloud Scheduler）
gcloud scheduler jobs create app-engine firestore-backup \
  --schedule "0 2 * * *" \
  --message-body "{}" \
  --http-method POST \
  --uri "https://region-project.cloudfunctions.net/firestore-backup"
```

#### 容量制限設定

```bash
# Firestore の容量制限を設定（オプション）
# Firebase コンソール → Firestore → 設定 → バックアップ
```

### 4.3 Analytics の設定

#### Firebase Analytics 有効化

```bash
# Firebase コンソール → Analytics

# COPPA 対応
# Analytics → 設定 → データ収集
# 「広告機能の共有」を無効化
# 「ユーザーの分析レポート」で匿名化を有効化
```

---

## 監視・ロギング

### 5.1 Firestore 監視

#### 読み書き監視ダッシュボード

```bash
# Cloud Console → Firestore → 監視
# または gcloud コマンド
gcloud firestore databases describe default \
  --project=[PROJECT_ID]
```

#### コスト監視

```bash
# Cloud Billing で使用量を監視
# 読み取り、書き込み、削除操作の課金を追跡
```

### 5.2 セキュリティ監視

#### ルール違反ログ

```bash
# Cloud Logging で Firestore アクセス拒否をログ
gcloud logging read \
  'resource.type="cloud_firestore_database" 
   severity="ERROR"' \
  --format=json \
  --limit=50
```

#### 異常なアクセスパターン

```bash
# Cloud Monitoring でアラートを設定
# - 異常な読み取り操作
# - 異常な書き込み操作
# - 認証エラーの増加
```

---

## トラブルシューティング

### 問題: Firestore ルールテストが失敗する

**エラーメッセージ**:
```
Error: Rules test failed
Field 'role' must exist
```

**解決方法**:
```dart
// firestore.rules でフィールド存在チェックを追加
function userHasRole(userId, role) {
  let userData = get(/databases/$(database)/documents/users/$(userId)).data;
  return "role" in userData && userData.role == role;
}
```

### 問題: デプロイ時に権限エラー

**エラーメッセージ**:
```
Error: Permission denied
You don't have permission to deploy to this project
```

**解決方法**:
```bash
# Firebase プロジェクト所有者として再ログイン
firebase logout
firebase login

# または特定の認証情報を使用
firebase deploy --token [your-firebase-token]

# トークンを取得
firebase login:ci
```

### 問題: Storage のサイズ制限エラー

**エラーメッセージ**:
```
Error: File size exceeds limit
```

**解決方法**:
```javascript
// firebase/storage.rules でサイズ制限を確認
function isValidSize() {
  return request.resource.size <= 5 * 1024 * 1024; // 5MB
}
```

---

## セキュリティベストプラクティス

### 6.1 ルール設計の原則

1. **最小権限の原則**: 必要最小限のアクセスのみを許可
2. **明示的な拒否**: デフォルトは拒否、明示的に許可する
3. **ユーザーコンテキスト**: リクエストユーザーの情報を活用
4. **検証**: 入力データを常に検証

### 6.2 定期的なセキュリティレビュー

```bash
# 月次レビュー
# 1. ルール変更ログを確認
# 2. セキュリティアラートを確認
# 3. アクセスパターンを分析
# 4. ルール設計を見直し
```

### 6.3 バージョン管理

ルール設定を Git で管理:

```bash
# Firestore ルール
git add firebase/firestore.rules
git commit -m "Update Firestore rules: Add user validation"

# Storage ルール
git add firebase/storage.rules
git commit -m "Update Storage rules: Add file size limit"
```

---

最終更新: 2024-09-01
バージョン: 1.0.0
