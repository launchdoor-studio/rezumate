from fastapi import Header, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.database import get_db, User
from uuid import UUID


DEV_USER_UUID = UUID("00000000-0000-0000-0000-000000000000")


def normalize_sqlite_dev_user_ids(db: Session) -> None:
    """
    Older local SQLite databases stored UUID(int=0) as the integer 0.
    SQLAlchemy's UUID loader expects a UUID string/hex value and crashes while
    hydrating that row, so normalize the dev rows before ORM queries run.
    """
    if db.bind is None or db.bind.dialect.name != "sqlite":
        return

    dev_id = str(DEV_USER_UUID)
    db.execute(text("UPDATE users SET id = :dev_id WHERE id = '0' OR id = 0"), {"dev_id": dev_id})
    db.execute(text("UPDATE resumes SET user_id = :dev_id WHERE user_id = '0' OR user_id = 0"), {"dev_id": dev_id})
    db.execute(text("UPDATE job_descriptions SET user_id = :dev_id WHERE user_id = '0' OR user_id = 0"), {"dev_id": dev_id})
    db.commit()

async def get_current_user(authorization: str = Header(None), db: Session = Depends(get_db)) -> User:
    """
    Mock dependency for Supabase Auth.
    In a real implementation, this validates the JWT token from the Authorization header,
    extracts the Supabase user ID, and fetches the User from the database.
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing authorization header")
    
    token = authorization.replace("Bearer ", "").strip()
    
    # MOCK implementation: Use a hardcoded dummy user UUID for testing.
    # Replace this with actual supabase.auth.get_user(token) later.
    dummy_uuid = DEV_USER_UUID
    normalize_sqlite_dev_user_ids(db)
    
    user = db.query(User).filter(User.id == dummy_uuid).first()
    if not user:
        # Auto-create the dummy user for testing
        user = User(id=dummy_uuid, email="test@example.com", plan_tier="free")
        db.add(user)
        db.commit()
        db.refresh(user)

    return user

async def check_usage_limits(user: User = Depends(get_current_user)):
    """
    Dependency to check if the user has exceeded their Free tier limits.
    In the real implementation, you'd reset these daily via a cron or by checking timestamps.
    """
    if user.plan_tier == "free":
        # Check an arbitrary combined limit for the sake of the MVP
        if user.analyses_count_today >= 3 and user.rewrites_count_today >= 3:
            raise HTTPException(
                status_code=429, 
                detail="Free tier limits reached. Upgrade to Pro for unlimited usage."
            )
    return user
