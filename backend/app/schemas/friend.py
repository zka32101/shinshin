from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, Field, ConfigDict, field_validator
from pydantic.alias_generators import to_camel


class FriendAddRequest(BaseModel):
    """招待コードで友だちを追加するリクエスト"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    child_id: UUID = Field(..., description="友だちを追加する側の子どもID")
    invite_code: str = Field(..., min_length=1, max_length=16, description="相手の招待コード")

    @field_validator('invite_code')
    @classmethod
    def normalize_code(cls, v: str) -> str:
        return v.strip().upper()


class FriendResponse(BaseModel):
    """友だち一覧の1件分の応答スキーマ"""
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    friend_id: UUID  # friends.id (関係レコードのID。削除時に使用)
    child_id: UUID  # 友だち側の子どもID
    name: str
    avatar_emoji: str
    grade: int
    level: int
    created_at: datetime
