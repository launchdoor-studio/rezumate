import io
import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from unittest.mock import patch

from main import app
from app.database import Base, get_db, User
from app.services.auth_service import get_current_user
from reportlab.pdfgen import canvas

# --- Test DB Setup ---
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

# Override the database dependency
app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    # create the dummy user expected by auth_service mock
    db = TestingSessionLocal()
    dummy_uuid = uuid.UUID(int=0)
    user = User(id=dummy_uuid, email="test@example.com", plan_tier="free")
    db.add(user)
    db.commit()
    db.close()
    yield
    Base.metadata.drop_all(bind=engine)

def generate_dummy_pdf() -> bytes:
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer)
    c.drawString(100, 750, "John Doe")
    c.drawString(100, 730, "Software Engineer")
    c.drawString(100, 710, "Experience: Python, AWS, and APIs.")
    c.save()
    pdf_bytes = buffer.getvalue()
    buffer.close()
    return pdf_bytes

def test_full_workflow():
    # 1. Upload Resume
    pdf_bytes = generate_dummy_pdf()
    response = client.post(
        "/api/upload",
        files={"resume_file": ("resume.pdf", pdf_bytes, "application/pdf")},
        headers={"Authorization": "Bearer dummy-token"}
    )
    
    assert response.status_code == 200
    upload_data = response.json()
    assert upload_data["success"] is True
    assert "resume_id" in upload_data
    assert "Python" in upload_data["extracted_text"]
    resume_id = upload_data["resume_id"]
    resume_text = upload_data["extracted_text"]

    # 2. Analyze Resume against JD
    jd_text = "Looking for a Software Engineer with Python and AWS."
    response = client.post(
        "/api/analyze",
        json={
            "resume_id": resume_id,
            "resume_text": resume_text,
            "job_description": jd_text
        },
        headers={"Authorization": "Bearer dummy-token"}
    )
    
    assert response.status_code == 200
    analyze_data = response.json()
    assert analyze_data["success"] is True
    assert "variant_id" in analyze_data
    assert analyze_data["score"] > 0
    variant_id = analyze_data["variant_id"]

    # 3. Rewrite Bullet Point (Mocked to avoid Groq API call)
    with patch("app.routes.api.rewrite_bullet_point") as mock_rewrite:
        mock_rewrite.return_value = ["Rewritten bullet 1", "Rewritten bullet 2", "Rewritten bullet 3"]
        
        response = client.post(
            "/api/rewrite-bullet",
            json={
                "original_bullet": "Worked on APIs.",
                "job_title": "Software Engineer"
            },
            headers={"Authorization": "Bearer dummy-token"}
        )
        
        assert response.status_code == 200
        rewrite_data = response.json()
        assert rewrite_data["success"] is True
        assert len(rewrite_data["rewritten_bullets"]) == 3
        assert rewrite_data["rewritten_bullets"][0] == "Rewritten bullet 1"

    # 4. Get History
    response = client.get(
        "/api/history",
        headers={"Authorization": "Bearer dummy-token"}
    )
    
    assert response.status_code == 200
    history_data = response.json()
    assert history_data["success"] is True
    assert len(history_data["variants"]) == 1
    assert history_data["variants"][0]["id"] == variant_id

    # 5. Get Specific Variant
    response = client.get(
        f"/api/variants/{variant_id}",
        headers={"Authorization": "Bearer dummy-token"}
    )
    
    assert response.status_code == 200
    variant_data = response.json()
    assert variant_data["success"] is True
    assert variant_data["variant"]["id"] == variant_id

    # 6. Export Variant
    response = client.post(
        "/api/export",
        json={"variant_id": variant_id},
        headers={"Authorization": "Bearer dummy-token"}
    )
    
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert "attachment; filename=" in response.headers["content-disposition"]
    # Verify we got actual PDF bytes back
    assert response.content.startswith(b"%PDF")

def test_upload_invalid_file():
    response = client.post(
        "/api/upload",
        files={"resume_file": ("resume.txt", b"just text", "text/plain")},
        headers={"Authorization": "Bearer dummy-token"}
    )
    assert response.status_code == 400
    assert "Only PDF and DOCX files are supported" in response.json()["detail"]
