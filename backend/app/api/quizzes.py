from uuid import UUID
from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.models.quiz import QuizSession
from app.models.child import Child
from app.models.story import StoryChoice
from app.models.progress import Progress
from app.schemas.quiz import QuizSessionCreate, QuizSessionResponse, QuizSessionComplete, QuizCompleteResponse
from app.security import get_current_user_id

router = APIRouter()


@router.post("", response_model=QuizSessionResponse, response_model_by_alias=True, status_code=status.HTTP_201_CREATED)
async def start_quiz(
    body: QuizSessionCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """クイズセッション開始"""
    # 子供の所有者確認
    result = await db.execute(
        select(Child).where(Child.id == body.child_id, Child.parent_id == UUID(user_id))
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="権限がありません")

    session = QuizSession(
        child_id=body.child_id,
        story_id=body.story_id,
    )
    db.add(session)
    await db.flush()
    await db.refresh(session)
    return QuizSessionResponse.model_validate(session)


@router.post("/{session_id}/complete", response_model=QuizCompleteResponse, response_model_by_alias=True)
async def complete_quiz(
    session_id: UUID,
    body: QuizSessionComplete,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """クイズセッション完了・スコア更新"""
    # セッション取得
    result = await db.execute(select(QuizSession).where(QuizSession.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="セッションが見つかりません")

    # 子供の所有者確認
    child_result = await db.execute(
        select(Child).where(Child.id == session.child_id, Child.parent_id == UUID(user_id))
    )
    child = child_result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=403, detail="権限がありません")

    # 選択肢の点数取得
    choice_result = await db.execute(
        select(StoryChoice).where(StoryChoice.id == body.chosen_choice_id)
    )
    choice = choice_result.scalar_one_or_none()
    points = choice.points if choice else 10

    # セッション更新
    session.chosen_choice_id = body.chosen_choice_id
    session.time_spent_seconds = body.time_spent_seconds
    session.reflection_text = body.reflection_text
    session.points_earned = points
    session.is_completed = True
    session.completed_at = datetime.utcnow()

    # 徳目スコア変化量を記録（更新前に取得）
    score_before = {
        "kindness": child.kindness_score,
        "honesty": child.honesty_score,
        "responsibility": child.responsibility_score,
        "courage": child.courage_score,
        "respect": child.respect_score,
        "cooperation": child.cooperation_score,
    }

    # 子供のポイント・スコア更新
    child.total_points += points
    child.level = max(1, child.total_points // 100 + 1)

    # 徳目スコア更新
    if choice and choice.score_impact:
        _apply_score_impact(child, choice.score_impact)

    # 変化量を計算
    score_deltas = {
        "kindness": child.kindness_score - score_before["kindness"],
        "honesty": child.honesty_score - score_before["honesty"],
        "responsibility": child.responsibility_score - score_before["responsibility"],
        "courage": child.courage_score - score_before["courage"],
        "respect": child.respect_score - score_before["respect"],
        "cooperation": child.cooperation_score - score_before["cooperation"],
    }
    # ゼロの変化量は省略
    score_deltas = {k: v for k, v in score_deltas.items() if v != 0.0}

    # 進捗記録
    progress = Progress(
        child_id=child.id,
        story_id=session.story_id,
        action="story_completed",
        detail=str(session.story_id),
        points_delta=points,
    )
    db.add(progress)

    await db.commit()

    return QuizCompleteResponse(
        session_id=session.id,
        story_id=session.story_id,
        points_earned=points,
        time_spent_seconds=session.time_spent_seconds,
        is_completed=True,
        completed_at=session.completed_at,
        new_level=child.level,
        new_total_points=child.total_points,
        score_deltas=score_deltas,
    )


def _apply_score_impact(child: Child, impact: dict) -> None:
    """徳目スコアに影響を適用 (0-100にクランプ)"""
    mapping = {
        "kindness": "kindness_score",
        "honesty": "honesty_score",
        "responsibility": "responsibility_score",
        "courage": "courage_score",
        "respect": "respect_score",
        "cooperation": "cooperation_score",
    }
    for key, attr in mapping.items():
        if key in impact:
            current = getattr(child, attr, 50.0)
            new_val = max(0.0, min(100.0, current + float(impact[key])))
            setattr(child, attr, new_val)
