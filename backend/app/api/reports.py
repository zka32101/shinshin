from uuid import UUID
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.db.database import get_db
from app.models.report import MonthlyReport
from app.models.child import Child
from app.models.quiz import QuizSession
from app.schemas.report import MonthlyReportResponse
from app.security import get_current_user_id

router = APIRouter()


@router.get("/{child_id}/monthly", response_model=Optional[MonthlyReportResponse], response_model_by_alias=True)
async def get_monthly_report(
    child_id: UUID,
    year: int = Query(...),
    month: int = Query(..., ge=1, le=12),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """月次レポート取得"""
    # 所有者確認
    child_result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    if not child_result.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="権限がありません")

    result = await db.execute(
        select(MonthlyReport).where(
            MonthlyReport.child_id == child_id,
            MonthlyReport.year == year,
            MonthlyReport.month == month,
        )
    )
    report = result.scalar_one_or_none()
    if not report:
        return None
    return MonthlyReportResponse.model_validate(report)


@router.post("/{child_id}/monthly/generate", response_model=MonthlyReportResponse, response_model_by_alias=True)
async def generate_monthly_report(
    child_id: UUID,
    year: int = Query(...),
    month: int = Query(..., ge=1, le=12),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """月次レポート生成 (既存があれば更新)"""
    # 所有者確認
    child_result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    child = child_result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=403, detail="権限がありません")

    # 月内のクイズセッション集計
    sessions_result = await db.execute(
        select(QuizSession).where(
            QuizSession.child_id == child_id,
            QuizSession.is_completed == True,
            func.extract("year", QuizSession.completed_at) == year,
            func.extract("month", QuizSession.completed_at) == month,
        )
    )
    sessions = sessions_result.scalars().all()

    stories_completed = len(sessions)
    total_points = sum(s.points_earned for s in sessions)
    total_minutes = sum(s.time_spent_seconds for s in sessions) // 60

    # テーマ別集計
    theme_breakdown = _calc_theme_breakdown(sessions)

    # 既存レポート検索
    existing_result = await db.execute(
        select(MonthlyReport).where(
            MonthlyReport.child_id == child_id,
            MonthlyReport.year == year,
            MonthlyReport.month == month,
        )
    )
    report = existing_result.scalar_one_or_none()

    if report:
        # 更新
        report.stories_completed = stories_completed
        report.total_points_earned = total_points
        report.total_study_minutes = total_minutes
        report.kindness_score = child.kindness_score
        report.honesty_score = child.honesty_score
        report.responsibility_score = child.responsibility_score
        report.courage_score = child.courage_score
        report.respect_score = child.respect_score
        report.cooperation_score = child.cooperation_score
        report.theme_breakdown = theme_breakdown
        report.highlight_comment = _generate_highlight(child, stories_completed)
        report.growth_comment = _generate_growth(child)
        report.advice_comment = _generate_advice(child)
        report.parent_message = _generate_parent_message(child, stories_completed, total_points)
        report.updated_at = datetime.utcnow()
    else:
        # 新規作成
        report = MonthlyReport(
            child_id=child_id,
            year=year,
            month=month,
            stories_completed=stories_completed,
            total_points_earned=total_points,
            total_study_minutes=total_minutes,
            kindness_score=child.kindness_score,
            honesty_score=child.honesty_score,
            responsibility_score=child.responsibility_score,
            courage_score=child.courage_score,
            respect_score=child.respect_score,
            cooperation_score=child.cooperation_score,
            theme_breakdown=theme_breakdown,
            highlight_comment=_generate_highlight(child, stories_completed),
            growth_comment=_generate_growth(child),
            advice_comment=_generate_advice(child),
            parent_message=_generate_parent_message(child, stories_completed, total_points),
        )
        db.add(report)

    await db.commit()
    await db.refresh(report)
    return MonthlyReportResponse.model_validate(report)


def _calc_theme_breakdown(sessions) -> dict:
    """テーマ別集計"""
    # Simplified - requires story join for full implementation
    return {}


def _generate_highlight(child, stories_completed: int) -> str:
    if stories_completed >= 10:
        return f"{child.name}さんは今月{stories_completed}個のストーリーを学習しました！とても意欲的に取り組んでいます。"
    elif stories_completed >= 5:
        return f"{child.name}さんは今月{stories_completed}個のストーリーを完了しました。コツコツ頑張っています！"
    else:
        return f"{child.name}さんは今月{stories_completed}個のストーリーに挑戦しました。次の月もチャレンジしてみよう！"


def _generate_growth(child) -> str:
    scores = {
        "思いやり": child.kindness_score,
        "正直さ": child.honesty_score,
        "責任感": child.responsibility_score,
        "勇気": child.courage_score,
        "礼儀": child.respect_score,
        "協調性": child.cooperation_score,
    }
    top_virtue = max(scores, key=scores.get)
    return f"特に「{top_virtue}」の面で素晴らしい成長が見られます（スコア: {scores[top_virtue]:.0f}点）。日常生活でも活かせているようです。"


def _generate_advice(child) -> str:
    scores = {
        "思いやり": child.kindness_score,
        "正直さ": child.honesty_score,
        "責任感": child.responsibility_score,
        "勇気": child.courage_score,
        "礼儀": child.respect_score,
        "協調性": child.cooperation_score,
    }
    weakest = min(scores, key=scores.get)
    return f"来月は「{weakest}」に関するストーリーに注目してみましょう。日常生活の中で意識すると、さらに成長できますよ。"


def _generate_parent_message(child, stories: int, points: int) -> str:
    return (
        f"{child.name}さんは今月も道徳学習を頑張りました。"
        f"{stories}個のストーリーを通じて{points}ポイントを獲得し、"
        f"現在レベル{child.level}です。"
        f"お子さんの成長を一緒に応援しましょう！"
    )
