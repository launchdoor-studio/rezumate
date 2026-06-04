import re
from hashlib import sha256


SCORE_VERSION = "ats-v1"

SECTION_ALIASES = {
    "summary": ("summary", "profile", "objective"),
    "experience": ("experience", "work experience", "employment", "professional experience"),
    "projects": ("projects", "project experience"),
    "skills": ("skills", "technical skills", "technologies"),
    "education": ("education", "academic background"),
}

KNOWN_SKILLS = {
    "aws", "azure", "gcp", "docker", "kubernetes", "terraform", "linux",
    "python", "java", "javascript", "typescript", "go", "golang", "rust",
    "c++", "c#", "react", "next.js", "node.js", "fastapi", "django",
    "flask", "spring", "postgresql", "postgres", "mysql", "mongodb",
    "redis", "graphql", "rest", "api", "microservices", "ci/cd", "git",
    "github", "sql", "nosql", "spark", "kafka", "airflow", "pandas",
    "machine learning", "ml", "ai", "llm", "nlp", "tensorflow",
    "pytorch", "scikit-learn", "data analysis", "analytics", "excel",
    "power bi", "tableau", "figma", "product management", "agile", "scrum",
    "html", "css", "json", "rest api", "rest apis", "responsive design",
    "accessibility", "web applications", "ui", "frontend", "nextjs",
    "tailwind", "tailwind css", "node", "apis",
}

CANONICAL_KEYWORDS = {
    "apis": "api",
    "api": "api",
    "nextjs": "next.js",
    "next.js": "next.js",
    "node": "node.js",
    "node.js": "node.js",
    "rest": "rest api",
    "rest api": "rest api",
    "rest apis": "rest api",
    "tailwind": "tailwind css",
    "tailwind css": "tailwind css",
}

REDUNDANT_KEYWORDS = {
    "api": {"rest api", "graphql", "fastapi"},
}

KEYWORD_NOISE = {
    "ability", "basic", "collaborating", "communication", "developer",
    "development", "engineer", "engineering", "experience", "familiarity",
    "good", "intern", "internship", "knowledge", "learn", "learning",
    "nice", "requirements", "responsibilities", "responsibility", "role",
    "strong", "understanding", "web", "willingness", "work", "working",
}

WEAK_BULLET_STARTERS = (
    "worked on", "helped with", "responsible for", "involved in",
    "participated in", "assisted with", "handled", "did", "made",
)

ACTION_LINE_STARTERS = (
    "built", "created", "developed", "designed", "implemented", "improved",
    "integrated", "launched", "led", "maintained", "managed", "optimized",
    "shipped", "worked on", "helped with", "responsible for", "assisted with",
)

MEASURABLE_IMPACT_RE = re.compile(
    r"(\d+[%+]?|\$[\d,.]+|[<>]\s*\d+|\b\d+\s*(x|k|m|million|billion|users|customers|requests|seconds|minutes|hours|days)\b)",
    re.IGNORECASE,
)


def content_hash(value: str) -> str:
    return sha256(value.encode("utf-8")).hexdigest()


def analyze_resume_against_jd(resume_text: str, job_description: str) -> dict:
    jd_keywords = extract_keywords(job_description)
    resume_lower = resume_text.lower()

    matched_keywords = []
    missing_keywords = []
    partial_matches = []

    for keyword in jd_keywords:
        keyword_lower = keyword.lower()
        if _keyword_in_text(keyword_lower, resume_lower):
            matched_keywords.append(keyword)
        elif _partial_keyword_match(keyword_lower, resume_lower):
            partial_matches.append(keyword)
        else:
            missing_keywords.append(keyword)

    bullets = extract_bullets(resume_text)
    weak_bullets = [bullet for bullet in bullets if is_weak_bullet(bullet)]
    bullets_without_impact = [bullet for bullet in bullets if not MEASURABLE_IMPACT_RE.search(bullet)]
    sections = detect_sections(resume_text)
    formatting_warnings = detect_formatting_warnings(resume_text)

    keyword_coverage = _percentage(len(matched_keywords) + (0.5 * len(partial_matches)), len(jd_keywords))
    impact_quality = _percentage(len(bullets) - len(bullets_without_impact), len(bullets))
    structure_quality = _percentage(sum(1 for present in sections.values() if present), len(sections))
    formatting_quality = max(0, 100 - (len(formatting_warnings) * 20))

    score = round(
        (keyword_coverage * 0.45)
        + (impact_quality * 0.25)
        + (structure_quality * 0.20)
        + (formatting_quality * 0.10)
    )

    return {
        "score_version": SCORE_VERSION,
        "score": score,
        "jd_keywords": jd_keywords,
        "matched_keywords": matched_keywords,
        "missing_keywords": missing_keywords,
        "partial_matches": partial_matches,
        "keyword_coverage": round(keyword_coverage),
        "bullet_count": len(bullets),
        "weak_bullet_count": len(weak_bullets),
        "bullets_without_measurable_impact_count": len(bullets_without_impact),
        "weak_bullets": weak_bullets[:8],
        "bullets_without_measurable_impact": bullets_without_impact[:8],
        "sections": sections,
        "formatting_warnings": formatting_warnings,
        "estimated_resume_length_words": len(re.findall(r"\b\w+\b", resume_text)),
        "component_scores": {
            "keyword_coverage": round(keyword_coverage),
            "impact_quality": round(impact_quality),
            "structure_readability": round(structure_quality),
            "formatting_risk": round(formatting_quality),
        },
    }


