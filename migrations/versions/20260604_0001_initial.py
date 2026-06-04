"""Create production schema.

Revision ID: 20260604_0001
Revises:
Create Date: 2026-06-04
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260604_0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.String(), nullable=False),
        sa.Column("apple_subject", sa.String(), nullable=True),
        sa.Column("plan_tier", sa.String(), nullable=False),
        sa.Column("analyses_count_today", sa.Integer(), nullable=False),
        sa.Column("rewrites_count_today", sa.Integer(), nullable=False),
        sa.Column("usage_reset_at", sa.DateTime(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_id", "users", ["id"])
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_index("ix_users_apple_subject", "users", ["apple_subject"], unique=True)

    op.create_table(
        "resumes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.String(), nullable=False),
        sa.Column("original_file_url", sa.String(), nullable=True),
        sa.Column("parsed_content", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_resumes_id", "resumes", ["id"])

    op.create_table(
        "job_descriptions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("raw_text", sa.Text(), nullable=False),
        sa.Column("extracted_keywords", sa.JSON(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_job_descriptions_id", "job_descriptions", ["id"])

    op.create_table(
        "resume_variants",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("resume_id", sa.Uuid(), nullable=False),
        sa.Column("job_description_id", sa.Uuid(), nullable=False),
        sa.Column("variant_name", sa.String(), nullable=False),
        sa.Column("tailored_content", sa.JSON(), nullable=True),
        sa.Column("ats_score", sa.Integer(), nullable=True),
        sa.Column("analysis_feedback", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["job_description_id"], ["job_descriptions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["resume_id"], ["resumes.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_resume_variants_id", "resume_variants", ["id"])


def downgrade() -> None:
    op.drop_table("resume_variants")
    op.drop_table("job_descriptions")
    op.drop_table("resumes")
    op.drop_table("users")
