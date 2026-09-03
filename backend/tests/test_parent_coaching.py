"""親向けコーチング機能のテスト"""

import pytest
import uuid
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import WeeklyCoachingData, Child, User
from app.services.parent_analytics_service import ParentAnalyticsService
from app.services.gemini_coaching_service import GeminiCoachingService, CoachingMessage


@pytest.mark.asyncio
async def test_parent_analytics_weekly_analysis(db_session: AsyncSession):
    """週次分析の生成テスト"""

    # テストデータ作成
    parent_id = str(uuid.uuid4())
    child_id = uuid.uuid4()

    # サービスを初期化
    analytics_service = ParentAnalyticsService(db_session)

    # 週次分析を生成
    week_start = datetime.utcnow() - timedelta(days=7)
    coaching_data = await analytics_service.generate_weekly_analysis(
        child_id=child_id,
        parent_id=parent_id,
        week_start=week_start,
    )

    # アサーション
    assert coaching_data.child_id == child_id
    assert coaching_data.parent_id == parent_id
    assert coaching_data.week_start_date == week_start
    assert isinstance(coaching_data.weekly_stories_completed, int)
    assert isinstance(coaching_data.weekly_study_minutes, int)
    assert isinstance(coaching_data.weekly_points_earned, int)


@pytest.mark.asyncio
async def test_coaching_message_generation():
    """Gemini AI コーチングメッセージ生成テスト（モック）"""

    # テスト用のコーチングメッセージ
    coaching_message = CoachingMessage(
        highlight="これ週も頑張りました！",
        advice="来週は思いやりのストーリーがお勧めです。",
        parent_tip="お子様の成長を応援しています。",
    )

    # アサーション
    assert coaching_message.highlight == "これ週も頑張りました！"
    assert coaching_message.advice == "来週は思いやりのストーリーがお勧めです。"
    assert coaching_message.parent_tip == "お子様の成長を応援しています。"

    # to_dict() メソッドをテスト
    message_dict = coaching_message.to_dict()
    assert "highlight" in message_dict
    assert "advice" in message_dict
    assert "parent_tip" in message_dict


def test_coaching_data_to_dict():
    """WeeklyCoachingData の to_dict() メソッドテスト"""

    coaching_data = WeeklyCoachingData(
        child_id="test-child",
        parent_id="test-parent",
        week_start_date=datetime.utcnow(),
        week_end_date=datetime.utcnow() + timedelta(days=7),
        week_number=20,
        weekly_stories_completed=5,
        weekly_study_minutes=120,
        weekly_points_earned=250,
        strongest_virtue="思いやり",
        weakest_virtue="責任",
        highlight="頑張りました！",
    )

    data_dict = coaching_data.to_dict()

    # アサーション
    assert data_dict["child_id"] == "test-child"
    assert data_dict["week_number"] == 20
    assert data_dict["weekly_stories_completed"] == 5
    assert data_dict["weekly_study_minutes"] == 120
    assert data_dict["weekly_points_earned"] == 250
