# 支払い統合ガイド

## 概要

このドキュメントは、小学コレ！道徳アプリの支払い処理を実装するためのバックエンド統合ガイドです。

## アーキテクチャ

```
┌─────────────────┐
│  Flutter App    │
│  - Payment      │
│  - UI Logic     │
└────────┬────────┘
         │ Receipt (JSON)
         ▼
┌─────────────────┐
│  FastAPI       │
│  Backend       │
│ - Verify       │
│ - Store        │
└────────┬────────┘
         │ VerificationResult
         ▼
┌─────────────────┐
│  Firestore      │
│  - Store        │
│  - Query        │
└─────────────────┘
```

## Receipt 検証の流れ

### 1. クライアント側（Flutter）

```dart
// payment_service.dart
Future<void> handlePurchaseUpdate(
  PurchaseDetails purchaseDetails,
  String userId,
) async {
  if (purchaseDetails.status == PurchaseStatus.purchased) {
    // サーバーに Receipt を送信
    if (Platform.isIOS) {
      bool verified = await _subscriptionService.verifyAppleReceipt(
        userId: userId,
        receipt: purchaseDetails.serverVerificationData.localVerificationData,
      );
    } else if (Platform.isAndroid) {
      bool verified = await _subscriptionService.verifyGooglePlayReceipt(
        userId: userId,
        packageName: purchaseDetails.packageName,
        productId: purchaseDetails.productID,
        purchaseToken: purchaseDetails.verificationData.serverVerificationData,
      );
    }
  }
}
```

### 2. サーバー側（FastAPI）

#### 2.1 Apple Receipt Verification

```python
# backend/app/routes/subscriptions.py

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.app_store_service import AppStoreService

router = APIRouter()

class AppleReceiptRequest(BaseModel):
    userId: str
    receipt: str  # Base64-encoded receipt data

@router.post("/api/subscriptions/verify-receipt-apple")
async def verify_apple_receipt(request: AppleReceiptRequest):
    try:
        app_store_service = AppStoreService()
        
        # App Store Server API で Receipt を検証
        result = await app_store_service.verify_receipt(
            receipt_data=request.receipt,
        )
        
        if result.get("valid"):
            # Firestore に購入情報を記録
            transaction_id = result.get("transaction_id")
            product_id = result.get("product_id")
            
            # Update user subscription in Firestore
            # ... implementation ...
            
            return {
                "success": True,
                "transaction_id": transaction_id,
                "product_id": product_id,
            }
        else:
            raise HTTPException(
                status_code=400,
                detail="Invalid receipt",
            )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )
```

#### 2.2 Google Play Receipt Verification

```python
# backend/app/routes/subscriptions.py

from app.services.google_play_service import GooglePlayService

class GooglePlayReceiptRequest(BaseModel):
    userId: str
    packageName: str
    productId: str
    purchaseToken: str

@router.post("/api/subscriptions/verify-receipt-google")
async def verify_google_play_receipt(request: GooglePlayReceiptRequest):
    try:
        google_play_service = GooglePlayService()
        
        # Google Play Billing API で Receipt を検証
        result = await google_play_service.verify_subscription(
            package_name=request.packageName,
            subscription_id=request.productId,
            token=request.purchaseToken,
        )
        
        if result.get("valid"):
            # Firestore に購入情報を記録
            purchase_time = result.get("purchase_time")
            expiry_time = result.get("expiry_time")
            
            # Update user subscription in Firestore
            # ... implementation ...
            
            return {
                "success": True,
                "purchase_time": purchase_time,
                "expiry_time": expiry_time,
            }
        else:
            raise HTTPException(
                status_code=400,
                detail="Invalid purchase token",
            )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )
```

## サービス実装例

### 3.1 Apple App Store Service

