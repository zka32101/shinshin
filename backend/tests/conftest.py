import os
import pytest
import asyncio
from typing import AsyncGenerator

# Set test DATABASE_URL BEFORE importing app modules so the engine
# uses SQLite in-memory instead of PostgreSQL.
# Note: config.py uses case_sensitive=True, so lowercase key is required.
os.environ["database_url"] = "sqlite+aiosqlite:///:memory:"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"  # also uppercase
os.environ.setdefault("secret_key", "test-secret-key-not-for-production-use-12345678")
os.environ.setdefault("SECRET_KEY", "test-secret-key-not-for-production-use-12345678")
os.environ.setdefault("FIREBASE_PROJECT_ID", "test-project")
# Disable rate limiting for tests to avoid 429 errors during rapid test execution
os.environ.setdefault("RATE_LIMIT_PER_MINUTE", "10000")

from httpx import AsyncClient, ASGITransport  # noqa: E402
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker  # noqa: E402
from app.config import get_settings  # noqa: E402
from app.db.base import Base  # noqa: E402

# Invalidate the lru_cache so settings pick up the overridden env vars
get_settings.cache_clear()

from app.main import app  # noqa: E402
from app.db.database import get_db  # noqa: E402

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(TEST_DB_URL, echo=False)
TestingSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(autouse=True)
async def setup_db():
    """Reset DB tables before each test."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
    async with TestingSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac


@pytest.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Raw DB session for direct manipulation inside tests.
    Call ``await db_session.commit()`` explicitly to make changes visible
    to subsequent HTTP calls through the test client.
    """
    async with TestingSessionLocal() as session:
        yield session


@pytest.fixture
def testing_db():
    """Return the TestingSessionLocal factory for inline session creation."""
    return TestingSessionLocal


@pytest.fixture
async def test_user(client: AsyncClient) -> dict:
    """Create a test user via the register endpoint."""
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "test@example.com", "password": "password123", "name": "テストユーザー"},
    )
    assert response.status_code == 201, response.text
    return response.json()


@pytest.fixture
async def auth_headers(test_user: dict) -> dict:
    """Return Authorization header for the test user."""
    token = test_user.get("accessToken")
    assert token, f"No token in response: {test_user}"
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def test_child(client: AsyncClient, auth_headers: dict) -> dict:
    """Create a test child profile."""
    response = await client.post(
        "/api/v1/children",
        json={"name": "テスト太郎", "grade": 3, "avatarEmoji": "⭐"},
        headers=auth_headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


@pytest.fixture
async def test_story() -> dict:
    """Seed a Story + StoryChoice directly in the test DB; return a dict with id/choice_id."""
    import uuid
    from app.models.story import Story, StoryChoice

    story_id = uuid.uuid4()
    choice_id = uuid.uuid4()

    async with TestingSessionLocal() as session:
        story = Story(
            id=story_id,
            title="テスト道徳ストーリー",
            description="テスト用の説明文",
            theme="kindness",
            grade_min=3,
            difficulty=2,
            is_premium=False,
            content={
                "introduction": "ある日、太郎は公園で…",
                "mainNarrative": ["第一段落のテキスト"],
                "dilemmaScene": "あなたならどうしますか？",
            },
            estimated_minutes=5,
            is_published=True,
        )
        session.add(story)
        await session.flush()

        choice = StoryChoice(
            id=choice_id,
            story_id=story_id,
            order=1,
            text="友達を助ける",
            branch_content="太郎は友達を助けました。",
            reflection="思いやりの大切さを学びました。",
            value="kindness",
            points=15,
            is_recommended=True,
        )
        session.add(choice)
        await session.commit()

    return {"id": str(story_id), "choice_id": str(choice_id)}
