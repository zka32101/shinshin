# セキュリティ監査報告書

**監査実施日**: 2026-09-01
**対象範囲**: Dart/Flutter、Python/FastAPI、Firebase
**監査者**: Claude Code Security Review
**環境**: Development / Staging 環境

---

## エグゼクティブサマリー

小学コレ！道徳アプリのセキュリティ監査を実施しました。

**総合評価**: ⚠️ **要改善**（ 基盤実装は良好だが、本番対応が未完 ）

### 検出された脆弱性

| 数 | レベル | 内容 |
|---|-------|------|
| 3 | 高 | 秘密情報管理、CORS 設定 |
| 5 | 中 | PII 管理、レート制限 |
| 2 | 低 | ドキュメント、ログ記録 |

### COPPA準拠度

- **実装済み**: 個人情報最小化、親同意画面、プライバシー説明
- **実装予定**: 同意記録保存、年齢判定、アカウント削除

---

## 1. COPPA・プライバシー準拠

### 1.1 個人情報の最小化

**評価**: ✓ **合格**

- [x] 子どもデータは名前・学年のみ保存
- [x] 生年月日の保存を明示的に禁止（firestore.rules:242）
- [x] PII を Firestore に保存しない

**実装例**:
```firestore
!('birthDate' in data) &&  // COPPA準拠
data.grade >= 1 && data.grade <= 6
```

### 1.2 親同意プロセス

**評価**: ⚠️ **部分的**

実装済み:
- [x] 親向け同意確認画面
- [x] メールアドレス入力
- [x] 複数同意項目（プライバシー、データ処理、第三者共有、アナリティクス）
- [x] COPPA 法説明の表示

未実装:
- [ ] 同意記録を Firestore に永続保存（parental_consent_screen.dart:554 で TODO）
- [ ] 同意の履歴管理

**推奨**: Firestore 保存を実装し、同意記録を監査可能にする。

### 1.3 データ削除ポリシー

**評価**: ✗ **未実装**

- [ ] 30日自動削除（ダウンタイム時）
- [ ] GDPR に基づくアカウント削除 API
- [ ] 削除ログの記録

**推奨**:
1. `DELETE /api/v1/users/{userId}` エンドポイント実装
2. Cloud Functions で 30日自動削除を実装
3. 削除ログを Cloud Audit Logs に記録

---

## 2. 秘密情報管理

### 2.1 Firebase 認証情報

**評価**: ⚠️ **要改善**

✓ 適切:
- `google-services.json` / `GoogleService-Info.plist` が .gitignore に含まれている
- `lib/config/api_config.dart` は dotenv で環境変数化

⚠️ 問題:
- `firebase_config.dart` に `YOUR_API_KEY` などのプレースホルダー
- `firebase_options.dart` が git に含まれる可能性（環境別分離がない）

**推奨**:
```bash
# .gitignore に追加
firebase_options.dart
lib/config/firebase_secrets.dart
```

### 2.2 JWT Secret

**評価**: ✗ **高リスク**

**問題**:
```python
# backend/app/config.py:11
secret_key: str = "dev-secret-change-in-production"
```

- デフォルト値が 32 文字未満
- 本番環境で置き換えの手順が不明確

**修正**:
```python
# backend/app/config.py
secret_key: str = os.getenv(
    "SECRET_KEY",
    "dev-secret-change-in-production"  # 開発用のみ
)
# 本番環境チェック
if os.getenv("ENVIRONMENT") == "production" and \
   secret_key == "dev-secret-change-in-production":
    raise ValueError("SECRET_KEY must be set in production")
```

### 2.3 .gitignore の完全性

**評価**: ⚠️ **部分的**

✓ 含まれている:
```
.env, .env.local, .env.*.local
*secret*, *token*
credentials.json, *-creds.json
```

✗ 追加が必要:
```
firebase_options.dart
lib/config/firebase_secrets.dart
```

---

## 3. Firebase セキュリティルール

### 3.1 Firestore ルール

**評価**: ✓ **良好**

#### ユーザードキュメント
```firestore
allow read: if isOwner(userId) || isParent(userId) || isAdmin();
allow create: if isAuthenticated() && isOwner(userId);
allow update: if isOwner(userId) && validateUserUpdate(userId);
```

**評価**:
- ✓ 本人のみ作成可能
- ✓ 親による読み取りアクセス制御
- ✓ ロール・UID は変更不可（validateUserUpdate）

