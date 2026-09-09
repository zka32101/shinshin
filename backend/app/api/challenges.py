"""
協力ジレンマチャレンジ API エンドポイント

友だちを指名し、同じストーリーの選択肢をそれぞれ選んで後で結果を比較する、
勝敗なし・非同期・非リアルタイムな機能。

将来のリアルタイム対戦拡張の余地を残すため、モデルの status フィールドは
"pending"（相手の回答待ち）/ "completed"（双方回答済み）に加えて
"active" / "expired" を予約している。今回のAPIでは pending / completed のみを扱う。
"""

from datetime import datetime
from uuid import UUID
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_

from app.db.database import get_db
from app.models.child import Child
from app.models.friend import Friend
from app.models.story import Story, StoryChoice
from app.models.challenge import DilemmaChallenge
from app.schemas.challenge import (
    ChallengeCreateRequest,
    ChallengeRespondRequest,
    ChallengeResponse,
)
from app.security import get_current_user_id

router = APIRouter()


async def _get_owned_child(db: AsyncSession, child_id: UUID, user_id: str) -> Child:
    """自分の子どもプロフィールであることを確認して返す（他人の場合は404）"""
    result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=404, detail="子供プロフィールが見つかりません")
    return child


async def _are_friends(db: AsyncSession, child_id: UUID, other_child_id: UUID) -> bool:
    result = await db.execute(
        select(Friend).where(
            and_(Friend.child_id == child_id, Friend.friend_child_id == other_child_id)
        )
    )
    return result.scalar_one_or_none() is not None


async def _get_challenge_or_404(db: AsyncSession, challenge_id: UUID) -> DilemmaChallenge:
    result = await db.execute(
        select(DilemmaChallenge).where(DilemmaChallenge.id == challenge_id)
    )
    challenge = result.scalar_one_or_none()
    if not challenge:
        raise HTTPException(status_code=404, detail="チャレンジが見つかりません")
    return challenge


async def _assert_owned_participant(db: AsyncSession, challenge: DilemmaChallenge, user_id: str) -> Child:
    """自分の子どもがこのチャレンジの参加者（招待した側 or された側）であることを確認する"""
    result = await db.execute(
        select(Child).where(
            Child.parent_id == UUID(user_id),
            Child.id.in_([challenge.initiator_child_id, challenge.invitee_child_id]),
        )
    )
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=403, detail="このチャレンジにアクセスする権限がありません")
    return child


def _to_response_for_viewer(challenge: DilemmaChallenge, viewer_child_id: UUID) -> ChallengeResponse:
    """閲覧者本人の選択は常に見せる。相手の選択は completed になるまで隠す。"""
    is_initiator = viewer_child_id == challenge.initiator_child_id

    initiator_choice_id = challenge.initiator_choice_id
    invitee_choice_id = challenge.invitee_choice_id

    if challenge.status != "completed":
        if is_initiator:
            invitee_choice_id = None
        else:
            initiator_choice_id = None

    return ChallengeResponse(
        id=challenge.id,
        story_id=challenge.story_id,
        status=challenge.status,
        initiator_child_id=challenge.initiator_child_id,
        invitee_child_id=challenge.invitee_child_id,
        initiator_choice_id=initiator_choice_id,
        invitee_choice_id=invitee_choice_id,
        created_at=challenge.created_at,
        completed_at=challenge.completed_at,
    )


async def _validate_choice(db: AsyncSession, story_id: UUID, choice_id: UUID) -> None:
    result = await db.execute(
        select(StoryChoice).where(StoryChoice.id == choice_id, StoryChoice.story_id == story_id)
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="選択肢がこのストーリーのものではありません")


@router.post("", response_model=ChallengeResponse, response_model_by_alias=True, status_code=status.HTTP_201_CREATED)
async def create_challenge(
    body: ChallengeCreateRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """友だちを指名して協力ジレンマチャレンジを作成する"""
    child = await _get_owned_child(db, body.child_id, user_id)

    if body.friend_child_id == child.id:
        raise HTTPException(status_code=400, detail="自分自身をチャレンジに招待することはできません")

    friend_result = await db.execute(select(Child).where(Child.id == body.friend_child_id))
    friend_child = friend_result.scalar_one_or_none()
    if not friend_child:
        raise HTTPException(status_code=404, detail="招待する子どもが見つかりません")

    if not await _are_friends(db, child.id, friend_child.id):
        raise HTTPException(status_code=403, detail="友だちにのみチャレンジを送ることができます")

    story_result = await db.execute(select(Story).where(Story.id == body.story_id))
    story = story_result.scalar_one_or_none()
    if not story:
        raise HTTPException(status_code=404, detail="ストーリーが見つかりません")

    if body.choice_id is not None:
        await _validate_choice(db, story.id, body.choice_id)

    challenge = DilemmaChallenge(
        story_id=story.id,
        initiator_child_id=child.id,
        invitee_child_id=friend_child.id,
        initiator_choice_id=body.choice_id,
        status="pending",
    )
    db.add(challenge)
    await db.flush()
    await db.refresh(challenge)
    await db.commit()

    return _to_response_for_viewer(challenge, child.id)


@router.get("", response_model=List[ChallengeResponse], response_model_by_alias=True)
async def list_challenges(
    child_id: UUID = Query(..., description="チャレンジ一覧を取得する子どもID"),
    challenge_status: Optional[str] = Query(default=None, alias="status", description="pending / completed で絞り込み"),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """自分宛て・自分発の協力ジレンマチャレンジ一覧を取得する"""
    child = await _get_owned_child(db, child_id, user_id)

    conditions = [or_(DilemmaChallenge.initiator_child_id == child.id, DilemmaChallenge.invitee_child_id == child.id)]
    if challenge_status:
        conditions.append(DilemmaChallenge.status == challenge_status)

    result = await db.execute(
        select(DilemmaChallenge).where(and_(*conditions)).order_by(DilemmaChallenge.created_at.desc())
    )
    challenges = result.scalars().all()
    return [_to_response_for_viewer(c, child.id) for c in challenges]


@router.get("/{challenge_id}", response_model=ChallengeResponse, response_model_by_alias=True)
async def get_challenge(
    challenge_id: UUID,
    child_id: UUID = Query(..., description="閲覧する側の子どもID"),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """チャレンジの詳細（双方の選択結果）を取得する。

    双方が回答済みになるまでは相手の選択は隠す（先出し情報で影響されないように）。
    """
    child = await _get_owned_child(db, child_id, user_id)
    challenge = await _get_challenge_or_404(db, challenge_id)

    if child.id not in (challenge.initiator_child_id, challenge.invitee_child_id):
        raise HTTPException(status_code=403, detail="このチャレンジにアクセスする権限がありません")

    return _to_response_for_viewer(challenge, child.id)


@router.post("/{challenge_id}/respond", response_model=ChallengeResponse, response_model_by_alias=True)
async def respond_to_challenge(
    challenge_id: UUID,
    body: ChallengeRespondRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """チャレンジに選択肢で回答する（招待した側・された側どちらも使用可）。

    両者の選択が揃うと status が completed になる。
    """
    child = await _get_owned_child(db, body.child_id, user_id)
    challenge = await _get_challenge_or_404(db, challenge_id)

    if child.id not in (challenge.initiator_child_id, challenge.invitee_child_id):
        raise HTTPException(status_code=403, detail="このチャレンジに回答する権限がありません")

    if challenge.status == "completed":
        raise HTTPException(status_code=409, detail="このチャレンジはすでに完了しています")

    await _validate_choice(db, challenge.story_id, body.choice_id)

    is_initiator = child.id == challenge.initiator_child_id
    if is_initiator:
        if challenge.initiator_choice_id is not None:
            raise HTTPException(status_code=409, detail="すでに回答済みです")
        challenge.initiator_choice_id = body.choice_id
    else:
        if challenge.invitee_choice_id is not None:
            raise HTTPException(status_code=409, detail="すでに回答済みです")
        challenge.invitee_choice_id = body.choice_id

    if challenge.initiator_choice_id is not None and challenge.invitee_choice_id is not None:
        challenge.status = "completed"
        challenge.completed_at = datetime.utcnow()

    await db.flush()
    await db.refresh(challenge)
    await db.commit()

    return _to_response_for_viewer(challenge, child.id)
