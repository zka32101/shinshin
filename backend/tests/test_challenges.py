import uuid
import pytest
from httpx import AsyncClient

from app.models.story import StoryChoice


async def _create_user_and_child(client: AsyncClient, email: str, name: str, grade: int = 3) -> dict:
    """別の親ユーザー + 子どもプロフィールを作成し、authヘッダーと子ども情報を返す"""
    register = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "TestPassword123", "name": name},
    )
    assert register.status_code == 201, register.text
    token = register.json()["accessToken"]
    headers = {"Authorization": f"Bearer {token}"}

    child_resp = await client.post(
        "/api/v1/children",
        json={"name": f"{name}の子ども", "grade": grade, "avatarEmoji": "🐣"},
        headers=headers,
    )
    assert child_resp.status_code == 201, child_resp.text
    return {"headers": headers, "child": child_resp.json()}


async def _make_friends(client: AsyncClient, headers: dict, child_id: str, other_invite_code: str) -> None:
    resp = await client.post(
        "/api/v1/friends",
        json={"childId": child_id, "inviteCode": other_invite_code},
        headers=headers,
    )
    assert resp.status_code == 201, resp.text


@pytest.fixture
async def second_choice(test_story: dict, testing_db) -> str:
    """test_story に2つ目の選択肢を追加し、そのIDを返す（招待した側/された側で違う選択をするテスト用）"""
    choice_id = uuid.uuid4()
    async with testing_db() as session:
        session.add(
            StoryChoice(
                id=choice_id,
                story_id=uuid.UUID(test_story["id"]),
                order=2,
                text="先生に相談する",
                branch_content="太郎は先生に相談しました。",
                reflection="頼ることも大切です。",
                value="responsibility",
                points=10,
                is_recommended=False,
            )
        )
        await session.commit()
    return str(choice_id)


