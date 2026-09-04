from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, EmailStr, ConfigDict, Field, field_validator
from pydantic.alias_generators import to_camel
import re


class UserCreate(BaseModel):
    email: EmailStr = Field(..., max_length=254)
    name: str = Field(..., min_length=1, max_length=100)
    password: str = Field(
        ...,
        min_length=8,
        description="Password must be at least 8 characters with uppercase, lowercase, and number"
    )

    @field_validator('password')
    @classmethod
    def validate_password_complexity(cls, v: str) -> str:
        """Password must contain uppercase, lowercase, and number"""
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
        return v

    @field_validator('name')
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Name cannot be only whitespace"""
        if not v.strip():
            raise ValueError('Name cannot be empty or whitespace only')
        return v.strip()


class UserUpdate(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    fcm_token: Optional[str] = Field(default=None, min_length=1)

    @field_validator('name')
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        """Name cannot be only whitespace"""
        if v is not None and not v.strip():
            raise ValueError('Name cannot be empty or whitespace only')
        return v.strip() if v else None

    @field_validator('fcm_token')
    @classmethod
    def validate_fcm_token(cls, v: Optional[str]) -> Optional[str]:
        """FCM token should be non-empty"""
        if v is not None and not v.strip():
            raise ValueError('FCM token cannot be empty')
        return v.strip() if v else None


class UserResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    email: str
    name: str
    is_active: bool
    created_at: datetime
