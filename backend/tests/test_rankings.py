import pytest
from httpx import AsyncClient
from datetime import date
from uuid import UUID


@pytest.mark.asyncio
async def test_get_monthly_ranking_empty(client: AsyncClient, auth_headers: dict):
    """Test getting monthly ranking when no data exists"""
    response = await client.get(
        "/api/v1/rankings/month/2026-09-01",
        params={"group_type": "overall"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["ranking_month"] == "2026-09-01"
    assert data["group_type"] == "overall"
    assert data["rankings"] == []


@pytest.mark.asyncio
async def test_get_monthly_ranking_by_group_type(
    client: AsyncClient, auth_headers: dict
):
    """Test getting monthly ranking with different group types"""
    group_types = ["overall", "by_grade", "by_start_month", "combined"]

    for group_type in group_types:
        response = await client.get(
            "/api/v1/rankings/month/2026-09-01",
            params={"group_type": group_type},
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["group_type"] == group_type


@pytest.mark.asyncio
async def test_get_child_current_ranking_not_found(
    client: AsyncClient, auth_headers: dict, test_child: dict
):
    """Test getting child's ranking when no ranking data exists"""
    child_id = test_child["id"]
    response = await client.get(
        f"/api/v1/rankings/child/{child_id}/current",
        params={"group_type": "overall"},
        headers=auth_headers,
    )
    # Should return 200 with None (no ranking exists yet)
    assert response.status_code == 200 or response.status_code == 204


@pytest.mark.asyncio
async def test_monthly_ranking_anonymizes_name_by_default(
    client: AsyncClient, auth_headers: dict, test_child: dict, db_session
):
    """isNamePublic が false（デフォルト）の場合、実名ではなく匿名表示名を返す"""
    from app.models.ranking import Ranking
    from app.models.child import Child
    from sqlalchemy import select

    child_id = UUID(test_child["id"])
    child = (
        await db_session.execute(select(Child).where(Child.id == child_id))
    ).scalar_one()
    assert child.is_name_public is False

    db_session.add(
        Ranking(
            child_id=child_id,
            ranking_month=date(2026, 9, 1),
            group_type="overall",
            group_value=None,
            rank=1,
            total_answers=5,
            total_growth_score=100,
        )
    )
    await db_session.commit()

    response = await client.get(
        "/api/v1/rankings/month/2026-09-01",
        params={"group_type": "overall"},
        headers=auth_headers,
    )
    data = response.json()
    assert data["rankings"][0]["child_name"] == "ユーザー"
    assert data["rankings"][0]["child_name"] != child.name


@pytest.mark.asyncio
async def test_monthly_ranking_shows_name_when_public(
    client: AsyncClient, auth_headers: dict, test_child: dict, db_session
):
    """isNamePublic が true の場合、実名を返す"""
    from app.models.ranking import Ranking
    from app.models.child import Child
    from sqlalchemy import select

    child_id = UUID(test_child["id"])
    child = (
        await db_session.execute(select(Child).where(Child.id == child_id))
    ).scalar_one()
    child.is_name_public = True
    db_session.add(
        Ranking(
            child_id=child_id,
            ranking_month=date(2026, 9, 1),
            group_type="overall",
            group_value=None,
            rank=1,
            total_answers=5,
            total_growth_score=100,
        )
    )
    await db_session.commit()

    response = await client.get(
        "/api/v1/rankings/month/2026-09-01",
        params={"group_type": "overall"},
        headers=auth_headers,
    )
    data = response.json()
    assert data["rankings"][0]["child_name"] == child.name
