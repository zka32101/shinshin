"""
ランキング API エンドポイント
"""

from uuid import UUID
from typing import List, Literal, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.db.database import get_db
from app.models.ranking import Ranking
from app.models.child import Child
from app.schemas.ranking import RankingListResponse, RankingDetailResponse
from app.security import get_current_user_id
from app.services.ranking_service import RankingService

router = APIRouter(tags=["rankings"])

# フロントエンド (lib/models/ranking.dart の getDisplayName()) と同じ匿名表示名
ANONYMOUS_DISPLAY_NAME = "ユーザー"


def _display_name(child: Child) -> str:
    """isNamePublic 設定に従い、公開可能な表示名を返す（COPPA対応）"""
    return child.name if child.is_name_public else ANONYMOUS_DISPLAY_NAME


@router.get(
    "/month/{ranking_month}",
    response_model=RankingListResponse,
    response_model_by_alias=True,
)
async def get_monthly_ranking(
    ranking_month: str,
    group_type: Literal["overall", "by_grade", "by_start_month", "combined", "friends"] = Query(
        "overall", description="グループ化タイプ"
    ),
    group_value: Optional[str] = Query(
        None, description="グループ値（該当する場合）"
    ),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    指定月のランキングを取得

    Args:
        ranking_month: ランキング対象月 (例: 2026-09-01)
        group_type: グループ化タイプ (overall, by_grade, by_start_month, combined)
        group_value: グループ値

    Returns:
        RankingListResponse
    """
    try:
        # 友だちランキングは group_value = 輪の持ち主の child_id であり、
        # 個人の交友関係を含むため、自分の子どもの輪以外は閲覧不可にする
        if group_type == "friends":
            if not group_value:
                raise HTTPException(status_code=400, detail="友だちランキングには group_value（child_id）が必要です")
            owner_result = await db.execute(
                select(Child).where(Child.id == UUID(group_value), Child.parent_id == UUID(user_id))
            )
            if owner_result.scalar_one_or_none() is None:
                raise HTTPException(status_code=403, detail="権限がありません")

        # Parse date string to date object
        ranking_month_date = date.fromisoformat(ranking_month)

        rankings = await RankingService.get_ranking_for_month(
            db,
            ranking_month=ranking_month_date,
            group_type=group_type,
            group_value=group_value,
        )

        # 子ども情報を結合
        ranking_details = []
        for ranking in rankings:
            child_result = await db.execute(
                select(Child).where(Child.id == ranking.child_id)
            )
            child = child_result.scalar_one_or_none()

            if child:
                ranking_details.append(
                    RankingDetailResponse(
                        rank=ranking.rank,
                        child_id=ranking.child_id,
                        child_name=_display_name(child),
                        avatar_emoji=child.avatar_emoji,
                        total_answers=ranking.total_answers,
                        total_growth_score=ranking.total_growth_score,
                        updated_at=ranking.updated_at,
                        is_name_public=child.is_name_public,
                    )
                )

        return RankingListResponse(
            ranking_month=ranking_month,
            group_type=group_type,
            group_value=group_value,
            rankings=ranking_details,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get(
    "/child/{child_id}/current",
    response_model=Optional[RankingDetailResponse],
    response_model_by_alias=True,
)
async def get_child_current_ranking(
    child_id: UUID,
    group_type: Literal["overall", "by_grade", "by_start_month", "combined", "friends"] = Query(
        "overall", description="グループ化タイプ"
    ),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    子どもの現月ランキング情報を取得

    Args:
        child_id: 子ども ID
        group_type: グループ化タイプ

    Returns:
        子どものランキング情報、または null（ランキングがない場合）
    """
    # 所有者確認
    child_result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    child = child_result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=403, detail="権限がありません")

    try:
        # 現在の月を取得
        today = date.today()
        current_month = date(today.year, today.month, 1)

        # 子どもの group_value を決定
        group_value = None
        if group_type == "by_grade":
            group_value = str(child.grade)
        elif group_type == "by_start_month":
            group_value = child.created_at.strftime("%Y-%m")
        elif group_type == "combined":
            group_value = f"{child.grade}_{child.created_at.strftime('%Y-%m')}"
        elif group_type == "friends":
            group_value = str(child.id)

        # ランキングを取得
        conditions = [
            Ranking.child_id == child_id,
            Ranking.ranking_month == current_month,
            Ranking.group_type == group_type,
        ]
        if group_value:
            conditions.append(Ranking.group_value == group_value)
        else:
            conditions.append(Ranking.group_value.is_(None))

        ranking_result = await db.execute(
            select(Ranking).where(and_(*conditions))
        )
        ranking = ranking_result.scalar_one_or_none()

        if not ranking:
            # Return 200 with null response when no ranking exists
            return None

        # 自分の子どものランキング情報なので、実名をそのまま返す
        # （isNamePublic は「他ユーザーへの公開ランキング」にのみ適用される）
        # is_name_public=True にして、フロント側の getDisplayName() でも
        # 実名（child_name）がそのまま表示されるようにする
        return RankingDetailResponse(
            rank=ranking.rank,
            child_id=ranking.child_id,
            child_name=child.name,
            avatar_emoji=child.avatar_emoji,
            total_answers=ranking.total_answers,
            total_growth_score=ranking.total_growth_score,
            updated_at=ranking.updated_at,
            is_name_public=True,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/calculate/{ranking_month}")
async def manually_calculate_ranking(
    ranking_month: date,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    手動でランキングを計算・保存
    （本来は スケジュール処理で自動実行される）

    Args:
        ranking_month: ランキング対象月

    Returns:
        成功メッセージ
    """
    # 管理者のみ許可（必要に応じて追加）
    try:
        await RankingService.calculate_rankings_for_month(db, ranking_month)
        return {"message": f"Ranking calculated for {ranking_month}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
