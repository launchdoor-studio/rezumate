from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

# --- Request/Response Models ---

class UploadResponse(BaseModel):
    success: bool
    filename: str
    extracted_text: str
    warnings: List[str]
    character_count: int

class AnalyzeRequest(BaseModel):
    resume_text: str = Field(description="The extracted raw text of the resume")
    job_description: str = Field(description="The raw text of the job description")

class AnalyzeResponse(BaseModel):
    success: bool
    score: int
    matched_keywords: List[str]
    missing_keywords: List[str]
    weak_bullets: List[str]
    bullets_without_measurable_impact: List[str]
    formatting_warnings: List[str]
    component_scores: Dict[str, int]

class RewriteBulletRequest(BaseModel):
    original_bullet: str
    job_title: Optional[str] = None
    focus_keywords: Optional[List[str]] = None

class RewriteBulletResponse(BaseModel):
    success: bool
    original_bullet: str
    rewritten_bullets: List[str]
    ai_model_name: str
