from typing import List, Optional, Dict
from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID

# --- Request/Response Models ---

class UploadResponse(BaseModel):
    success: bool
    filename: str
    resume_id: UUID
    extracted_text: str
    warnings: List[str]
    character_count: int

class AppleAuthRequest(BaseModel):
    identity_token: str = Field(description="The identityToken returned by Sign in with Apple")
    email: Optional[str] = Field(default=None, description="Email returned by Apple on first authorization")
    full_name: Optional[str] = Field(default=None, description="Display name returned by Apple on first authorization")

class AuthUser(BaseModel):
    id: UUID
    email: str
    plan_tier: str

class AuthResponse(BaseModel):
    success: bool
    token: str
    user: AuthUser

class AnalyzeRequest(BaseModel):
    resume_id: UUID = Field(description="The UUID of the previously uploaded resume")
    resume_text: str = Field(min_length=1, description="The extracted raw text of the resume")
    job_description: str = Field(min_length=1, description="The raw text of the job description")

class AnalyzeResponse(BaseModel):
    success: bool
    variant_id: UUID
    score: int
    matched_keywords: List[str]
    missing_keywords: List[str]
    weak_bullets: List[str]
    bullets_without_measurable_impact: List[str]
    formatting_warnings: List[str]
    component_scores: Dict[str, int]
    analysis_status: Optional[str] = "complete"
    ai_model_name: Optional[str] = None

class RewriteBulletRequest(BaseModel):
    original_bullet: str = Field(min_length=1, max_length=1000)
    job_title: Optional[str] = None
    focus_keywords: Optional[List[str]] = None

class RewriteBulletResponse(BaseModel):
    success: bool
    original_bullet: str
    rewritten_bullets: List[str]
    ai_model_name: str

class VariantSummary(BaseModel):
    id: UUID
    resume_id: UUID
    variant_name: str
    ats_score: Optional[int]
    created_at: datetime
    updated_at: datetime

class HistoryResponse(BaseModel):
    success: bool
    variants: List[VariantSummary]

class AcceptRewriteRequest(BaseModel):
    variant_id: UUID
    original_bullet: str = Field(min_length=1, max_length=2000)
    rewritten_bullet: str = Field(min_length=1, max_length=2000)

class AcceptRewriteResponse(BaseModel):
    success: bool
    variant_id: UUID
    updated_resume_text: str

class DeleteAccountResponse(BaseModel):
    success: bool

class ExportRequest(BaseModel):
    variant_id: UUID
