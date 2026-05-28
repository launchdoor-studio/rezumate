import os

from dotenv import load_dotenv
from fastapi import FastAPI

from app.routes.api import router as api_router
from app.database import init_db

load_dotenv()

# Initialize database
init_db()

app = FastAPI(title="Rezumate API", description="Mobile-First AI-Assisted Resume Optimization API")

app.include_router(api_router, prefix="/api")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
