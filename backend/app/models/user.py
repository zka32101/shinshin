import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class User(Base):
    """保護者ユーザー"""
    __tablename__ = "users"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    firebase_uid = Column(String(128), unique=True, index=True, nullable=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    password_hash = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    fcm_token = Column(String(512), nullable=True)  # Firebase Cloud Messaging token
    # プレミアム課金状態（検証済みのGoogle Play購読/App Store購読を反映）。
    # 購入はアカウント（保護者）単位で行われるため、全ての子どもプロフィールに適用される。
    is_premium = Column(Boolean, default=False, server_default="false", nullable=False)
    premium_plan = Column(String(20), nullable=True)  # 'monthly' | 'yearly'
    premium_expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    children = relationship("Child", back_populates="parent", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    purchases = relationship("Purchase", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email}>"
