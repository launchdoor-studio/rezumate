import logging
from pathlib import Path

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Response
from sqlalchemy import text
from sqlalchemy.orm import Session
from uuid import UUID

from app.config import get_settings
from app.database import get_db, User, Resume, JobDescription, ResumeVariant
from app.services.auth_service import (
    check_analysis_limit,
    check_rewrite_limit,
    create_session_token,
    get_current_user,
    get_or_create_apple_user,
    verify_apple_identity_token,
)
from app.services.document_service import extract_pdf_text, extract_docx_text
from app.services.export_service import generate_ats_pdf
from app.services.ats_service import analyze_resume_against_jd
from app.services.ai_service import analyze_resume_with_groq, rewrite_bullet_point, MODEL_NAME
from app.services.schemas import (
    UploadResponse, 
    AppleAuthRequest,
    AuthResponse,
    AuthUser,
    AnalyzeRequest, 
    AnalyzeResponse,
    RewriteBulletRequest,
    RewriteBulletResponse,
    HistoryResponse,
    VariantSummary,
    AcceptRewriteRequest,
    AcceptRewriteResponse,
    DeleteAccountResponse,
    ExportRequest
)

router = APIRouter()
logger = logging.getLogger(__name__)

SUPPORTED_CONTENT_TYPES = {
    "application/pdf": extract_pdf_text,
    "application/x-pdf": extract_pdf_text,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": extract_docx_text
}

def validate_upload(upload: UploadFile):
    if not upload.filename:
        raise HTTPException(status_code=400, detail="File is required")
    
    content_type = upload.content_type
    if content_type not in SUPPORTED_CONTENT_TYPES:
        # Fallback based on extension
        if upload.filename.lower().endswith(".pdf"):
            return extract_pdf_text
        elif upload.filename.lower().endswith(".docx"):
            return extract_docx_text
        raise HTTPException(status_code=400, detail="Only PDF and DOCX files are supported")
        
    return SUPPORTED_CONTENT_TYPES[content_type]


def build_analyze_response(variant_id: UUID, signals: dict) -> AnalyzeResponse:
    return AnalyzeResponse(
        success=True,
        variant_id=variant_id,
        score=signals.get("score", 0),
        matched_keywords=signals.get("matched_keywords", []),
        missing_keywords=signals.get("missing_keywords", []),
        weak_bullets=signals.get("weak_bullets", []),
        bullets_without_measurable_impact=signals.get("bullets_without_measurable_impact", []),
        formatting_warnings=signals.get("formatting_warnings", []),
        component_scores=signals.get("component_scores", {}),
        analysis_status=signals.get("analysis_status", "complete"),
        ai_model_name=signals.get("ai_model_name"),
    )


@router.get("/health")
def health_check():
    return {"status": "ok"}


@router.get("/ready")
def readiness_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
    except Exception as exc:
        logger.exception("Database readiness check failed")
        raise HTTPException(status_code=503, detail="Database unavailable") from exc
    return {"status": "ready"}


@router.post("/auth/apple", response_model=AuthResponse)
def authenticate_with_apple(request: AppleAuthRequest, db: Session = Depends(get_db)):
    claims = verify_apple_identity_token(request.identity_token)
    user = get_or_create_apple_user(db, claims, request.email)
    token = create_session_token(user)

    return AuthResponse(
        success=True,
        token=token,
        user=AuthUser(id=user.id, email=user.email, plan_tier=user.plan_tier),
    )


@router.get("/me", response_model=AuthUser)
def get_account(user: User = Depends(get_current_user)):
    return AuthUser(id=user.id, email=user.email, plan_tier=user.plan_tier)


