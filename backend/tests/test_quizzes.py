"""Tests for quiz session API."""
import pytest
from uuid import uuid4
from httpx import AsyncClient


async def _start_session(client: AsyncClient, auth_headers: dict, child_id: str) -> str:
    """Helper: start a quiz session and return the session ID."""
    story_id = str(uuid4())
    r = await client.post(
        "/api/v1/quizzes",
        json={"childId": child_id, "storyId": story_id},
        headers=auth_headers,
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


@pytest.mark.asyncio
async def test_start_quiz_session(client: AsyncClient, auth_headers: dict, test_child: dict):
    """Start a quiz session returns session ID and metadata."""
    child_id = test_child["id"]
    story_id = str(uuid4())

    r = await client.post(
        "/api/v1/quizzes",
        json={"childId": child_id, "storyId": story_id},
        headers=auth_headers,
    )
    assert r.status_code == 201
    data = r.json()
    assert "id" in data
    assert data["childId"] == child_id
    assert data["storyId"] == story_id
    assert data["isCompleted"] is False
    assert data["pointsEarned"] == 0


@pytest.mark.asyncio
async def test_complete_quiz_session(client: AsyncClient, auth_headers: dict, test_child: dict):
    """Complete a quiz session updates points and is_completed."""
    child_id = test_child["id"]
    session_id = await _start_session(client, auth_headers, child_id)
    choice_id = str(uuid4())  # Unknown choice → fallback points = 10

    r = await client.post(
        f"/api/v1/quizzes/{session_id}/complete",
        json={
            "chosenChoiceId": choice_id,
            "timeSpentSeconds": 120,
            "reflectionText": "よく考えました。",
        },
        headers=auth_headers,
    )
    assert r.status_code == 200
    data = r.json()
    assert data["isCompleted"] is True
    assert data["pointsEarned"] >= 0  # 10 fallback when choice not found
    assert data["timeSpentSeconds"] == 120
    assert data["completedAt"] is not None


@pytest.mark.asyncio
async def test_complete_quiz_without_reflection(
    client: AsyncClient, auth_headers: dict, test_child: dict
):
    """Complete a quiz without reflection text (optional field)."""
    session_id = await _start_session(client, auth_headers, test_child["id"])
    choice_id = str(uuid4())

    r = await client.post(
        f"/api/v1/quizzes/{session_id}/complete",
        json={"chosenChoiceId": choice_id, "timeSpentSeconds": 60},
        headers=auth_headers,
    )
    assert r.status_code == 200
    assert r.json()["isCompleted"] is True


@pytest.mark.asyncio
async def test_start_quiz_unauthorized(client: AsyncClient, test_child: dict):
    """Start quiz without auth returns 401."""
    r = await client.post(
        "/api/v1/quizzes",
        json={"childId": test_child["id"], "storyId": str(uuid4())},
    )
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_start_quiz_other_users_child(
    client: AsyncClient, auth_headers: dict
):
    """Cannot start quiz for another user's child."""
    # Register second user
    r = await client.post(
        "/api/v1/auth/register",
        json={"email": "quiz_other@example.com", "password": "OtherPass123", "name": "Other"},
    )
    assert r.status_code == 201
    other_token = r.json()["accessToken"]

    # Create child for other user
    r2 = await client.post(
        "/api/v1/children",
        json={"name": "OtherKid", "grade": 3, "avatar_emoji": "🐶"},
        headers={"Authorization": f"Bearer {other_token}"},
    )
    assert r2.status_code == 201
    other_child_id = r2.json()["id"]

    # Try to start session with first user's token for other's child
    r3 = await client.post(
        "/api/v1/quizzes",
        json={"childId": other_child_id, "storyId": str(uuid4())},
        headers=auth_headers,
    )
    assert r3.status_code == 403


@pytest.mark.asyncio
async def test_complete_quiz_not_found(client: AsyncClient, auth_headers: dict):
    """Complete a non-existent session returns 404."""
    r = await client.post(
        f"/api/v1/quizzes/{uuid4()}/complete",
        json={"chosenChoiceId": str(uuid4()), "timeSpentSeconds": 30},
        headers=auth_headers,
    )
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_complete_quiz_updates_child_points(
    client: AsyncClient, auth_headers: dict, test_child: dict
):
    """After completing a quiz, child's total_points increases."""
    child_id = test_child["id"]
    initial_points = test_child.get("total_points", 0)

    session_id = await _start_session(client, auth_headers, child_id)
    await client.post(
        f"/api/v1/quizzes/{session_id}/complete",
        json={"chosenChoiceId": str(uuid4()), "timeSpentSeconds": 45},
        headers=auth_headers,
    )

    # Fetch updated child
    r = await client.get(f"/api/v1/children/{child_id}", headers=auth_headers)
    assert r.status_code == 200
    assert r.json()["totalPoints"] > initial_points


@pytest.mark.asyncio
async def test_complete_quiz_with_real_choice(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict
):
    """Complete quiz using a real StoryChoice earns choice-defined points (15)."""
    child_id = test_child["id"]

    # Start session using the seeded story
    r = await client.post(
        "/api/v1/quizzes",
        json={"childId": child_id, "storyId": test_story["id"]},
        headers=auth_headers,
    )
    assert r.status_code == 201
    session_id = r.json()["id"]

    # Complete using the real choice (15 points configured in fixture)
    r2 = await client.post(
        f"/api/v1/quizzes/{session_id}/complete",
        json={"chosenChoiceId": test_story["choice_id"], "timeSpentSeconds": 90},
        headers=auth_headers,
    )
    assert r2.status_code == 200
    data = r2.json()
    assert data["isCompleted"] is True
    assert data["pointsEarned"] == 15  # matches StoryChoice.points in fixture


@pytest.mark.asyncio
async def test_complete_quiz_other_users_child(
    client: AsyncClient, auth_headers: dict, test_child: dict
):
    """Complete a session whose child belongs to another user returns 403."""
    # Start a valid session as user #1
    session_id = await _start_session(client, auth_headers, test_child["id"])

    # Register second user
    r = await client.post(
        "/api/v1/auth/register",
        json={"email": "quiz_complete_other@example.com", "password": "OtherPass123", "name": "Other"},
    )
    assert r.status_code == 201
    other_headers = {"Authorization": f"Bearer {r.json()['accessToken']}"}

    # Second user tries to complete a session that belongs to user #1's child
    r2 = await client.post(
        f"/api/v1/quizzes/{session_id}/complete",
        json={"chosenChoiceId": str(uuid4()), "timeSpentSeconds": 30},
        headers=other_headers,
    )
    assert r2.status_code == 403


@pytest.mark.asyncio
async def test_complete_quiz_with_score_impact(
    client: AsyncClient, auth_headers: dict, test_child: dict, testing_db
):
    """StoryChoice.score_impact triggers _apply_score_impact; scoreDeltas is non-empty."""
    import uuid
    from app.models.story import Story, StoryChoice

    story_id = uuid.uuid4()
    choice_id = uuid.uuid4()

    async with testing_db() as session:
        story = Story(
            id=story_id,
            title="Score Impact テスト",
            description="徳目スコア変化テスト用ストーリー",
            theme="kindness",
            grade_min=3,
            difficulty=1,
            is_premium=False,
            content={
                "introduction": "ある日…",
                "mainNarrative": ["場面テキスト"],
                "dilemmaScene": "どうする？",
            },
            estimated_minutes=3,
            is_published=True,
        )
        session.add(story)
        await session.flush()

        choice = StoryChoice(
            id=choice_id,
            story_id=story_id,
            order=1,
            text="友達を助ける",
            branch_content="助けた結果…",
            reflection="優しさの大切さ",
            value="kindness",
            points=20,
            score_impact={"kindness": 5, "honesty": 2},
        )
        session.add(choice)
        await session.commit()

    child_id = test_child["id"]

    r = await client.post(
        "/api/v1/quizzes",
        json={"childId": child_id, "storyId": str(story_id)},
        headers=auth_headers,
    )
    assert r.status_code == 201
    session_id = r.json()["id"]

    r2 = await client.post(
        f"/api/v1/quizzes/{session_id}/complete",
        json={"chosenChoiceId": str(choice_id), "timeSpentSeconds": 75},
        headers=auth_headers,
    )
    assert r2.status_code == 200
    data = r2.json()
    assert data["pointsEarned"] == 20
    # _apply_score_impact ran → non-zero deltas in response
    assert data["scoreDeltas"].get("kindness") == 5
    assert data["scoreDeltas"].get("honesty") == 2
