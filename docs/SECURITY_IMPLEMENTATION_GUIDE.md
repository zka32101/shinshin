# セキュリティ改善実装ガイド

このドキュメントは、セキュリティ監査報告書で指摘された脆弱性を修正するための具体的な実装ガイドです。

---

## Phase 1: 高優先度（Week 1-2）

### 1. JWT secret_key の環境変数化

**現状**:
```python
# backend/app/config.py:11
secret_key: str = "dev-secret-change-in-production"
```

**修正**:

```python
# backend/app/config.py
import os
from datetime import datetime, timedelta
from typing import Optional

class Settings(BaseSettings):
    # ... 既存設定 ...
    
    # JWT
    secret_key: str = os.getenv(
        "SECRET_KEY",
        "dev-secret-change-in-production"
    )
    
    def __init__(self, **data):
        super().__init__(**data)
        # 本番環境でのチェック
        if self.environment == "production" and \
           self.secret_key == "dev-secret-change-in-production":
            raise ValueError(
                "SECRET_KEY must be set in production environment. "
                "Please set the SECRET_KEY environment variable."
            )
```

**環境変数設定**:

```bash
# .env.development
SECRET_KEY=dev-secret-change-in-production
ENVIRONMENT=development
DEBUG=true

# .env.production (CI/CD に設定)
SECRET_KEY=$(openssl rand -base64 32)
ENVIRONMENT=production
DEBUG=false
```

**検証**:

```bash
# 本番環境チェック
python -c "from app.config import get_settings; s = get_settings(); print('OK')"
```

---

### 2. CORS 設定の修正

**現状**:
```python
# backend/app/main.py:50-51
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.debug else ["https://shougaku-kore.jp"],
```

**修正**:

```python
# backend/app/config.py
class Settings(BaseSettings):
    # ... 既存設定 ...
    
    # CORS
    cors_origins: list[str] = [
        "https://api.shougaku-kore.jp"
    ]
    cors_allow_methods: list[str] = [
        "GET", "POST", "PUT", "DELETE", "OPTIONS"
    ]
    cors_allow_headers: list[str] = [
        "Content-Type", "Authorization"
    ]
    
    def __init__(self, **data):
        super().__init__(**data)
        if self.environment == "development":
            self.cors_origins = [
                "http://localhost:3000",
                "http://localhost:8000",
                "http://localhost:8080",  # Flutter web
            ]

# backend/app/main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=settings.cors_allow_methods,
    allow_headers=settings.cors_allow_headers,
    max_age=3600,  # キャッシュ時間
)
```

**検証**:

```bash
# 開発環境
curl -H "Origin: http://localhost:3000" http://localhost:8000/api/v1/auth/login

# 本番環境（許可されない）
curl -H "Origin: http://localhost:3000" https://api.shougaku-kore.jp/api/v1/auth/login
# → CORS エラー
```

---

### 3. Firebase 同意記録保存の実装

**現状**:
```dart
// lib/screens/auth/parental_consent_screen.dart:554
Future<void> submitConsent({...}) async {
  state = const AsyncValue.loading();
  try {
    final authService = ref.read(authServiceProvider);
    // TODO: 実装 - Firebase Firestore に同意情報を保存
    await Future.delayed(const Duration(seconds: 2)); // ダミー遅延
    state = const AsyncValue.data(null);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
  }
}
```

**修正**:

```dart
// lib/models/parental_consent.dart
class ParentalConsent {
  final String consentId;
  final String parentUid;
  final String childEmail;
  final String privacyPolicyVersion;
  final DateTime consentedAt;
  final Map<String, bool> consentTo;
  final DateTime? revokedAt;

  ParentalConsent({
    required this.consentId,
    required this.parentUid,
    required this.childEmail,
    required this.privacyPolicyVersion,
    required this.consentedAt,
    required this.consentTo,
    this.revokedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'parentUid': parentUid,
      'childEmail': childEmail,
      'privacyPolicyVersion': privacyPolicyVersion,
      'consentedAt': consentedAt.toIso8601String(),
      'consentTo': consentTo,
      'revokedAt': revokedAt?.toIso8601String(),
    };
  }

  static ParentalConsent fromJson(Map<String, dynamic> json) {
    return ParentalConsent(
      consentId: json['id'] as String,
      parentUid: json['parentUid'] as String,
      childEmail: json['childEmail'] as String,
      privacyPolicyVersion: json['privacyPolicyVersion'] as String,
      consentedAt: DateTime.parse(json['consentedAt'] as String),
      consentTo: Map<String, bool>.from(json['consentTo'] as Map),
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'] as String)
          : null,
    );
  }
}

// lib/screens/auth/parental_consent_screen.dart
class ParentalConsentNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ParentalConsentNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> submitConsent({
    required String parentEmail,
    required String childEmail,
    required Map<String, bool> consentData,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final currentUser = firebaseService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final parentalConsent = ParentalConsent(
        consentId: DateTime.now().millisecondsSinceEpoch.toString(),
        parentUid: currentUser.uid,
        childEmail: childEmail,
        privacyPolicyVersion: '1.0.0',
        consentedAt: DateTime.now(),
        consentTo: consentData,
      );

      // Firestore に保存
      await firebaseService.saveParentalConsent(parentalConsent);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// lib/services/firebase_service.dart に追加
Future<void> saveParentalConsent(ParentalConsent consent) async {
  try {
    await _firestore
        .collection('parental_consents')
        .doc(consent.consentId)
        .set(consent.toJson());
  } catch (e) {
    rethrow;
  }
}
```

---

