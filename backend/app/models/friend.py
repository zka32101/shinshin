import uuid
from datetime import datetime
from sqlalchemy import Column, DateTime, ForeignKey, UniqueConstraint, CheckConstraint
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class Friend(Base):
    """友だち関係（片方向レコード。相互に見せたい場合は追加時に双方向レコードを作成する）"""
    __tablename__ = "friends"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    child_id = Column(UUIDType(binary=False), ForeignKey("children.id", ondelete="CASCADE"), nullable=False, index=True)
    friend_child_id = Column(UUIDType(binary=False), ForeignKey("children.id", ondelete="CASCADE"), nullable=False, index=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    child = relationship("Child", foreign_keys=[child_id], back_populates="friends")
    friend_child = relationship("Child", foreign_keys=[friend_child_id])

    __table_args__ = (
        UniqueConstraint('child_id', 'friend_child_id', name='uq_friend_pair'),
        CheckConstraint('child_id != friend_child_id', name='ck_friend_not_self'),
    )

    def __repr__(self) -> str:
        return f"<Friend child_id={self.child_id} friend_child_id={self.friend_child_id}>"
