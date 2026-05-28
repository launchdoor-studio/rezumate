from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.pdf_service import extract_pdf_text
from app.services.ats_service import analyze_resume_against_jd
from app.services.ai_service import rewrite_bullet_point, MODEL_NAME
from app.services.schemas import (
    UploadResponse, 
    AnalyzeRequest, 
    AnalyzeResponse,
    RewriteBulletRequest,
    RewriteBulletResponse
)

router = APIRouter()

PDF_CONTENT_TYPES = {"application/pdf", "application/x-pdf"}

def validate_pdf_upload(upload: UploadFile):
    if not upload.filename:
        raise HTTPException(status_code=400, detail="File is required")
    
    if upload.content_type not in PDF_CONTENT_TYPES and not upload.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported right now")

@router.post("/upload", response_model=UploadResponse)
async def upload_resume(
    resume: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Extracts raw text from an uploaded PDF.
    """
    validate_pdf_upload(resume)
    content = await resume.read()
    extraction = extract_pdf_text(content)

    if extraction.status in {"failed", "empty"} or not extraction.text.strip():
        raise HTTPException(
            status_code=400,
            detail="Could not extract text from this PDF. Please upload a text-based resume PDF.",
        )

    # In a full implementation, we'd save this to Supabase Storage and create a Resume record.
    # For now, return the extracted text to the client.
    
    return UploadResponse(
        success=True,
        filename=resume.filename,
        extracted_text=extraction.text,
        warnings=extraction.warnings,
        character_count=extraction.character_count
    )

@router.post("/analyze", response_model=AnalyzeResponse)
def analyze_resume(
    request: AnalyzeRequest,
    db: Session = Depends(get_db)
):
    """
    Analyzes a resume against a job description using deterministic ATS rules.
    """
    if not request.job_description.strip() or not request.resume_text.strip():
        raise HTTPException(status_code=400, detail="Both resume text and job description are required")

    signals = analyze_resume_against_jd(request.resume_text, request.job_description)

    return AnalyzeResponse(
        success=True,
        score=signals.get("score", 0),
        matched_keywords=signals.get("matched_keywords", []),
        missing_keywords=signals.get("missing_keywords", []),
        weak_bullets=signals.get("weak_bullets", []),
        bullets_without_measurable_impact=signals.get("bullets_without_measurable_impact", []),
        formatting_warnings=signals.get("formatting_warnings", []),
        component_scores=signals.get("component_scores", {})
    )

@router.post("/rewrite-bullet", response_model=RewriteBulletResponse)
def rewrite_bullet(
    request: RewriteBulletRequest,
    db: Session = Depends(get_db)
):
    """
    Uses AI to rewrite a single bullet point.
    """
    if not request.original_bullet.strip():
        raise HTTPException(status_code=400, detail="Original bullet is required")

    try:
        rewritten = rewrite_bullet_point(
            original_bullet=request.original_bullet,
            job_title=request.job_title,
            focus_keywords=request.focus_keywords
        )

        return RewriteBulletResponse(
            success=True,
            original_bullet=request.original_bullet,
            rewritten_bullets=rewritten,
            ai_model_name=MODEL_NAME
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
