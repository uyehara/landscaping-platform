import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings

from src.routes import health, embeddings, ai_analysis, image_processing


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://landscape:postgres@localhost:5432/landscaping"
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    LOG_LEVEL: str = "INFO"

    class Config:
        env_file = ".env"


settings = Settings()
logging.basicConfig(level=settings.LOG_LEVEL)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting AI Service...")
    # Initialize services
    yield
    logger.info("Shutting down AI Service...")


app = FastAPI(
    title="Landscaping AI Service",
    description="AI microservices for image analysis, embeddings, and LLM orchestration",
    version="0.1.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(health.router, tags=["Health"])
app.include_router(embeddings.router, prefix="/api/embeddings", tags=["Embeddings"])
app.include_router(ai_analysis.router, prefix="/api/ai", tags=["AI Analysis"])
app.include_router(image_processing.router, prefix="/api/images", tags=["Image Processing"])


@app.get("/")
async def root():
    return {
        "service": "Landscaping AI Service",
        "version": "0.1.0",
        "endpoints": ["/api/embeddings", "/api/ai", "/api/images"]
    }
