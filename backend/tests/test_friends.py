import pytest
from httpx import AsyncClient
from datetime import date


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


@pytest.mark.asyncio
async def test_child_gets_invite_code_on_creation(client: AsyncClient, auth_headers: dict, test_child: dict):
    """子ども作成時に招待コードが発行される"""
    assert test_child["inviteCode"]
    assert len(test_child["inviteCode"]) == 8


@pytest.mark.asyncio
async def test_add_friend_via_invite_code(client: AsyncClient, auth_headers: dict, test_child: dict):
    """招待コードで友だちを追加できる（双方向に成立する）"""
    other = await _create_user_and_child(client, "friend1@example.com", "友だち一号")

    response = await client.post(
        "/api/v1/friends",
        json={"childId": test_child["id"], "inviteCode": other["child"]["inviteCode"]},
        headers=auth_headers,
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["childId"] == other["child"]["id"]
    assert data["name"] == other["child"]["name"]

    # 自分側の一覧に相手が表示される
    list_resp = await client.get(
        "/api/v1/friends", params={"child_id": test_child["id"]}, headers=auth_headers
    )
    assert list_resp.status_code == 200
    friends = list_resp.json()
    assert len(friends) == 1
    assert friends[0]["childId"] == other["child"]["id"]

    # 相手側の一覧にも自分が表示される（双方向）
    other_list_resp = await client.get(
        "/api/v1/friends",
        params={"child_id": other["child"]["id"]},
        headers=other["headers"],
    )
    assert other_list_resp.status_code == 200
    other_friends = other_list_resp.json()
    assert len(other_friends) == 1
    assert other_friends[0]["childId"] == test_child["id"]


@pytest.mark.asyncio
async def test_add_friend_invalid_code(client: AsyncClient, auth_headers: dict, test_child: dict):
    """存在しない招待コードは404"""
    response = await client.post(
        "/api/v1/friends",
        json={"childId": test_child["id"], "inviteCode": "ZZZZZZZZ"},
        headers=auth_headers,
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_add_friend_self_code_rejected(client: AsyncClient, auth_headers: dict, test_child: dict):
    """自分自身の招待コードでは追加できない"""
    response = await client.post(
        "/api/v1/friends",
        json={"childId": test_child["id"], "inviteCode": test_child["inviteCode"]},
        headers=auth_headers,
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_add_friend_duplicate_rejected(client: AsyncClient, auth_headers: dict, test_child: dict):
    """すでに友だちの相手を再度追加しようとすると409"""
    other = await _create_user_and_child(client, "friend2@example.com", "友だち二号")

    first = await client.post(
        "/api/v1/friends",
        json={"childId": test_child["id"], "inviteCode": other["child"]["inviteCode"]},
        headers=auth_headers,
    )
    assert first.status_code == 201

    second = await client.post(
        "/api/v1/friends",
        json={"childId": test_child["id"], "inviteCode": other["child"]["inviteCode"]},
        headers=auth_headers,
    )
    assert second.status_code == 409


@pytest.mark.asyncio
async def test_remove_friend(client: AsyncClient, auth_headers: dict, test_child: dict):
    """友だちを削除すると双方の一覧から消える"""
    other = await _create_user_and_child(client, "friend3@example.com", "友だち三号")

    add_resp = await client.post(
        "/api/v1/friends",
        json={"childId": test_child["id"], "inviteCode": other["child"]["inviteCode"]},
        headers=auth_headers,
    )
    friend_id = add_resp.json()["friendId"]

    del_resp = await client.delete(
        f"/api/v1/friends/{friend_id}",
        params={"child_id": test_child["id"]},
        headers=auth_headers,
    )
    assert del_resp.status_code == 204

    list_resp = await client.get(
        "/api/v1/friends", params={"child_id": test_child["id"]}, headers=auth_headers
    )
    assert list_resp.json() == []

    other_list_resp = await client.get(
        "/api/v1/friends",
        params={"child_id": other["child"]["id"]},
        headers=other["headers"],
    )
    assert other_list_resp.json() == []


@pytest.mark.asyncio
async def test_friends_endpoints_require_ownership(client: AsyncClient, auth_headers: dict, test_child: dict):
    """他人の子どもIDで友だち一覧を取得しようとすると404"""
    other = await _create_user_and_child(client, "friend4@example.com", "友だち四号")

    response = await client.get(
        "/api/v1/friends", params={"child_id": other["child"]["id"]}, headers=auth_headers
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_friends_ranking_calculation(client: AsyncClient, auth_headers: dict, test_child: dict, db_session):
    """友だちランキングのバッチ計算 → 自分の輪の中で順位付けされる"""
    from app.models.quiz import QuizSession
    from app.models.child import Child
    from sqlalchemy import select
    from uuid import UUID
    from datetime import datetime

    other = await _create_user_and_child(client, "friend5@example.com", "友だち五号")

    add_resp = await client.post(
        "/api/v1/friends",
        json={"childId": test_child["id"], "inviteCode": other["child"]["inviteCode"]},
        headers=auth_headers,
    )
    assert add_resp.status_code == 201

    child_id = UUID(test_child["id"])
    friend_child_id = UUID(other["child"]["id"])

    # 友だちの方がスコアが高くなるよう完了済みクイズセッションを作成
    db_session.add(QuizSession(
        child_id=child_id,
        story_id=None,
        is_completed=True,
        points_earned=10,
        completed_at=datetime(2026, 9, 5),
    ))
    db_session.add(QuizSession(
        child_id=friend_child_id,
        story_id=None,
        is_completed=True,
        points_earned=50,
        completed_at=datetime(2026, 9, 5),
    ))
    await db_session.commit()

    calc_resp = await client.post(
        "/api/v1/rankings/calculate/2026-09-01", headers=auth_headers
    )
    assert calc_resp.status_code == 200, calc_resp.text

    ranking_resp = await client.get(
        "/api/v1/rankings/month/2026-09-01",
        params={"group_type": "friends", "group_value": str(child_id)},
        headers=auth_headers,
    )
    assert ranking_resp.status_code == 200, ranking_resp.text
    rankings = ranking_resp.json()["rankings"]
    assert len(rankings) == 2
    # 友だちの方がポイントが高いので1位
    assert rankings[0]["child_id"] == str(friend_child_id)
    assert rankings[0]["rank"] == 1
    assert rankings[1]["child_id"] == str(child_id)
    assert rankings[1]["rank"] == 2


@pytest.mark.asyncio
async def test_friends_ranking_requires_ownership(client: AsyncClient, auth_headers: dict, test_child: dict):
    """他人の友だちの輪 (group_value) を覗き見できない"""
    other = await _create_user_and_child(client, "friend6@example.com", "友だち六号")

    response = await client.get(
        "/api/v1/rankings/month/2026-09-01",
        params={"group_type": "friends", "group_value": other["child"]["id"]},
        headers=auth_headers,
    )
    assert response.status_code == 403
