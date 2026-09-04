"""
COPPA (Children's Online Privacy Protection Act) Compliance Schemas

Schemas for parental consent tracking and COPPA compliance verification.
"""

from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from uuid import UUID
from typing import Optional
from pydantic.alias_generators import to_camel


class COPPAConsentRequest(BaseModel):
    """Request to give parental consent for a child profile"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    child_id: UUID
    parental_consent_given: bool = Field(..., description="Parent confirms consent to data collection")
    privacy_policy_acknowledged: bool = Field(..., description="Parent acknowledges privacy policy")
    consent_method: Optional[str] = Field(default="in-app", description="Method of consent (email, in-app, etc.)")


class COPPAConsentResponse(BaseModel):
    """Response for COPPA consent status"""
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    parent_id: UUID
    child_id: UUID
    parental_consent_given: bool
    consent_date: Optional[datetime]
    privacy_policy_acknowledged: bool
    privacy_policy_acknowledged_date: Optional[datetime]
    data_deletion_requested: bool
    data_deletion_completed: bool
    is_consent_valid: bool = Field(..., description="Whether consent is currently valid and active")
    created_at: datetime
    updated_at: datetime


class COPPADataDeletionRequest(BaseModel):
    """Request to delete child's data (parental request)"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    child_id: UUID
    reason: Optional[str] = Field(
        default=None,
        description="Optional reason for deletion (reaching age 13, account closure, etc.)"
    )


class COPPAPrivacyPolicyResponse(BaseModel):
    """Response with current privacy policy details"""
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    version: str
    title: str
    description: str
    content: str
    effective_date: datetime
    created_at: datetime


class COPPAComplianceStatus(BaseModel):
    """Overall COPPA compliance status for a child"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    child_id: UUID
    child_name: str
    parental_consent_valid: bool = Field(..., description="Is parental consent valid and current?")
    privacy_policy_acknowledged: bool
    data_deletion_requested: bool
    data_deletion_completed: bool
    compliance_notes: str = Field(..., description="Human-readable compliance status")


class COPPAComplianceWarning(BaseModel):
    """Warning about COPPA compliance issues"""
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    child_id: UUID
    warning_type: str  # "missing_consent", "policy_not_acknowledged", "data_retention_expired"
    message: str
    action_required: bool
    recommended_action: str
