import os
from dataclasses import dataclass
from functools import lru_cache

from dotenv import load_dotenv


load_dotenv()


def _bool_env(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _int_env(name: str, default: int) -> int:
    value = os.getenv(name)
    if value is None:
        return default
    return int(value)


@dataclass(frozen=True)
class Settings:
    app_env: str
    database_url: str
    groq_api_key: str | None
    session_secret: str | None
    apple_bundle_id: str | None
    allow_dev_auth: bool
    max_upload_bytes: int
    max_resume_characters: int
    max_job_description_characters: int
    free_analyses_per_day: int
    free_rewrites_per_day: int

    @property
    def is_production(self) -> bool:
        return self.app_env in {"production", "prod"}


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    app_env = os.getenv("APP_ENV", "development").strip().lower()
    database_url = os.getenv("DATABASE_URL", "sqlite:///./rezumate.db")
    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql+psycopg://", 1)
    elif database_url.startswith("postgresql://"):
        database_url = database_url.replace("postgresql://", "postgresql+psycopg://", 1)

    return Settings(
        app_env=app_env,
        database_url=database_url,
        groq_api_key=os.getenv("GROQ_API_KEY"),
        session_secret=os.getenv("SESSION_SECRET"),
        apple_bundle_id=os.getenv("APPLE_BUNDLE_ID"),
        allow_dev_auth=_bool_env("ALLOW_DEV_APPLE_AUTH", default=app_env not in {"production", "prod"}),
        max_upload_bytes=_int_env("MAX_UPLOAD_BYTES", 4_000_000),
        max_resume_characters=_int_env("MAX_RESUME_CHARACTERS", 100_000),
        max_job_description_characters=_int_env("MAX_JOB_DESCRIPTION_CHARACTERS", 30_000),
        free_analyses_per_day=_int_env("FREE_ANALYSES_PER_DAY", 3),
        free_rewrites_per_day=_int_env("FREE_REWRITES_PER_DAY", 3),
    )


def validate_production_settings() -> None:
    settings = get_settings()
    if not settings.is_production:
        return

    missing = []
    if settings.database_url.startswith("sqlite"):
        missing.append("DATABASE_URL (hosted PostgreSQL required)")
    if not settings.groq_api_key:
        missing.append("GROQ_API_KEY")
    if not settings.session_secret or len(settings.session_secret) < 32:
        missing.append("SESSION_SECRET (at least 32 characters)")
    if not settings.apple_bundle_id:
        missing.append("APPLE_BUNDLE_ID")
    if settings.allow_dev_auth:
        missing.append("ALLOW_DEV_APPLE_AUTH must be false")

    if missing:
        raise RuntimeError(f"Invalid production configuration: {', '.join(missing)}")
