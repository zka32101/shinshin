import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class Purchase(Base):
    """課金購入・購読の検証記録（Google Play / App Store）

    transaction_id はプロバイダ側の一意な取引識別子で、
    Google Playの場合は purchaseToken、App Storeの場合は transactionId を格納する。
    同一取引の再送（リトライ・復元購入）に対する冪等性の担保に使う。
    """

    __tablename__ = "purchases"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(
        UUIDType(binary=False), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    platform = Column(String(20), nullable=False)  # 'google_play' | 'app_store'
    product_id = Column(String(255), nullable=False)
    plan_type = Column(String(20), nullable=False)  # 'monthly' | 'yearly'
    transaction_id = Column(String(255), unique=True, nullable=False, index=True)
    status = Column(String(20), default="verified", nullable=False)  # verified | expired | revoked
    verified_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    expires_at = Column(DateTime, nullable=True)
    # 検証時のプロバイダ生レスポンス（監査・デバッグ用にJSON文字列で保持）
    raw_response = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="purchases")

    def __repr__(self) -> str:
        return f"<Purchase id={self.id} platform={self.platform} product={self.product_id}>"