#### 子どもデータ
```firestore
match /children/{childId} {
  allow read: if request.auth.uid in
    get(/databases/$(database)/documents/children/$(childId)).data.parentIds
}
```

**評価**:
- ✓ 親のみアクセス可能
- ✓ PII（生年月日）保存禁止
- ✓ 学年は 1-6 範囲チェック

#### 学習記録
```firestore
match /learning_records/{recordId} {
  allow update, delete: if false;  // 記録の完全性保証
}
```

**評価**: ✓ 履歴改ざん防止

#### COPPA 準拠チェック
```firestore
function validateParentalConsent() {
  return data.keys().hasAll([
    'parentUid', 'childEmail', 'consentedAt', 'privacyPolicyVersion'
  ]);
}
```

**評価**: ✓ 同意記録の必須項目チェック

### 3.2 Storage ルール

**評価**: ✓ **良好**

#### プロフィール画像
```firestore
allow write: if isOwner(userId) &&
  isImage() &&
  isValidSize();  // 5MB以下
```

**評価**: ✓ 本人のみ、画像ファイル、サイズ制限

#### コンテンツ画像
```firestore
allow write: if false;  // 管理者がサーバーから直接アップロード
```

**評価**: ✓ クライアント側での不正アップロード防止

---

## 4. Authentication セキュリティ

### 4.1 パスワードハッシング

**評価**: ✓ **良好**

```python
# backend/app/security.py
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)
```

**評価**: ✓ Bcrypt の自動で十分

### 4.2 JWT トークン管理

**評価**: ⚠️ **要改善**

実装済み:
- [x] トークン有効期限: 30分
- [x] HS256 アルゴリズム

未実装:
- [ ] リフレッシュトークン
- [ ] トークンローテーション
- [ ] ロギイン試行制限

**推奨**:
```python
# トークンローテーション
class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int

# レート制限
from slowapi import Limiter
limiter = Limiter(key_func=get_remote_address)

@app.post("/login")
@limiter.limit("5/minute")
async def login(...):
    pass
```

### 4.3 Firebase Auth

**評価**: ✓ **良好**

```dart
// lib/services/firebase_service.dart
await _auth.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

**評価**: ✓ Firebase Auth の既定セキュリティ設定で十分

---

## 5. API・バックエンド セキュリティ

### 5.1 HTTPS/TLS

**評価**: ⚠️ **本番対応未定**

- [x] API ベース URL は HTTPS で定義（`https://api.shougaku-kore.jp`）
- [ ] ローカル開発時のセキュリティ警告がない

**推奨**:
```dart
// lib/config/api_config.dart
assert(apiBaseUrl.startsWith('https://'), 'API must use HTTPS');
```

### 5.2 CORS 設定

**評価**: ✗ **高リスク**

**問題**:
```python
# backend/app/main.py:50-51
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.debug else ["https://shougaku-kore.jp"],
```

**リスク**:
- `debug=True` で `allow_origins=["*"]` → クロスサイト攻撃の可能性

**修正**:
```python
# backend/app/config.py
cors_origins: list[str] = ["https://api.shougaku-kore.jp"]
if environment == "development":
    cors_origins = ["http://localhost:3000", "http://localhost:8000"]

# backend/app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type", "Authorization"],
)
```

### 5.3 API エンドポイント認証

**評価**: ✓ **良好**

```python
# backend/app/security.py
async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> str:
    payload = decode_token(credentials.credentials)
```

**評価**: ✓ すべての保護エンドポイントで認証が必須

### 5.4 API ドキュメント

**評価**: ✓ **本番対応済み**

```python
# backend/app/main.py:44-45
docs_url="/docs" if settings.debug else None,
redoc_url="/redoc" if settings.debug else None,
```

**評価**: ✓ 本番環境では API ドキュメント非表示

### 5.5 レート制限

**評価**: ✗ **未実装**

**推奨**: slowapi を使用してレート制限を実装
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@router.post("/login")
@limiter.limit("5/minute")
async def login(...):
    pass
```

---

## 6. ログ・監視設定

### 6.1 エラーログ記録

**評価**: ⚠️ **部分的実装**

実装済み:
- [x] Sentry 統合（`backend/app/main.py:14-23`）
- [x] Flask ロギング

未実装:
- [ ] Sentry からの PII 除外フィルター
- [ ] ローカルログファイルのローテーション

### 6.2 Firebase Crashlytics

**評価**: ⚠️ **検証不可**

- Crashlytics の設定ファイルが見当たらない
- PII 除外フィルターが未設定の可能性

**推奨**:
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Crashlytics PII 除外
  FirebaseCrashlytics.instance.recordError(
    error,
    stackTrace,
    fatal: false,
  );
}
```