### 4. Analytics の child_id を匿名化

**現状**:
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

**修正**:

```dart
// lib/utils/anonymization.dart
import 'package:crypto/crypto.dart';

class AnonymizationHelper {
  static const String _SALT = 'shougaku-kore-secret-salt';

  static String anonymizeChildId(String childId) {
    return sha256
        .convert((childId + _SALT).codeUnits)
        .toString()
        .substring(0, 16);
  }
}

// lib/services/analytics_service.dart
import 'package:shougaku_kore_doutoku/utils/anonymization.dart';

Future<void> logReportViewed({
  required String childId,
  required int year,
  required int month,
}) async {
  await _analytics.logEvent(
    name: 'report_viewed',
    parameters: {
      'anonymized_child_id': AnonymizationHelper.anonymizeChildId(childId),
      'year': year,
      'month': month,
    },
  );
}

// 他のイベントも同様に修正
Future<void> logReportGenerated({
  required String childId,
  required int storiesCompleted,
}) async {
  await _analytics.logEvent(
    name: 'report_generated',
    parameters: {
      'anonymized_child_id': AnonymizationHelper.anonymizeChildId(childId),
      'stories_completed': storiesCompleted,
    },
  );
}
```

**検証**:

```dart
// テスト
test('anonymizeChildId produces consistent results', () {
  String childId = 'child_123';
  String anon1 = AnonymizationHelper.anonymizeChildId(childId);
  String anon2 = AnonymizationHelper.anonymizeChildId(childId);
  expect(anon1, anon2);
});
```

---

## Phase 2: 中優先度（Week 3-4）

### 5. レート制限の実装

```bash
# backend/requirements.txt に追加
slowapi==0.1.9
```

```python
# backend/app/main.py
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request, exc):
    return JSONResponse(
        status_code=429,
        content={"detail": "Too many requests. Please try again later."},
    )

# backend/app/api/auth.py
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/login")
@limiter.limit("5/minute")
async def login(request: Request, ...):
    # 既存実装
    pass

@router.post("/register")
@limiter.limit("3/minute")
async def register(request: Request, ...):
    # 既存実装
    pass
```

---

### 6. アカウント削除 API の実装

```python
# backend/app/api/users.py に追加
@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """ユーザーアカウントを削除（GDPR 準拠）"""
    # 本人のみ削除可能
    if current_user_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    
    # ユーザー削除（Firestore）
    await firebaseService.deleteUserData(user_id)
    
    # Firebase Auth からも削除
    try:
        firebase_auth.delete_user(user_id)
    except Exception as e:
        logger.error(f"Failed to delete Firebase user: {e}")
    
    return {"message": "Account deleted successfully"}
```

---

## Phase 3: 低優先度（Week 5-6）

### 7. リフレッシュトークンの実装

```python
# backend/app/schemas/auth.py
class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

# backend/app/security.py
def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (
        expires_delta or timedelta(days=7)
    )
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)

# backend/app/api/auth.py
@router.post("/refresh")
async def refresh_token(
    request: dict,
    db: AsyncSession = Depends(get_db),
):
    """リフレッシュトークンから新しいアクセストークンを取得"""
    refresh_token = request.get("refresh_token")
    payload = decode_token(refresh_token)
    
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid token type")
    
    user_id = payload.get("sub")
    new_access_token = create_access_token({"sub": user_id})
    
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=refresh_token,
        expires_in=settings.access_token_expire_minutes * 60,
    )
```

---

## チェックリスト

### Phase 1 実装確認

- [ ] JWT secret_key を環境変数化
  - [ ] backend/app/config.py を修正
  - [ ] .env ファイルを設定
  - [ ] ローカルテスト実施
  - [ ] CI/CD で本番環境値を設定

- [ ] CORS 設定を修正
  - [ ] backend/app/config.py に cors_origins を追加
  - [ ] backend/app/main.py を修正
  - [ ] develop/staging/production での動作確認

- [ ] Firestore 同意記録保存
  - [ ] ParentalConsent モデル作成
  - [ ] firebase_service.saveParentalConsent() 実装
  - [ ] parental_consent_screen.dart の TODO 完了
  - [ ] テスト実施

- [ ] Analytics 匿名化
  - [ ] anonymization.dart を作成
  - [ ] analytics_service.dart の全イベント更新
  - [ ] テスト実施

### Phase 2 実装確認

- [ ] レート制限実装
  - [ ] slowapi 導入
  - [ ] login/register に適用
  - [ ] テスト実施

- [ ] アカウント削除 API
  - [ ] DELETE /api/v1/users/{user_id} 実装
  - [ ] 本人確認ロジック
  - [ ] Firestore/Firebase Auth データ削除
  - [ ] テスト実施

### Phase 3 実装確認

- [ ] リフレッシュトークン実装
  - [ ] create_refresh_token() 関数
  - [ ] POST /api/v1/auth/refresh エンドポイント
  - [ ] フロントエンド側での token 更新処理
  - [ ] テスト実施

---

## テストコマンド

```bash
# 環境変数テスト
export SECRET_KEY="test-key-$(openssl rand -base64 16)"
export ENVIRONMENT=production
python -c "from app.config import get_settings; print('OK')"

# CORS テスト
curl -H "Origin: http://localhost:3000" -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS http://localhost:8000/api/v1/auth/login

# レート制限テスト
for i in {1..10}; do
  curl -X POST http://localhost:8000/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"test"}'
done
```

---

## 参考資料

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Firebase Security: https://firebase.google.com/docs/rules/start
- COPPA Compliance: https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy
