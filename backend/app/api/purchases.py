"""
課金レシート検証 API エンドポイント

クライアント（Flutterアプリ）は in_app_purchase での購入完了後、
購入トークン/トランザクションIDをここに送信する。バックエンドが
Google Play Developer API / App Store Server API を使って実際に
検証してから、ユーザー（保護者アカウント）のプレミアムフラグを更新する。

購入はアカウント（保護者）単位で行われるものであり、特定の子ども
プロフィールに紐づくものではないため、認証済みユーザー本人の
User レコードを更新する（= 全ての子どもプロフィールがプレミアム対象になる）。
"""

import json
from datetime import datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.database import get_db
from app.config import get_settings, Settings
from app.models.user import User
from app.models.purchase import Purchase
from app.schemas.purchase import (
    GooglePlayVerifyRequest,
    AppleVerifyRequest,
    PurchaseVerifyResponse,
    PurchaseStatusResponse,
)
from app.security import get_current_user_id
from app.services.receipt_verification import (
    GooglePlayVerifier,
    AppleVerifier,
    ReceiptVerificationError,
    ms_to_datetime,
)

router = APIRouter()

# 商品IDの末尾からプラン種別を判定する（モデルに合わせてmonthly/yearlyの2種類のみ対応）
_PLAN_SUFFIXES = ("monthly", "yearly")


def _resolve_plan_type(product_id: str) -> str:
    for suffix in _PLAN_SUFFIXES:
        if product_id.endswith(suffix):
            return suffix
    raise HTTPException(status_code=400, detail=f"不明な商品IDです: {product_id}")


async def _get_user(db: AsyncSession, user_id: str) -> User:
    result = await db.execute(select(User).where(User.id == UUID(user_id)))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="ユーザーが見つかりません")
    return user


async def _finalize_purchase(
    db: AsyncSession,
    *,
    user: User,
    platform: str,
    product_id: str,
    plan_type: str,
    transaction_id: str,
    expires_at: datetime,
    raw_response: dict,
) -> Purchase:
    """検証済みの購入を記録し、ユーザーのプレミアムフラグを更新する。

    同一 transaction_id の購入が既に存在する場合は上書き更新する（冪等）。
    別ユーザーの取引IDと衝突した場合は 409 を返す（なりすまし対策）。
    """
    existing_result = await db.execute(
        select(Purchase).where(Purchase.transaction_id == transaction_id)
    )
    purchase = existing_result.scalar_one_or_none()

    if purchase and purchase.user_id != user.id:
        raise HTTPException(status_code=409, detail="この購入は別のユーザーに紐づいています")

    raw_json = json.dumps(raw_response, ensure_ascii=False, default=str)

    if purchase:
        purchase.status = "verified"
        purchase.expires_at = expires_at
        purchase.verified_at = datetime.utcnow()
        purchase.raw_response = raw_json
        purchase.plan_type = plan_type
    else:
        purchase = Purchase(
            id=uuid4(),
            user_id=user.id,
            platform=platform,
            product_id=product_id,
            plan_type=plan_type,
            transaction_id=transaction_id,
            status="verified",
            verified_at=datetime.utcnow(),
            expires_at=expires_at,
            raw_response=raw_json,
        )
        db.add(purchase)

    user.is_premium = True
    user.premium_plan = plan_type
    user.premium_expires_at = expires_at

    await db.flush()
    await db.refresh(purchase)
    await db.commit()
    return purchase


@router.post("/verify/google", response_model=PurchaseVerifyResponse, response_model_by_alias=True)
async def verify_google_play_purchase(
    body: GooglePlayVerifyRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
):
    """Google Play購読の購入トークンを検証し、プレミアムを有効化する"""
    user = await _get_user(db, user_id)
    plan_type = _resolve_plan_type(body.product_id)

    package_name = body.package_name or settings.google_play_package_name
    if not package_name:
        raise HTTPException(status_code=400, detail="packageNameが指定されていません")

    verifier = GooglePlayVerifier(settings)
    try:
        result = await verifier.verify_subscription(
            package_name=package_name,
            subscription_id=body.product_id,
            purchase_token=body.purchase_token,
        )
    except ReceiptVerificationError as e:
        raise HTTPException(status_code=502 if e.retryable else 400, detail=str(e))

    payment_state = result.get("paymentState")
    expiry_ms = result.get("expiryTimeMillis")

    # paymentState: 0=支払い保留, 1=支払い完了, 2=無料トライアル中, 3=保留支払い(延期)
    if payment_state not in (1, 2) or not expiry_ms:
        raise HTTPException(status_code=400, detail="有効な購読ではありません（未払い/キャンセル済み）")

    expires_at = ms_to_datetime(expiry_ms)
    if expires_at <= datetime.utcnow():
        raise HTTPException(status_code=400, detail="購読の有効期限が切れています")

    purchase = await _finalize_purchase(
        db,
        user=user,
        platform="google_play",
        product_id=body.product_id,
        plan_type=plan_type,
        transaction_id=body.purchase_token,
        expires_at=expires_at,
        raw_response=result,
    )

    return PurchaseVerifyResponse(
        verified=True,
        is_premium=True,
        plan_type=purchase.plan_type,
        expires_at=purchase.expires_at,
        transaction_id=purchase.transaction_id,
        platform=purchase.platform,
    )


@router.post("/verify/apple", response_model=PurchaseVerifyResponse, response_model_by_alias=True)
async def verify_apple_purchase(
    body: AppleVerifyRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
    settings: Settings = Depends(get_settings),
):
    """App Storeのトランザクションを検証し、プレミアムを有効化する"""
    user = await _get_user(db, user_id)
    plan_type = _resolve_plan_type(body.product_id)

    verifier = AppleVerifier(settings)
    try:
        claims = await verifier.verify_transaction(transaction_id=body.transaction_id)
    except ReceiptVerificationError as e:
        raise HTTPException(status_code=502 if e.retryable else 400, detail=str(e))

    if claims.get("revocationDate"):
        raise HTTPException(status_code=400, detail="この購入は返金/取り消し済みです")

    claim_product_id = claims.get("productId")
    if claim_product_id and claim_product_id != body.product_id:
        raise HTTPException(status_code=400, detail="商品IDが一致しません")

    expires_date_ms = claims.get("expiresDate")
    if not expires_date_ms:
        raise HTTPException(status_code=400, detail="有効期限情報が取得できませんでした")

    expires_at = ms_to_datetime(expires_date_ms)
    if expires_at <= datetime.utcnow():
        raise HTTPException(status_code=400, detail="購読の有効期限が切れています")

    transaction_id = claims.get("transactionId") or body.transaction_id

    purchase = await _finalize_purchase(
        db,
        user=user,
        platform="app_store",
        product_id=body.product_id,
        plan_type=plan_type,
        transaction_id=transaction_id,
        expires_at=expires_at,
        raw_response=claims,
    )

    return PurchaseVerifyResponse(
        verified=True,
        is_premium=True,
        plan_type=purchase.plan_type,
        expires_at=purchase.expires_at,
        transaction_id=purchase.transaction_id,
        platform=purchase.platform,
    )


@router.get("/status", response_model=PurchaseStatusResponse, response_model_by_alias=True)
async def get_purchase_status(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """現在のプレミアム状態を取得する"""
    user = await _get_user(db, user_id)
    is_active = bool(
        user.is_premium and user.premium_expires_at and user.premium_expires_at > datetime.utcnow()
    )
    return PurchaseStatusResponse(
        is_premium=is_active,
        plan_type=user.premium_plan if is_active else None,
        expires_at=user.premium_expires_at,
    )
