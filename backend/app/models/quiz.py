import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, Boolean, Text, ForeignKey, Float
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class QuizSession(Base):
    """クイズセッション (ストーリー1回分の学習)"""
    __tablename__ = "quiz_sessions"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    child_id = Column(UUIDType(binary=False), ForeignKey("children.id", ondelete="CASCADE"), nullable=False)
    story_id = Column(UUIDType(binary=False), ForeignKey("stories.id", ondelete="SET NULL"), nullable=True)
    chosen_choice_id = Column(UUIDType(binary=False), nullable=True)  # 最終選択
    points_earned = Column(Integer, default=0)
    time_spent_seconds = Column(Integer, default=0)
    is_completed = Column(Boolean, default=False)
    reflection_text = Column(Text, nullable=True)   # 振り返りメモ
    started_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    child = relationship("Child", back_populates="quiz_sessions")
    story = relationship("Story", back_populates="quiz_sessions")
    answers = relationship("QuizAnswer", back_populates="session", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<QuizSession id={self.id} child_id={self.child_id}>"


class QuizAnswer(Base):
    """クイズ個別回答"""
    __tablename__ = "quiz_answers"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUIDType(binary=False), ForeignKey("quiz_sessions.id", ondelete="CASCADE"), nullable=False)
    question_text = Column(Text, nullable=False)
    selected_choice_id = Column(UUIDType(binary=False), nullable=True)
    selected_choice_text = Column(Text, nullable=True)
    is_correct = Column(Boolean, nullable=True)     # 明確な正解がある場合
    answered_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    session = relationship("QuizSession", back_populates="answers")
