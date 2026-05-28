from functools import lru_cache
from langchain_groq import ChatGroq
from app.services.schemas import AnalysisResult, ComparisonResult, RankingResult


MODEL_NAME = "llama-3.3-70b-versatile"
SCORE_PROMPT_VERSION = "score-v1"


@lru_cache(maxsize=1)
def get_model():
    return ChatGroq(model=MODEL_NAME, temperature=0.7)


def get_ai_response(job_description: str, resume_content: str) -> AnalysisResult:
    prompt = f"""
You are a calibrated ATS scanner combined with an expert Technical Sourcer. 
Analyze the following resume against the job description and return a structured analysis.

Job Description:
{job_description}

Resume Content:
{resume_content}
"""
    structured_llm = get_model().with_structured_output(AnalysisResult)
    return structured_llm.invoke(prompt)


def get_comparison_response(job_description: str, resume1: str, resume2: str) -> ComparisonResult:
    prompt = f"""
Compare two resumes against the job description. Be objective and critical.

Job Description:
{job_description}

Resume 1:
{resume1}

Resume 2:
{resume2}
"""
    structured_llm = get_model().with_structured_output(ComparisonResult)
    return structured_llm.invoke(prompt)


def get_ranking_response(job_description: str, resumes: list[dict]) -> RankingResult:
    resumes_text = ""
    for i, resume in enumerate(resumes, 1):
        resumes_text += f"\n--- Resume {i}: {resume['filename']} ---\n{resume['content']}\n"

    prompt = f"""
Rank all provided resumes against the job description.

Job Description:
{job_description}

Resumes to Rank:
{resumes_text}
"""
    structured_llm = get_model().with_structured_output(RankingResult)
    return structured_llm.invoke(prompt)


def get_chat_response(job_description: str, resume_content: str, chat_history: list[dict], user_message: str) -> str:
    history_text = ""
    for msg in chat_history:
        role = "User" if msg["role"] == "user" else "Assistant"
        history_text += f"{role}: {msg['content']}\n"

    full_prompt = f"""
You are a professional career coach and resume expert. You are helping a user improve their resume for a specific job.

Job Description:
{job_description}

User's Resume:
{resume_content}

Previous Conversation:
{history_text}

User's New Message: {user_message}

Provide helpful, actionable advice. Be specific and reference the actual content from the resume and job description. Keep responses concise but thorough.
"""
    response = get_model().invoke(full_prompt)
    return response.content
