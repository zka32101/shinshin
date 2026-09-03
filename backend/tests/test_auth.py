import pytest
from unittest.mock import patch
from jose import jwt
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.config import get_settings


@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    """正常登録"""
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "new@example.com", "password": "NewPass123", "name": "新規ユーザー"},
    )
    assert response.status_code == 201
    data = response.json()
    assert "accessToken" in data
    assert data["tokenType"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate_email(client: AsyncClient, test_user: dict):
    """重複メールアドレス"""
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "test@example.com", "password": "DupePass123", "name": "重複"},
    )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, test_user: dict):
    """正常ログイン"""
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "test@example.com", "password": "TestPassword123"},
    )
    assert response.status_code == 200
    assert "accessToken" in response.json()


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient, test_user: dict):
    """パスワード間違い"""
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "test@example.com", "password": "WrongPassword123"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_login_unknown_email(client: AsyncClient):
    """存在しないメール"""
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "nobody@example.com", "password": "AnyPass123"},
    )
    assert response.status_code == 401


# ── JWT / security layer tests ────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_invalid_token_rejected(client: AsyncClient):
    """ゴミトークンは 401 を返す (decode_token JWTError パス)"""
    response = await client.get(
        "/api/v1/children",
        headers={"Authorization": "Bearer this.is.garbage"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_token_missing_sub_rejected(client: AsyncClient):
    """sub クレームがないトークンは 401 を返す (get_current_user_id パス)"""
    settings = get_settings()
    # subなしでトークンを作成
    token_no_sub = jwt.encode(
        {"data": "no_sub_claim"},
        settings.secret_key,
        algorithm=settings.algorithm,
    )
    response = await client.get(
        "/api/v1/children",
        headers={"Authorization": f"Bearer {token_no_sub}"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_optional_auth_no_credentials():
    """get_optional_user_id: credentials=None のとき None を返す"""
    from app.security import get_optional_user_id
    result = await get_optional_user_id(credentials=None)
    assert result is None


@pytest.mark.asyncio
async def test_optional_auth_invalid_credentials():
    """get_optional_user_id: 不正トークンのとき None を返す (except HTTPException パス)"""
    from fastapi.security import HTTPAuthorizationCredentials
    from app.security import get_optional_user_id
    fake_creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="bad.token.here")
    result = await get_optional_user_id(credentials=fake_creds)
    assert result is None


@pytest.mark.asyncio
async def test_optional_auth_valid_credentials(auth_headers: dict):
    """get_optional_user_id: 正しいトークンのとき user_id (UUID 文字列) を返す"""
    from fastapi.security import HTTPAuthorizationCredentials
    from app.security import get_optional_user_id
    token = auth_headers["Authorization"].split(" ")[1]
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
    result = await get_optional_user_id(credentials=creds)
    assert result is not None
    # sub claim は UUID 文字列
    import uuid
    uuid.UUID(result)  # raises ValueError if not valid UUID


# ── Firebase login tests ──────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_firebase_login_new_user(client: AsyncClient):
    """Firebase login creates a new user record on first call."""
    fake_decoded = {
        "uid": "firebase-uid-newuser-001",
        "email": "firebase_new@example.com",
        "name": "Firebase ユーザー",
    }
    with patch("app.api.auth.firebase_auth.verify_id_token", return_value=fake_decoded):
        r = await client.post(
            "/api/v1/auth/firebase",
            json={"firebase_token": "valid-id-token"},
        )
    assert r.status_code == 200
    data = r.json()
    assert "accessToken" in data
    assert data["tokenType"] == "bearer"


@pytest.mark.asyncio
async def test_firebase_login_existing_user(client: AsyncClient):
    """Second Firebase login with the same uid reuses the existing user row."""
    fake_decoded = {
        "uid": "firebase-uid-existing-001",
        "email": "fb_existing@example.com",
    }
    with patch("app.api.auth.firebase_auth.verify_id_token", return_value=fake_decoded):
        r1 = await client.post("/api/v1/auth/firebase", json={"firebase_token": "tok1"})
        assert r1.status_code == 200
        r2 = await client.post("/api/v1/auth/firebase", json={"firebase_token": "tok2"})
        assert r2.status_code == 200
    assert "accessToken" in r2.json()


@pytest.mark.asyncio
async def test_firebase_login_invalid_token(client: AsyncClient):
    """Invalid Firebase ID token returns 401."""
    with patch("app.api.auth.firebase_auth.verify_id_token", side_effect=Exception("bad token")):
        r = await client.post(
            "/api/v1/auth/firebase",
            json={"firebase_token": "bad-firebase-token"},
        )
    assert r.status_code == 401


# ── Edge-case login paths ─────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_login_inactive_user(client: AsyncClient, db_session: AsyncSession):
    """ログイン: is_active=False のアカウントは 403 を返す"""
    from sqlalchemy import select
    from app.models.user import User

    # Register user
    await client.post(
        "/api/v1/auth/register",
        json={"email": "inactive@example.com", "password": "InactivePass123", "name": "停止ユーザー"},
    )

    # Deactivate directly in DB
    result = await db_session.execute(select(User).where(User.email == "inactive@example.com"))
    user = result.scalar_one()
    user.is_active = False
    await db_session.commit()

    r = await client.post(
        "/api/v1/auth/login",
        json={"email": "inactive@example.com", "password": "InactivePass123"},
    )
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_login_firebase_user_no_password(client: AsyncClient, db_session: AsyncSession):
    """Firebase 登録ユーザー (password_hash なし) のメールログインは 401 を返す"""
    from app.models.user import User

    fb_user = User(
        email="fb_only@example.com",
        name="Firebase Only",
        firebase_uid="uid-fb-only-xyz",
    )
    db_session.add(fb_user)
    await db_session.commit()

    r = await client.post(
        "/api/v1/auth/login",
        json={"email": "fb_only@example.com", "password": "whatever"},
    )
    assert r.status_code == 401
