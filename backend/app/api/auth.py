from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest, FirebaseLoginRequest, TokenResponse
from app.schemas.user import UserCreate, UserResponse
from app.security import verify_password, get_password_hash, create_access_token
from app.config import get_settings
import firebase_admin
from firebase_admin import auth as firebase_auth
import logging

logger = logging.getLogger(__name__)

settings = get_settings()
router = APIRouter()


@router.post("/register", response_model=TokenResponse, response_model_by_alias=True, status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """メールアドレスで新規登録"""
    # 重複チェック
    result = await db.execute(select(User).where(User.email == request.email))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="このメールアドレスはすでに登録されています",
        )

    user = User(
        email=request.email,
        name=request.name,
        password_hash=get_password_hash(request.password),
    )
    db.add(user)
    await db.flush()
    await db.commit()

    token = create_access_token(
        {"sub": str(user.id)},
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )
    return TokenResponse(
        access_token=token,
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post("/login", response_model=TokenResponse, response_model_by_alias=True)
async def login(request: LoginRequest, db: AsyncSession = Depends(get_db)):
    """メールアドレスでログイン"""
    result = await db.execute(select(User).where(User.email == request.email))
    user = result.scalar_one_or_none()

    if not user or not user.password_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="メールアドレスまたはパスワードが間違っています",
        )
    if not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="メールアドレスまたはパスワードが間違っています",
        )
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="アカウントが無効です")

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(
        access_token=token,
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post("/firebase", response_model=TokenResponse, response_model_by_alias=True)
async def firebase_login(request: FirebaseLoginRequest, db: AsyncSession = Depends(get_db)):
    """Firebase IDトークンでログイン/登録"""
    try:
        decoded = firebase_auth.verify_id_token(request.firebase_token)
    except ValueError as e:
        # Invalid token format
        logger.warning(f"Firebase: Invalid token format - {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase tokenが無効です",
        )
    except firebase_admin.exceptions.FirebaseError as e:
        # Firebase-specific errors (expired, revoked, invalid signature, etc.)
        logger.warning(f"Firebase: Token verification failed - {type(e).__name__}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase tokenが無効です",
        )
    except Exception as e:
        # Unexpected errors - log but don't expose details
        logger.error(f"Firebase: Unexpected error during token verification - {type(e).__name__}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase tokenが無効です",
        )

    firebase_uid = decoded["uid"]
    email = decoded.get("email", "")
    name = decoded.get("name", email.split("@")[0])

    # 既存ユーザー検索
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    if not user:
        # 初回→新規作成
        user = User(firebase_uid=firebase_uid, email=email, name=name)
        db.add(user)
        await db.flush()
        await db.commit()

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(
        access_token=token,
        expires_in=settings.access_token_expire_minutes * 60,
    )
