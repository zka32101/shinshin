import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, Date, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base import Base


class Ranking(Base):
    """月間ランキング記録"""
    __tablename__ = "rankings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    child_id = Column(UUID(as_uuid=True), ForeignKey("children.id", ondelete="CASCADE"), nullable=False, index=True)
    ranking_month = Column(Date, nullable=False, index=True)  # ランキング対象月 (2026-09-01 など)

    # グループ化タイプ: "overall", "by_grade", "by_start_month", "combined"
    group_type = Column(String(50), nullable=False, index=True)
    group_value = Column(String(100), nullable=True)  # グループの値 (例: "4", "2026-01", "4_2026-01")

    # ランキング統計
    rank = Column(Integer, nullable=False)  # 1, 2, 3...
    total_answers = Column(Integer, default=0)  # 回答総数
    total_growth_score = Column(Integer, default=0)  # 成長スコア (points合計)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    child = relationship("Child", foreign_keys=[child_id], back_populates="rankings")

    # インデックス: 月ごと、グループごとの検索を高速化
    __table_args__ = (
        Index('ix_ranking_month_group', 'ranking_month', 'group_type', 'group_value'),
    )

    def __repr__(self) -> str:
        return f"<Ranking child_id={self.child_id} month={self.ranking_month} rank={self.rank}>"
