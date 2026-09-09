"""add friends table and invite_code to children

Revision ID: 003
Revises: 002
Create Date: 2026-09-09 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 友だち追加用の招待コード（8文字の英数字、ユニーク）
    op.add_column(
        'children',
        sa.Column('invite_code', sa.String(length=16), nullable=True),
    )
    op.create_index('ix_children_invite_code', 'children', ['invite_code'], unique=True)

    # friends テーブル
    op.create_table(
        'friends',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            'child_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('children.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'friend_child_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('children.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.UniqueConstraint('child_id', 'friend_child_id', name='uq_friend_pair'),
        sa.CheckConstraint('child_id != friend_child_id', name='ck_friend_not_self'),
    )
    op.create_index('ix_friends_child_id', 'friends', ['child_id'])
    op.create_index('ix_friends_friend_child_id', 'friends', ['friend_child_id'])


def downgrade() -> None:
    op.drop_index('ix_friends_friend_child_id', table_name='friends')
    op.drop_index('ix_friends_child_id', table_name='friends')
    op.drop_table('friends')

    op.drop_index('ix_children_invite_code', table_name='children')
    op.drop_column('children', 'invite_code')
