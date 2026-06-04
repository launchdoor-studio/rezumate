import pytest
from app.services.ats_service import analyze_resume_against_jd, is_weak_bullet, extract_bullets, extract_keywords

def test_extract_keywords():
    jd_text = "We are looking for a Senior Software Engineer with experience in Python, AWS, and Docker. Must know Kubernetes."
    keywords = extract_keywords(jd_text)
    
    assert "python" in keywords
    assert "aws" in keywords
    assert "docker" in keywords
    assert "kubernetes" in keywords

def test_extract_keywords_ignores_requirement_filler_words():
    jd_text = """
    We are looking for a Web Development Intern.
    Requirements:
    - Strong understanding of HTML, CSS, and JavaScript
    - Basic knowledge of REST APIs and JSON
    - Good communication and willingness to learn
    Nice to have: TypeScript experience and familiarity with Figma
    """

    keywords = extract_keywords(jd_text)

    assert {"html", "css", "javascript", "rest api", "json", "typescript", "figma"}.issubset(set(keywords))
    assert "api" not in keywords
    assert "apis" not in keywords
    assert "rest" not in keywords
    assert "basic" not in keywords
    assert "good" not in keywords
    assert "nice" not in keywords
    assert "requirements" not in keywords
    assert "understanding" not in keywords
    assert "familiarity" not in keywords

def test_extract_keywords_deduplicates_skill_aliases():
    jd_text = """
    Build UI features with React, Next.js, Node.js, Tailwind CSS, and REST APIs.
    Experience with nextjs, nodejs, tailwind, API integrations, and GitHub is useful.
    """

    keywords = extract_keywords(jd_text)

    assert "next.js" in keywords
    assert "node.js" in keywords
    assert "tailwind css" in keywords
    assert "rest api" in keywords
    assert "github" in keywords
    assert "nextjs" not in keywords
    assert "node" not in keywords
    assert "tailwind" not in keywords
    assert "rest" not in keywords
    assert "apis" not in keywords
    assert keywords.count("next.js") == 1
    assert keywords.count("node.js") == 1
    assert keywords.count("tailwind css") == 1
    assert keywords.count("rest api") == 1

def test_short_keywords_do_not_match_inside_words():
    resume = "Built Python machine learning pipelines and APIs."
    jd = "Need UI development with React."

    signals = analyze_resume_against_jd(resume, jd)

    assert "ui" not in signals["matched_keywords"]
    assert "ui" in signals["missing_keywords"]

def test_weak_bullet_detection():
    # Weak
    assert is_weak_bullet("Worked on the backend API.")
    assert is_weak_bullet("Helped with bug fixes.")
    assert is_weak_bullet("Did backend cleanup for the product.")
    
    # Strong
    assert not is_weak_bullet("Engineered a scalable microservice architecture in Go processing 50k requests.")

def test_repetitive_pdf_extraction_noise_is_not_treated_as_bullet():
    text = """
    - ShippedBBBBBBBBBBBBBBBBB-Booooooooooooooootttttttttttttttttttttttttttttttttttttttttt
    - Builtcccccccccccccccccccooooooooooooooooommmmmmmmmmmmmmmpppppppppppppprrrrrrrrrrrr
    - Built a React dashboard for internal analytics and reduced manual reporting by 30%.
    """

    bullets = extract_bullets(text)

    assert bullets == ["Built a React dashboard for internal analytics and reduced manual reporting by 30%."]

def test_pdf_extracted_action_lines_are_treated_as_bullets():
    text = """
    Experience
    Worked on backend APIs for the customer dashboard.
    Built a React dashboard for internal analytics and reduced manual reporting by 30%.
    Skills
    React JavaScript Python
    """

    bullets = extract_bullets(text)

    assert "Worked on backend APIs for the customer dashboard." in bullets
    assert "Built a React dashboard for internal analytics and reduced manual reporting by 30%." in bullets

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
