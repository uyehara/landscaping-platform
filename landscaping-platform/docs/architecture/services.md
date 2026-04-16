# Service Descriptions

## Overview

The platform consists of 6 Docker services working together:

| Service | Technology | Port | Purpose |
|---------|-------------|------|---------|
| frontend | SvelteKit | 5173 | User interface |
| api-gateway | Fastify/Node.js | 3001 | API gateway |
| ai-service | FastAPI/Python | 8000 | AI/ML processing |
| collaboration | Hocuspocus/Y.js | 1234 | Real-time collaboration |
| postgres | PostgreSQL 16 + pgvector | 5432 | Primary database |
| minio | MinIO | 9000/9001 | S3-compatible storage |

## Frontend Service

**Image:** `packages/frontend/Dockerfile`

### Technology Stack
- **Framework:** SvelteKit with SSR
- **UI Library:** Flowbite Svelte (Tailwind-based components)
- **Styling:** Tailwind CSS
- **State Management:** TanStack Query (React Query port for Svelte)
- **Canvas:** Konva.js for CAD/design overlays
- **Collaboration:** Y.js with Hocuspocus client
- **Authentication:** Auth.js (SvelteKit adapter)

### Configuration
```bash
PUBLIC_API_URL=http://localhost:3001        # API gateway URL
PUBLIC_COLLABORATION_URL=ws://localhost:1234  # WebSocket server
```

### Development Mode
In development, the source directory is mounted as a volume, enabling hot-reload:
```yaml
volumes:
  - ./packages/frontend:/app
  - /app/node_modules
```

### Key Routes
- `/` - Dashboard
- `/projects` - Project list
- `/projects/[id]` - Project detail with design canvas
- `/customers` - Customer management
- `/contracts` - Contract management
- `/library` - Reference library (plants, styles, guides)
- `/estimates` - Estimate builder

---

## API Gateway Service

**Image:** `packages/api-gateway/Dockerfile`

### Technology Stack
- **Runtime:** Node.js 20+
- **Framework:** Fastify (high-performance web framework)
- **Database Client:** pg (Node-Postgres)
- **Storage:** MinIO JavaScript SDK
- **Authentication:** JWT validation
- **Validation:** JSON Schema / Zod

### Configuration
```bash
NODE_ENV=development
PORT=3001
DATABASE_URL=postgres://user:pass@postgres:5432/landscaping
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=landscaping-assets
AI_SERVICE_URL=http://ai-service:8000
COLLABORATION_URL=ws://collaboration:1234
CORS_ORIGIN=http://localhost:5173
JWT_SECRET=your-secret-key
```


### Route Structure
```
/auth/*          - Authentication endpoints
/projects/*      - Project CRUD
/customers/*     - Customer management
/contracts/*    - Contract management
/jobs/*          - Job management
/library/*       - Reference library
/media/*         - Media management
/estimates/*     - Estimate builder
/storage/*       - MinIO operations
/health          - Health check
```

### Key Features
- **Auth Plugin:** JWT token validation on protected routes
- **Storage Plugin:** Pre-signed URL generation for uploads
- **RBAC Middleware:** Permission checking based on user roles
- **Error Handling:** Standardized error responses

---

## AI Service

**Image:** `packages/ai-service/Dockerfile`


### Technology Stack
- **Runtime:** Python 3.11+
- **Framework:** FastAPI
- **AI Providers:** OpenAI GPT-4V, Anthropic Claude (configurable)
- **Image Processing:** Pillow, OpenCV
- **Database:** SQLAlchemy + asyncpg
- **Vector Search:** pgvector via psycopg2

### Configuration
```bash
DATABASE_URL=postgres://user:pass@postgres:5432/landscaping
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
LOG_LEVEL=INFO
```

### API Routes

#### Image Processing (`/images/*`)
```
POST /images/generate-thumbnail
  - Input: storage_key, dimensions
  - Output: thumbnail_key

POST /images/describe
  - Input: image data or storage_key
  - Output: AI-generated description, tags
```

