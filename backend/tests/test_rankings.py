import pytest
from httpx import AsyncClient
from datetime import date


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
