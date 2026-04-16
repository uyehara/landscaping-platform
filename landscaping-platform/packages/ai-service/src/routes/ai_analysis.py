from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, Literal

router = APIRouter()


class ChatMessage(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    model: str = "gpt-4o-mini"
    temperature: float = 0.7
    max_tokens: Optional[int] = None


class ChatResponse(BaseModel):
    message: ChatMessage
    usage: dict
    model: str


class PlantAnalysisRequest(BaseModel):
    description: str
    zone_type: Optional[str] = None
    climate_zone: Optional[str] = None
    soil_type: Optional[str] = None


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Send a chat message to the LLM."""
    # TODO: Implement actual LLM call with OpenAI/Anthropic
    response_content = "This is a mock response. Implement actual LLM integration."

    return ChatResponse(
        message=ChatMessage(role="assistant", content=response_content),
        usage={"prompt_tokens": 100, "completion_tokens": 50, "total_tokens": 150},
        model=request.model
    )


@router.post("/plant-suggestions")
async def suggest_plants(request: PlantAnalysisRequest):
    """Get AI-suggested plants based on project context."""
    # TODO: Implement plant suggestion logic with RAG or LLM
    return {
        "suggestions": [
            {
                "name": "Japanese Maple",
                "scientific_name": "Acer palmatum",
                "zone": "5-9",
                "sun_requirement": "Partial shade",
                "water_requirement": "Regular",
                "mature_size": "15-25 ft",
                "reason": "Adds year-round visual interest with colorful foliage"
            },
            {
                "name": "Boxwood",
                "scientific_name": "Buxus sempervirens",
                "zone": "5-9",
                "sun_requirement": "Full to partial sun",
                "water_requirement": "Moderate",
                "mature_size": "3-4 ft",
                "reason": "Excellent for hedges and formal borders"
            }
        ],
        "context": {
            "zone_type": request.zone_type,
            "climate_zone": request.climate_zone
        }
    }


@router.post("/cost-estimate")
async def estimate_costs(
    items: list[dict],
    region: str = "us-east"
):
    """Estimate costs for landscaping materials and labor."""
    # TODO: Implement cost estimation with pricing database
    return {
        "items": items,
        "subtotal_materials": 0.0,
        "estimated_labor": 0.0,
        "total": 0.0,
        "region": region,
        "note": "Mock implementation - integrate pricing database"
    }
