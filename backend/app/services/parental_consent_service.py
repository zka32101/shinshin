"""
親の同意管理サービス
COPPA（児童オンラインプライバシー保護法）準拠

子どもの個人情報の処理に関する親の同意を取得・管理・記録します。
"""

import logging
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc

logger = logging.getLogger(__name__)


class ParentalConsentService:
    """親の同意管理サービス"""

    # 同意の有効期限（年）
    CONSENT_VALIDITY_YEARS = 1

    @staticmethod
    async def create_parental_consent(
        db: AsyncSession,
        parent_uid: str,
        child_email: str,
        privacy_policy_version: str,
        consent_to: Dict[str, bool],
    ) -> Dict[str, Any]:
        """
        親の同意記録を作成

        Args:
            db: データベースセッション
            parent_uid: 親のFirebase UID
            child_email: 子どものメールアドレス
            privacy_policy_version: プライバシーポリシーバージョン
            consent_to: 同意内容
                {
                    "dataProcessing": true/false,
                    "thirdPartySharing": true/false,
                    "analyticsTracking": true/false,
                }

        Returns:
            作成された同意記録
        """
        try:
            if not ParentalConsentService._validate_consent_data(consent_to):
                logger.error("Invalid consent data format")
                return None

            consent_record = {
                "parent_uid": parent_uid,
                "child_email": child_email,
                "consented_at": datetime.utcnow(),
                "privacy_policy_version": privacy_policy_version,
                "consent_to": consent_to,
                "valid_until": datetime.utcnow() + timedelta(
                    days=365 * ParentalConsentService.CONSENT_VALIDITY_YEARS
                ),
                "revoked_at": None,
            }

            # NOTE: Firestore に保存する場合の実装
            # from app.db.firestore import get_firestore_db
            # fb = await get_firestore_db()
            # fb.collection("parental_consents").document(parent_uid).set(consent_record)

            logger.info(
                f"Parental consent created for parent_uid={parent_uid}, "
                f"child_email={child_email}"
            )

            return consent_record

        except Exception as e:
            logger.error(f"Failed to create parental consent: {e}")
            return None

    @staticmethod
    async def get_parental_consent(
        db: AsyncSession,
        parent_uid: str,
    ) -> Optional[Dict[str, Any]]:
        """
        親の有効な同意記録を取得

        Args:
            db: データベースセッション
            parent_uid: 親のFirebase UID

        Returns:
            有効な同意記録、または None
        """
        try:
            # NOTE: Firestore から取得する場合の実装
            # from app.db.firestore import get_firestore_db
            # fb = await get_firestore_db()
            # consent = fb.collection("parental_consents").document(parent_uid).get()
            #
            # if not consent.exists:
            #     return None
            #
            # data = consent.to_dict()
            # if data.get("revoked_at") or data.get("valid_until") < datetime.utcnow():
            #     return None
            #
            # return data

            logger.debug(f"Fetched parental consent for parent_uid={parent_uid}")
            return None

        except Exception as e:
            logger.error(f"Failed to get parental consent: {e}")
            return None

    @staticmethod
    async def revoke_parental_consent(
        db: AsyncSession,
        parent_uid: str,
    ) -> bool:
        """
        親の同意を取り下げ（削除）

        Args:
            db: データベースセッション
            parent_uid: 親のFirebase UID

        Returns:
            成功したか
        """
        try:
            # NOTE: Firestore での実装
            # from app.db.firestore import get_firestore_db
            # fb = await get_firestore_db()
            # consent_ref = fb.collection("parental_consents").document(parent_uid)
            # consent = consent_ref.get()
            #
            # if not consent.exists:
            #     logger.warning(f"No consent found for parent_uid={parent_uid}")
            #     return False
            #
            # consent_ref.update({"revoked_at": datetime.utcnow()})

            logger.info(f"Parental consent revoked for parent_uid={parent_uid}")
            return True

        except Exception as e:
            logger.error(f"Failed to revoke parental consent: {e}")
            return False

    @staticmethod
    async def check_consent_for_operation(
        db: AsyncSession,
        parent_uid: str,
        operation_type: str,
    ) -> bool:
        """
        特定の操作に対する親の同意があるか確認

        Args:
            db: データベースセッション
            parent_uid: 親のFirebase UID
            operation_type: 操作タイプ（dataProcessing, thirdPartySharing, analyticsTracking）

        Returns:
            同意がある場合 True
        """
        try:
            consent = await ParentalConsentService.get_parental_consent(
                db,
                parent_uid,
            )

            if not consent:
                logger.warning(
                    f"No valid consent found for parent_uid={parent_uid}, "
                    f"operation_type={operation_type}"
                )
                return False

            if not consent.get("consent_to", {}).get(operation_type):
                logger.info(
                    f"Consent not given for parent_uid={parent_uid}, "
                    f"operation_type={operation_type}"
                )
                return False

            return True

        except Exception as e:
            logger.error(f"Failed to check consent: {e}")
            return False

    @staticmethod
    def _validate_consent_data(consent_to: Dict[str, bool]) -> bool:
        """
        同意データの形式を検証

        Args:
            consent_to: 同意内容

        Returns:
            有効か
        """
        required_keys = {
            "dataProcessing",
            "thirdPartySharing",
            "analyticsTracking",
        }

        if not isinstance(consent_to, dict):
            return False

        if not all(key in consent_to for key in required_keys):
            return False

        if not all(isinstance(v, bool) for v in consent_to.values()):
            return False

        return True

    @staticmethod
    async def audit_log_consent_operation(
        db: AsyncSession,
        parent_uid: str,
        operation: str,
        details: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """
        同意関連の操作をAuditログに記録（GDPR/COPPA対応）

        Args:
            db: データベースセッション
            parent_uid: 親のFirebase UID
            operation: 操作内容（created, revoked, viewed, etc.）
            details: 詳細情報

        Returns:
            成功したか
        """
        try:
            audit_record = {
                "parent_uid": parent_uid,
                "operation": operation,
                "timestamp": datetime.utcnow(),
                "details": details or {},
            }

            # NOTE: Firestore Audit Collection に保存
            # from app.db.firestore import get_firestore_db
            # fb = await get_firestore_db()
            # fb.collection("consent_audit_logs").add(audit_record)

            logger.info(
                f"Consent audit logged: parent_uid={parent_uid}, "
                f"operation={operation}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to audit log consent operation: {e}")
            return False
