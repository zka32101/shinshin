from uuid import UUID
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.models.child import Child
from app.schemas.child import ChildCreate, ChildUpdate, ChildResponse
from app.security import get_current_user_id

router = APIRouter()


def _child_to_response(child: Child) -> ChildResponse:
    return ChildResponse.from_orm(child)


@router.get("", response_model=List[ChildResponse], response_model_by_alias=True)
async def list_children(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """子供一覧取得"""
    result = await db.execute(
        select(Child).where(Child.parent_id == UUID(user_id)).order_by(Child.created_at)
    )
    children = result.scalars().all()
    return [_child_to_response(c) for c in children]


@router.post("", response_model=ChildResponse, response_model_by_alias=True, status_code=status.HTTP_201_CREATED)
async def create_child(
    body: ChildCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """子供プロフィール作成"""
    child = Child(
        parent_id=UUID(user_id),
        name=body.name,
        avatar_emoji=body.avatar_emoji,
        grade=body.grade,
        is_name_public=body.is_name_public,
    )
    db.add(child)
    await db.flush()
    await db.refresh(child)
    return _child_to_response(child)


@router.get("/{child_id}", response_model=ChildResponse, response_model_by_alias=True)
async def get_child(
    child_id: UUID,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """子供詳細取得"""
    result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=404, detail="子供プロフィールが見つかりません")
    return _child_to_response(child)


@router.put("/{child_id}", response_model=ChildResponse, response_model_by_alias=True)
async def update_child(
    child_id: UUID,
    body: ChildUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """子供プロフィール更新"""
    result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=404, detail="子供プロフィールが見つかりません")

    if body.name is not None:
        child.name = body.name
    if body.avatar_emoji is not None:
        child.avatar_emoji = body.avatar_emoji
    if body.grade is not None:
        child.grade = body.grade
    if body.is_name_public is not None:
        child.is_name_public = body.is_name_public

    await db.commit()
    await db.refresh(child)
    return _child_to_response(child)


@router.delete("/{child_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_child(
    child_id: UUID,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Child).where(Child.id == child_id, Child.parent_id == UUID(user_id))
    )
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=404, detail="子供プロフィールが見つかりません")
    await db.delete(child)
    await db.commit()
