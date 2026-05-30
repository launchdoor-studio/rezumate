import base64
import hashlib
import hmac
import json
import os
import time
import urllib.request
from functools import lru_cache
from typing import Any

from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes
from fastapi import Header, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.database import get_db, User
from uuid import UUID


DEV_USER_UUID = UUID("00000000-0000-0000-0000-000000000000")
APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
SESSION_TTL_SECONDS = 60 * 60 * 24 * 30


def _session_secret() -> bytes:
    return os.getenv("SESSION_SECRET", "rezumate-local-session-secret").encode("utf-8")


def _b64url_encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _b64url_decode(value: str) -> bytes:
    padded = value + ("=" * (-len(value) % 4))
    return base64.urlsafe_b64decode(padded.encode("ascii"))


def _json_b64(value: dict[str, Any]) -> str:
    return _b64url_encode(json.dumps(value, separators=(",", ":"), sort_keys=True).encode("utf-8"))


def create_session_token(user: User) -> str:
    payload = {
        "sub": str(user.id),
        "email": user.email,
        "iat": int(time.time()),
        "exp": int(time.time()) + SESSION_TTL_SECONDS,
    }
    body = _json_b64(payload)
    signature = hmac.new(_session_secret(), body.encode("ascii"), hashlib.sha256).digest()
    return f"rzm.{body}.{_b64url_encode(signature)}"


def decode_session_token(token: str) -> dict[str, Any]:
    try:
        prefix, body, signature = token.split(".", 2)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="Invalid session token") from exc

    if prefix != "rzm":
        raise HTTPException(status_code=401, detail="Invalid session token")

    expected = hmac.new(_session_secret(), body.encode("ascii"), hashlib.sha256).digest()
    if not hmac.compare_digest(_b64url_encode(expected), signature):
        raise HTTPException(status_code=401, detail="Invalid session token")

    payload = json.loads(_b64url_decode(body))
    if int(payload.get("exp", 0)) < int(time.time()):
        raise HTTPException(status_code=401, detail="Session expired")
    return payload


@lru_cache(maxsize=1)
def _apple_public_keys() -> dict[str, Any]:
    with urllib.request.urlopen(APPLE_KEYS_URL, timeout=5) as response:
        return json.loads(response.read().decode("utf-8"))


def verify_apple_identity_token(identity_token: str) -> dict[str, Any]:
    if os.getenv("ALLOW_DEV_APPLE_AUTH", "false").lower() == "true" and identity_token.startswith("dev-apple-token:"):
        subject = identity_token.split(":", 1)[1] or "local"
        return {
            "sub": subject,
            "email": f"{subject}@apple.rezumate.local",
            "email_verified": "true",
        }

    try:
        header_b64, payload_b64, signature_b64 = identity_token.split(".")
        header = json.loads(_b64url_decode(header_b64))
        payload = json.loads(_b64url_decode(payload_b64))
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="Invalid Apple identity token") from exc

    if payload.get("iss") != "https://appleid.apple.com":
        raise HTTPException(status_code=401, detail="Invalid Apple token issuer")

    audience = os.getenv("APPLE_BUNDLE_ID")
    if audience and payload.get("aud") != audience:
        raise HTTPException(status_code=401, detail="Invalid Apple token audience")

    if int(payload.get("exp", 0)) < int(time.time()):
        raise HTTPException(status_code=401, detail="Apple identity token expired")

    key = next((item for item in _apple_public_keys().get("keys", []) if item.get("kid") == header.get("kid")), None)
    if not key:
        raise HTTPException(status_code=401, detail="Apple signing key not found")

    public_numbers = rsa.RSAPublicNumbers(
        e=int.from_bytes(_b64url_decode(key["e"]), "big"),
        n=int.from_bytes(_b64url_decode(key["n"]), "big"),
    )
    public_key = public_numbers.public_key()
    signed_part = f"{header_b64}.{payload_b64}".encode("ascii")
    signature = _b64url_decode(signature_b64)

    try:
        public_key.verify(signature, signed_part, padding.PKCS1v15(), hashes.SHA256())
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid Apple token signature") from exc

    return payload


def get_or_create_apple_user(db: Session, apple_claims: dict[str, Any], fallback_email: str | None = None) -> User:
    subject = str(apple_claims.get("sub") or "").strip()
    if not subject:
        raise HTTPException(status_code=401, detail="Apple token missing subject")

    apple_email = (apple_claims.get("email") or fallback_email or f"{subject}@apple.rezumate.local").lower()
    user = db.query(User).filter(User.email == apple_email).first()
    if user:
        return user

    user = User(email=apple_email, plan_tier="free")
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


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

    if token in {"dev-token", "dummy-token"}:
        dummy_uuid = DEV_USER_UUID
        normalize_sqlite_dev_user_ids(db)

        user = db.query(User).filter(User.id == dummy_uuid).first()
        if not user:
            user = db.query(User).filter(User.email == "test@example.com").first()
        if not user:
            user = User(id=dummy_uuid, email="test@example.com", plan_tier="free")
            db.add(user)
            db.commit()
            db.refresh(user)
        return user

    payload = decode_session_token(token)
    user = db.query(User).filter(User.id == UUID(payload["sub"])).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
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