@router.post("/upload", response_model=UploadResponse)
async def upload_resume(
    resume_file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    """
    Extracts raw text from an uploaded document (PDF/DOCX) and creates a Resume record.
    """
    extraction_func = validate_upload(resume_file)
    settings = get_settings()
    content = await resume_file.read(settings.max_upload_bytes + 1)
    if len(content) > settings.max_upload_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"Resume file exceeds the {settings.max_upload_bytes // 1_000_000} MB upload limit.",
        )
    extraction = extraction_func(content)

    if extraction.status in {"failed", "empty"} or not extraction.text.strip():
        raise HTTPException(
            status_code=400,
            detail="Could not extract text from this document. Please upload a valid text-based file.",
        )

    # Save Master Resume record
    db_resume = Resume(
        user_id=user.id,
        title=Path(resume_file.filename).name,
        parsed_content={"raw_text": extraction.text}
    )
    db.add(db_resume)
    db.commit()
    db.refresh(db_resume)
    
    return UploadResponse(
        success=True,
        filename=resume_file.filename,
        resume_id=db_resume.id,
        extracted_text=extraction.text,
        warnings=extraction.warnings,
        character_count=extraction.character_count
    )

@router.post("/analyze", response_model=AnalyzeResponse)
def analyze_resume(
    request: AnalyzeRequest,
    db: Session = Depends(get_db),
    user: User = Depends(check_analysis_limit)
):
    """
    Analyzes a resume against a job description, saves the JD, and creates a Variant.
    """
    if not request.job_description.strip() or not request.resume_text.strip():
        raise HTTPException(status_code=400, detail="Both resume text and job description are required")
    settings = get_settings()
    if len(request.resume_text) > settings.max_resume_characters:
        raise HTTPException(status_code=413, detail="Resume text is too large to analyze.")
    if len(request.job_description) > settings.max_job_description_characters:
        raise HTTPException(status_code=413, detail="Job description is too large to analyze.")

    # Ensure resume belongs to user
    resume = db.query(Resume).filter(Resume.id == request.resume_id, Resume.user_id == user.id).first()
    if not resume:
        raise HTTPException(status_code=404, detail="Resume not found")

    signals = analyze_resume_against_jd(request.resume_text, request.job_description)
    signals["analysis_source"] = "deterministic_baseline"
    signals["analysis_status"] = "pending"
    
    db_jd = JobDescription(
        user_id=user.id,
        raw_text=request.job_description,
        extracted_keywords=signals.get("jd_keywords", [])
    )
    db.add(db_jd)
    db.flush()

    # Save Variant
    db_variant = ResumeVariant(
        resume_id=resume.id,
        job_description_id=db_jd.id,
        variant_name=f"Analysis {db_jd.id}",
        tailored_content={"raw_text": request.resume_text}, 
        ats_score=signals.get("score", 0),
        analysis_feedback=signals
    )
    db.add(db_variant)
    
    # Update usage
    user.analyses_count_today += 1
    db.commit()
    db.refresh(db_variant)

    return build_analyze_response(db_variant.id, signals)

