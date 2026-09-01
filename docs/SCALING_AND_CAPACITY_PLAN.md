# スケーリング・容量計画

**小学コレ！道徳** - インフラストラクチャの拡張計画

**最終更新**: 2026年9月1日

---

## 概要

本ドキュメントは、予想されるユーザー数増加に対応するためのスケーリング戦略と容量計画を定めています。

**計画期間**: リリース後 24か月

---

## 予想ユーザー成長率

### フェーズ別 ユーザー数予測

| フェーズ | 期間 | DAU | MAU | MRR | 備考 |
|---------|------|-----|-----|-----|------|
| **Phase 1: Launch** | 月1-3 | 100-500 | 500-2,000 | ¥50k-100k | ベータテスト |
| **Phase 2: Growth** | 月4-6 | 1,000-5,000 | 5,000-20,000 | ¥250k-500k | マーケティング本格化 |
| **Phase 3: Scale** | 月7-12 | 10,000-30,000 | 50,000-100,000 | ¥2M-3M | PR・パートナーシップ |
| **Phase 4: Mature** | 月13-24 | 50,000-100,000 | 200,000-500,000 | ¥5M-10M | 国内 No.1 教育アプリ目指す |

### 成長仮定

```
【ユーザー獲得】
- 月 20% の成長率（初期段階）
- 月 10% の成長率（中期段階）
- 月 5% の成長率（成熟段階）

【購入変換率】
- トライアル → 購入: 10%
- サブスク継続率: 70%
- ARPU: ¥500-1,000/月

【チャーンレート】
- Month 1: 30%
- Month 3: 15%
- Month 6: 10%
```

---

## インフラストラクチャ容量計画

### 1. Firebase Firestore 容量

#### 1.1 データ容量予測

| リソース | 月1 | 月6 | 月12 | 月24 |
|---------|-----|-----|------|------|
| Users | 2,000 | 20,000 | 100,000 | 500,000 |
| Story Progress | 5,000 | 50,000 | 500,000 | 2,500,000 |
| Reports | 500 | 5,000 | 50,000 | 250,000 |
| Total Size | 100MB | 1GB | 10GB | 50GB |

#### 1.2 読み取り/書き込み数予測

| 操作 | 月1 | 月6 | 月12 | 月24 |
|------|-----|-----|------|------|
| 読み取り/日 | 5,000 | 50,000 | 500,000 | 2,500,000 |
| 書き込み/日 | 1,000 | 10,000 | 100,000 | 500,000 |
| ピーク読み取り/分 | 10 | 100 | 1,000 | 5,000 |

#### 1.3 Firestore コスト試算

```
【読み取り料金】
- 最初の 50,000: $0
- $0.06 per 100,000 読み取り

【月1】
- 5,000読み取り/日 × 30日 = 150,000 読み取り
- コスト: $0 (フリーティア)

【月6】
- 50,000 読み取り/日 × 30日 = 1,500,000 読み取り
- コスト: $0 + (1,450,000 × $0.06 / 100,000) = $0.87

【月12】
- 500,000 読み取り/日 × 30日 = 15,000,000 読み取り
- コスト: $0 + (14,950,000 × $0.06 / 100,000) = $8.97

【月24】
- 2,500,000 読み取り/日 × 30日 = 75,000,000 読み取り
- コスト: $0 + (74,950,000 × $0.06 / 100,000) = $44.97
```

#### 1.4 Firestore 最適化戦略

```
【インデックス最適化】
- 複合インデックス削除
- クエリの効率化
- パーティショニング

【キャッシング】
- クライアント側キャッシュ（アプリ内）
- CDN キャッシング（ダウンロード対象コンテンツ）
- Cloud Memorystore キャッシュ（バックエンド）
```

実装例:

```dart
// キャッシング戦略
class FirestoreOptimizer {
  // バッチ読み取り
  Future<List<StoryProgress>> getMultipleProgress(List<String> storyIds) async {
    // 複数の読み取りを 1 つのクエリに
    return await FirebaseFirestore.instance
      .collection('story_progress')
      .where(FieldPath.documentId, whereIn: storyIds)  // whereIn でバッチ取得
      .get()
      .then((snapshot) => snapshot.docs.map((doc) => StoryProgress.fromFirestore(doc)).toList());
  }
  
  // ページング
  Future<List<Report>> getReportsPaged(int pageSize) async {
    return await FirebaseFirestore.instance
      .collection('reports')
      .limit(pageSize)
      .get()
      .then((snapshot) => snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList());
  }
  
  // リアルタイムリスナー数を制限
  StreamSubscription listenToUserProgress(String userId) {
    // 同時接続数を最小化
    return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .listen((doc) {
        // ユーザー更新処理
      });
  }
}
```

### 2. Cloud Run バックエンド API スケーリング

#### 2.1 API トラフィック予測

| メトリクス | 月1 | 月6 | 月12 | 月24 |
|-----------|-----|-----|------|------|
| リクエスト/日 | 10,000 | 100,000 | 1,000,000 | 5,000,000 |
| ピークRPS | 5 | 50 | 500 | 2,500 |
| 平均レスポンスタイム | 200ms | 300ms | 400ms | 500ms |

#### 2.2 Cloud Run リソース計画

```
【月1】
- CPU: 0.5
- メモリ: 256MB
- インスタンス: 1
- コスト: $0 (フリーティア)

【月6】
- CPU: 2
- メモリ: 1GB
- インスタンス: 5（max-instances）
- コスト: ~¥5,000/月

【月12】
- CPU: 4
- メモリ: 2GB
- インスタンス: 20
- コスト: ~¥30,000/月

【月24】
- CPU: 4
- メモリ: 4GB
- インスタンス: 100
- コスト: ~¥150,000/月
```

#### 2.3 Cloud Run オートスケーリング設定

```bash
# インスタンス設定
gcloud run services update shougaku-kore-backend \
  --memory=1Gi \
  --cpu=2 \
  --concurrency=100 \
  --timeout=60s \
  --max-instances=50 \
  --min-instances=1

# ハイトラフィック期間（午後 3-5 時）用の最小インスタンス数
gcloud scheduler jobs create http scale-up-api \
  --location=asia-northeast1 \
  --schedule="0 15 * * *" \
  --uri="https://asia-northeast1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/[project]/services/shougaku-kore-backend:update" \
  --http-method=PATCH \
  --headers="Authorization: Bearer $(gcloud auth print-identity-token)"
```

#### 2.4 API キャッシング戦略

```
【HTTP キャッシング】
- GET /api/stories: キャッシュ 1 時間
- GET /api/story/{id}: キャッシュ 24 時間
- POST /api/progress: キャッシュなし

【Cloud CDN】
- Cloud Armor で静的コンテンツをキャッシュ
- Edge Location から配信

【アプリケーションレベル】
- Redis (Cloud Memorystore) でセッションキャッシュ
```

実装:

```python
# Flask バックエンド
from flask import Flask, jsonify, request
from flask_caching import Cache

app = Flask(__name__)
cache = Cache(app, config={'CACHE_TYPE': 'simple'})

@app.route('/api/stories', methods=['GET'])
@cache.cached(timeout=3600, key_prefix='stories')  # 1 時間キャッシュ
def get_stories():
    stories = db.query(Story).all()
    return jsonify([s.to_dict() for s in stories])

@app.route('/api/story/<story_id>', methods=['GET'])
@cache.cached(timeout=86400, key_prefix='story')  # 24 時間キャッシュ
def get_story(story_id):
    story = db.query(Story).get(story_id)
    return jsonify(story.to_dict())

@app.route('/api/progress', methods=['POST'])
def save_progress():
    # キャッシュなし - リアルタイム処理
    data = request.json
    progress = StoryProgress(**data)
    db.add(progress)
    db.commit()
    return jsonify({'status': 'success'})
```

### 3. Cloud Storage 容量計画

#### 3.1 ストレージ容量予測

