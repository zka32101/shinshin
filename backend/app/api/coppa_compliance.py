"""
COPPA (Children's Online Privacy Protection Act) Compliance Endpoints

This module implements COPPA compliance tracking and verification.
All endpoints require parent authentication (user_id from JWT).
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID
from datetime import datetime
from app.db.database import get_db
from app.security import get_current_user_id
from app.models.user import User
from app.models.child import Child
from app.models.coppa_compliance import COPPAConsent, COPPAPrivacyPolicy
from app.schemas.coppa import (
    COPPAConsentRequest,
    COPPAConsentResponse,
    COPPADataDeletionRequest,
    COPPAPrivacyPolicyResponse,
    COPPAComplianceStatus,
    COPPAComplianceWarning,
)
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/privacy-policy", response_model=COPPAPrivacyPolicyResponse)
async def get_current_privacy_policy(db: AsyncSession = Depends(get_db)):
    """Get the current privacy policy (no authentication required)"""
    result = await db.execute(
        select(COPPAPrivacyPolicy).order_by(COPPAPrivacyPolicy.effective_date.desc()).limit(1)
    )
    policy = result.scalar_one_or_none()

    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Privacy policy not found"
        )

    return COPPAPrivacyPolicyResponse.model_validate(policy)


@router.post("/consent", response_model=COPPAConsentResponse)
async def provide_parental_consent(
    request: COPPAConsentRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Parent provides consent for child's data collection.
    Required before child data is collected under COPPA.
    """
    # Verify parent owns the child
    result = await db.execute(
        select(Child).where(
            (Child.id == request.child_id) & (Child.parent_id == UUID(user_id))
        )
    )
    child = result.scalar_one_or_none()

    if not child:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Child profile not found or not owned by this parent"
        )

    # Check if consent already exists
    result = await db.execute(
        select(COPPAConsent).where(
            (COPPAConsent.parent_id == UUID(user_id)) & (COPPAConsent.child_id == request.child_id)
        )
    )
    consent = result.scalar_one_or_none()

    if consent:
        # Update existing consent
        consent.parental_consent_given = request.parental_consent_given
        if request.parental_consent_given:
            consent.consent_date = datetime.utcnow()
            consent.consent_method = request.consent_method

        consent.privacy_policy_acknowledged = request.privacy_policy_acknowledged
        if request.privacy_policy_acknowledged:
            consent.privacy_policy_acknowledged_date = datetime.utcnow()
    else:
        # Create new consent record
        consent = COPPAConsent(
            parent_id=UUID(user_id),
            child_id=request.child_id,
            parental_consent_given=request.parental_consent_given,
            consent_date=datetime.utcnow() if request.parental_consent_given else None,
            consent_method=request.consent_method,
            privacy_policy_acknowledged=request.privacy_policy_acknowledged,
            privacy_policy_acknowledged_date=datetime.utcnow() if request.privacy_policy_acknowledged else None,
        )
        db.add(consent)

    await db.commit()
    await db.refresh(consent)

    # Log COPPA compliance event
    logger.info(
        f"SECURITY: COPPA consent provided - user_id={user_id}, child_id={request.child_id}, "
        f"consent={request.parental_consent_given}, policy_acknowledged={request.privacy_policy_acknowledged}"
    )

    return COPPAConsentResponse.model_validate(consent)


@router.get("/consent/{child_id}", response_model=COPPAConsentResponse)
async def get_consent_status(
    child_id: UUID,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Get parental consent status for a child"""
    result = await db.execute(
        select(COPPAConsent).where(
            (COPPAConsent.parent_id == UUID(user_id)) & (COPPAConsent.child_id == child_id)
        )
    )
    consent = result.scalar_one_or_none()

    if not consent:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consent record not found"
        )

    return COPPAConsentResponse.model_validate(consent)


@router.post("/request-data-deletion", response_model=COPPAConsentResponse)
async def request_data_deletion(
    request: COPPADataDeletionRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Parent requests deletion of child's data.
    COPPA requires ability to delete child data upon request or when child turns 13.
    """
    result = await db.execute(
        select(COPPAConsent).where(
            (COPPAConsent.parent_id == UUID(user_id)) & (COPPAConsent.child_id == request.child_id)
        )
    )
    consent = result.scalar_one_or_none()

    if not consent:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consent record not found"
        )

    # Mark data deletion as requested
    consent.data_deletion_requested = True
    consent.data_deletion_requested_date = datetime.utcnow()

    await db.commit()
    await db.refresh(consent)

    # Log data deletion request (security/compliance event)
    logger.info(
        f"SECURITY: Data deletion requested - user_id={user_id}, child_id={request.child_id}, "
        f"reason={request.reason}"
    )

    return COPPAConsentResponse.model_validate(consent)