@router.post("/rewrite-bullet", response_model=RewriteBulletResponse)
def rewrite_bullet(
    request: RewriteBulletRequest,
    db: Session = Depends(get_db),
    user: User = Depends(check_rewrite_limit)
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

        # Update usage
        user.rewrites_count_today += 1
        db.commit()

        return RewriteBulletResponse(
            success=True,
            original_bullet=request.original_bullet,
            rewritten_bullets=rewritten,
            ai_model_name=MODEL_NAME
        )
    except Exception as exc:
        logger.exception("Groq bullet rewrite failed")
        raise HTTPException(status_code=503, detail="AI rewrite is temporarily unavailable.") from exc


@router.post("/accept-rewrite", response_model=AcceptRewriteResponse)
def accept_rewrite(
    request: AcceptRewriteRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    variant = db.query(ResumeVariant).join(Resume).filter(
        ResumeVariant.id == request.variant_id,
        Resume.user_id == user.id,
    ).first()
    if not variant:
        raise HTTPException(status_code=404, detail="Variant not found")

    tailored_content = dict(variant.tailored_content or {})
    resume_text = tailored_content.get("raw_text", "")
    if request.original_bullet not in resume_text:
        raise HTTPException(status_code=409, detail="Original bullet was not found in the saved resume.")

    updated_text = resume_text.replace(request.original_bullet, request.rewritten_bullet, 1)
    tailored_content["raw_text"] = updated_text
    variant.tailored_content = tailored_content
    db.commit()

    return AcceptRewriteResponse(
        success=True,
        variant_id=variant.id,
        updated_resume_text=updated_text,
    )

@router.get("/history", response_model=HistoryResponse)
def get_history(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    """
    Retrieves the analysis history (Resume Variants) for the authenticated user.
    """
    # Join across Resume -> Variant to ensure ownership
    variants = db.query(ResumeVariant).join(Resume).filter(Resume.user_id == user.id).order_by(ResumeVariant.created_at.desc()).all()
    
    return HistoryResponse(
        success=True,
        variants=[
            VariantSummary(
                id=v.id,
                resume_id=v.resume_id,
                variant_name=v.variant_name,
                ats_score=v.ats_score,
                created_at=v.created_at,
                updated_at=v.updated_at
            ) for v in variants
        ]
    )

@router.get("/variants/{variant_id}")
def get_variant(
    variant_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    """
    Retrieves a specific analysis/variant by ID.
    """
    variant = db.query(ResumeVariant).join(Resume).filter(
        ResumeVariant.id == variant_id,
        Resume.user_id == user.id
    ).first()
    
    if not variant:
        raise HTTPException(status_code=404, detail="Variant not found")
        
    return {
        "success": True,
        "variant": {
            "id": variant.id,
            "resume_id": variant.resume_id,
            "variant_name": variant.variant_name,
            "tailored_content": variant.tailored_content,
            "ats_score": variant.ats_score,
            "analysis_feedback": variant.analysis_feedback,
            "created_at": variant.created_at
        }
    }


@router.get("/analysis/{variant_id}", response_model=AnalyzeResponse)
def get_analysis_result(
    variant_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    variant = db.query(ResumeVariant).join(Resume).filter(
        ResumeVariant.id == variant_id,
        Resume.user_id == user.id
    ).first()

    if not variant:
        raise HTTPException(status_code=404, detail="Variant not found")

    signals = variant.analysis_feedback or {}
    if signals.get("analysis_status") == "pending":
        baseline_signals = dict(signals)
        resume_text = (variant.tailored_content or {}).get("raw_text", "")
        job_description = variant.job_description.raw_text
        try:
            signals = analyze_resume_with_groq(resume_text, job_description, baseline_signals)
            signals["analysis_status"] = "complete"
        except Exception:
            logger.exception("Groq analysis refinement failed for variant %s", variant.id)
            signals = baseline_signals
            signals["analysis_source"] = "deterministic_fallback"
            signals["analysis_status"] = "failed"

        variant.ats_score = signals.get("score", variant.ats_score)
        variant.analysis_feedback = signals
        db.commit()

    return build_analyze_response(variant.id, signals)


@router.delete("/account", response_model=DeleteAccountResponse)
def delete_account(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    db.delete(user)
    db.commit()
    return DeleteAccountResponse(success=True)

@router.post("/export")
def export_resume(
    request: ExportRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    """
    Exports a specific variant into an ATS-safe PDF.
    """
    variant = db.query(ResumeVariant).join(Resume).filter(
        ResumeVariant.id == request.variant_id,
        Resume.user_id == user.id
    ).first()
    
    if not variant:
        raise HTTPException(status_code=404, detail="Variant not found")

    text_content = variant.tailored_content.get("raw_text", "")
    pdf_bytes = generate_ats_pdf(text_content)
    
    filename = f"{variant.variant_name.replace(' ', '_')}.pdf"
    
    return Response(
        content=pdf_bytes, 
        media_type="application/pdf", 
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )
