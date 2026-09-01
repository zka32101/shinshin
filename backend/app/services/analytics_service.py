"""
Firebase Analytics サービス
子どもの個人情報を匿名化した状態でアナリティクスデータを記録
COPPA（児童オンラインプライバシー保護法）準拠
"""

import hashlib
import logging
from typing import Optional, Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)


class AnalyticsService:
    """Firebase Analytics を用いた匿名化されたイベント記録"""

    # 匿名化される child_id の接頭辞
    ANONYMIZED_PREFIX = "anon_"

    @staticmethod
    def anonymize_child_id(child_id: str, salt: str = "") -> str:
        """
        child_id を SHA256 ハッシュで匿名化

        Args:
            child_id: 元のチャイルドID
            salt: ハッシュ化のためのソルト値

        Returns:
            匿名化されたID
        """
        try:
            # ソルトを付加してハッシュ化
            hash_input = f"{child_id}{salt}".encode("utf-8")
            hash_digest = hashlib.sha256(hash_input).hexdigest()[:16]

            return f"{AnalyticsService.ANONYMIZED_PREFIX}{hash_digest}"
        except Exception as e:
            logger.error(f"Failed to anonymize child_id: {e}")
            # フォールバック: ハッシュ化失敗時は一般的なIDを使用
            return f"{AnalyticsService.ANONYMIZED_PREFIX}unknown"

    @staticmethod
    def sanitize_event_data(
        event_data: Dict[str, Any],
        anonymized_child_id: str
    ) -> Dict[str, Any]:
        """
        イベントデータをサニタイズして個人情報を削除

        禁止される情報:
        - 名前、メールアドレス
        - 生年月日
        - 住所、電話番号
        - その他の個人を特定できる情報

        Args:
            event_data: 元のイベントデータ
            anonymized_child_id: 匿名化されたチャイルドID

        Returns:
            サニタイズされたデータ
        """
        sanitized = {
            "anonymized_child_id": anonymized_child_id,
            "timestamp": event_data.get("timestamp", datetime.utcnow().isoformat()),
        }

        # 許可される属性
        allowed_fields = {
            "story_id",
            "choice_id",
            "choice_sentiment",  # 「優しい」「強い」など
            "learning_score",
            "badge_earned",
            "learning_category",  # 道徳のカテゴリー
            "session_duration_seconds",
            "difficulty_level",
        }

        # 許可されたフィールドのみをコピー
        for field in allowed_fields:
            if field in event_data:
                sanitized[field] = event_data[field]

        return sanitized

    @staticmethod
    def validate_analytics_event(event_data: Dict[str, Any]) -> bool:
        """
        アナリティクスイベントが COPPA に準拠しているか検証

        Args:
            event_data: イベントデータ

        Returns:
            準拠している場合 True
        """
        # 禁止される個人情報キー
        forbidden_keys = {
            "name",
            "email",
            "phone",
            "address",
            "birthdate",
            "birth_date",
            "date_of_birth",
            "ssn",
            "ip_address",
            "device_id",
            "mac_address",
            "imei",
            "advertising_id",
        }

        for key in event_data.keys():
            if key.lower() in forbidden_keys:
                logger.warning(f"Forbidden field in analytics event: {key}")
                return False

        return True

    @staticmethod
    def log_learning_event(
        child_id: str,
        story_id: str,
        choice_id: str,
        choice_sentiment: str,
        learning_score: float,
        session_duration_seconds: int,
    ) -> bool:
        """
        学習イベントをログに記録

        Args:
            child_id: チャイルドID
            story_id: ストーリーID
            choice_id: 選択肢ID
            choice_sentiment: 選択肢の感情タイプ（「優しい」など）
            learning_score: 学習スコア（0-100）
            session_duration_seconds: セッション時間（秒）

        Returns:
            ログが成功したか
        """
        try:
            # チャイルドIDを匿名化
            anonymized_id = AnalyticsService.anonymize_child_id(child_id)

            # イベントデータを構築
            event_data = {
                "story_id": story_id,
                "choice_id": choice_id,
                "choice_sentiment": choice_sentiment,
                "learning_score": learning_score,
                "session_duration_seconds": session_duration_seconds,
            }

            # 個人情報を検証
            if not AnalyticsService.validate_analytics_event(event_data):
                logger.error("Analytics event contains forbidden data")
                return False

            # データをサニタイズ
            sanitized = AnalyticsService.sanitize_event_data(
                event_data,
                anonymized_id,
            )

            # Firebase Analytics に送信
            # NOTE: 実装時には Firebase Admin SDK を使用
            # firebase.analytics().log_event(
            #     "learning_session_completed",
            #     sanitized
            # )

            logger.info(
                f"Learning event logged: "
                f"anonymized_id={anonymized_id}, "
                f"story_id={story_id}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to log learning event: {e}")
            return False

    @staticmethod
    def log_badge_earned(
        child_id: str,
        badge_id: str,
        badge_name: str,
    ) -> bool:
        """
        バッジ獲得イベントをログに記録

        Args:
            child_id: チャイルドID
            badge_id: バッジID
            badge_name: バッジ名

        Returns:
            ログが成功したか
        """
        try:
            anonymized_id = AnalyticsService.anonymize_child_id(child_id)

            event_data = {
                "badge_id": badge_id,
                "badge_name": badge_name,
            }

            if not AnalyticsService.validate_analytics_event(event_data):
                logger.error("Badge event contains forbidden data")
                return False

            sanitized = AnalyticsService.sanitize_event_data(
                event_data,
                anonymized_id,
            )

            logger.info(
                f"Badge event logged: "
                f"anonymized_id={anonymized_id}, "
                f"badge_id={badge_id}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to log badge event: {e}")
            return False

    @staticmethod
    def log_report_viewed(child_id: str, report_month: str) -> bool:
        """
        レポート閲覧イベントをログに記録

        Args:
            child_id: チャイルドID
            report_month: レポート月（YYYY-MM形式）

        Returns:
            ログが成功したか
        """
        try:
            anonymized_id = AnalyticsService.anonymize_child_id(child_id)

            event_data = {
                "report_month": report_month,
            }

            if not AnalyticsService.validate_analytics_event(event_data):
                logger.error("Report event contains forbidden data")
                return False

            sanitized = AnalyticsService.sanitize_event_data(
                event_data,
                anonymized_id,
            )

            logger.info(
                f"Report viewed event logged: "
                f"anonymized_id={anonymized_id}, "
                f"report_month={report_month}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to log report event: {e}")
            return False
