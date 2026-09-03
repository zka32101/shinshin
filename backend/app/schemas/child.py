from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field, ConfigDict, field_validator
from pydantic.alias_generators import to_camel


class ChildCreate(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    name: str = Field(..., min_length=1, max_length=100)
    avatar_emoji: str = Field(default="🌟", max_length=2)  # Emoji + ZWJ joiner
    grade: int = Field(ge=3, le=4)  # 3年生または4年生

    @field_validator('name')
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Name cannot be only whitespace"""
        if not v.strip():
            raise ValueError('Name cannot be empty or whitespace only')
        return v.strip()

    @field_validator('avatar_emoji')
    @classmethod
    def validate_emoji(cls, v: str) -> str:
        """Avatar emoji validation"""
        if not v or not v.strip():
            raise ValueError('Emoji cannot be empty')
        return v


class ChildUpdate(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    avatar_emoji: Optional[str] = Field(default=None, max_length=2)
    grade: Optional[int] = Field(default=None, ge=3, le=4)

    @field_validator('name')
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        """Name cannot be only whitespace"""
        if v is not None and not v.strip():
            raise ValueError('Name cannot be empty or whitespace only')
        return v.strip() if v else None

    @field_validator('avatar_emoji')
    @classmethod
    def validate_emoji(cls, v: Optional[str]) -> Optional[str]:
        """Avatar emoji validation"""
        if v is not None and not v.strip():
            raise ValueError('Emoji cannot be empty')
        return v


class VirtueScores(BaseModel):
    kindness: float
    honesty: float
    responsibility: float
    courage: float
    respect: float
    cooperation: float


class ChildResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )

    id: UUID
    parent_id: UUID
    name: str
    avatar_emoji: str
    grade: int
    level: int
    total_points: int
    virtue_scores: VirtueScores
    created_at: datetime

    @classmethod
    def from_orm(cls, child):
        return cls(
            id=child.id,
            parent_id=child.parent_id,
            name=child.name,
            avatar_emoji=child.avatar_emoji,
            grade=child.grade,
            level=child.level,
            total_points=child.total_points,
            virtue_scores=VirtueScores(
                kindness=child.kindness_score,
                honesty=child.honesty_score,
                responsibility=child.responsibility_score,
                courage=child.courage_score,
                respect=child.respect_score,
                cooperation=child.cooperation_score,
            ),
            created_at=child.created_at,
        )
