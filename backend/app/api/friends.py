"""
友だち関係 API エンドポイント
"""

from uuid import UUID
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.db.database import get_db
from app.models.child import Child
from app.models.friend import Friend
from app.schemas.friend import FriendAddRequest, FriendResponse
from app.security import get_current_user_id

router = APIRouter()


async def _get_owned_child(db: AsyncSession, child_id: UUID, user_id: str) -> Child:
    """自分の子どもプロフィールであることを確認して返す（他人の場合は403/404）"""
    result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=404, detail="子供プロフィールが見つかりません")
    return child


def _friend_to_response(friend_row: Friend, friend_child: Child) -> FriendResponse:
    return FriendResponse(
        friend_id=friend_row.id,
        child_id=friend_child.id,
        name=friend_child.name,
        avatar_emoji=friend_child.avatar_emoji,
        grade=friend_child.grade,
        level=friend_child.level,
        created_at=friend_row.created_at,
    )


@router.get("", response_model=List[FriendResponse], response_model_by_alias=True)
async def list_friends(
    child_id: UUID = Query(..., description="友だち一覧を取得する子どもID"),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """友だち一覧取得"""
    await _get_owned_child(db, child_id, user_id)

    result = await db.execute(
        select(Friend, Child)
        .join(Child, Child.id == Friend.friend_child_id)
        .where(Friend.child_id == child_id)
        .order_by(Friend.created_at)
    )
    rows = result.all()
    return [_friend_to_response(friend_row, friend_child) for friend_row, friend_child in rows]


@router.post("", response_model=FriendResponse, response_model_by_alias=True, status_code=status.HTTP_201_CREATED)
async def add_friend(
    body: FriendAddRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """招待コードを使って友だちを追加する（追加すると双方向に友だち関係が成立する）"""
    child = await _get_owned_child(db, body.child_id, user_id)

    friend_result = await db.execute(
        select(Child).where(Child.invite_code == body.invite_code)
    )
    friend_child = friend_result.scalar_one_or_none()
    if not friend_child:
        raise HTTPException(status_code=404, detail="招待コードが見つかりません")

    if friend_child.id == child.id:
        raise HTTPException(status_code=400, detail="自分自身は友だちに追加できません")

    # 既に友だちかどうか確認
    existing_result = await db.execute(
        select(Friend).where(
            and_(Friend.child_id == child.id, Friend.friend_child_id == friend_child.id)
        )
    )
    if existing_result.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="すでに友だちです")

    # 双方向のレコードを作成（お互いのランキング・一覧に表示されるようにする）
    forward = Friend(child_id=child.id, friend_child_id=friend_child.id)
    backward = Friend(child_id=friend_child.id, friend_child_id=child.id)
    db.add(forward)
    db.add(backward)
    await db.flush()
    await db.refresh(forward)
    await db.commit()

    return _friend_to_response(forward, friend_child)


@router.delete("/{friend_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_friend(
    friend_id: UUID,
    child_id: UUID = Query(..., description="友だちを削除する側の子どもID"),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """友だちを削除する（自分側・相手側両方の関係レコードを削除する）"""
    child = await _get_owned_child(db, child_id, user_id)

    result = await db.execute(
        select(Friend).where(Friend.id == friend_id, Friend.child_id == child.id)
    )
    friend_row = result.scalar_one_or_none()
    if not friend_row:
        raise HTTPException(status_code=404, detail="友だち関係が見つかりません")

    friend_child_id = friend_row.friend_child_id
    await db.delete(friend_row)

    # 相手側の逆向きレコードも削除
    reverse_result = await db.execute(
        select(Friend).where(
            and_(Friend.child_id == friend_child_id, Friend.friend_child_id == child.id)
        )
    )
    reverse_row = reverse_result.scalar_one_or_none()
    if reverse_row:
        await db.delete(reverse_row)

    await db.commit()