#### Embeddings (`/embeddings/*`)
```
POST /embeddings/text
  - Input: text string
  - Output: embedding vector

POST /embeddings/image
  - Input: image data
  - Output: embedding vector

GET /embeddings/search/{type}
  - Query: embedding, limit, threshold
  - Output: matching records with similarity scores
```


#### AI Analysis (`/ai/*`)
```
POST /ai/analyze/property
  - Input: property_id
  - Output: site analysis, recommendations

POST /ai/suggest/plants
  - Input: criteria (zone, sun, water, style)
  - Output: plant recommendations with rationale
```

### Processing Pipeline
1. Job created in `media_processing_log`
2. AI service polls for pending jobs
3. Processing happens asynchronously
4. Results stored in database
5. Frontend polls for job completion

---

## Collaboration Service

**Image:** `packages/collaboration/Dockerfile`

### Technology Stack
- **Runtime:** Node.js
- **Framework:** Hocuspocus (Y.js server)
- **Protocol:** WebSocket + Y.js CRDT
- **Persistence:** In-memory (MVP), PostgreSQL (production)

### Configuration
```bash
PORT=1234
DB_TYPE=memory  # 'database' for production
DB_URL=postgres://user:pass@postgres:5432/landscaping
JWT_SECRET=your-secret-key
```

### Document Structure
Documents follow the naming convention: `project:{project_id}:canvas`

### Connection Flow
1. Client connects via WebSocket
2. JWT token validated
3. Document state synced from persistence
4. Real-time updates via Y.js awareness
5. Periodic state persistence

### Persistence Hooks
```typescript
onStoreDocument: async (document) => {
  // Save to yjs_documents table
}

onLoadDocument: async (name) => {
  // Load from yjs_documents table
}
```


---

## PostgreSQL Service

**Image:** `pgvector/pgvector:pg16`

### Extensions
- **uuid-ossp:** UUID generation
- **vector:** pgvector for similarity search


### Connection
```bash
POSTGRES_USER=landscape
POSTGRES_PASSWORD=postgres
POSTGRES_DB=landscaping
```

### Key Tables
See [Data Model](./data-model.md) for detailed schema.

### Health Check
```bash
pg_isready -U landscape
```

---

## MinIO Service

**Image:** `minio/minio:latest`

### Purpose
S3-compatible object storage for:
- Plant images
- Style photos
- Property images
- Project documents
- Media thumbnails

### Ports
- **9000:** S3 API
- **9001:** Console (web UI)

### Default Credentials
```bash
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
```

### Buckets
Created on startup via `minio-setup` service:
- `landscaping-assets` (public download)

### Health Check
```bash
mc ready local
```

### Client Usage
Use `mc` (MinIO Client) to interact:
```bash
mc alias set local http://minio:9000 minioadmin minioadmin
mc ls local/landscaping-assets
mc presign local/landscaping-assets/object-key
```

---

## Service Dependencies

```
┌────────────────┐
│   postgres     │  (No dependencies)
└────────────────┘
        │
        ▼
┌────────────────┐     ┌────────────────┐
│     minio      │────▶│  minio-setup   │
└────────────────┘     └────────────────┘
        │
        ├────────────────────┐
        ▼                    ▼
┌────────────────┐   ┌────────────────┐
│  api-gateway   │   │   ai-service   │
└────────────────┘   └────────────────┘
        │
        ▼
┌────────────────┐   ┌────────────────┐
│    frontend    │   │ collaboration  │
└────────────────┘   └────────────────┘
```

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | landscape | Database user |
| `POSTGRES_PASSWORD` | postgres | Database password |
| `POSTGRES_DB` | landscaping | Database name |
| `MINIO_ROOT_USER` | minioadmin | MinIO access key |
| `MINIO_ROOT_PASSWORD` | minioadmin | MinIO secret key |
| `API_GATEWAY_PORT` | 3001 | API gateway port |
| `JWT_SECRET` | (required) | JWT signing secret |
| `OPENAI_API_KEY` | | OpenAI API key |
| `ANTHROPIC_API_KEY` | | Anthropic API key |
| `CORS_ORIGIN` | http://localhost:5173 | Allowed CORS origin |
