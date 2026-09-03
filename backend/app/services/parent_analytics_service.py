"""親向け週次分析サービス - ParentAnalyticsService"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from sqlalchemy import func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlalchemy import select

from app.models import WeeklyCoachingData, Progress, Story, QuizSession, Child
from app.db.base import Base


class ParentAnalyticsService:
    """
    子の学習データから親向けの週次分析を生成するサービス
    MonthlyReport とは独立した分析ロジック
    """

    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def generate_weekly_analysis(
        self,
        child_id: str,
        parent_id: str,
        week_start: datetime,
    ) -> WeeklyCoachingData:
        """
        指定期間の週次コーチング分析データを生成

        Args:
            child_id: 子の ID
            parent_id: 親の ID
            week_start: 週の開始日時（通常：日曜日）

        Returns:
            WeeklyCoachingData: 週次分析データ
        """

        week_end = week_start + timedelta(days=7)
        week_number = week_start.isocalendar()[1]

        # 1. 週間ストーリー完了数を集計
        weekly_stories = await self._get_weekly_stories_completed(
            child_id, week_start, week_end
        )

        # 2. 週間学習時間を集計
        weekly_minutes = await self._get_weekly_study_minutes(
            child_id, week_start, week_end
        )

        # 3. 週間獲得ポイントを集計
        weekly_points = await self._get_weekly_points_earned(
            child_id, week_start, week_end
        )

        # 4. 徳目スコア変化を分析
        virtue_changes = await self._analyze_virtue_changes(
            child_id, week_start, week_end
        )
        strongest_virtue = max(virtue_changes, key=virtue_changes.get) if virtue_changes else None
        weakest_virtue = min(virtue_changes, key=virtue_changes.get) if virtue_changes else None

        # 5. 連続完了日数を計算
        completion_streak = await self._calculate_completion_streak(child_id)

        # 6. 前週のポイントを取得
        prev_week_start = week_start - timedelta(days=7)
        prev_week_points = await self._get_weekly_points_earned(
            child_id, prev_week_start, week_start
        )

        # 7. トレンド分析
        trend_analysis = self._analyze_trend(weekly_points, prev_week_points)

        # 8. 次のマイルストーン
        next_milestone = await self._calculate_next_milestone(child_id, weekly_points)

        # WeeklyCoachingData モデルを作成
        coaching_data = WeeklyCoachingData(
            child_id=child_id,
            parent_id=parent_id,
            week_start_date=week_start,
            week_end_date=week_end,
            week_number=week_number,
            weekly_stories_completed=weekly_stories,
            weekly_study_minutes=weekly_minutes,
            weekly_points_earned=weekly_points,
            strongest_virtue=strongest_virtue,
            weakest_virtue=weakest_virtue,
            virtue_score_changes=virtue_changes,
            completion_streak=completion_streak,
            previous_week_points=prev_week_points,
            trend_analysis=trend_analysis,
            next_milestone=next_milestone,
            analyzed_at=datetime.utcnow(),
        )

        return coaching_data

    async def _get_weekly_stories_completed(
        self,
        child_id: str,
        week_start: datetime,
        week_end: datetime,
    ) -> int:
        """この週に完了したストーリー数を取得"""
        result = await self.db.execute(
            select(func.count(Progress.id)).where(
                (Progress.child_id == child_id)
                & (Progress.recorded_at >= week_start)
                & (Progress.recorded_at < week_end)
                & (Progress.action == "story_completed")
            )
        )
        return result.scalar() or 0

    async def _get_weekly_study_minutes(
        self,
        child_id: str,
        week_start: datetime,
        week_end: datetime,
    ) -> int:
        """この週の学習時間を分単位で取得（進捗レコード数×5分で概算）"""
        result = await self.db.execute(
            select(func.count(Progress.id)).where(
                (Progress.child_id == child_id)
                & (Progress.recorded_at >= week_start)
                & (Progress.recorded_at < week_end)
            )
        )
        # 各進捗レコードを約5分として計算
        count = result.scalar() or 0
        return int(count * 5)

    async def _get_weekly_points_earned(
        self,
        child_id: str,
        week_start: datetime,
        week_end: datetime,
    ) -> int:
        """この週に獲得したポイントを取得"""
        result = await self.db.execute(
            select(func.coalesce(func.sum(Progress.points_delta), 0)).where(
                (Progress.child_id == child_id)
                & (Progress.recorded_at >= week_start)
                & (Progress.recorded_at < week_end)
            )
        )
        return int(result.scalar() or 0)

    async def _analyze_virtue_changes(
        self,
        child_id: str,
        week_start: datetime,
        week_end: datetime,
    ) -> Dict[str, int]:
        """
        この週の徳目スコア変化を分析
        Returns: {"思いやり": 25, "責任": -5, ...}
        """
        # Progress から virtue_score_delta を抽出
        result = await self.db.execute(
            select(Progress.virtue_scores).where(
                (Progress.child_id == child_id)
                & (Progress.completed_at >= week_start)
                & (Progress.completed_at < week_end)
            )
        )

        virtue_changes: Dict[str, int] = {}
        for row in result.scalars().all():
            if row:  # virtue_scores は JSON カラム
                for virtue, change in row.items():
                    virtue_changes[virtue] = virtue_changes.get(virtue, 0) + change

        return virtue_changes

    async def _calculate_completion_streak(self, child_id: str) -> int:
        """
        連続完了日数を計算（本日を含む）
        """
        # 子の completed_at を日付ごとにグループ化して、連続した日数を数える
        result = await self.db.execute(
            select(Progress.completed_at)
            .where(
                (Progress.child_id == child_id)
                & (Progress.status == "completed")
            )
            .order_by(Progress.completed_at.desc())
        )

        completed_dates = set()
        for row in result.scalars().all():
            if row:
                completed_dates.add(row.date())

        # 本日から遡って連続した日数を計算
        streak = 0
        current_date = datetime.utcnow().date()
        while current_date in completed_dates:
            streak += 1
            current_date -= timedelta(days=1)

        return streak

    def _analyze_trend(self, current_points: int, previous_points: int) -> str:
        """トレンド分析テキストを生成"""
        if previous_points == 0:
            return "初週のため比較対象がありません"

        percentage = ((current_points - previous_points) / previous_points) * 100
        if percentage > 0:
            return f"前週比 +{percentage:.0f}% で好調な伸び"
        elif percentage < 0:
            return f"前週比 {percentage:.0f}% で少し下降"
        else:
            return "前週と同程度の進捗"

    async def _calculate_next_milestone(
        self,
        child_id: str,
        weekly_points: int,
    ) -> Optional[str]:
        """次のマイルストーン（目標）を計算"""
        # Child の current_level と total_points を取得
        result = await self.db.execute(
            select(Child).where(Child.id == child_id)
        )
        child = result.scalar_one_or_none()

        if not child:
            return None

        # 仮定：次のレベルアップには 500ポイント必要
        points_per_level = 500
        next_level = child.level + 1
        points_for_next_level = next_level * points_per_level
        points_needed = max(0, points_for_next_level - child.total_points)

        if points_needed == 0:
            return f"レベル {next_level} に到達！おめでとう！"

        return f"レベル {next_level} 到達まであと {points_needed} ポイント"

    async def save_weekly_coaching_data(
        self,
        coaching_data: WeeklyCoachingData,
    ) -> WeeklyCoachingData:
        """週次分析データを Firestore に保存"""
        self.db.add(coaching_data)
        await self.db.commit()
        await self.db.refresh(coaching_data)
        return coaching_data
