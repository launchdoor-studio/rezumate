import pytest
from app.services.ats_service import analyze_resume_against_jd, is_weak_bullet, extract_keywords

def test_extract_keywords():
    jd_text = "We are looking for a Senior Software Engineer with experience in Python, AWS, and Docker. Must know Kubernetes."
    keywords = extract_keywords(jd_text)
    
    assert "python" in keywords
    assert "aws" in keywords
    assert "docker" in keywords
    assert "kubernetes" in keywords

def test_weak_bullet_detection():
    # Weak
    assert is_weak_bullet("Worked on the backend API.")
    assert is_weak_bullet("Helped with bug fixes.")
    assert is_weak_bullet("Did stuff.")
    
    # Strong
    assert not is_weak_bullet("Engineered a scalable microservice architecture in Go processing 50k requests.")

def test_analyze_resume_determinism():
    resume = """
    John Doe
    Software Engineer
    
    Experience:
    - Developed a Python REST API using FastAPI and deployed it to AWS.
    - Improved database query latency by 40%.
    - Handled customer support tickets.
    """
    
    jd = "Seeking a backend engineer with Python, FastAPI, AWS, and Kubernetes experience."
    
    signals_1 = analyze_resume_against_jd(resume, jd)
    signals_2 = analyze_resume_against_jd(resume, jd)
    
    # Must be perfectly deterministic
    assert signals_1 == signals_2
    
    assert "python" in signals_1["matched_keywords"]
    assert "fastapi" in signals_1["matched_keywords"]
    assert "aws" in signals_1["matched_keywords"]
    assert "kubernetes" in signals_1["missing_keywords"]
    
    assert "Handled customer support tickets." in signals_1["weak_bullets"]
    
def test_component_scores():
    resume = "we use Python and java alongside c++"
    jd = "requires Python or java or c++ or go or rust"
    
    signals = analyze_resume_against_jd(resume, jd)
    # 3 out of 5 keywords matched = 60% coverage
    assert signals["keyword_coverage"] == 60
    assert signals["score"] > 0