| リソース | 月1 | 月6 | 月12 | 月24 |
|---------|-----|-----|------|------|
| Story Images | 100MB | 500MB | 1GB | 2GB |
| Story Audio | 200MB | 1GB | 2GB | 5GB |
| Parent Reports (PDF) | 50MB | 500MB | 5GB | 25GB |
| Backups | 100MB | 1GB | 10GB | 50GB |
| **合計** | **450MB** | **3GB** | **18GB** | **82GB** |

#### 3.2 Cloud Storage コスト試算

```
【月1 (450MB)】
- 読み取り: $0.01
- 保存: $0.018 (450MB × $0.020/GB)
- 月額: ~¥2

【月6 (3GB)】
- 月額: ~¥100

【月12 (18GB)】
- 月額: ~¥400

【月24 (82GB)】
- 月額: ~¥1,800

【注】Google Cloud Storage の最初の 5GB は無料
```

#### 3.3 Cloud Storage 最適化

```bash
# アップロード前に画像を圧縮
# iOS/Android SDK で自動圧縮

# 古いバックアップを削除
gsutil -m rm gs://shougaku-kore-backups/**/backup-*.tar.gz

# ライフサイクル設定（30日後に削除）
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"age": 30}
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://shougaku-kore-backups/
```

### 4. Cloud SQL バックアップ容量

#### 4.1 バックアップ戦略

```
【自動バックアップ】
- 毎日 1 回（最新 30 日分保持）
- 1 日あたり 1-2GB

【スナップショット】
- 週 1 回手動（重要なタイミング）

【リージョナルバックアップ】
- 災害復旧用
- 別リージョン（asia-southeast1）に複製
```

#### 4.2 バックアップコスト

```
【月1】
- バックアップストレージ: 30GB × $0.026 = $0.78

【月6】
- バックアップストレージ: 60GB × $0.026 = $1.56

【月12】
- バックアップストレージ: 120GB × $0.026 = $3.12

【月24】
- バックアップストレージ: 240GB × $0.026 = $6.24
```

---

## CDN・キャッシング戦略

### 1. Cloud CDN 設定

```
【対象コンテンツ】
- ストーリー画像（変更頻度：低）
- ストーリーオーディオ（変更頻度：低）
- UI アセット（変更頻度：低）

【非対象コンテンツ】
- ユーザープログレス（パーソナライズ）
- 親向けレポート（パーソナライズ）
```

実装:

```bash
# Cloud CDN を有効化
gcloud compute backend-services update shougaku-kore-cdn \
  --enable-cdn \
  --cache-mode CACHE_ALL_STATIC \
  --default-ttl=3600 \
  --max-ttl=86400

# キャッシュキー設定
gcloud compute backend-services update shougaku-kore-cdn \
  --cache-key-include-host \
  --cache-key-include-protocol \
  --cache-key-include-query-string
```

### 2. アプリケーション内キャッシング

#### 2.1 ローカルキャッシュ戦略

```dart
// Hive でローカルキャッシュ
class LocalCacheManager {
  Future<void> cacheStories(List<Story> stories) async {
    final box = await Hive.openBox<Story>('stories_cache');
    for (var story in stories) {
      await box.put(story.id, story);
    }
  }
  
  Future<Story?> getCachedStory(String storyId) async {
    final box = await Hive.openBox<Story>('stories_cache');
    return box.get(storyId);
  }
  
  Future<void> clearCache() async {
    await Hive.deleteBoxFromDisk('stories_cache');
  }
}

// SharedPreferences でメタデータキャッシュ
final prefs = await SharedPreferences.getInstance();
final lastUpdateTime = prefs.getInt('stories_last_update');
final now = DateTime.now().millisecondsSinceEpoch;

if (lastUpdateTime != null && (now - lastUpdateTime) < 3600000) {
  // 1 時間以内 = キャッシュから取得
  return getCachedStories();
}
```

---

## データベース バックアップ・復旧戦略

### 1. バックアップ計画

```
【自動バックアップ】
- Cloud SQL: 毎日 1 回
- Firestore: リアルタイム複製（自動）
- Cloud Storage: 週 1 回

【手動バックアップ】
- リリース前
- 大規模更新前
- セキュリティ監査後
```

