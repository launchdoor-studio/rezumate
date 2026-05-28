import os
import tempfile
import unittest
from unittest.mock import AsyncMock, patch


_temp_dir = tempfile.TemporaryDirectory()
os.environ["DATABASE_URL"] = f"sqlite:///{_temp_dir.name}/test.db"

from fastapi.testclient import TestClient

from app.database import Analysis, SessionLocal
from app.routes import api
from app.services.pdf_service import ExtractionResult
from app.services.schemas import AnalysisResult, SkillMatch
from main import app


client = TestClient(app)


class ScoreApiTests(unittest.TestCase):
    def tearDown(self):
        with SessionLocal() as db:
            db.query(Analysis).delete()
            db.commit()

    def test_score_rejects_non_pdf_before_parsing(self):
        response = client.post(
            "/api/score",
            data={"job_description": "Need Python"},
            files={"resume": ("resume.docx", b"not a pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document")},
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["detail"], "Only PDF files are supported right now")

    def test_score_rejects_unreadable_pdf(self):
        response = client.post(
            "/api/score",
            data={"job_description": "Need Python"},
            files={"resume": ("resume.pdf", b"not actually a pdf", "application/pdf")},
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json()["detail"],
            "Could not extract text from this PDF. Please upload a text-based resume PDF.",
        )

    def test_score_returns_structured_analysis_and_persists_metadata(self):
        extraction = ExtractionResult(
            text="Skills\nPython FastAPI\nExperience\n- Built APIs serving 1000 users",
            status="ok",
            warnings=[],
            page_count=1,
            character_count=70,
        )
        ai_result = AnalysisResult(
            match_percentage=82,
            fit_level="Strong Match",
            matched_skills=[
                SkillMatch(skill="Python", match_type="Full", evidence="Listed in skills")
            ],
            missing_skills=["AWS"],
            strengths=["Backend API experience"],
            improvement_suggestions=["Add truthful AWS experience if applicable"],
        )

        with patch.object(api, "extract_resume_text", new=AsyncMock(return_value=extraction)):
            with patch.object(api, "get_ai_response", return_value=ai_result):
                response = client.post(
                    "/api/score",
                    data={"job_description": "Need Python, FastAPI, AWS"},
                    files={"resume": ("resume.pdf", b"%PDF-1.4", "application/pdf")},
                )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["success"])
        self.assertEqual(payload["filename"], "resume.pdf")
        self.assertIn("deterministic_signals", payload)
        self.assertIn("analysis_id", payload)

        with SessionLocal() as db:
            analysis = db.query(Analysis).one()
            self.assertEqual(analysis.filename, "resume.pdf")
            self.assertEqual(analysis.extraction_status, "ok")
            self.assertEqual(analysis.model_name, "llama-3.3-70b-versatile")
            self.assertEqual(analysis.prompt_version, "score-v1")
            self.assertIsNotNone(analysis.resume_hash)
            self.assertIsNotNone(analysis.job_description_hash)
            self.assertIn("score", analysis.deterministic_signals)

    def test_score_returns_deterministic_fallback_when_ai_fails(self):
        extraction = ExtractionResult(
            text="Skills\nPython\nExperience\n- Worked on APIs",
            status="low_quality",
            warnings=["Very little text was extracted, so the analysis may be incomplete."],
            page_count=1,
            character_count=45,
        )

        with patch.object(api, "extract_resume_text", new=AsyncMock(return_value=extraction)):
            with patch.object(api, "get_ai_response", side_effect=RuntimeError("model unavailable")):
                response = client.post(
                    "/api/score",
                    data={"job_description": "Need Python and AWS"},
                    files={"resume": ("resume.pdf", b"%PDF-1.4", "application/pdf")},
                )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["success"])
        self.assertIn("AI analysis was unavailable", " ".join(payload["warnings"]))
        self.assertEqual(payload["result"]["match_percentage"], payload["deterministic_signals"]["score"])

        with SessionLocal() as db:
            analysis = db.query(Analysis).one()
            self.assertEqual(analysis.model_name, "deterministic-fallback")
            self.assertEqual(analysis.prompt_version, "score-v1")


if __name__ == "__main__":
    unittest.main()
