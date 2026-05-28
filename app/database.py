import os
from sqlalchemy import Column, Integer, Text, DateTime, JSON, create_engine, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Use Turso if credentials exist, otherwise fallback to local SQLite
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    DATABASE_URL = "sqlite:///./rezumate.db"

# For Turso, we typically use the libsql driver if installed
# but for this MVP, we'll support standard sqlite/postgres URLs
engine = create_engine(
    DATABASE_URL, 
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class Analysis(Base):
    __tablename__ = "analyses"

    id = Column(Integer, primary_key=True, index=True)
    filename = Column(Text)
    job_description = Column(Text)
    resume_text = Column(Text)
    resume_hash = Column(Text)
    job_description_hash = Column(Text)
    extraction_status = Column(Text)
    extraction_warnings = Column(JSON)
    deterministic_signals = Column(JSON)
    result_json = Column(JSON)
    match_score = Column(Integer)
    model_name = Column(Text)
    prompt_version = Column(Text)
    latency_ms = Column(Integer)
    user_id = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

def init_db():
    Base.metadata.create_all(bind=engine)
    ensure_analysis_columns()


def ensure_analysis_columns():
    inspector = inspect(engine)
    if "analyses" not in inspector.get_table_names():
        return

    existing_columns = {column["name"] for column in inspector.get_columns("analyses")}
    column_definitions = {
        "filename": "TEXT",
        "resume_hash": "TEXT",
        "job_description_hash": "TEXT",
        "extraction_status": "TEXT",
        "extraction_warnings": "JSON",
        "deterministic_signals": "JSON",
        "model_name": "TEXT",
        "prompt_version": "TEXT",
        "latency_ms": "INTEGER",
        "user_id": "TEXT",
    }

    with engine.begin() as connection:
        for column_name, column_type in column_definitions.items():
            if column_name not in existing_columns:
                connection.execute(text(f"ALTER TABLE analyses ADD COLUMN {column_name} {column_type}"))

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
