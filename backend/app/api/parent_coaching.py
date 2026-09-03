"""親向けコーチング API エンドポイント"""

from datetime import datetime, timedelta
from typing import Optional
import logging
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
import os

from app.db.database import get_db
from app.services.parent_analytics_service import ParentAnalyticsService
from app.services.gemini_coaching_service import GeminiCoachingService, CoachingMessage
from app.services.email_service import EmailService
from app.models import WeeklyCoachingData, User, Child

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/children", tags=["parent-coaching"])


class WeeklyCoachingResponse(BaseModel):
    """週次コーチングレスポンス"""

    child_id: str
    child_name: str
    week_number: int
    weekly_stories_completed: int
    weekly_study_minutes: int
    weekly_points_earned: int
    strongest_virtue: Optional[str]
    weakest_virtue: Optional[str]
    highlight: Optional[str]
    advice: Optional[str]
    parent_tip: Optional[str]
    next_milestone: Optional[str]
    trend_analysis: Optional[str]
    email_sent: Optional[bool] = False

    class Config:
        from_attributes = True


@router.post(
    "/{child_id}/weekly-coaching/generate",
    response_model=WeeklyCoachingResponse,
    summary="週次コーチングデータを生成 & 親にメール送信",
    description="子の学習データから週次分析を生成し、AI生成コーチングメッセージを作成して親にメール送信します。",
)
async def generate_and_send_weekly_coaching(
    child_id: str,
    db: AsyncSession = Depends(get_db),
) -> WeeklyCoachingResponse:
    """
    週次コーチングデータを生成してメール送信

    Args:
        child_id: 子の ID

    Returns:
        WeeklyCoachingResponse: 生成されたコーチングデータ
    """

    try:
        # 1. 子情報を取得
        child = await _get_child_or_raise(db, child_id)
        parent_id = child.parent_id

        # 2. 週の開始日を計算（日曜日から開始）
        today = datetime.utcnow()
        week_start = today - timedelta(days=today.weekday() + 1)  # 前の日曜日

        # 3. 週次分析を生成（ParentAnalyticsService）
        analytics_service = ParentAnalyticsService(db)
        coaching_data = await analytics_service.generate_weekly_analysis(
            child_id=child_id,
            parent_id=parent_id,
            week_start=week_start,
        )

        # 4. Gemini AI でコーチングメッセージを生成
        gemini_service = GeminiCoachingService(
            project_id=os.getenv("GCP_PROJECT_ID"),
            location=os.getenv("VERTEX_AI_LOCATION", "asia-northeast1"),
            model_id=os.getenv("GEMINI_MODEL_ID", "gemini-2.0-flash"),
        )
        coaching_message = await gemini_service.generate_coaching_message(
            coaching_data=coaching_data,
            child_name=child.name,
            child_grade=child.grade,
        )

        # 5. コーチングメッセージをデータに格納
        coaching_data.highlight = coaching_message.highlight
        coaching_data.advice = coaching_message.advice
        coaching_data.parent_tip = coaching_message.parent_tip

        # 6. 親のメールアドレスを取得
        parent = await _get_parent_or_raise(db, parent_id)
        parent_email = parent.email

        # 7. SendGrid でメール送信
        email_service = EmailService(
            sendgrid_api_key=os.getenv("SENDGRID_API_KEY"),
        )
        email_result = await email_service.send_weekly_coaching_email(
            parent_email=parent_email,
            child_name=child.name,
            coaching_data=coaching_data,
        )

        # 8. メール送信結果を記録
        if email_result["success"]:
            coaching_data.email_sent = datetime.utcnow()
            coaching_data.sendgrid_message_id = email_result.get("message_id")
            logger.info(
                f"コーチングメール送信成功: child_id={child_id}, parent_email={parent_email}"
            )
        else:
            logger.error(
                f"コーチングメール送信失敗: child_id={child_id}, error={email_result.get('error')}"
            )

        # 9. 週次分析データを保存
        coaching_data = await analytics_service.save_weekly_coaching_data(coaching_data)

        # 10. レスポンスを返す
        return WeeklyCoachingResponse(
            child_id=child_id,
            child_name=child.name,
            week_number=coaching_data.week_number,
            weekly_stories_completed=coaching_data.weekly_stories_completed,
            weekly_study_minutes=coaching_data.weekly_study_minutes,
            weekly_points_earned=coaching_data.weekly_points_earned,
            strongest_virtue=coaching_data.strongest_virtue,
            weakest_virtue=coaching_data.weakest_virtue,
            highlight=coaching_data.highlight,
            advice=coaching_data.advice,
            parent_tip=coaching_data.parent_tip,
            next_milestone=coaching_data.next_milestone,
            trend_analysis=coaching_data.trend_analysis,
            email_sent=coaching_data.email_sent is not None,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
    except Exception as e:
        logger.error(f"週次コーチング生成エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="週次コーチングの生成に失敗しました",
        )


@router.get(
    "/{child_id}/weekly-coaching/{week_number}",
    response_model=WeeklyCoachingResponse,
    summary="週次コーチングデータを取得",
    description="指定された週のコーチングデータを取得します。",
)
async def get_weekly_coaching(
    child_id: str,
    week_number: int,
    db: AsyncSession = Depends(get_db),
) -> WeeklyCoachingResponse:
    """
    指定週の週次コーチングデータを取得

    Args:
        child_id: 子の ID
        week_number: 週番号（1-53）

    Returns:
        WeeklyCoachingResponse: コーチングデータ
    """

    try:
        # 週次コーチングデータを取得
        coaching_data = await _get_weekly_coaching_or_raise(
            db, child_id, week_number
        )

        # 子情報を取得
        child = await _get_child_or_raise(db, child_id)

        return WeeklyCoachingResponse(
            child_id=child_id,
            child_name=child.name,
            week_number=coaching_data.week_number,
            weekly_stories_completed=coaching_data.weekly_stories_completed,
            weekly_study_minutes=coaching_data.weekly_study_minutes,
            weekly_points_earned=coaching_data.weekly_points_earned,
            strongest_virtue=coaching_data.strongest_virtue,
            weakest_virtue=coaching_data.weakest_virtue,
            highlight=coaching_data.highlight,
            advice=coaching_data.advice,
            parent_tip=coaching_data.parent_tip,
            next_milestone=coaching_data.next_milestone,
            trend_analysis=coaching_data.trend_analysis,
            email_sent=coaching_data.email_sent is not None,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
    except Exception as e:
        logger.error(f"週次コーチング取得エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="週次コーチングの取得に失敗しました",
        )


# ─── ヘルパー関数 ─────────────────────────────────────────────────────────


async def _get_child_or_raise(db: AsyncSession, child_id: str) -> Child:
    """子情報を取得、存在しない場合は例外を発行"""
    from sqlalchemy import select

    result = await db.execute(select(Child).where(Child.id == child_id))
    child = result.scalar_one_or_none()
    if not child:
        raise ValueError(f"子が見つかりません: {child_id}")
    return child


async def _get_parent_or_raise(db: AsyncSession, parent_id: str) -> User:
    """親情報を取得、存在しない場合は例外を発行"""
    from sqlalchemy import select

    result = await db.execute(select(User).where(User.id == parent_id))
    parent = result.scalar_one_or_none()
    if not parent:
        raise ValueError(f"親が見つかりません: {parent_id}")
    return parent


async def _get_weekly_coaching_or_raise(
    db: AsyncSession,
    child_id: str,
    week_number: int,
) -> WeeklyCoachingData:
    """週次コーチングデータを取得、存在しない場合は例外を発行"""
    from sqlalchemy import select

    result = await db.execute(
        select(WeeklyCoachingData).where(
            (WeeklyCoachingData.child_id == child_id)
            & (WeeklyCoachingData.week_number == week_number)
        )
    )
    coaching_data = result.scalar_one_or_none()
    if not coaching_data:
        raise ValueError(
            f"週次コーチングデータが見つかりません: child_id={child_id}, week={week_number}"
        )
    return coaching_data
