import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, Float, ForeignKey, Text, JSON
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class MonthlyReport(Base):
    """月次成長レポート (保護者向け)"""
    __tablename__ = "monthly_reports"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    child_id = Column(UUIDType(binary=False), ForeignKey("children.id", ondelete="CASCADE"), nullable=False)
    year = Column(Integer, nullable=False)
    month = Column(Integer, nullable=False)

    # 学習統計
    stories_completed = Column(Integer, default=0)
    total_study_minutes = Column(Integer, default=0)
    total_points_earned = Column(Integer, default=0)

    # 徳目スコア (月次スナップショット)
    kindness_score = Column(Float, default=50.0)
    honesty_score = Column(Float, default=50.0)
    responsibility_score = Column(Float, default=50.0)
    courage_score = Column(Float, default=50.0)
    respect_score = Column(Float, default=50.0)
    cooperation_score = Column(Float, default=50.0)

    # AI生成コメント
    highlight_comment = Column(Text, nullable=True)     # 今月の頑張り
    growth_comment = Column(Text, nullable=True)        # 成長ポイント
    advice_comment = Column(Text, nullable=True)        # 来月へのアドバイス
    parent_message = Column(Text, nullable=True)        # 保護者へのメッセージ

    # テーマ別詳細 (JSON)
    theme_breakdown = Column(JSON, nullable=True)  # {"kindness": {"count": 3, "avg_score": 75}, ...}

    generated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    child = relationship("Child", back_populates="monthly_reports")

    def __repr__(self) -> str:
        return f"<MonthlyReport child={self.child_id} {self.year}/{self.month}>"
