"""add purchases table and premium fields on users (課金レシート検証)

Revision ID: 005
Revises: 004
Create Date: 2026-09-09 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '005'
down_revision = '004'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'users',
        sa.Column('is_premium', sa.Boolean(), nullable=False, server_default='false'),
    )
    op.add_column('users', sa.Column('premium_plan', sa.String(length=20), nullable=True))
    op.add_column('users', sa.Column('premium_expires_at', sa.DateTime(), nullable=True))

    op.create_table(
        'purchases',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            'user_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('users.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('platform', sa.String(length=20), nullable=False),
        sa.Column('product_id', sa.String(length=255), nullable=False),
        sa.Column('plan_type', sa.String(length=20), nullable=False),
        sa.Column('transaction_id', sa.String(length=255), nullable=False, unique=True),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='verified'),
        sa.Column('verified_at', sa.DateTime(), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=True),
        sa.Column('raw_response', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
    )
    op.create_index('ix_purchases_user_id', 'purchases', ['user_id'])
    op.create_index('ix_purchases_transaction_id', 'purchases', ['transaction_id'], unique=True)


def downgrade() -> None:
    op.drop_index('ix_purchases_transaction_id', table_name='purchases')
    op.drop_index('ix_purchases_user_id', table_name='purchases')
    op.drop_table('purchases')
    op.drop_column('users', 'premium_expires_at')
    op.drop_column('users', 'premium_plan')
    op.drop_column('users', 'is_premium')
