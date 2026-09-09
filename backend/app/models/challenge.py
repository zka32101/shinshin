import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, CheckConstraint
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class DilemmaChallenge(Base):
    """協力ジレンマチャレンジ（勝敗なし・非同期）

    友だちを指名し、同じストーリーの選択肢をそれぞれ選んで後で結果を比較する機能。
    現時点では非同期（後から結果を見る）のみをサポートする。
    将来リアルタイム対戦を追加する場合は status に "active"（両者オンラインで進行中）等を
    拡張する想定で、モデル自体はそのまま流用できるようにしてある。
    """
    __tablename__ = "dilemma_challenges"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    story_id = Column(UUIDType(binary=False), ForeignKey("stories.id", ondelete="CASCADE"), nullable=False, index=True)

    initiator_child_id = Column(
        UUIDType(binary=False), ForeignKey("children.id", ondelete="CASCADE"), nullable=False, index=True
    )
    invitee_child_id = Column(
        UUIDType(binary=False), ForeignKey("children.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # pending: 招待済み・相手未回答 / completed: 双方回答済み
    # (将来のリアルタイム拡張用に "active"（進行中）, "expired"（期限切れ）も予約)
    status = Column(String(20), default="pending", nullable=False)

    initiator_choice_id = Column(UUIDType(binary=False), ForeignKey("story_choices.id"), nullable=True)
    invitee_choice_id = Column(UUIDType(binary=False), ForeignKey("story_choices.id"), nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    story = relationship("Story")
    initiator_child = relationship("Child", foreign_keys=[initiator_child_id])
    invitee_child = relationship("Child", foreign_keys=[invitee_child_id])
    initiator_choice = relationship("StoryChoice", foreign_keys=[initiator_choice_id])
    invitee_choice = relationship("StoryChoice", foreign_keys=[invitee_choice_id])

    __table_args__ = (
        CheckConstraint('initiator_child_id != invitee_child_id', name='ck_challenge_not_self'),
    )

    def __repr__(self) -> str:
        return f"<DilemmaChallenge id={self.id} status={self.status}>"
