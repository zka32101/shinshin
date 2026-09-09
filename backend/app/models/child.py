import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, Float, Boolean
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class Child(Base):
    """子供プロフィール"""
    __tablename__ = "children"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    parent_id = Column(UUIDType(binary=False), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(50), nullable=False)
    avatar_emoji = Column(String(10), default="🌟", nullable=False)
    grade = Column(Integer, nullable=False)  # 3 or 4 (小学3-4年生)
    level = Column(Integer, default=1, nullable=False)
    # ランキングで実名を公表するか（COPPA対応: デフォルトは非公表＝匿名）
    is_name_public = Column(Boolean, default=False, server_default="false", nullable=False)
    # 友だち追加用の招待コード（8文字の英数字、ユニーク）
    invite_code = Column(String(16), unique=True, nullable=True, index=True)
    total_points = Column(Integer, default=0, nullable=False)
    # 徳目スコア (moral virtue scores 0-100)
    kindness_score = Column(Float, default=50.0)      # 思いやり
    honesty_score = Column(Float, default=50.0)       # 正直さ
    responsibility_score = Column(Float, default=50.0) # 責任感
    courage_score = Column(Float, default=50.0)       # 勇気
    respect_score = Column(Float, default=50.0)       # 礼儀
    cooperation_score = Column(Float, default=50.0)   # 協調性
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    parent = relationship("User", back_populates="children")
    quiz_sessions = relationship("QuizSession", back_populates="child", cascade="all, delete-orphan")
    progress_records = relationship("Progress", back_populates="child", cascade="all, delete-orphan")
    monthly_reports = relationship("MonthlyReport", back_populates="child", cascade="all, delete-orphan")
    rankings = relationship("Ranking", back_populates="child", cascade="all, delete-orphan")
    friends = relationship(
        "Friend",
        foreign_keys="Friend.child_id",
        back_populates="child",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<Child id={self.id} name={self.name} grade={self.grade}>"
