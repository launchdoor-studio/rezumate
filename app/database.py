import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Uuid, JSON, inspect, text
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from sqlalchemy import create_engine
from sqlalchemy.pool import NullPool

from app.config import get_settings


settings = get_settings()
DATABASE_URL = settings.database_url
connect_args = {}
engine_options = {"pool_pre_ping": True}
if DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False
else:
    engine_options["poolclass"] = NullPool

engine = create_engine(DATABASE_URL, connect_args=connect_args, **engine_options)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


class User(Base):
    __tablename__ = "users"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    apple_subject = Column(String, unique=True, index=True, nullable=True)
    plan_tier = Column(String, default="free", nullable=False)
    analyses_count_today = Column(Integer, default=0, nullable=False)
    rewrites_count_today = Column(Integer, default=0, nullable=False)
    usage_reset_at = Column(DateTime, default=utc_now, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    resumes = relationship("Resume", back_populates="user", cascade="all, delete-orphan")
    job_descriptions = relationship("JobDescription", back_populates="user", cascade="all, delete-orphan")


class Resume(Base):
    __tablename__ = "resumes"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    original_file_url = Column(String, nullable=True)
    parsed_content = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    user = relationship("User", back_populates="resumes")
    variants = relationship("ResumeVariant", back_populates="resume", cascade="all, delete-orphan")


class JobDescription(Base):
    __tablename__ = "job_descriptions"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    raw_text = Column(Text, nullable=False)
    extracted_keywords = Column(JSON, nullable=True)

    user = relationship("User", back_populates="job_descriptions")
    variants = relationship("ResumeVariant", back_populates="job_description", cascade="all, delete-orphan")


class ResumeVariant(Base):
    __tablename__ = "resume_variants"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4, index=True)
    resume_id = Column(Uuid, ForeignKey("resumes.id", ondelete="CASCADE"), nullable=False)
    job_description_id = Column(Uuid, ForeignKey("job_descriptions.id", ondelete="CASCADE"), nullable=False)
    variant_name = Column(String, nullable=False)
    tailored_content = Column(JSON, nullable=True)
    ats_score = Column(Integer, nullable=True)
    analysis_feedback = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    resume = relationship("Resume", back_populates="variants")
    job_description = relationship("JobDescription", back_populates="variants")


def init_db():
    Base.metadata.create_all(bind=engine)
    if engine.dialect.name == "sqlite":
        _upgrade_local_sqlite_schema()


def _upgrade_local_sqlite_schema() -> None:
    columns = {column["name"] for column in inspect(engine).get_columns("users")}
    with engine.begin() as connection:
        if "apple_subject" not in columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN apple_subject VARCHAR"))
        if "usage_reset_at" not in columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN usage_reset_at DATETIME"))
            connection.execute(text("UPDATE users SET usage_reset_at = CURRENT_TIMESTAMP WHERE usage_reset_at IS NULL"))
        connection.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_apple_subject ON users (apple_subject)"))

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