@router.get("/compliance-status/{child_id}", response_model=COPPAComplianceStatus)
async def get_compliance_status(
    child_id: UUID,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Get COPPA compliance status for a child profile"""
    # Verify parent owns the child
    result = await db.execute(
        select(Child).where(
            (Child.id == child_id) & (Child.parent_id == UUID(user_id))
        )
    )
    child = result.scalar_one_or_none()

    if not child:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Child profile not found or not owned by this parent"
        )

    # Get consent record
    result = await db.execute(
        select(COPPAConsent).where(
            (COPPAConsent.parent_id == UUID(user_id)) & (COPPAConsent.child_id == child_id)
        )
    )
    consent = result.scalar_one_or_none()

    # Determine compliance status
    if not consent:
        compliance_notes = "PENDING: Parental consent required before data collection"
        parental_consent_valid = False
        privacy_policy_acknowledged = False
    else:
        parental_consent_valid = consent.is_consent_valid
        privacy_policy_acknowledged = consent.privacy_policy_acknowledged

        if consent.data_deletion_completed:
            compliance_notes = "COMPLETED: Data deletion has been completed"
        elif consent.data_deletion_requested:
            compliance_notes = "IN_PROGRESS: Data deletion has been requested"
        elif not parental_consent_valid:
            compliance_notes = "INACTIVE: Parental consent is not valid"
        elif not privacy_policy_acknowledged:
            compliance_notes = "ACTION_REQUIRED: Privacy policy acknowledgement required"
        else:
            compliance_notes = "COMPLIANT: All COPPA requirements met"

    return COPPAComplianceStatus(
        child_id=child_id,
        child_name=child.name,
        parental_consent_valid=parental_consent_valid,
        privacy_policy_acknowledged=privacy_policy_acknowledged,
        data_deletion_requested=consent.data_deletion_requested if consent else False,
        data_deletion_completed=consent.data_deletion_completed if consent else False,
        compliance_notes=compliance_notes,
    )


@router.get("/compliance-warnings", response_model=list[COPPAComplianceWarning])
async def get_compliance_warnings(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Get COPPA compliance warnings for all parent's children"""
    # Get all children for this parent
    result = await db.execute(
        select(Child).where(Child.parent_id == UUID(user_id))
    )
    children = result.scalars().all()

    warnings = []

    for child in children:
        # Get consent record
        result = await db.execute(
            select(COPPAConsent).where(
                (COPPAConsent.parent_id == UUID(user_id)) & (COPPAConsent.child_id == child.id)
            )
        )
        consent = result.scalar_one_or_none()

        # Check for compliance issues
        if not consent:
            warnings.append(COPPAComplianceWarning(
                child_id=child.id,
                warning_type="missing_consent",
                message=f"Parental consent required for {child.name}",
                action_required=True,
                recommended_action="Provide parental consent to enable data collection"
            ))
        else:
            if not consent.privacy_policy_acknowledged:
                warnings.append(COPPAComplianceWarning(
                    child_id=child.id,
                    warning_type="policy_not_acknowledged",
                    message=f"Privacy policy not acknowledged for {child.name}",
                    action_required=True,
                    recommended_action="Acknowledge privacy policy"
                ))

            if consent.data_retention_expired:
                warnings.append(COPPAComplianceWarning(
                    child_id=child.id,
                    warning_type="data_retention_expired",
                    message=f"Data retention period expired for {child.name}",
                    action_required=True,
                    recommended_action="Review data retention policy and delete if needed"
                ))

    return warnings
