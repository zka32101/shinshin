from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate
from app.security import get_current_user_id
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/me", response_model=UserResponse, response_model_by_alias=True)
async def get_me(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """ログイン中のユーザー情報取得"""
    result = await db.execute(select(User).where(User.id == UUID(user_id)))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="ユーザーが見つかりません")
    return UserResponse.model_validate(user)


@router.put("/me", response_model=UserResponse, response_model_by_alias=True)
async def update_me(
    body: UserUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """ユーザー情報更新"""
    result = await db.execute(select(User).where(User.id == UUID(user_id)))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="ユーザーが見つかりません")

    updated_fields = []
    if body.name is not None:
        user.name = body.name
        updated_fields.append("name")
    if body.fcm_token is not None:
        user.fcm_token = body.fcm_token
        updated_fields.append("fcm_token")

    await db.commit()
    await db.refresh(user)

    # Log user profile update (security event)
    if updated_fields:
        logger.info(f"SECURITY: User profile updated - user_id={user_id}, fields={updated_fields}")

    return UserResponse.model_validate(user)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """アカウント削除"""
    result = await db.execute(select(User).where(User.id == UUID(user_id)))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="ユーザーが見つかりません")

    # Log account deletion (security event)
    user_email = user.email
    logger.info(f"SECURITY: Account deleted - user_id={user_id}, email={user_email}")

    await db.delete(user)
    await db.commit()
