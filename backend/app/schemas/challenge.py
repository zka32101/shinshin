from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel


class ChallengeCreateRequest(BaseModel):
    """協力ジレンマチャレンジの作成リクエスト（招待する側が作成する）"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    child_id: UUID = Field(..., description="招待する側（自分）の子どもID")
    friend_child_id: UUID = Field(..., description="招待される側（友だち）の子どもID")
    story_id: UUID = Field(..., description="対象のストーリーID")
    choice_id: Optional[UUID] = Field(
        default=None, description="招待する側が既に選んだ選択肢ID（未回答なら省略可）"
    )


class ChallengeRespondRequest(BaseModel):
    """チャレンジへの回答リクエスト（招待した側・された側どちらも使用可）"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    child_id: UUID = Field(..., description="回答する側の子どもID")
    choice_id: UUID = Field(..., description="選んだ選択肢ID")


class ChallengeParticipantResponse(BaseModel):
    """チャレンジ参加者（子ども）の最小限の情報"""
    model_config = ConfigDict(from_attributes=True, alias_generator=to_camel, populate_by_name=True)

    child_id: UUID
    name: str
    avatar_emoji: str


class ChallengeResponse(BaseModel):
    """協力ジレンマチャレンジの応答スキーマ

    双方が回答済み（status=completed）になるまでは、相手の選択肢ID
    （opponent_choice_id 相当の情報）は含めない＝先出し情報で影響されないようにする。
    """
    model_config = ConfigDict(from_attributes=True, alias_generator=to_camel, populate_by_name=True)

    id: UUID
    story_id: UUID
    status: str

    initiator_child_id: UUID
    invitee_child_id: UUID

    # 自分自身の選択は常に見える／相手の選択は completed になるまで null
    initiator_choice_id: Optional[UUID] = None
    invitee_choice_id: Optional[UUID] = None

    created_at: datetime
    completed_at: Optional[datetime] = None
