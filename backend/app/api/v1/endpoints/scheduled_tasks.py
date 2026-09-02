"""
スケジュール済みタスク
- 毎月1日: ランキング計算
- 4月1日: 学年自動昇格
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, date
from app.db.database import get_db
from app.models.child import Child
from app.services.ranking_service import RankingService

router = APIRouter(prefix="/tasks", tags=["scheduled-tasks"])


@router.post("/monthly-ranking-calculation")
async def monthly_ranking_calculation(
    db: AsyncSession = Depends(get_db),
):
    """
    毎月1日実行: 前月のランキングを計算
    Cloud Scheduler から呼び出される
    """
    try:
        # 前月を計算（今が 2026-09-02 なら 2026-09-01）
        today = date.today()
        if today.day == 1:
            # 今月のランキングを計算
            ranking_month = today
        else:
            # 今月が過ぎていれば翌月を、そうでなければ今月を計算
            ranking_month = date(today.year, today.month, 1)

        await RankingService.calculate_rankings_for_month(db, ranking_month)

        return {
            "status": "success",
            "message": f"Ranking calculated for {ranking_month}",
            "timestamp": datetime.utcnow(),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/april-grade-promotion")
async def april_grade_promotion(
    db: AsyncSession = Depends(get_db),
):
    """
    4月1日実行: 全ユーザーの学年を自動昇格
    例: grade 3 → grade 4, grade 4 → grade 5（上限を超える場合は そのまま）
    Cloud Scheduler から呼び出される
    """
    try:
        today = date.today()

        # 4月1日のみ実行を許可（安全弁）
        if today.month != 4 or today.day != 1:
            return {
                "status": "skipped",
                "message": f"This task should run on April 1st only. Current date: {today}",
                "timestamp": datetime.utcnow(),
            }

        # 全ての子どもを取得
        children_result = await db.execute(select(Child))
        children = children_result.scalars().all()

        # 各子どもの学年を昇格（ただし上限は設定しない）
        promoted_count = 0
        for child in children:
            # 学年を +1 する
            child.grade += 1
            promoted_count += 1

        await db.commit()

        return {
            "status": "success",
            "message": f"Grade promoted for {promoted_count} children",
            "promoted_count": promoted_count,
            "timestamp": datetime.utcnow(),
        }

    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
