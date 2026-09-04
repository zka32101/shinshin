"""Tests for monthly report API."""
import pytest
from datetime import datetime


@pytest.mark.asyncio
async def test_get_report_not_found(client, auth_headers, test_child):
    """Get monthly report when none exists yet."""
    child_id = test_child["id"]
    response = await client.get(
        f"/api/v1/reports/{child_id}/monthly",
        params={"year": 2024, "month": 1},
        headers=auth_headers,
    )
    # Either 404 or empty data
    assert response.status_code in (200, 404)
    if response.status_code == 200:
        data = response.json()
        assert data is None or data.get("id") is not None


@pytest.mark.asyncio
async def test_generate_report(client, auth_headers, test_child):
    """Generate a monthly report."""
    child_id = test_child["id"]
    now = datetime.now()
    response = await client.post(
        f"/api/v1/reports/{child_id}/monthly/generate",
        params={"year": now.year, "month": now.month},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["childId"] == child_id
    assert data["year"] == now.year
    assert data["month"] == now.month
    assert "storiesCompleted" in data
    assert "totalStudyMinutes" in data
    assert "totalPointsEarned" in data
    assert "kindnessScore" in data
    assert "honestyScore" in data
    assert "responsibilityScore" in data
    assert "courageScore" in data
    assert "respectScore" in data
    assert "cooperationScore" in data


@pytest.mark.asyncio
async def test_generate_report_idempotent(client, auth_headers, test_child):
    """Generating report twice returns same (updated) report."""
    child_id = test_child["id"]
    now = datetime.now()
    params = {"year": now.year, "month": now.month}

    r1 = await client.post(
        f"/api/v1/reports/{child_id}/monthly/generate",
        params=params,
        headers=auth_headers,
    )
    r2 = await client.post(
        f"/api/v1/reports/{child_id}/monthly/generate",
        params=params,
        headers=auth_headers,
    )
    assert r1.status_code == 200
    assert r2.status_code == 200
    # Same child and period
    assert r1.json()["childId"] == r2.json()["childId"]
    assert r1.json()["year"] == r2.json()["year"]


@pytest.mark.asyncio
async def test_generate_report_unauthorized(client, auth_headers):
    """Cannot generate report for another user's child."""
    # Register a second user
    r = await client.post(
        "/api/v1/auth/register",
        json={"email": "other@example.com", "password": "OtherPass123", "name": "Other"},
    )
    assert r.status_code == 201
    other_token = r.json()["accessToken"]

    # Create a child for the other user
    r2 = await client.post(
        "/api/v1/children",
        json={"name": "OtherChild", "grade": 3, "avatarEmoji": "🐱"},
        headers={"Authorization": f"Bearer {other_token}"},
    )
    assert r2.status_code == 201
    other_child_id = r2.json()["id"]

    # Try to generate report for other user's child
    now = datetime.now()
    r3 = await client.post(
        f"/api/v1/reports/{other_child_id}/monthly/generate",
        params={"year": now.year, "month": now.month},
        headers=auth_headers,  # original user's token
    )
    assert r3.status_code == 403


@pytest.mark.asyncio
async def test_get_report_after_generate(client, auth_headers, test_child):
    """After generating, GET should return the report."""
    child_id = test_child["id"]
    now = datetime.now()
    params = {"year": now.year, "month": now.month}

    # Generate first
    gen = await client.post(
        f"/api/v1/reports/{child_id}/monthly/generate",
        params=params,
        headers=auth_headers,
    )
    assert gen.status_code == 200
    report_id = gen.json()["id"]

    # Then fetch
    get = await client.get(
        f"/api/v1/reports/{child_id}/monthly",
        params=params,
        headers=auth_headers,
    )
    assert get.status_code == 200
    assert get.json()["id"] == report_id


@pytest.mark.asyncio
async def test_report_has_comments(client, auth_headers, test_child):
    """Generated report should have AI-generated comments."""
    child_id = test_child["id"]
    now = datetime.now()
    r = await client.post(
        f"/api/v1/reports/{child_id}/monthly/generate",
        params={"year": now.year, "month": now.month},
        headers=auth_headers,
    )
    assert r.status_code == 200
    data = r.json()
    # Comments might be None if no activity, but keys should exist
    assert "highlightComment" in data
    assert "growthComment" in data
    assert "adviceComment" in data
    assert "parentMessage" in data


@pytest.mark.asyncio
async def test_get_monthly_report_unauthorized(client, auth_headers):
    """GET /reports/{other_child_id}/monthly returns 403 for unowned child."""
    # Register a second user and create their child
    r = await client.post(
        "/api/v1/auth/register",
        json={"email": "report_other@example.com", "password": "OtherPass123", "name": "Other"},
    )
    assert r.status_code == 201
    other_token = r.json()["accessToken"]

    r2 = await client.post(
        "/api/v1/children",
        json={"name": "OtherKid", "grade": 3, "avatarEmoji": "🐻"},
        headers={"Authorization": f"Bearer {other_token}"},
    )
    assert r2.status_code == 201
    other_child_id = r2.json()["id"]

    # First user tries to GET the other user's report
    r3 = await client.get(
        f"/api/v1/reports/{other_child_id}/monthly",
        params={"year": 2024, "month": 1},
        headers=auth_headers,
    )
    assert r3.status_code == 403


# ── _generate_highlight branch coverage ──────────────────────────────────────

def test_generate_highlight_5_stories():
    """stories_completed >= 5 (but < 10) uses the 'コツコツ' branch."""
    from app.api.reports import _generate_highlight
    from unittest.mock import MagicMock
    child = MagicMock()
    child.name = "花子"
    result = _generate_highlight(child, 5)
    assert "5個" in result
    assert "コツコツ" in result


def test_generate_highlight_10_stories():
    """stories_completed >= 10 uses the 'とても意欲的' branch."""
    from app.api.reports import _generate_highlight
    from unittest.mock import MagicMock
    child = MagicMock()
    child.name = "太郎"
    result = _generate_highlight(child, 10)
    assert "10個" in result
    assert "意欲的" in result
