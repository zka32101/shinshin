"""
COPPA (Children's Online Privacy Protection Act) Compliance Model

This module implements COPPA compliance tracking and enforcement.
COPPA requires parental consent before collecting data from children under 13.

Requirements tracked:
1. Parental consent/verification
2. Data collection for child profiles (name, grade, emoji avatar only)
3. No marketing/tracking for advertising
4. Parental access to child data
5. Data deletion capabilities
6. Data retention limits
"""

import uuid
from datetime import datetime, timedelta
from sqlalchemy import Column, String, DateTime, Boolean, ForeignKey, Integer
from sqlalchemy_utils import UUIDType
from sqlalchemy.orm import relationship
from app.db.base import Base


class COPPAConsent(Base):
    """
    Tracks COPPA parental consent for each child profile.

    Required by COPPA: Parents must provide affirmative consent before
    any personally identifiable information (PII) of children is collected.
    """
    __tablename__ = "coppa_consents"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    parent_id = Column(UUIDType(binary=False), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    child_id = Column(UUIDType(binary=False), ForeignKey("children.id", ondelete="CASCADE"), nullable=False, index=True)

    # Consent tracking
    parental_consent_given = Column(Boolean, default=False, nullable=False)
    consent_date = Column(DateTime, nullable=True)  # When consent was given
    consent_method = Column(String(50), nullable=True)  # email, in-app, etc.

    # COPPA requires acknowledgement of privacy practices
    privacy_policy_acknowledged = Column(Boolean, default=False, nullable=False)
    privacy_policy_acknowledged_date = Column(DateTime, nullable=True)
    privacy_policy_version = Column(String(20), default="1.0", nullable=False)

    # Data retention: COPPA recommends deleting child data upon account deletion
    # Or when child reaches age of consent (13)
    data_deletion_requested = Column(Boolean, default=False, nullable=False)
    data_deletion_requested_date = Column(DateTime, nullable=True)
    data_deletion_completed = Column(Boolean, default=False, nullable=False)
    data_deletion_completed_date = Column(DateTime, nullable=True)

    # Parental access logs (for audit trail)
    last_parental_access_date = Column(DateTime, nullable=True)

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    parent = relationship("User")
    child = relationship("Child")

    def __repr__(self) -> str:
        return f"<COPPAConsent parent={self.parent_id} child={self.child_id} consented={self.parental_consent_given}>"

    @property
    def is_consent_valid(self) -> bool:
        """Check if parental consent is still valid and active"""
        return self.parental_consent_given and not self.data_deletion_completed

    @property
    def data_retention_expired(self) -> bool:
        """
        COPPA recommends deleting child data after 5 years of inactivity
        or when child turns 13 (whichever comes first).
        This is configurable based on privacy policy.
        """
        if not self.created_at:
            return False
        five_years_ago = datetime.utcnow() - timedelta(days=365 * 5)
        return self.created_at < five_years_ago


class COPPAPrivacyPolicy(Base):
    """
    Tracks privacy policy versions and updates for COPPA compliance.
    COPPA requires clear disclosure of information practices.
    """
    __tablename__ = "coppa_privacy_policies"

    id = Column(UUIDType(binary=False), primary_key=True, default=uuid.uuid4, index=True)
    version = Column(String(20), unique=True, nullable=False, index=True)  # e.g., "1.0", "1.1", "2.0"

    # Policy content
    title = Column(String(255), nullable=False)
    description = Column(String(1000), nullable=False)
    content = Column(String(5000), nullable=False)  # Full policy text

    # Effective date
    effective_date = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    def __repr__(self) -> str:
        return f"<COPPAPrivacyPolicy version={self.version}>"
