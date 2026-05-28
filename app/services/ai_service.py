from functools import lru_cache
from typing import List
from langchain_groq import ChatGroq
from pydantic import BaseModel, Field

MODEL_NAME = "llama-3.3-70b-versatile"

class RewriteOptions(BaseModel):
    rewritten_bullets: List[str] = Field(description="3 options of rewritten, optimized bullet points.")

@lru_cache(maxsize=1)
def get_model():
    # Use Llama 3 or fallback to whatever groq provides.
    return ChatGroq(model=MODEL_NAME, temperature=0.7)

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
