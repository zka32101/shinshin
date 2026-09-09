"""
ランキングサービス
月間ランキングの計算と保存を担当
"""

import logging
from datetime import datetime, date, timedelta
from typing import List, Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.models.ranking import Ranking
from app.models.child import Child
from app.models.quiz import QuizSession
from app.models.story import StoryChoice
from app.models.friend import Friend

logger = logging.getLogger(__name__)


class RankingService:
    """ランキング計算・管理サービス"""

    @staticmethod
    async def calculate_child_stats(
        session: AsyncSession,
        child_id: UUID,
        start_date: date,
        end_date: date,
    ) -> tuple[int, int]:
        """
        指定期間における子どもの統計を計算

        Args:
            session: DB セッション
            child_id: 子ども ID
            start_date: 集計開始日
            end_date: 集計終了日

        Returns:
            (total_answers, total_growth_score) のタプル
        """
        # 完了済みの QuizSession を取得
        result = await session.execute(
            select(
                func.count(QuizSession.id).label("total_answers"),
                func.sum(QuizSession.points_earned).label("total_points"),
            ).where(
                and_(
                    QuizSession.child_id == child_id,
                    QuizSession.is_completed == True,
                    QuizSession.completed_at >= datetime.combine(start_date, datetime.min.time()),
                    QuizSession.completed_at <= datetime.combine(end_date, datetime.max.time()),
                )
            )
        )

        row = result.one()
        total_answers = row[0] or 0
        total_growth_score = row[1] or 0

        return total_answers, total_growth_score

    @staticmethod
    async def calculate_rankings_for_month(
        session: AsyncSession,
        ranking_month: date,
    ) -> None:
        """
        指定月のランキングを計算して保存

        Args:
            session: DB セッション
            ranking_month: ランキング対象月 (例: 2026-09-01)
        """
        logger.info(f"Calculating rankings for {ranking_month}")

        # 月の開始日と終了日を計算
        year = ranking_month.year
        month = ranking_month.month

        if month == 12:
            next_month = date(year + 1, 1, 1)
        else:
            next_month = date(year, month + 1, 1)

        start_date = date(year, month, 1)
        end_date = next_month - timedelta(days=1)

        # 全ての子どもを取得
        children_result = await session.execute(select(Child))
        children = children_result.scalars().all()

        # 既存のランキングデータを削除（再計算用）
        existing = await session.execute(
            select(Ranking).where(Ranking.ranking_month == ranking_month)
        )
        existing_rankings = existing.scalars().all()
        for ranking in existing_rankings:
            session.delete(ranking)

        # 全体ランキング（overall）を計算
        await RankingService._calculate_overall_ranking(
            session, children, start_date, end_date, ranking_month
        )

        # 学年別ランキング（by_grade）を計算
        await RankingService._calculate_grade_ranking(
            session, children, start_date, end_date, ranking_month
        )

        # 開始月別ランキング（by_start_month）を計算
        await RankingService._calculate_start_month_ranking(
            session, children, start_date, end_date, ranking_month
        )

        # 複合ランキング（combined）を計算
        await RankingService._calculate_combined_ranking(
            session, children, start_date, end_date, ranking_month
        )

        # 友だちランキング（friends）を計算
        await RankingService._calculate_friends_ranking(
            session, children, start_date, end_date, ranking_month
        )

        await session.commit()
        logger.info(f"Ranking calculation completed for {ranking_month}")

    @staticmethod
    async def _calculate_overall_ranking(
        session: AsyncSession,
        children: List[Child],
        start_date: date,
        end_date: date,
        ranking_month: date,
    ) -> None:
        """全体ランキングを計算して保存"""
        # 各子どもの統計を計算
        child_stats = []
        for child in children:
            total_answers, total_growth_score = (
                await RankingService.calculate_child_stats(
                    session, child.id, start_date, end_date
                )
            )
            child_stats.append({
                "child_id": child.id,
                "total_answers": total_answers,
                "total_growth_score": total_growth_score,
            })

        # スコアでソート（成長スコア > 回答数の順）
        child_stats.sort(
            key=lambda x: (x["total_growth_score"], x["total_answers"]),
            reverse=True
        )

        # ランキングレコードを作成
        for rank, stats in enumerate(child_stats, start=1):
            ranking = Ranking(
                child_id=stats["child_id"],
                ranking_month=ranking_month,
                group_type="overall",
                group_value=None,
                rank=rank,
                total_answers=stats["total_answers"],
                total_growth_score=stats["total_growth_score"],
            )
            session.add(ranking)

    @staticmethod
    async def _calculate_grade_ranking(
        session: AsyncSession,
        children: List[Child],
        start_date: date,
        end_date: date,
        ranking_month: date,
    ) -> None:
        """学年別ランキングを計算して保存"""
        # 学年ごとに子どもをグループ化
        children_by_grade = {}
        for child in children:
            grade = child.grade
            if grade not in children_by_grade:
                children_by_grade[grade] = []
            children_by_grade[grade].append(child)

        # 学年ごとにランキングを計算
        for grade, grade_children in children_by_grade.items():
            child_stats = []
            for child in grade_children:
                total_answers, total_growth_score = (
                    await RankingService.calculate_child_stats(
                        session, child.id, start_date, end_date
                    )
                )
                child_stats.append({
                    "child_id": child.id,
                    "total_answers": total_answers,
                    "total_growth_score": total_growth_score,
                })

            # スコアでソート
            child_stats.sort(
                key=lambda x: (x["total_growth_score"], x["total_answers"]),
                reverse=True
            )

            # ランキングレコードを作成
            for rank, stats in enumerate(child_stats, start=1):
                ranking = Ranking(
                    child_id=stats["child_id"],
                    ranking_month=ranking_month,
                    group_type="by_grade",
                    group_value=str(grade),
                    rank=rank,
                    total_answers=stats["total_answers"],
                    total_growth_score=stats["total_growth_score"],
                )
                session.add(ranking)

    @staticmethod
    async def _calculate_start_month_ranking(
        session: AsyncSession,
        children: List[Child],
        start_date: date,
        end_date: date,
        ranking_month: date,
    ) -> None:
        """開始月別ランキングを計算して保存"""
        # 開始月ごとに子どもをグループ化
        children_by_start_month = {}
        for child in children:
            start_month_str = child.created_at.strftime("%Y-%m")
            if start_month_str not in children_by_start_month:
                children_by_start_month[start_month_str] = []
            children_by_start_month[start_month_str].append(child)

        # 開始月ごとにランキングを計算
        for start_month, month_children in children_by_start_month.items():
            child_stats = []
            for child in month_children:
                total_answers, total_growth_score = (
                    await RankingService.calculate_child_stats(
                        session, child.id, start_date, end_date
                    )
                )
                child_stats.append({
                    "child_id": child.id,
                    "total_answers": total_answers,
                    "total_growth_score": total_growth_score,
                })

            # スコアでソート
            child_stats.sort(
                key=lambda x: (x["total_growth_score"], x["total_answers"]),
                reverse=True
            )

            # ランキングレコードを作成
            for rank, stats in enumerate(child_stats, start=1):
                ranking = Ranking(
                    child_id=stats["child_id"],
                    ranking_month=ranking_month,
                    group_type="by_start_month",
                    group_value=start_month,
                    rank=rank,
                    total_answers=stats["total_answers"],
                    total_growth_score=stats["total_growth_score"],
                )
                session.add(ranking)

    @staticmethod
    async def _calculate_combined_ranking(
        session: AsyncSession,
        children: List[Child],
        start_date: date,
        end_date: date,
        ranking_month: date,
    ) -> None:
        """複合（学年 + 開始月）ランキングを計算して保存"""
        # 学年と開始月の組み合わせでグループ化
        children_by_combined = {}
        for child in children:
            grade = child.grade
            start_month_str = child.created_at.strftime("%Y-%m")
            key = f"{grade}_{start_month_str}"

            if key not in children_by_combined:
                children_by_combined[key] = []
            children_by_combined[key].append(child)

        # 組み合わせごとにランキングを計算
        for combined_key, combined_children in children_by_combined.items():
            child_stats = []
            for child in combined_children:
                total_answers, total_growth_score = (
                    await RankingService.calculate_child_stats(
                        session, child.id, start_date, end_date
                    )
                )
                child_stats.append({
                    "child_id": child.id,
                    "total_answers": total_answers,
                    "total_growth_score": total_growth_score,
                })

            # スコアでソート
            child_stats.sort(
                key=lambda x: (x["total_growth_score"], x["total_answers"]),
                reverse=True
            )

            # ランキングレコードを作成
            for rank, stats in enumerate(child_stats, start=1):
                ranking = Ranking(
                    child_id=stats["child_id"],
                    ranking_month=ranking_month,
                    group_type="combined",
                    group_value=combined_key,
                    rank=rank,
                    total_answers=stats["total_answers"],
                    total_growth_score=stats["total_growth_score"],
                )
                session.add(ranking)

    @staticmethod
    async def _calculate_friends_ranking(
        session: AsyncSession,
        children: List[Child],
        start_date: date,
        end_date: date,
        ranking_month: date,
    ) -> None:
        """友だちランキングを計算して保存

        友だち関係は子どもごとに異なる集合（友だちの輪）になるため、
        子どもごとに「自分 + 友だち」のグループを作り、
        group_value = str(その輪の持ち主の child_id) として、
        輪に含まれる全メンバー分の Ranking レコードを保存する。
        （= by_grade 等と同じ「グループ内のメンバー全員分を保存する」方式。
        1人の子どもが複数の友だちの輪に所属することもあるため、
        同じ子どもについて group_value の異なる複数の行が作られ得る）

        自分の友だちランキングを見る場合は
        group_type="friends", group_value=str(自分の child_id) で参照する。
        """
        children_by_id = {child.id: child for child in children}

        # 全ての友だち関係を一括取得して child_id ごとにまとめる
        friend_result = await session.execute(select(Friend))
        friend_rows = friend_result.scalars().all()

        friend_ids_by_child: dict = {}
        for row in friend_rows:
            friend_ids_by_child.setdefault(row.child_id, []).append(row.friend_child_id)

        # 統計値をキャッシュして重複計算を避ける
        stats_cache: dict = {}

        async def _get_stats(child_id):
            if child_id not in stats_cache:
                stats_cache[child_id] = await RankingService.calculate_child_stats(
                    session, child_id, start_date, end_date
                )
            return stats_cache[child_id]

        for child in children:
            friend_ids = friend_ids_by_child.get(child.id, [])
            # 友だちが未登録でも自分だけのランキング（順位1）を作成する
            group_member_ids = [child.id] + [
                fid for fid in friend_ids if fid in children_by_id
            ]

            member_stats = []
            for member_id in group_member_ids:
                total_answers, total_growth_score = await _get_stats(member_id)
                member_stats.append({
                    "child_id": member_id,
                    "total_answers": total_answers,
                    "total_growth_score": total_growth_score,
                })

            member_stats.sort(
                key=lambda x: (x["total_growth_score"], x["total_answers"]),
                reverse=True
            )

            for rank, stats in enumerate(member_stats, start=1):
                ranking = Ranking(
                    child_id=stats["child_id"],
                    ranking_month=ranking_month,
                    group_type="friends",
                    group_value=str(child.id),
                    rank=rank,
                    total_answers=stats["total_answers"],
                    total_growth_score=stats["total_growth_score"],
                )
                session.add(ranking)

    @staticmethod
    async def get_ranking_for_month(
        session: AsyncSession,
        ranking_month: date,
        group_type: str = "overall",
        group_value: Optional[str] = None,
    ) -> List[Ranking]:
        """
        指定月のランキングデータを取得

        Args:
            session: DB セッション
            ranking_month: ランキング対象月
            group_type: グループ化タイプ
            group_value: グループ値（該当する場合）

        Returns:
            ランキングレコードのリスト
        """
        query = select(Ranking).where(
            and_(
                Ranking.ranking_month == ranking_month,
                Ranking.group_type == group_type,
            )
        )

        if group_value:
            query = query.where(Ranking.group_value == group_value)

        result = await session.execute(
            query.order_by(Ranking.rank.asc())
        )
        return result.scalars().all()
