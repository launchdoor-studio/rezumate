import json
import time

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from fastapi import Depends

from app.services.ats_service import analyze_resume_against_jd, content_hash
from app.services.pdf_service import ExtractionResult, extract_pdf_text
from app.services.ai_service import (
    MODEL_NAME,
    SCORE_PROMPT_VERSION,
    get_ai_response,
    get_comparison_response,
    get_ranking_response,
    get_chat_response,
)
from app.services.schemas import AnalysisResult, SkillMatch
from app.database import get_db, Analysis

router = APIRouter()

PDF_CONTENT_TYPES = {"application/pdf", "application/x-pdf"}


def validate_pdf_upload(upload: UploadFile, label: str = "Resume"):
    filename = upload.filename or ""
    content_type = upload.content_type or ""

    if not filename:
        raise HTTPException(status_code=400, detail=f"{label} file is required")

    if content_type not in PDF_CONTENT_TYPES and not filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported right now")


def build_fallback_analysis(deterministic_signals: dict) -> AnalysisResult:
    score = deterministic_signals["score"]
    if score >= 80:
        fit_level = "Strong Match"
    elif score >= 65:
        fit_level = "Moderate"
    elif score >= 50:
        fit_level = "Weak"
    else:
        fit_level = "Poor"

    matched_skills = [
        SkillMatch(skill=skill, match_type="Full", evidence="Found in the extracted resume text.")
        for skill in deterministic_signals["matched_keywords"][:12]
    ]
    matched_skills.extend(
        SkillMatch(skill=skill, match_type="Partial", evidence="Related wording was found in the extracted resume text.")
        for skill in deterministic_signals["partial_matches"][:8]
    )

    improvement_suggestions = []
    if deterministic_signals["missing_keywords"]:
        improvement_suggestions.append(
            "Review the missing role keywords and add only the ones that truthfully reflect your experience."
        )
    if deterministic_signals["weak_bullet_count"]:
        improvement_suggestions.append(
            "Rewrite weak bullets to start with stronger action verbs and describe the outcome."
        )
    if deterministic_signals["bullets_without_measurable_impact_count"]:
        improvement_suggestions.append(
            "Add measurable impact to bullets where you have real numbers, scale, frequency, or business results."
        )
    if deterministic_signals["formatting_warnings"]:
        improvement_suggestions.extend(deterministic_signals["formatting_warnings"])

    return AnalysisResult(
        match_percentage=score,
        fit_level=fit_level,
        matched_skills=matched_skills,
        missing_skills=deterministic_signals["missing_keywords"][:12],
        strengths=[
            f"{deterministic_signals['keyword_coverage']}% deterministic keyword coverage.",
            "Resume text was extracted successfully and analyzed with repeatable ATS checks.",
        ],
        improvement_suggestions=improvement_suggestions or [
            "Review the deterministic checks and tune the resume toward the most important role requirements."
        ],
    )


async def extract_resume_text(upload: UploadFile) -> ExtractionResult:
    validate_pdf_upload(upload)
    content = await upload.read()
    extraction = extract_pdf_text(content)

    if extraction.status in {"failed", "empty"} or not extraction.text.strip():
        raise HTTPException(
            status_code=400,
            detail="Could not extract text from this PDF. Please upload a text-based resume PDF.",
        )

    return extraction


@router.post("/score")
async def score_resume(
    job_description: str = Form(...),
    resume: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    if not job_description.strip():
        raise HTTPException(status_code=400, detail="Job description is required")

    validate_pdf_upload(resume)

    try:
        started_at = time.perf_counter()
        extraction = await extract_resume_text(resume)
        resume_text = extraction.text

        deterministic_signals = analyze_resume_against_jd(resume_text, job_description)

        warnings = list(extraction.warnings)
        try:
            result = get_ai_response(job_description, resume_text)
            model_name = MODEL_NAME
        except Exception:
            result = build_fallback_analysis(deterministic_signals)
            model_name = "deterministic-fallback"
            warnings.append("AI analysis was unavailable, so Rezumate returned deterministic ATS checks.")

        latency_ms = round((time.perf_counter() - started_at) * 1000)

        # Save to database
        db_analysis = Analysis(
            filename=resume.filename,
            job_description=job_description,
            resume_text=resume_text,
            resume_hash=content_hash(resume_text),
            job_description_hash=content_hash(job_description),
            extraction_status=extraction.status,
            extraction_warnings=warnings,
            deterministic_signals=deterministic_signals,
            result_json=result.model_dump(),
            match_score=deterministic_signals["score"],
            model_name=model_name,
            prompt_version=SCORE_PROMPT_VERSION,
            latency_ms=latency_ms,
        )
        db.add(db_analysis)
        db.commit()
        db.refresh(db_analysis)

        return {
            "success": True,
            "result": result,
            "filename": resume.filename,
            "resume_text": resume_text,
            "analysis_id": db_analysis.id,
            "deterministic_signals": deterministic_signals,
            "warnings": warnings,
            "model_name": model_name,
            "prompt_version": SCORE_PROMPT_VERSION,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/compare")
async def compare_resumes(
    job_description: str = Form(...),
    resume1: UploadFile = File(...),
    resume2: UploadFile = File(...)
):
    if not job_description.strip():
        raise HTTPException(status_code=400, detail="Job description is required")

    try:
        resume1_text = (await extract_resume_text(resume1)).text
        resume2_text = (await extract_resume_text(resume2)).text

        result = get_comparison_response(job_description, resume1_text, resume2_text)

        return {
            "success": True,
            "result": result,
            "resume1_filename": resume1.filename,
            "resume2_filename": resume2.filename
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/rank")
async def rank_resumes(
    job_description: str = Form(...),
    resumes: list[UploadFile] = File(...)
):
    if not job_description.strip():
        raise HTTPException(status_code=400, detail="Job description is required")

    if len(resumes) < 2:
        raise HTTPException(status_code=400, detail="At least 2 resumes are required for ranking")

    try:
        parsed_resumes = []
        for resume in resumes:
            text = (await extract_resume_text(resume)).text
            if text.strip():
                parsed_resumes.append({
                    "filename": resume.filename,
                    "content": text
                })

        if len(parsed_resumes) < 2:
            raise HTTPException(status_code=400, detail="Could not extract text from enough resumes")

        result = get_ranking_response(job_description, parsed_resumes)

        return {
            "success": True,
            "result": result,
            "resume_count": len(parsed_resumes),
            "filenames": [r["filename"] for r in parsed_resumes]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/chat")
async def chat(
    message: str = Form(...),
    job_description: str = Form(...),
    resume_text: str = Form(...),
    chat_history: str = Form(default="[]")
):
    if not message.strip():
        raise HTTPException(status_code=400, detail="Message is required")

    try:
        history = json.loads(chat_history)
        response = get_chat_response(job_description, resume_text, history, message)

        return {
            "success": True,
            "response": response
        }
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid chat history format")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