### 2. 復旧手順

#### 2.1 Cloud SQL 復旧

```bash
# バックアップ一覧確認
gcloud sql backups list --instance=shougaku-kore-db

# 特定の時刻まで復旧
gcloud sql backups restore [BACKUP_ID] \
  --backup-instance=shougaku-kore-db \
  --restore-instance=shougaku-kore-db-restored

# クローン インスタンスで検証
gcloud sql connect shougaku-kore-db-restored
```

#### 2.2 Firestore 復旧

```bash
# エクスポート
gcloud firestore export gs://shougaku-kore-backups/backup-$(date +%Y%m%d)

# インポート（復旧）
gcloud firestore import gs://shougaku-kore-backups/backup-20260901/
```

---

## ネットワーク・帯域幅計画

### 1. 帯域幅予測

| フェーズ | DAU | 平均 Session | 平均 DL | ピーク帯域 |
|---------|-----|-------------|--------|----------|
| Month 1 | 500 | 10MB | 1GB/日 | 10Mbps |
| Month 6 | 20k | 10MB | 40GB/日 | 400Mbps |
| Month 12 | 100k | 10MB | 200GB/日 | 2Gbps |
| Month 24 | 500k | 10MB | 1TB/日 | 10Gbps |

### 2. DDoS 対策・セキュリティ

```bash
# Cloud Armor で DDoS 対策
gcloud compute security-policies create shougaku-kore-armor \
  --description="DDoS protection for shougaku-kore"

# レート制限
gcloud compute security-policies rules create 100 \
  --security-policy=shougaku-kore-armor \
  --action=rate-based-ban \
  --rate-limit-options=enforced-on-key=IP \
  --rate-limit-options=rate-limit-threshold-count=100 \
  --rate-limit-options=rate-limit-threshold-interval-sec=60 \
  --ban-duration-sec=600
```

---

## モニタリング・スケーリング判定基準

### 1. スケールアップのトリガー

```
【メトリクス】
- Cloud Run インスタンス稼働率 > 80%
- Firestore 読み取り > 1M/日
- Cloud SQL CPU > 70%
- API レスポンスタイム > 1秒

【アクション】
→ インスタンス数の増加
→ データベースのリソース拡大
→ キャッシング戦略の強化
```

### 2. スケールダウンのトリガー

```
【メトリクス】
- Cloud Run インスタンス稼働率 < 20% （連続 1 日以上）
- API レスポンスタイム < 200ms

【アクション】
→ インスタンス数の削減
→ 不要なインデックス削除
→ キャッシュ時間の延長
```

---

## コスト最適化

### 1. Google Cloud コスト試算（予測）

| フェーズ | Firestore | Cloud Run | Storage | SQL | 合計 |
|---------|-----------|-----------|---------|-----|------|
| Month 1 | ~¥0 | ~¥0 | ~¥100 | ~¥2,000 | ~¥2,100 |
| Month 6 | ~¥100 | ~¥5,000 | ~¥500 | ~¥4,000 | ~¥9,600 |
| Month 12 | ~¥1,000 | ~¥30,000 | ~¥1,000 | ~¥8,000 | ~¥40,000 |
| Month 24 | ~¥5,000 | ~¥150,000 | ~¥3,000 | ~¥16,000 | ~¥174,000 |

### 2. コスト最適化施策

```
【リソース予約】
- Google Cloud Committed Use Discounts（CUD）
- 年間契約で 25-37% 割引

【使用量の削減】
- Cloud Storage ライフサイクル
- Firestore インデックス削除
- Cloud Run 最小インスタンス削減

【キャッシング強化】
- Cloud CDN 拡張
- Cloud Memorystore 導入
- クライアント側キャッシング強化
```

---

## 参考資料

- [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator)
- [Cloud Run Scaling](https://cloud.google.com/run/docs/quickstarts/build-and-deploy#container-requirements)
- [Firestore Quotas and Limits](https://firebase.google.com/docs/firestore/quotas)
- [Cloud SQL High Availability](https://cloud.google.com/sql/docs/mysql/high-availability)