def extract_keywords(text: str) -> list[str]:
    text_lower = text.lower()
    found = {
        _canonical_keyword(skill)
        for skill in KNOWN_SKILLS
        if skill not in KEYWORD_NOISE and _keyword_in_text(skill, text_lower)
    }

    return sorted(_remove_redundant_keywords(found))


def extract_bullets(text: str) -> list[str]:
    bullets = []
    for line in text.splitlines():
        stripped = line.strip()
        if re.match(r"^([\-*•]|\d+[.)])\s+", stripped):
            bullet = re.sub(r"^([\-*•]|\d+[.)])\s+", "", stripped).strip()
            if is_valid_bullet_text(bullet):
                bullets.append(bullet)
        elif _looks_like_resume_action_line(stripped) and is_valid_bullet_text(stripped):
            bullets.append(stripped)
    return bullets


def detect_sections(text: str) -> dict[str, bool]:
    lowered_lines = {line.strip().lower().rstrip(":") for line in text.splitlines()}
    return {
        section: any(alias in lowered_lines for alias in aliases)
        for section, aliases in SECTION_ALIASES.items()
    }


def detect_formatting_warnings(text: str) -> list[str]:
    warnings = []
    word_count = len(re.findall(r"\b\w+\b", text))

    if word_count < 250:
        warnings.append("Resume appears unusually short after extraction.")
    if word_count > 1200:
        warnings.append("Resume appears long; consider tightening for ATS and recruiter scanning.")
    if "\t" in text:
        warnings.append("Tabs were detected and may indicate table-like formatting.")
    if len([line for line in text.splitlines() if len(line) > 140]) >= 5:
        warnings.append("Several very long lines were detected, which may indicate layout extraction issues.")

    return warnings


def is_weak_bullet(bullet: str) -> bool:
    normalized = bullet.strip().lower()
    if not normalized or not is_valid_bullet_text(bullet):
        return False
    return normalized.startswith(WEAK_BULLET_STARTERS) or len(normalized.split()) < 7


def is_valid_bullet_text(value: str) -> bool:
    normalized = re.sub(r"\s+", " ", value).strip()
    if len(normalized) < 12 or len(normalized) > 320:
        return False
    if _has_repetitive_noise(normalized):
        return False
    words = re.findall(r"[A-Za-z][A-Za-z+#./-]*", normalized)
    if len(words) < 3:
        return False
    average_word_length = sum(len(word) for word in words) / len(words)
    return average_word_length <= 18


def _partial_keyword_match(keyword: str, resume_lower: str) -> bool:
    parts = [part for part in re.split(r"[\s/+-]+", keyword) if len(part) > 2]
    return bool(parts) and any(part in resume_lower for part in parts)


def _keyword_in_text(keyword: str, text_lower: str) -> bool:
    escaped = re.escape(keyword.lower()).replace(r"\ ", r"\s+")
    if re.search(rf"(?<![a-z0-9]){escaped}(?![a-z0-9])", text_lower):
        return True

    if keyword == "api":
        return bool(re.search(r"(?<![a-z0-9])apis?(?![a-z0-9])", text_lower))
    if keyword == "rest api":
        return bool(re.search(r"(?<![a-z0-9])rest\s+apis?(?![a-z0-9])", text_lower))
    if keyword == "next.js":
        return bool(re.search(r"(?<![a-z0-9])next[.\s-]?js(?![a-z0-9])", text_lower))
    if keyword == "node.js":
        return bool(re.search(r"(?<![a-z0-9])node[.\s-]?js(?![a-z0-9])", text_lower))
    return False


def _canonical_keyword(keyword: str) -> str:
    return CANONICAL_KEYWORDS.get(keyword, keyword)


def _remove_redundant_keywords(keywords: set[str]) -> set[str]:
    cleaned = set(keywords)
    for keyword, stronger_matches in REDUNDANT_KEYWORDS.items():
        if keyword in cleaned and cleaned.intersection(stronger_matches):
            cleaned.remove(keyword)
    return cleaned


def _has_repetitive_noise(value: str) -> bool:
    lowered = value.lower()
    if re.search(r"([a-z])\1{7,}", lowered):
        return True
    compact = re.sub(r"[^a-z]", "", lowered)
    if len(compact) >= 40 and len(set(compact)) <= 5:
        return True
    return False


def _looks_like_resume_action_line(value: str) -> bool:
    normalized = value.strip().lower()
    if not normalized or len(normalized.split()) < 5:
        return False
    if normalized.endswith(":"):
        return False
    return normalized.startswith(ACTION_LINE_STARTERS)


def _percentage(numerator: float, denominator: int) -> float:
    if denominator <= 0:
        return 100.0
    return max(0.0, min(100.0, (numerator / denominator) * 100))
