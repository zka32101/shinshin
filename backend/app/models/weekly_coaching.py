"""WeeklyCoachingData モデル（親向け週次コーチング分析）"""

from datetime import datetime
from typing import Dict, Optional
from sqlalchemy import Column, String, Integer, Float, DateTime, JSON, Text
from sqlalchemy_utils import UUIDType
import uuid
from app.db.base import Base


class WeeklyCoachingData(Base):
    """
    親向け週次コーチング分析データ
    MonthlyReport とは独立した週次分析を管理
    """

    __tablename__ = "weekly_coaching_data"

    # PK & FK
    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4)
    child_id = Column(String(255), nullable=False, index=True)
    parent_id = Column(String(255), nullable=False, index=True)

    # 週次分析期間
    week_start_date = Column(DateTime, nullable=False, index=True)
    week_end_date = Column(DateTime, nullable=False)
    week_number = Column(Integer, nullable=False)  # 1-53

    # 学習統計
    weekly_stories_completed = Column(Integer, default=0)
    weekly_study_minutes = Column(Integer, default=0)
    weekly_points_earned = Column(Integer, default=0)

    # 徳目分析（virtue = 道徳的な徳目）
    strongest_virtue = Column(String(100), nullable=True)  # 最も伸びた徳目
    weakest_virtue = Column(String(100), nullable=True)    # 最も改善が必要な徳目
    virtue_score_changes = Column(JSON, default={})  # {"思いやり": +25, "責任": -5, ...}

    # 進捗指標
    completion_streak = Column(Integer, default=0)  # 連続完了日数
    previous_week_points = Column(Integer, default=0)  # 前週の獲得ポイント
    trend_analysis = Column(Text, nullable=True)  # テキスト分析（e.g., "前週比+20%"）

    # マイルストーン
    next_milestone = Column(String(255), nullable=True)  # 次のマイルストーン（e.g., "レベル5到達まであと10ポイント"）

    # Gemini AI コーチング内容
    highlight = Column(Text, nullable=True)  # 🌟 この週の成長（50文字程度）
    advice = Column(Text, nullable=True)  # 💡 来週へのアドバイス（50文字程度）
    parent_tip = Column(Text, nullable=True)  # 👨‍👩‍👧 親向けメッセージ（50文字程度）

    # メール送信管理
    email_sent = Column(DateTime, nullable=True)  # メール送信日時
    sendgrid_message_id = Column(String(255), nullable=True)  # SendGrid メッセージID
    email_opened = Column(DateTime, nullable=True)  # 開封日時（Webhook トラッキング用）

    # メタデータ
    analyzed_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return (
            f"<WeeklyCoachingData(child_id={self.child_id}, "
            f"week={self.week_number}, "
            f"points={self.weekly_points_earned})>"
        )

    def to_dict(self) -> Dict:
        """辞書形式に変換（JSON シリアライズ用）"""
        return {
            "id": str(self.id),
            "child_id": self.child_id,
            "parent_id": self.parent_id,
            "week_start_date": self.week_start_date.isoformat() if self.week_start_date else None,
            "week_end_date": self.week_end_date.isoformat() if self.week_end_date else None,
            "week_number": self.week_number,
            "weekly_stories_completed": self.weekly_stories_completed,
            "weekly_study_minutes": self.weekly_study_minutes,
            "weekly_points_earned": self.weekly_points_earned,
            "strongest_virtue": self.strongest_virtue,
            "weakest_virtue": self.weakest_virtue,
            "virtue_score_changes": self.virtue_score_changes,
            "completion_streak": self.completion_streak,
            "trend_analysis": self.trend_analysis,
            "next_milestone": self.next_milestone,
            "highlight": self.highlight,
            "advice": self.advice,
            "parent_tip": self.parent_tip,
            "email_sent": self.email_sent.isoformat() if self.email_sent else None,
            "analyzed_at": self.analyzed_at.isoformat() if self.analyzed_at else None,
        }
