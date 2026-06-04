from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import get_settings, validate_production_settings


validate_production_settings()

from app.routes.api import router as api_router
from app.database import init_db


@asynccontextmanager
async def lifespan(_: FastAPI):
    validate_production_settings()
    if not get_settings().is_production:
        init_db()
    yield


app = FastAPI(
    title="Rezumate API",
    description="Native iOS resume optimization API",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(api_router, prefix="/api")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
