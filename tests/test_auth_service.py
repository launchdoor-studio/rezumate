from datetime import timedelta
from unittest.mock import patch

import pytest
from fastapi import HTTPException

from app.config import Settings
from app.database import User, utc_now
from app.services.auth_service import get_current_user, reset_usage_window_if_needed


def test_usage_window_resets_counts(TestingSessionLocal=None):
    # Reset behavior is exercised with a small session-like mock to avoid coupling to integration fixtures.
    class SessionMock:
        committed = False

        def commit(self):
            self.committed = True

        def refresh(self, _):
            pass

    user = User(
        email="usage@example.com",
        analyses_count_today=3,
        rewrites_count_today=3,
        usage_reset_at=utc_now() - timedelta(days=2),
    )
    db = SessionMock()

    reset_usage_window_if_needed(db, user)

    assert user.analyses_count_today == 0
    assert user.rewrites_count_today == 0
    assert db.committed is True


@pytest.mark.anyio
async def test_dev_token_is_rejected_when_dev_auth_is_disabled():
    settings = Settings(
        app_env="production",
        database_url="postgresql://example",
        groq_api_key="key",
        session_secret="secret",
        apple_bundle_id="com.rezumate.app",
        allow_dev_auth=False,
        max_upload_bytes=4_000_000,
        max_resume_characters=100_000,
        max_job_description_characters=30_000,
        free_analyses_per_day=3,
        free_rewrites_per_day=3,
    )

    with patch("app.services.auth_service.get_settings", return_value=settings):
        with pytest.raises(HTTPException) as error:
            await get_current_user(authorization="Bearer dev-token", db=None)

    assert error.value.status_code == 401
