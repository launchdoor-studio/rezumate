from typing import List, Optional
from pydantic import BaseModel, Field

class SkillMatch(BaseModel):
    skill: str = Field(description="The name of the skill or requirement")
    match_type: str = Field(description="One of: 'Full', 'Partial', 'Missing'")
    evidence: Optional[str] = Field(description="Brief evidence from the resume (only if Full or Partial match)")

class AnalysisResult(BaseModel):
    match_percentage: int = Field(description="The overall match percentage (0-100)")
    fit_level: str = Field(description="Fit level: Strong Match (80%+), Moderate (65-79%), Weak (50-64%), Poor (<50%)")
    matched_skills: List[SkillMatch] = Field(description="List of skills that were found or partially found")
    missing_skills: List[str] = Field(description="List of key requirements that are missing")
    strengths: List[str] = Field(description="Key strengths of the candidate for this role")
    improvement_suggestions: List[str] = Field(description="Specific, actionable advice to improve the resume")

class ComparisonResult(BaseModel):
    winner: str = Field(description="Resume 1, Resume 2, or Tie")
    resume1_score: int
    resume2_score: int
    resume1_summary: str
    resume2_summary: str
    key_differentiators: List[str]
    recommendation: str

class RankingItem(BaseModel):
    filename: str
    match_percentage: int
    strengths: List[str]
    gaps: List[str]

class RankingResult(BaseModel):
    rankings: List[RankingItem]
    overall_summary: str
