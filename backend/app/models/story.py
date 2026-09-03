import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, Boolean, Text, ForeignKey, JSON
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class Story(Base):
    """道徳ストーリー"""
    __tablename__ = "stories"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)

    # ストーリー本文 — JSON形式で構造化
    # {
    #   "introduction": str,
    #   "mainNarrative": [str, ...],
    #   "dilemmaScene": str,
    #   "illustrationUrl": str | null
    # }
    content = Column(JSON, nullable=False, default=dict)

    theme = Column(String(50), nullable=False)   # 徳目テーマ (kindness/honesty/etc)
    grade_min = Column(Integer, default=3)       # 対象学年 (3-4年生)
    grade_max = Column(Integer, default=4)
    difficulty = Column(Integer, default=1)      # 難易度 1-3
    is_premium = Column(Boolean, default=False)
    is_published = Column(Boolean, default=True)
    emoji = Column(String(10), default="📖")
    audio_url = Column(String(512), nullable=True)   # 音声ナレーションURL
    image_url = Column(String(512), nullable=True)
    estimated_minutes = Column(Integer, default=5)
    week_number = Column(Integer, nullable=True)     # 週番号 (weekly theme)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    choices = relationship("StoryChoice", back_populates="story", cascade="all, delete-orphan", order_by="StoryChoice.order")
    quiz_sessions = relationship("QuizSession", back_populates="story")

    def __repr__(self) -> str:
        return f"<Story id={self.id} title={self.title}>"


class StoryChoice(Base):
    """ストーリー選択肢"""
    __tablename__ = "story_choices"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4)
    story_id = Column(UUIDType(binary=False), ForeignKey("stories.id", ondelete="CASCADE"), nullable=False)
    order = Column(Integer, nullable=False)             # 表示順
    text = Column(Text, nullable=False)                 # 選択肢テキスト
    branch_content = Column(Text, nullable=False, default="")  # 選択後の展開テキスト (旧: outcome_text)
    reflection = Column(Text, nullable=False, default="")      # 振り返り (親向けコメント)
    value = Column(String(50), nullable=True)           # 関わる徳目 (kindness/honesty/etc) (旧: virtue_type)
    points = Column(Integer, default=10)                # 獲得ポイント
    is_recommended = Column(Boolean, default=False)     # 推奨選択肢かどうか
    score_impact = Column(JSON, nullable=True)          # 各徳目スコアへの影響 {"kindness": 5, ...}

    # Relationships
    story = relationship("Story", back_populates="choices")

    def __repr__(self) -> str:
        return f"<StoryChoice id={self.id} story_id={self.story_id}>"
