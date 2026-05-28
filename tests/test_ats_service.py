import unittest

from app.services.ats_service import (
    analyze_resume_against_jd,
    content_hash,
    extract_bullets,
    extract_keywords,
    is_weak_bullet,
)
from app.services.pdf_service import normalize_resume_text
from app.services.schemas import AnalysisResult, SkillMatch


class AtsServiceTests(unittest.TestCase):
    def test_extract_keywords_finds_known_skills(self):
        keywords = extract_keywords("We need Python, FastAPI, AWS, Docker, and PostgreSQL experience.")

        self.assertIn("python", keywords)
        self.assertIn("fastapi", keywords)
        self.assertIn("aws", keywords)
        self.assertIn("docker", keywords)
        self.assertIn("postgresql", keywords)

    def test_analysis_is_deterministic(self):
        resume = "\n".join(
            [
                "Skills",
                "Python, FastAPI, AWS",
                "Experience",
                "- Built FastAPI services on AWS serving 1000 users",
            ]
        )
        jd = "Need Python, FastAPI, AWS, Docker"

        first = analyze_resume_against_jd(resume, jd)
        second = analyze_resume_against_jd(resume, jd)

        self.assertEqual(first, second)
        self.assertEqual(first["score_version"], "ats-v1")
        self.assertIn("docker", first["missing_keywords"])

    def test_weak_bullet_detection(self):
        self.assertTrue(is_weak_bullet("Worked on backend APIs"))
        self.assertFalse(is_weak_bullet("Built backend APIs serving 1000 daily users with 99.9% uptime"))

    def test_measurable_impact_detection_affects_counts(self):
        resume = "\n".join(
            [
                "Experience",
                "- Built backend APIs serving 1000 users",
                "- Improved reporting workflow",
            ]
        )
        result = analyze_resume_against_jd(resume, "Need backend API experience")

        self.assertEqual(result["bullet_count"], 2)
        self.assertEqual(result["bullets_without_measurable_impact_count"], 1)

    def test_normalize_resume_text_preserves_useful_line_breaks(self):
        text = "Skills   \r\n\r\n\r\n Python   FastAPI \r\n Experience"

        self.assertEqual(normalize_resume_text(text), "Skills\n\nPython FastAPI\nExperience")

    def test_content_hash_is_stable(self):
        self.assertEqual(content_hash("resume"), content_hash("resume"))
        self.assertNotEqual(content_hash("resume"), content_hash("other resume"))

    def test_pydantic_analysis_schema_validation(self):
        result = AnalysisResult(
            match_percentage=75,
            fit_level="Moderate",
            matched_skills=[
                SkillMatch(skill="Python", match_type="Full", evidence="Listed under Skills")
            ],
            missing_skills=["AWS"],
            strengths=["Strong backend experience"],
            improvement_suggestions=["Add truthful cloud deployment details if applicable"],
        )

        self.assertEqual(result.match_percentage, 75)
        self.assertEqual(result.matched_skills[0].skill, "Python")


if __name__ == "__main__":
    unittest.main()