```python
# backend/app/services/app_store_service.py

import httpx
import jwt
from datetime import datetime, timedelta
import os

class AppStoreService:
    """Apple App Store Server API との連携"""
    
    def __init__(self):
        self.bundle_id = os.getenv("APPLE_BUNDLE_ID")
        self.key_id = os.getenv("APPLE_KEY_ID")
        self.issuer_id = os.getenv("APPLE_ISSUER_ID")
        self.private_key_path = os.getenv("APPLE_PRIVATE_KEY_PATH")
    
    def _generate_jwt_token(self) -> str:
        """App Store Server API 用の JWT トークンを生成"""
        with open(self.private_key_path, "r") as f:
            private_key = f.read()
        
        now = datetime.utcnow()
        payload = {
            "iss": self.issuer_id,
            "iat": int(now.timestamp()),
            "exp": int((now + timedelta(minutes=5)).timestamp()),
            "aud": "appstoreconnect-v1",
        }
        
        token = jwt.encode(
            payload,
            private_key,
            algorithm="ES256",
            headers={"kid": self.key_id},
        )
        return token
    
    async def verify_receipt(self, receipt_data: str) -> dict:
        """Receipt を検証し、購入情報を取得"""
        token = self._generate_jwt_token()
        
        # App Store Server API エンドポイント
        url = (
            f"https://api.storekit.itunes.apple.com/inApps/v1/"
            f"subscriptions/validate"
        )
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/x-www-form-urlencoded",
        }
        
        data = {
            "receipt-data": receipt_data,
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                url,
                headers=headers,
                data=data,
            )
        
        if response.status_code == 200:
            result = response.json()
            
            # Receipt 内の情報を抽出
            if result.get("status") == 0:  # 0 = valid
                receipt = result.get("receipt", {})
                latest_receipt_info = result.get(
                    "latest_receipt_info",
                    [{}],
                )[0]
                
                return {
                    "valid": True,
                    "transaction_id": latest_receipt_info.get(
                        "original_transaction_id"
                    ),
                    "product_id": latest_receipt_info.get("product_id"),
                    "purchase_date": latest_receipt_info.get(
                        "purchase_date_ms"
                    ),
                    "expiry_date": latest_receipt_info.get(
                        "expires_date_ms"
                    ),
                }
            else:
                return {"valid": False, "status": result.get("status")}
        
        return {"valid": False, "status": response.status_code}
```

### 3.2 Google Play Service

```python
# backend/app/services/google_play_service.py

import httpx
from google.oauth2.service_account import Credentials
import os

class GooglePlayService:
    """Google Play Billing API との連携"""
    
    def __init__(self):
        self.package_name = os.getenv("GOOGLE_PLAY_PACKAGE_NAME")
        self.service_account_json_path = os.getenv(
            "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH"
        )
    
    def _get_access_token(self) -> str:
        """Google Play API 用のアクセストークンを取得"""
        credentials = Credentials.from_service_account_file(
            self.service_account_json_path,
            scopes=["https://www.googleapis.com/auth/androidpublisher"],
        )
        
        return credentials.token
    
    async def verify_subscription(
        self,
        package_name: str,
        subscription_id: str,
        token: str,
    ) -> dict:
        """Google Play のサブスクリプション購入を検証"""
        access_token = self._get_access_token()
        
        url = (
            f"https://androidpublisher.googleapis.com/androidpublisher/v3/"
            f"applications/{package_name}/subscriptions/{subscription_id}/"
            f"tokens/{token}"
        )
        
        headers = {
            "Authorization": f"Bearer {access_token}",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            
            return {
                "valid": True,
                "order_id": data.get("orderId"),
                "package_name": data.get("packageName"),
                "subscription_id": data.get("subscriptionId"),
                "purchase_time": data.get("startTimeMillis"),
                "expiry_time": data.get("expiryTimeMillis"),
                "auto_renewing": data.get("autoRenewing"),
            }
        
        return {"valid": False, "status": response.status_code}
```

## Firestore への記録

### 4.1 購入情報の保存

```python
# backend/app/routes/subscriptions.py

from firebase_admin import firestore

async def save_subscription(
    user_id: str,
    plan_type: str,  # 'monthly' or 'yearly'
    transaction_id: str,
    product_id: str,
    purchase_time: int,  # milliseconds
    expiry_time: int,  # milliseconds
):
    """Firestore にサブスクリプション情報を保存"""
    db = firestore.client()
    
    subscription_data = {
        "status": "active",
        "plan": plan_type,
        "planType": plan_type,
        "subscriptionStartDate": firestore.SERVER_TIMESTAMP,
        "subscriptionEndDate": datetime.fromtimestamp(
            expiry_time / 1000
        ),
        "lastPaymentDate": datetime.fromtimestamp(
            purchase_time / 1000
        ),
        "autoRenewalEnabled": True,
        "transactionId": transaction_id,
        "productId": product_id,
    }
    
    db.collection("users").document(user_id).collection(
        "subscription"
    ).document("info").set(subscription_data, merge=True)
```

## セキュリティ考慮事項

### 5.1 Receipt の署名検証

Receipt は必ずサーバー側で検証してください：