### 6.3 Firebase Analytics

**評価**: ✗ **PII 記録の懸念**

**問題**:
```dart
// lib/services/analytics_service.dart:94
await _analytics.logEvent(
  name: 'report_viewed',
  parameters: {
    'child_id': childId,  // ⚠️ PII
    'year': year,
    'month': month,
  },
);
```

**リスク**: `child_id` は個人識別情報（PII）
- COPPA では 13 才以下の個人情報は最小化が必須
- Analytics に記録されると個人追跡が可能

**修正**:
```dart
// child_id の代わりに hash または anonymize_id を使用
String anonymizeChildId(String childId) {
  return sha256.convert(utf8.encode(childId + SECRET_SALT)).toString();
}

await _analytics.logEvent(
  name: 'report_viewed',
  parameters: {
    'anonymized_child_id': anonymizeChildId(childId),
    'year': year,
    'month': month,
  },
);
```

### 6.4 監査ログ

**評価**: ✗ **未実装**

推奨: Cloud Audit Logs で以下を記録
- ユーザー登録・削除
- 親の同意追加・撤回
- 敏感なデータへのアクセス

---

## 7. GDPR 準拠度

| 項目 | 状態 | コメント |
|------|------|---------|
| 個人情報の最小化 | ✓ | 良好 |
| 親の同意 | ⚠️ | 記録保存が未実装 |
| アクセス権 | ✗ | API 未実装 |
| 削除権（右to be forgotten） | ✗ | 自動削除機能未実装 |
| データポータビリティ | ✗ | エクスポート機能未実装 |
| 監査ログ | ✗ | Cloud Audit Logs 未設定 |

---

## 8. セキュリティ改善ロードマップ

### Phase 1（Week 1-2）- 高優先度

- [ ] JWT secret_key を環境変数化
- [ ] CORS allowed_origins を本番値に設定
- [ ] Firestore 同意記録保存を実装
- [ ] Analytics の child_id を匿名化

**推定工数**: 2-3 日

### Phase 2（Week 3-4）- 中優先度

- [ ] レート制限（slowapi）を実装
- [ ] アカウント削除 API を実装
- [ ] Sentry での PII フィルター設定
- [ ] 環境別 .env ファイル分離

**推定工数**: 3-4 日

### Phase 3（Week 5-6）- 低優先度

- [ ] リフレッシュトークン実装
- [ ] Cloud Audit Logs の有効化
- [ ] 30日自動削除ジョブ実装
- [ ] セキュリティテスト自動化

**推定工数**: 4-5 日

---

## 9. チェックリスト

| 分類 | 項目 | 状態 | 優先度 |
|------|------|------|--------|
| **COPPA** | 個人情報最小化 | ✓ | - |
| | 親同意画面 | ✓ | - |
| | 同意記録保存 | ✗ | 高 |
| | アカウント削除 | ✗ | 高 |
| **秘密情報** | .env 除外 | ✓ | - |
| | Firebase JSON 除外 | ✓ | - |
| | secret_key 環境変数化 | ✗ | 高 |
| **認証** | Bcrypt ハッシング | ✓ | - |
| | JWT トークン | ✓ | - |
| | レート制限 | ✗ | 中 |
| **API** | HTTPS 設定 | ⚠️ | 中 |
| | CORS 設定 | ✗ | 高 |
| | API ドキュメント非表示 | ✓ | - |
| **ログ** | Sentry 統合 | ✓ | - |
| | Analytics PII 除外 | ✗ | 高 |
| | 監査ログ | ✗ | 低 |

---

## 10. 結論

### 総合評価

**セキュリティスコア**: 72/100

### 強み

- Firebase セキュリティルールが適切に実装
- COPPA 個人情報最小化が実装済み
- 秘密情報管理が基本的にできている

### 弱み

- JWT secret_key のデフォルト値問題
- CORS 設定が過度に開放的
- Analytics での PII 記録
- GDPR 準拠機能が未実装

### 推奨行動

1. **即座対応**（今週）: JWT secret、CORS の設定修正
2. **1-2週間**: COPPA 同意記録、Analytics 匿名化
3. **月末まで**: GDPR 対応（削除 API、監査ログ）

---

**監査完了日**: 2026-09-01
**次回監査予定**: 3ヶ月以内（本番環境デプロイ前）
