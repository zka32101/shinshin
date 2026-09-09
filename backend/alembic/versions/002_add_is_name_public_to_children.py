"""add is_name_public to children

Revision ID: 002
Revises: 001
Create Date: 2026-09-09 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ランキングで実名を公表するかどうか（COPPA対応: デフォルトは非公表＝匿名）
    op.add_column(
        'children',
        sa.Column('is_name_public', sa.Boolean(), nullable=False, server_default='false'),
    )


def downgrade() -> None:
    op.drop_column('children', 'is_name_public')