@pytest.mark.asyncio
async def test_create_challenge_requires_friendship(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict
):
    """友だちでない相手にはチャレンジを作成できない（403）"""
    other = await _create_user_and_child(client, "chal1@example.com", "チャレンジ一号")

    response = await client.post(
        "/api/v1/challenges",
        json={
            "childId": test_child["id"],
            "friendChildId": other["child"]["id"],
            "storyId": test_story["id"],
        },
        headers=auth_headers,
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_challenge_lifecycle_create_respond_complete(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict, second_choice: str
):
    """作成 → 招待された側が回答 → 完了、まで一通り確認する"""
    other = await _create_user_and_child(client, "chal2@example.com", "チャレンジ二号")
    await _make_friends(client, auth_headers, test_child["id"], other["child"]["inviteCode"])

    # 招待する側は自分の選択（既存の choice）を添えて作成
    create_resp = await client.post(
        "/api/v1/challenges",
        json={
            "childId": test_child["id"],
            "friendChildId": other["child"]["id"],
            "storyId": test_story["id"],
            "choiceId": test_story["choice_id"],
        },
        headers=auth_headers,
    )
    assert create_resp.status_code == 201, create_resp.text
    challenge = create_resp.json()
    assert challenge["status"] == "pending"
    assert challenge["initiatorChildId"] == test_child["id"]
    assert challenge["inviteeChildId"] == other["child"]["id"]
    # 自分の選択は見えるが、相手の未回答分はそもそも存在しない
    assert challenge["initiatorChoiceId"] == test_story["choice_id"]
    assert challenge["inviteeChoiceId"] is None
    challenge_id = challenge["id"]

    # 招待された側の一覧に表示される（相手の選択は completed になるまで見えない）
    other_list_resp = await client.get(
        "/api/v1/challenges", params={"child_id": other["child"]["id"]}, headers=other["headers"]
    )
    assert other_list_resp.status_code == 200
    other_list = other_list_resp.json()
    assert len(other_list) == 1
    assert other_list[0]["status"] == "pending"
    assert other_list[0]["initiatorChoiceId"] is None  # 相手（招待した側）の選択は隠される
    assert other_list[0]["inviteeChoiceId"] is None

    # 招待された側が別の選択肢で回答
    respond_resp = await client.post(
        f"/api/v1/challenges/{challenge_id}/respond",
        json={"childId": other["child"]["id"], "choiceId": second_choice},
        headers=other["headers"],
    )
    assert respond_resp.status_code == 200, respond_resp.text
    completed = respond_resp.json()
    assert completed["status"] == "completed"
    assert completed["completedAt"] is not None
    # 完了後は自分の回答が見える
    assert completed["inviteeChoiceId"] == second_choice

    # 双方が完了後は互いの選択が見える
    final_view = await client.get(
        f"/api/v1/challenges/{challenge_id}",
        params={"child_id": test_child["id"]},
        headers=auth_headers,
    )
    assert final_view.status_code == 200
    data = final_view.json()
    assert data["status"] == "completed"
    assert data["initiatorChoiceId"] == test_story["choice_id"]
    assert data["inviteeChoiceId"] == second_choice


@pytest.mark.asyncio
async def test_opponent_choice_hidden_before_completion(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict, second_choice: str
):
    """双方揃うまでは相手の選択が見えない（先出し防止）"""
    other = await _create_user_and_child(client, "chal3@example.com", "チャレンジ三号")
    await _make_friends(client, auth_headers, test_child["id"], other["child"]["inviteCode"])

    create_resp = await client.post(
        "/api/v1/challenges",
        json={
            "childId": test_child["id"],
            "friendChildId": other["child"]["id"],
            "storyId": test_story["id"],
            "choiceId": test_story["choice_id"],
        },
        headers=auth_headers,
    )
    challenge_id = create_resp.json()["id"]

    # 招待された側がまだ回答していない状態で、招待した側が詳細を見ても相手の選択(null)は分からない
    view_resp = await client.get(
        f"/api/v1/challenges/{challenge_id}",
        params={"child_id": test_child["id"]},
        headers=auth_headers,
    )
    assert view_resp.status_code == 200
    data = view_resp.json()
    assert data["status"] == "pending"
    assert data["inviteeChoiceId"] is None


@pytest.mark.asyncio
async def test_respond_twice_rejected(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict, second_choice: str
):
    """同じ側が二重に回答しようとすると409"""
    other = await _create_user_and_child(client, "chal4@example.com", "チャレンジ四号")
    await _make_friends(client, auth_headers, test_child["id"], other["child"]["inviteCode"])

    create_resp = await client.post(
        "/api/v1/challenges",
        json={
            "childId": test_child["id"],
            "friendChildId": other["child"]["id"],
            "storyId": test_story["id"],
        },
        headers=auth_headers,
    )
    challenge_id = create_resp.json()["id"]

    first = await client.post(
        f"/api/v1/challenges/{challenge_id}/respond",
        json={"childId": test_child["id"], "choiceId": test_story["choice_id"]},
        headers=auth_headers,
    )
    assert first.status_code == 200

    second = await client.post(
        f"/api/v1/challenges/{challenge_id}/respond",
        json={"childId": test_child["id"], "choiceId": second_choice},
        headers=auth_headers,
    )
    assert second.status_code == 409


@pytest.mark.asyncio
async def test_respond_after_completion_rejected(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict, second_choice: str
):
    """完了済みチャレンジへの追加回答は409"""
    other = await _create_user_and_child(client, "chal5@example.com", "チャレンジ五号")
    await _make_friends(client, auth_headers, test_child["id"], other["child"]["inviteCode"])

    create_resp = await client.post(
        "/api/v1/challenges",
        json={
            "childId": test_child["id"],
            "friendChildId": other["child"]["id"],
            "storyId": test_story["id"],
            "choiceId": test_story["choice_id"],
        },
        headers=auth_headers,
    )
    challenge_id = create_resp.json()["id"]

    respond_resp = await client.post(
        f"/api/v1/challenges/{challenge_id}/respond",
        json={"childId": other["child"]["id"], "choiceId": second_choice},
        headers=other["headers"],
    )
    assert respond_resp.status_code == 200
    assert respond_resp.json()["status"] == "completed"

    third_party_resp = await client.post(
        f"/api/v1/challenges/{challenge_id}/respond",
        json={"childId": other["child"]["id"], "choiceId": second_choice},
        headers=other["headers"],
    )
    assert third_party_resp.status_code == 409


@pytest.mark.asyncio
async def test_create_challenge_requires_ownership(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict
):
    """他人の子どもIDでチャレンジを作成しようとすると404"""
    other = await _create_user_and_child(client, "chal6@example.com", "チャレンジ六号")

    response = await client.post(
        "/api/v1/challenges",
        json={
            "childId": other["child"]["id"],
            "friendChildId": test_child["id"],
            "storyId": test_story["id"],
        },
        headers=auth_headers,
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_get_challenge_forbidden_for_non_participant_child(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict
):
    """自分の子どもだが、そのチャレンジの当事者でない場合は403"""
    other = await _create_user_and_child(client, "chal9@example.com", "チャレンジ九号")
    bystander = await _create_user_and_child(client, "chal10@example.com", "チャレンジ十号")
    await _make_friends(client, auth_headers, test_child["id"], other["child"]["inviteCode"])
    await _make_friends(client, auth_headers, test_child["id"], bystander["child"]["inviteCode"])

    create_resp = await client.post(
        "/api/v1/challenges",
        json={
            "childId": test_child["id"],
            "friendChildId": other["child"]["id"],
            "storyId": test_story["id"],
        },
        headers=auth_headers,
    )
    challenge_id = create_resp.json()["id"]

    response = await client.get(
        f"/api/v1/challenges/{challenge_id}",
        params={"child_id": bystander["child"]["id"]},
        headers=bystander["headers"],
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_list_challenges_filters_by_status(
    client: AsyncClient, auth_headers: dict, test_child: dict, test_story: dict, second_choice: str
):
    """status クエリで pending / completed を絞り込める"""
    other = await _create_user_and_child(client, "chal11@example.com", "チャレンジ十一号")
    await _make_friends(client, auth_headers, test_child["id"], other["child"]["inviteCode"])

    create_resp = await client.post(
        "/api/v1/challenges",
        json={
            "childId": test_child["id"],
            "friendChildId": other["child"]["id"],
            "storyId": test_story["id"],
            "choiceId": test_story["choice_id"],
        },
        headers=auth_headers,
    )
    challenge_id = create_resp.json()["id"]

    pending_resp = await client.get(
        "/api/v1/challenges",
        params={"child_id": test_child["id"], "status": "pending"},
        headers=auth_headers,
    )
    assert len(pending_resp.json()) == 1

    completed_resp = await client.get(
        "/api/v1/challenges",
        params={"child_id": test_child["id"], "status": "completed"},
        headers=auth_headers,
    )
    assert completed_resp.json() == []

    await client.post(
        f"/api/v1/challenges/{challenge_id}/respond",
        json={"childId": other["child"]["id"], "choiceId": second_choice},
        headers=other["headers"],
    )

    completed_resp_2 = await client.get(
        "/api/v1/challenges",
        params={"child_id": test_child["id"], "status": "completed"},
        headers=auth_headers,
    )
    assert len(completed_resp_2.json()) == 1
