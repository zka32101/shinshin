from pydantic import BaseModel
from datetime import date
from uuid import UUID
from typing import List, Literal


class RankingBase(BaseModel):
    """ランキング基本スキーマ"""
    child_id: UUID
    ranking_month: date
    group_type: Literal["overall", "by_grade", "by_start_month", "combined"]
    group_value: str | None = None
    rank: int
    total_answers: int
    total_growth_score: int


class RankingCreate(RankingBase):
    """ランキング作成スキーマ"""
    pass


class RankingResponse(RankingBase):
    """ランキング応答スキーマ"""
    id: UUID

    class Config:
        from_attributes = True


class RankingDetailResponse(BaseModel):
    """ランキング詳細応答（子ども情報を含む）"""
    rank: int
    child_id: UUID
    child_name: str
    avatar_emoji: str
    total_answers: int
    total_growth_score: int

    class Config:
        from_attributes = True


class RankingListResponse(BaseModel):
    """ランキング一覧応答スキーマ"""
    ranking_month: date
    group_type: Literal["overall", "by_grade", "by_start_month", "combined"]
    group_value: str | None = None
    rankings: List[RankingDetailResponse]
