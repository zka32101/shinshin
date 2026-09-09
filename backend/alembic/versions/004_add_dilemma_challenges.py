"""add dilemma_challenges table (協力ジレンマチャレンジ)

Revision ID: 004
Revises: 003
Create Date: 2026-09-09 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '004'
down_revision = '003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'dilemma_challenges',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            'story_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('stories.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'initiator_child_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('children.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'invitee_child_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('children.id', ondelete='CASCADE'),
            nullable=False,
        ),
        # pending / completed （将来のリアルタイム拡張用に active / expired を予約）
        sa.Column('status', sa.String(length=20), nullable=False, server_default='pending'),
        sa.Column(
            'initiator_choice_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('story_choices.id'),
            nullable=True,
        ),
        sa.Column(
            'invitee_choice_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('story_choices.id'),
            nullable=True,
        ),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.CheckConstraint('initiator_child_id != invitee_child_id', name='ck_challenge_not_self'),
    )
    op.create_index('ix_dilemma_challenges_story_id', 'dilemma_challenges', ['story_id'])
    op.create_index('ix_dilemma_challenges_initiator_child_id', 'dilemma_challenges', ['initiator_child_id'])
    op.create_index('ix_dilemma_challenges_invitee_child_id', 'dilemma_challenges', ['invitee_child_id'])


def downgrade() -> None:
    op.drop_index('ix_dilemma_challenges_invitee_child_id', table_name='dilemma_challenges')
    op.drop_index('ix_dilemma_challenges_initiator_child_id', table_name='dilemma_challenges')
    op.drop_index('ix_dilemma_challenges_story_id', table_name='dilemma_challenges')
    op.drop_table('dilemma_challenges')
