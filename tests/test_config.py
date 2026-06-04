from unittest.mock import patch

import pytest

from app.config import Settings, validate_production_settings


def _production_settings(**overrides):
    values = {
        "app_env": "production",
        "database_url": "postgresql://example",
        "groq_api_key": "groq-key",
        "session_secret": "long-random-session-secret-at-least-32",
        "apple_bundle_id": "com.rezumate.app",
        "allow_dev_auth": False,
        "max_upload_bytes": 4_000_000,
        "max_resume_characters": 100_000,
        "max_job_description_characters": 30_000,
        "free_analyses_per_day": 3,
        "free_rewrites_per_day": 3,
    }
    values.update(overrides)
    return Settings(**values)


def test_valid_production_settings_pass():
    with patch("app.config.get_settings", return_value=_production_settings()):
        validate_production_settings()


def test_standard_postgres_url_is_normalized(monkeypatch):
    from app.config import get_settings

    monkeypatch.setenv("DATABASE_URL", "postgresql://user:pass@example/db")
    get_settings.cache_clear()
    try:
        assert get_settings().database_url == "postgresql+psycopg://user:pass@example/db"
    finally:
        get_settings.cache_clear()


def test_production_settings_fail_closed():
    settings = _production_settings(
        database_url="sqlite:///./rezumate.db",
        groq_api_key=None,
        session_secret=None,
        apple_bundle_id=None,
        allow_dev_auth=True,
    )
    with patch("app.config.get_settings", return_value=settings):
        with pytest.raises(RuntimeError) as error:
            validate_production_settings()

    message = str(error.value)
    assert "DATABASE_URL" in message
    assert "GROQ_API_KEY" in message
    assert "SESSION_SECRET" in message
    assert "APPLE_BUNDLE_ID" in message
    assert "ALLOW_DEV_APPLE_AUTH" in message
