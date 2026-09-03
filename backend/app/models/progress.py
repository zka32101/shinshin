import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class Progress(Base):
    """学習進捗記録"""
    __tablename__ = "progress"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    child_id = Column(UUIDType(binary=False), ForeignKey("children.id", ondelete="CASCADE"), nullable=False)
    story_id = Column(UUIDType(binary=False), nullable=True)
    action = Column(String(50), nullable=False)   # story_completed / quiz_answered / badge_earned
    detail = Column(String(255), nullable=True)
    points_delta = Column(Integer, default=0)
    recorded_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    child = relationship("Child", back_populates="progress_records")
