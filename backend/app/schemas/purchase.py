from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict
from pydantic.alias_generators import to_camel


class GooglePlayVerifyRequest(BaseModel):
    """Google Play購読の検証リクエスト"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    product_id: str = Field(..., min_length=1, description="Google Playの商品ID（購読ID）")
    purchase_token: str = Field(..., min_length=1, description="購入トークン")
    package_name: Optional[str] = Field(
        None, description="パッケージ名（未指定時はサーバー設定値を使用）"
    )


class AppleVerifyRequest(BaseModel):
    """App Store購読の検証リクエスト"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    product_id: str = Field(..., min_length=1, description="App Storeの商品ID")
    transaction_id: str = Field(..., min_length=1, description="StoreKit2のトランザクションID")


class PurchaseVerifyResponse(BaseModel):
    """購入検証の応答スキーマ"""
    model_config = ConfigDict(from_attributes=True, alias_generator=to_camel, populate_by_name=True)

    verified: bool
    is_premium: bool
    plan_type: str
    expires_at: Optional[datetime] = None
    transaction_id: str
    platform: str


class PurchaseStatusResponse(BaseModel):
    """現在のプレミアム状態の応答スキーマ"""
    model_config = ConfigDict(from_attributes=True, alias_generator=to_camel, populate_by_name=True)

    is_premium: bool
    plan_type: Optional[str] = None
    expires_at: Optional[datetime] = None