```python
# ❌ 悪い例：クライアント側で検証
// Flutter
if (purchaseDetails.status == PurchaseStatus.purchased) {
    // Receipt をクライアントで信頼 - セキュリティリスク
    await _subscriptionService.activateSubscription(...);
}

# ✅ 良い例：サーバー側で検証
// Flutter
if (purchaseDetails.status == PurchaseStatus.purchased) {
    // サーバーに Receipt を送信
    bool verified = await _api.verifyReceipt(receipt);
    if (verified) {
        // Firestore から最新の購読情報を取得
    }
}
```

### 5.2 トランザクション ID の重複チェック

同じトランザクション ID が複数回処理されないようにチェック：

```python
@router.post("/api/subscriptions/verify-receipt-apple")
async def verify_apple_receipt(request: AppleReceiptRequest):
    db = firestore.client()
    
    # 同じ transaction_id が既に処理されていないか確認
    existing = db.collection("subscription_transactions").document(
        transaction_id
    ).get()
    
    if existing.exists:
        return {"success": False, "reason": "duplicate_transaction"}
    
    # Receipt を検証
    result = await app_store_service.verify_receipt(...)
    
    if result["valid"]:
        # トランザクション記録を作成
        db.collection("subscription_transactions").document(
            transaction_id
        ).set({
            "user_id": user_id,
            "verified_at": firestore.SERVER_TIMESTAMP,
            "product_id": result["product_id"],
        })
```

### 5.3 API 認証

サーバー側の API エンドポイントは Firebase Authentication で保護：

```python
from firebase_admin import auth

@router.post("/api/subscriptions/verify-receipt-apple")
async def verify_apple_receipt(
    request: AppleReceiptRequest,
    token: str = Header(...)  # Firebase ID Token
):
    try:
        # Firebase ID Token を検証
        decoded = auth.verify_id_token(token)
        user_id = decoded["uid"]
        
        # ユーザー ID がリクエストの user_id と一致するか確認
        if user_id != request.userId:
            raise HTTPException(
                status_code=403,
                detail="Unauthorized",
            )
        
        # ... rest of implementation ...
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=401,
            detail="Invalid token",
        )
```

## エラーハンドリング

### 6.1 一般的なエラー

```python
class ReceiptVerificationError(Exception):
    """Receipt 検証エラーの基底クラス"""
    pass

class InvalidReceiptError(ReceiptVerificationError):
    """無効な Receipt"""
    pass

class ExpiredReceiptError(ReceiptVerificationError):
    """期限切れの Receipt"""
    pass

class DuplicateTransactionError(ReceiptVerificationError):
    """重複するトランザクション"""
    pass

@router.post("/api/subscriptions/verify-receipt-apple")
async def verify_apple_receipt(request: AppleReceiptRequest):
    try:
        result = await app_store_service.verify_receipt(...)
        
        if not result.get("valid"):
            raise InvalidReceiptError("Receipt validation failed")
        
        # ... save to Firestore ...
        
    except InvalidReceiptError as e:
        logger.error(f"Invalid receipt: {e}")
        raise HTTPException(status_code=400, detail="Invalid receipt")
    
    except ExpiredReceiptError as e:
        logger.error(f"Expired receipt: {e}")
        raise HTTPException(status_code=400, detail="Expired receipt")
    
    except DuplicateTransactionError as e:
        logger.warning(f"Duplicate transaction: {e}")
        return {"success": True, "status": "duplicate"}  # Idempotent
    
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
```

## 監視とログ

### 7.1 ログ記録

```python
import logging

logger = logging.getLogger(__name__)

@router.post("/api/subscriptions/verify-receipt-apple")
async def verify_apple_receipt(request: AppleReceiptRequest):
    logger.info(
        f"Verifying Apple receipt",
        extra={
            "user_id": request.userId,
            "receipt_length": len(request.receipt),
        }
    )
    
    try:
        result = await app_store_service.verify_receipt(...)
        logger.info(
            f"Receipt verified successfully",
            extra={
                "user_id": request.userId,
                "transaction_id": result.get("transaction_id"),
                "product_id": result.get("product_id"),
            }
        )
    except Exception as e:
        logger.error(
            f"Receipt verification failed",
            extra={
                "user_id": request.userId,
                "error": str(e),
            }
        )
```

### 7.2 監視メトリクス

Google Cloud Monitoring で以下を監視：

```python
from google.cloud import monitoring_v3

# Receipt 検証成功率
# Receipt 検証処理時間
# サブスクリプション購入数
# サブスクリプション更新数
```

## 参考資料

- [App Store Server API Documentation](https://developer.apple.com/documentation/appstoreserverapi)
- [Google Play Billing Library Documentation](https://developer.android.com/google/play/billing)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
