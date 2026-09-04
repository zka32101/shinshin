from pydantic import BaseModel, EmailStr, ConfigDict, Field, field_validator
from pydantic.alias_generators import to_camel
import re


class LoginRequest(BaseModel):
    email: EmailStr = Field(..., max_length=254)
    password: str = Field(..., min_length=1)


class RegisterRequest(BaseModel):
    email: EmailStr = Field(..., max_length=254)
    password: str = Field(
        ...,
        min_length=8,
        description="Password must be at least 8 characters with uppercase, lowercase, and number"
    )
    name: str = Field(..., min_length=1, max_length=100)

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


class FirebaseLoginRequest(BaseModel):
    firebase_token: str  # Firebase IDトークン


class TokenResponse(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    access_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds
