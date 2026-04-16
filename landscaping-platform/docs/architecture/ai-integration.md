# AI Integration

## Architecture Overview

The AI service provides intelligent capabilities through a FastAPI-based microservice that handles:

- **Image Processing**: Thumbnail generation, AI descriptions, metadata extraction
- **Vector Embeddings**: Text and image embeddings for similarity search
- **AI Analysis**: Property analysis, plant recommendations, design assistance

## Service Communication

```
┌──────────────────┐         REST          ┌──────────────────┐
│   API Gateway    │◄──────────────────────►│   AI Service     │
│   (Fastify)      │                         │   (FastAPI)      │
└──────────────────┘                         └────────┬─────────┘
                                                      │
                     ┌───────────────────────────────┤
                     │                               │
                     ▼                               ▼
              ┌─────────────┐                 ┌─────────────┐
              │  PostgreSQL │                 │  External   │
              │  (pgvector) │                 │   APIs      │
              └─────────────┘                 │ OpenAI      │
                                            │ Anthropic   │
                                            └─────────────┘
```

## AI Providers

### OpenAI
Used for GPT-4V image analysis and text embeddings.

```bash
OPENAI_API_KEY=sk-...
```

### Anthropic
Used for Claude-based analysis and reasoning.

```bash
ANTHROPIC_API_KEY=sk-ant-...
```

## Image Processing Pipeline

### Workflow

```
1. Upload        2. Create Job     3. Process        4. Store Results
┌────────┐      ┌─────────────┐    ┌──────────────┐  ┌───────────────┐
│ Browser │────►│ API Gateway │───►│ AI Service   │─►│ PostgreSQL   │
└────────┘      │             │    │              │  │              │
               │ media_files │    │ Thumbnail    │  │ media_files  │
               │ media_      │    │ AI Describe  │  │ embedding    │
               │ processing_ │    │ Embeddings   │  │ thumbnail_key│
               │ log         │    │              │  │ metadata     │
               └─────────────┘    └──────────────┘  └───────────────┘
```

### Supported Workflows

| Workflow | Description |
|----------|-------------|
| `thumbnail` | Generate resized thumbnail versions |
| `ai_description` | AI-generated image captions and tags |
| `embeddings` | Generate vector embeddings for similarity search |
| `object_detection` | Detect plants/objects in images |

### Implementation

```python
# packages/ai-service/src/routes/image_processing.py

@router.post("/images/generate-thumbnail")
async def generate_thumbnail(request: ThumbnailRequest):
    """Generate thumbnail from stored image"""
    # 1. Download from MinIO
    # 2. Resize using Pillow
    # 3. Upload back to MinIO
    # 4. Return thumbnail key

@router.post("/images/describe")
async def describe_image(request: DescribeRequest):
    """Generate AI description for image using GPT-4V"""
    # 1. Load image from MinIO/storage
    # 2. Send to OpenAI GPT-4V
    # 3. Parse response for description, tags
    # 4. Store in media_files.metadata
```

## Embedding Strategy

### Embedding Types

| Entity Type | Embedding Dimension | Model |
|-------------|---------------------|-------|
| `plant_species` | 1536 | text-embedding-3-large |
| `landscaping_styles` | 1536 | text-embedding-3-large |
| `media_files` | 1536 | image-embedding-4 (when available) |

### Storage

Embeddings stored directly in PostgreSQL using pgvector:

```sql
ALTER TABLE plant_species ADD COLUMN embedding VECTOR(1536);
CREATE INDEX idx_plant_species_embedding ON plant_species 
    USING hnsw (embedding vector_cosine_ops);
```

### Generation Pipeline

```python
@router.post("/embeddings/text")
async def generate_text_embedding(request: TextEmbeddingRequest):
    """Generate embedding for text content"""
    response = openai.embeddings.create(
        model="text-embedding-3-large",
        input=request.text
    )
    return {"embedding": response.data[0].embedding}

@router.post("/embeddings/image")
async def generate_image_embedding(request: ImageEmbeddingRequest):
    """Generate embedding for image content"""
    # Use GPT-4V vision to describe, then embed description
    # Or use dedicated image embedding model when available
```

### Search

```python
@router.get("/embeddings/search/{entity_type}")
async def search_similar(
    entity_type: str,
    embedding: List[float],
    limit: int = 10,
    threshold: float = 0.7
):
    """Find similar entities by embedding"""
    results = await db.execute(
        f"""
        SELECT id, name,
               1 - (embedding <=> %s::vector) as similarity
        FROM {entity_type}
        WHERE embedding IS NOT NULL
          AND 1 - (embedding <=> %s::vector) > %s
        ORDER BY embedding <=> %s::vector
        LIMIT %s
        """,
        [embedding, embedding, threshold, embedding, limit]
    )
    return results
```

## Prompt Library Approach

### Structure

Prompts are stored as structured templates to ensure consistency:

```
packages/ai-service/
├── src/
│   ├── prompts/
│   │   ├── plant_search.yaml
│   │   ├── style_analysis.yaml
│   │   ├── property_assessment.yaml
│   │   └── design_recommendations.yaml
│   └── services/
│       └── prompt_loader.py
```

### Example: Plant Search Prompt

```yaml
# plant_search.yaml
name: plant_search
description: Find plants matching criteria
template: |
  You are a landscaping expert. Find plants matching these criteria:
  
  Hardiness Zone: {zone_min}-{zone_max}
  Sun Requirement: {sun_requirement}
  Water Requirement: {water_requirement}
  Style: {style}
  
  Return top 5 recommendations with reasoning.
variables:
  - zone_min
  - zone_max
  - sun_requirement
  - water_requirement
  - style
```

### Loading and Rendering

```python
from jinja2 import Template

def render_prompt(prompt_config: dict, variables: dict) -> str:
    """Render a prompt template with variables"""
    template = Template(prompt_config["template"])
    return template.render(**variables)
```

## AI Analysis Endpoints

### Property Analysis

```python
@router.post("/ai/analyze/property")
async def analyze_property(property_id: UUID):
    """
    Analyze property characteristics and provide recommendations.
    
    Inputs:
    - Property location and coordinates
    - Soil type information
    - Site photos
    - Climate zone
    
    Outputs:
    - Site analysis summary
    - Challenges and opportunities
    - Recommended plant categories
    - Design approach suggestions
    """
```

### Plant Recommendations

```python
@router.post("/ai/suggest/plants")
async def suggest_plants(criteria: PlantSearchCriteria):
    """
    Suggest plants based on criteria.
    
    Inputs:
    - zone_min, zone_max
    - sun_requirement
    - water_requirement
    - design_style
    - existing_plants (to avoid duplication)
    
    Outputs:
    - List of recommended species
    - Planting rationale
    - Companion suggestions
    - Avoidance recommendations
    """
```

## Async Processing

### Job Queue Pattern

Heavy operations use async job processing:

```sql
-- media_processing_log tracks all jobs
media_processing_log (
    id UUID PRIMARY KEY,
    media_file_id UUID,
    workflow_name VARCHAR,
    status processing_status,
    input_params JSONB,
    output_results JSONB,
    error_message TEXT,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
)
```

### Polling Flow

```
1. Frontend creates job: status = 'pending'
2. AI Service polls for pending jobs
3. AI Service updates: status = 'running'
4. AI Service completes: status = 'completed' | 'failed'
5. Frontend polls until completion
```

### Implementation


```python
async def poll_pending_jobs():
    """Poll for and process pending media jobs"""
    while True:
        job = await db.fetch_one(
            """SELECT * FROM media_processing_log 
               WHERE status = 'pending'
               ORDER BY created_at ASC
               LIMIT 1"""
        )
        if job:
            await process_job(job)
        await asyncio.sleep(5)  # Poll every 5 seconds
```

## Error Handling

### Retry Strategy

```python
MAX_RETRIES = 3
RETRY_DELAY = 60  # seconds

async def process_with_retry(job: Job):
    for attempt in range(MAX_RETRIES):
        try:
            await process_job(job)
            return
        except Exception as e:
            if attempt < MAX_RETRIES - 1:
                await asyncio.sleep(RETRY_DELAY)
            else:
                await db.execute(
                    """UPDATE media_processing_log 
                       SET status = 'failed', error_message = %s
                       WHERE id = %s""",
                    [str(e), job["id"]]
                )
```

### Error Types

| Error | Cause | Resolution |
|-------|-------|------------|
| `API_RATE_LIMIT` | OpenAI/Anthropic rate limit | Exponential backoff |
| `INVALID_IMAGE` | Corrupt or unsupported format | Return error, don't retry |
| `EMBEDDING_DIMENSION` | Model changed | Regenerate embeddings |
| `PROCESSING_TIMEOUT` | Large image processing | Increase timeout, retry |

## Testing

### Unit Tests

```python
# packages/ai-service/tests/test_embeddings.py

def test_text_embedding():
    response = client.post("/embeddings/text", json={
        "text": "Drought-tolerant native plant"
    })
    assert response.status_code == 200
    assert "embedding" in response.json()
    assert len(response.json()["embedding"]) == 1536
```

### Integration Tests

```python
def test_similarity_search():
    # 1. Create test embeddings
    # 2. Store in database
    # 3. Search for similar
    # 4. Verify results
```

## Performance Considerations

- **Batch Processing**: Process multiple images in batches for efficiency
- **Caching**: Cache frequently accessed embeddings
- **Async/Await**: Use async database operations throughout
- **Connection Pooling**: Configure appropriate pool sizes
- **Embedding Quantization**: Consider quantized embeddings for storage savings

## Security

- **API Keys**: Stored as environment variables, never in code
- **Request Validation**: Validate all inputs before processing
- **Rate Limiting**: Implement per-user rate limits
- **Audit Logging**: Log all AI service calls with user context
