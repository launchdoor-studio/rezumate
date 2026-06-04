import re
from functools import lru_cache
from typing import Dict, List
from langchain_groq import ChatGroq
from pydantic import BaseModel, Field

from app.config import get_settings

MODEL_NAME = "llama-3.3-70b-versatile"

class RewriteOptions(BaseModel):
    rewritten_bullets: List[str] = Field(description="3 options of rewritten, optimized bullet points.")

class AIResumeAnalysis(BaseModel):
    score: int = Field(description="Overall resume match score from 0 to 100.")
    matched_keywords: List[str] = Field(description="Important job keywords that are clearly present in the resume.")
    missing_keywords: List[str] = Field(description="Important job keywords missing or weakly represented in the resume.")
    weak_bullets: List[str] = Field(description="Resume bullets or resume statements that should be improved for this job.")
    bullets_without_measurable_impact: List[str] = Field(description="Resume bullets or statements that lack quantified impact.")
    formatting_warnings: List[str] = Field(description="ATS formatting or readability warnings visible from the extracted text.")
    component_scores: Dict[str, int] = Field(description="Scores from 0 to 100 for keyword_coverage, impact_quality, structure_readability, and formatting_risk.")

@lru_cache(maxsize=1)
def get_model():
    settings = get_settings()
    if not settings.groq_api_key:
        raise RuntimeError("GROQ_API_KEY is not configured on the backend.")
    return ChatGroq(
        api_key=settings.groq_api_key,
        model=MODEL_NAME,
        temperature=0.7,
        timeout=20,
        max_retries=1,
    )

def rewrite_bullet_point(original_bullet: str, job_title: str = None, focus_keywords: list = None) -> list[str]:
    """
    Rewrites a single resume bullet point using an LLM.
    Returns 3 different variations of the rewritten bullet.
    """
    context = ""
    if job_title:
        context += f"Target Job Title: {job_title}\n"
    if focus_keywords:
        context += f"Try to naturally include some of these keywords if they fit: {', '.join(focus_keywords)}\n"

    prompt = f"""
You are an expert technical resume writer. Your task is to rewrite the given resume bullet point to make it more impactful, concise, and ATS-friendly.

Guidelines:
- Start with a strong action verb.
- Ensure the bullet describes the *outcome* or *measurable impact*, not just the task.
- Keep it to a single sentence, concise but descriptive.
- Do NOT fabricate metrics, but if the original implies an outcome, make it sound professional.
- Do NOT use pronouns like "I", "We", "My".

Original Bullet:
{original_bullet}

{context}

Provide 3 distinct rewrite options.
"""
    structured_llm = get_model().with_structured_output(RewriteOptions)
    result = structured_llm.invoke(prompt)
    return result.rewritten_bullets

def analyze_resume_with_groq(resume_text: str, job_description: str, baseline_signals: dict) -> dict:
    """
    Uses Groq to score the resume and identify role-specific keyword gaps and rewrite candidates.
    The deterministic baseline is included for guardrails and merged back for stable metadata.
    """
    prompt = f"""
You are an expert ATS evaluator and technical recruiter. Analyze the resume against the job description.

Use the extracted resume text exactly as provided. PDF extraction may remove bullet symbols, so experience statements may appear as plain lines.

Scoring rubric:
- keyword_coverage: important hard skills, tools, frameworks, role responsibilities, and seniority alignment.
- impact_quality: quantified outcomes, scope, ownership, and business/user impact.
- structure_readability: clear sections, concise experience, projects, skills, education.
- formatting_risk: ATS-safe text, normal line lengths, readable extraction, no obvious table/layout issues.
- overall score should reflect actual fit for this specific job, not generic resume quality.

Keyword rules:
- Return only meaningful role keywords: languages, frameworks, tools, platforms, methods, and concrete job responsibilities.
- Do not return generic filler words such as basic, nice, good, strong, requirements, responsibilities, ability, experience, intern, web, or developer.
- Canonicalize aliases: REST APIs -> rest api, Node/NodeJS -> node.js, NextJS -> next.js, Tailwind -> tailwind css.
- matched_keywords must be clearly demonstrated in the resume.
- missing_keywords must be important in the job description and absent or weak in the resume.
- Prefer 8 to 18 total keywords across matched and missing.

Bullet improvement rules:
- weak_bullets should contain 3 to 8 exact or near-exact resume bullets/statements worth improving.
- Include bullets that are vague, task-only, too generic, missing impact, missing metrics, or poorly tailored to the job.
- If the resume has no literal bullet markers, choose improvable experience or project lines from the extracted text.
- Do not invent bullets that are not in the resume.
- bullets_without_measurable_impact should contain resume bullets/statements that lack numbers, scale, outcomes, or clear impact.

Baseline deterministic analysis for guardrails:
{baseline_signals}

Job description:
{job_description}

Resume text:
{resume_text}
"""
    structured_llm = get_model().with_structured_output(AIResumeAnalysis)
    result = structured_llm.invoke(prompt)

    matched_keywords = _filter_supported_keywords(
        _clean_keyword_list(result.matched_keywords),
        resume_text,
    )
    missing_keywords = _clean_keyword_list(result.missing_keywords)
    missing_keywords = [keyword for keyword in missing_keywords if keyword not in set(matched_keywords)]

    signals = dict(baseline_signals)
    signals.update({
        "score": _clamp_score(result.score),
        "matched_keywords": matched_keywords,
        "missing_keywords": missing_keywords,
        "weak_bullets": _clean_text_list(result.weak_bullets, limit=8),
        "bullets_without_measurable_impact": _clean_text_list(result.bullets_without_measurable_impact, limit=8),
        "formatting_warnings": _clean_text_list(result.formatting_warnings, limit=6) or baseline_signals.get("formatting_warnings", []),
        "component_scores": _clean_component_scores(result.component_scores),
        "analysis_source": "groq",
        "ai_model_name": MODEL_NAME,
    })
    signals["jd_keywords"] = sorted(set(signals["matched_keywords"] + signals["missing_keywords"]))
    return signals


