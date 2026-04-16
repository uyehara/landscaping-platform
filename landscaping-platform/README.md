# Landscaping Platform

AI-enabled landscaping business management platform with collaborative CAD-like design tools.


## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Frontend                                  │
│                   SvelteKit + Tailwind CSS                       │
│                   Konva.js (CAD Drawing)                         │
│                   Y.js (Real-time Collaboration)                 │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      API Gateway (Fastify)                        │
│              Auth │ Routing │ CRUD │ Business Logic                │
└─────────────────────────────────────────────────────────────────────┘
                    │                           │
                    ▼                           ▼
┌───────────────────────────────┐   ┌───────────────────────────────────┐
│         AI Service            │   │        Collaboration Server       │
│       (Python FastAPI)       │   │        (Hocuspocus Y.js)          │
│  Image Analysis │ Embeddings  │   │     Real-time CRDT Sync           │
│  LLM Orchestration            │   │                                   │
└───────────────────────────────┘   └───────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    PostgreSQL + pgvector                          │
│            Business Data │ Vector Embeddings │ Y.js Docs           │
└─────────────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│               S3-Compatible Storage (MinIO)                        │
│                    Asset Storage │ Media Files                    │
└─────────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | SvelteKit, Tailwind CSS, Flowbite Svelte, Konva.js |
| API Gateway | Fastify (Node.js) |
| AI Service | Python FastAPI |
| Collaboration | Hocuspocus (Y.js WebSocket server) |
| Database | PostgreSQL 16 + pgvector |
| Storage | MinIO (S3-compatible) |
| Auth | Auth.js (MVP) |
| Containerization | Docker Compose |

## Project Structure

```
landscaping-platform/
├── packages/
│   ├── frontend/          # SvelteKit application
│   ├── api-gateway/      # Fastify Node.js API
│   ├── ai-service/       # Python FastAPI AI microservice
│   └── collaboration/    # Hocuspocus WebSocket server
├── postgres/
│   └── init-scripts/      # Database initialization
├── docker-compose.yml     # Full stack orchestration
└── .env.example          # Environment template
```


## Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 20+ (for local development)
- Python 3.11+ (for local AI service development)


### 1. Clone and Configure

```bash
git clone <repository-url>
cd landscaping-platform
cp .env.example .env
```

### 2. Start All Services

```bash
docker-compose up -d
```

### 3. Access Services

| Service | URL |
|---------|-----|
| Frontend | http://localhost:5173 |
| API Gateway | http://localhost:3001 |
| MinIO Console | http://localhost:9001 |
| Collaboration | ws://localhost:1234 |

### 4. Verify Services

```bash
# Check all containers are running
docker-compose ps

# Check API health
curl http://localhost:3001/health

# Check AI service health
curl http://localhost:8000/health
```

## Local Development

### Frontend

```bash
cd packages/frontend
npm install
npm run dev
```

### API Gateway

```bash
cd packages/api-gateway
npm install
npm run dev
```

### AI Service

```bash
cd packages/ai-service
pip install -r requirements.txt
uvicorn src.main:app --reload
```

### Collaboration Server

```bash
cd packages/collaboration
npm install
npm run dev
```

## Services Documentation

- [Frontend](./packages/frontend/README.md)
- [API Gateway](./packages/api-gateway/README.md)
- [AI Service](./packages/ai-service/README.md)
- [Collaboration](./packages/collaboration/README.md)


## Environment Variables

See `.env.example` for all configuration options. Key variables:

- `POSTGRES_*` - PostgreSQL connection settings
- `MINIO_ROOT_*` - MinIO credentials
- `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` - AI model API keys
- `JWT_SECRET` - Authentication secret

## License

Proprietary - All rights reserved
