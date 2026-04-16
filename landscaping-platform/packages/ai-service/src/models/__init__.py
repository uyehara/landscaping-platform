from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class PlantSpecies(BaseModel):
    id: str
    name: str
    scientific_name: str
    description: str
    care_instructions: str
    growth_rate: str
    mature_height: float
    mature_spread: float
    zone_min: int
    zone_max: int
    sun_requirement: str
    water_requirement: str
    soil_type: str
    image_url: Optional[str] = None
    embedding: Optional[list[float]] = None


class ProjectContext(BaseModel):
    project_id: str
    zone_type: str
    climate_zone: str
    soil_type: str
    budget_range: str
    maintenance_level: str
    style_preference: str