def _clean_keyword_list(values: List[str], limit: int = 18) -> List[str]:
    noise = {
        "ability", "basic", "collaborating", "communication", "developer",
        "development", "engineer", "engineering", "experience", "familiarity",
        "good", "intern", "internship", "knowledge", "learn", "learning",
        "nice", "requirements", "responsibilities", "responsibility", "role",
        "strong", "understanding", "web", "willingness", "work", "working",
    }
    aliases = {
        "apis": "api",
        "api": "api",
        "nextjs": "next.js",
        "next js": "next.js",
        "node": "node.js",
        "nodejs": "node.js",
        "rest": "rest api",
        "rest apis": "rest api",
        "tailwind": "tailwind css",
    }
    cleaned = []
    seen = set()
    for value in values:
        keyword = " ".join(str(value).lower().strip().split())
        keyword = aliases.get(keyword, keyword)
        if not keyword or keyword in noise or keyword in seen:
            continue
        seen.add(keyword)
        cleaned.append(keyword)
        if len(cleaned) >= limit:
            break
    if "rest api" in seen and "api" in seen:
        cleaned = [keyword for keyword in cleaned if keyword != "api"]
    return cleaned


def _filter_supported_keywords(keywords: List[str], resume_text: str) -> List[str]:
    resume_lower = resume_text.lower()
    return [keyword for keyword in keywords if _keyword_present_in_resume(keyword, resume_lower)]


def _keyword_present_in_resume(keyword: str, resume_lower: str) -> bool:
    escaped = re.escape(keyword).replace(r"\ ", r"\s+")
    if re.search(rf"(?<![a-z0-9]){escaped}(?![a-z0-9])", resume_lower):
        return True

    patterns = {
        "api": r"(?<![a-z0-9])apis?(?![a-z0-9])",
        "next.js": r"(?<![a-z0-9])next[.\s-]?js(?![a-z0-9])",
        "node.js": r"(?<![a-z0-9])node[.\s-]?js(?![a-z0-9])",
        "tailwind css": r"(?<![a-z0-9])tailwind(\s+css)?(?![a-z0-9])",
    }
    if keyword in patterns:
        return bool(re.search(patterns[keyword], resume_lower))
    if keyword == "rest api":
        return bool(re.search(r"(?<![a-z0-9])rest\s+apis?(?![a-z0-9])", resume_lower))
    return False


def _clean_text_list(values: List[str], limit: int) -> List[str]:
    cleaned = []
    seen = set()
    for value in values:
        text = " ".join(str(value).strip().split())
        if len(text) < 8 or text in seen:
            continue
        seen.add(text)
        cleaned.append(text[:320])
        if len(cleaned) >= limit:
            break
    return cleaned


def _clean_component_scores(values: Dict[str, int]) -> Dict[str, int]:
    keys = ("keyword_coverage", "impact_quality", "structure_readability", "formatting_risk")
    return {key: _clamp_score(values.get(key, 0)) for key in keys}


def _clamp_score(value: int) -> int:
    try:
        return max(0, min(100, int(value)))
    except (TypeError, ValueError):
        return 0
