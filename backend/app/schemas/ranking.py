from datetime import date, datetime
from uuid import UUID
from typing import List, Literal
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class RankingBase(BaseModel):
    """ランキング基本スキーマ"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    child_id: UUID
    ranking_month: date
    group_type: Literal["overall", "by_grade", "by_start_month", "combined", "friends"]
    group_value: str | None = None
    rank: int
    total_answers: int
    total_growth_score: int


class RankingCreate(RankingBase):
    """ランキング作成スキーマ"""
    pass


class RankingResponse(RankingBase):
    """ランキング応答スキーマ"""
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID


class RankingDetailResponse(BaseModel):
    """ランキング詳細応答（子ども情報を含む）"""
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    rank: int
    child_id: UUID
    child_name: str
    avatar_emoji: str
    total_answers: int
    total_growth_score: int
    # フロントエンド (lib/models/ranking.dart の RankingEntry) が必須フィールドとして
    # 要求しているため、常に値を返す（自分の子どものランキングの場合は現在時刻でも可）
    updated_at: datetime
    # フロントエンドの RankingEntry.getDisplayName() が参照する。
    # child_name は既にこの値に基づいてサーバー側で匿名化済み。
    is_name_public: bool = False


class RankingListResponse(BaseModel):
    """ランキング一覧応答スキーマ"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    ranking_month: date
    group_type: Literal["overall", "by_grade", "by_start_month", "combined", "friends"]
    group_value: str | None = None
    rankings: List[RankingDetailResponse]
