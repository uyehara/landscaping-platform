# Architecture Overview

## System Architecture

The Landscaping Platform employs a service-oriented architecture with clear separation of concerns between frontend presentation, API business logic, AI/ML processing, and real-time collaboration.

## High-Level Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              Users                                           │
│                    (Web Browser / Mobile PWA)                              │
└────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                          Frontend Service                                   │
│                          (SvelteKit + Vite)                                │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │  Design Canvas  │  │   Admin UI      │  │    Customer Portal          │ │
│  │  (Konva.js)     │  │  (Flowbite)     │  │     (Auth.js)              │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
│                                                                             │
│  Responsibilities:                                                           │
│  - User interface and interactions                                          │
│  - CAD/design canvas rendering                                             │
│  - State management (TanStack Query)                                       │
│  - Real-time collaboration via Y.js                                         │
└─────────────────────────────────────┬──────────────────────────────────────┘
                                      │ HTTP REST API / WebSocket
                                      ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                           API Gateway                                       │
│                         (Fastify + Node.js)                                │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │  Auth Plugin    │  │  Storage Plugin │  │     CRUD Services           │ │
│  │  (JWT/OIDC)     │  │   (MinIO S3)    │  │   (Business Logic)          │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
│                                                                             │
│  Responsibilities:                                                           │
│  - RESTful API routing                                                      │
│  - Authentication & authorization                                            │
│  - Request validation                                                        │
│  - Business logic orchestration                                             │
│  - Integration with AI service and collaboration                            │
└────────────┬────────────────────┬────────────────────┬───────────────────┘
             │                    │                    │
             ▼                    ▼                    ▼
┌────────────────────┐ ┌────────────────────┐ ┌────────────────────────────────┐
│   AI Service       │ │  Collaboration     │ │        PostgreSQL              │
│  (FastAPI + Python)│ │   (Hocuspocus)      │ │      (pgvector enabled)         │
│                    │ │                    │ │                                 │
│ ┌────────────────┐ │ │ ┌────────────────┐ │ │ ┌──────────────────────────────┐ │
│ │ Image Process. │ │ │ │ Y.js WebSocket │ │ │ │ • Users, Roles, Permissions  │ │
│ │ Embeddings     │ │ │ │ Server         │ │ │ │ • Customers, Properties      │ │
│ │ AI Analysis    │ │ │ └────────────────┘ │ │ │ • Projects, Phases, Jobs     │ │
│ └────────────────┘ │ └────────────────────┘ │ │ • Contracts, Schedules       │ │
└────────────────────┘ └──────────────────────┘ │ • Reference Library (Vector) │ │
                                                │ • Media Files                │ │
                                                │ • Y.js Documents             │ │
                                                └──────────────────────────────┘ │
                                                         │
                                                         ▼
                                                ┌────────────────────┐
                                                │       MinIO         │
                                                │   (S3-compatible)   │
                                                │                     │
                                                │ • Plant images      │
                                                │ • Style photos      │
                                                │ • Property images   │
                                                │ • Project documents │
                                                └────────────────────┘
```

## Service Interactions

### Frontend → API Gateway
- All API calls go through the Fastify gateway
- JWT token authentication via Auth.js sessions
- TanStack Query for server state management
- WebSocket connection for collaboration

### API Gateway → PostgreSQL
- Direct database connection via `pg` driver
- Connection pooling for performance
- pgvector for similarity search

### API Gateway → AI Service
- REST calls to `/ai/analyze`, `/embeddings/*`, `/images/*`
- Async processing for heavy AI operations
- Results stored and polled via job status

### API Gateway → MinIO
- Pre-signed URLs for direct browser uploads
- Storage operations via MinIO S3 SDK
- Automatic thumbnail generation pipeline

### Frontend → Collaboration Server
- Direct WebSocket connection to Hocuspocus
- Y.js CRDTs for conflict-free collaborative editing
- Authentication via JWT token validation

## Data Flow

### Design Document Creation Flow
1. User creates project → API Gateway → PostgreSQL (projects table)
2. User opens design canvas → Frontend connects to Hocuspocus
3. Design changes → Y.js CRDT sync → Persisted to yjs_documents
4. Plant placement → AI similarity search via pgvector
5. Media upload → Browser → MinIO (direct) → PostgreSQL (media_files)

### Media Processing Flow
1. Image uploaded to MinIO
2. Media record created in PostgreSQL
3. Processing job queued in media_processing_log
4. AI Service polls job queue, processes image
5. Results (thumbnails, embeddings, metadata) stored
6. Frontend polls for completion, displays results

## Deployment Topology

### Development (Docker Compose)
```
┌─────────────────────────────────────────────────┐
│                   Host Machine                   │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │Frontend  │  │API       │  │  Services    │  │
│  │:5173     │  │Gateway   │  │  (Ports)     │  │
│  │          │  │:3001     │  │              │  │
│  └──────────┘  └──────────┘  └──────────────┘  │
│                                                  │
│  Ports exposed to host for local development     │
└─────────────────────────────────────────────────┘
```

### Production (Recommended)
```
┌─────────────────────────────────────────────────────────────┐
│                      Load Balancer                           │
└─────────────────────────────────────────────────────────────┘
                     │           │           │
                     ▼           ▼           ▼
┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
│  Frontend  │ │  Frontend  │ │     API    │ │    API     │
│  Instance  │ │  Instance  │ │  Instance  │ │  Instance  │
│  (x2+)     │ │  (x2+)     │ │  (x2+)     │ │  (x2+)     │
└────────────┘ └────────────┘ └────────────┘ └────────────┘
                                        │
                     ┌────────────────┼────────────────┐
                     ▼                ▼                ▼
              ┌────────────┐  ┌────────────┐  ┌────────────┐
              │ PostgreSQL│  │   MinIO    │  │  AI Service│
              │ (RDS/HA)  │  │  (S3/GCS)  │  │  (K8s)     │
              └────────────┘  └────────────┘  └────────────┘
```

## Security Considerations

- **Authentication**: JWT tokens with configurable expiry
- **Authorization**: Role-based with granular permission checks
- **Storage**: Pre-signed URLs with time-limited access
- **Network**: All services on isolated Docker bridge network
- **Database**: Connection pooling, parameterized queries

## Scalability Notes

- **Stateless API**: Horizontal scaling via load balancer
- **Session Storage**: Auth.js sessions can move to Redis for multi-instance
- **AI Service**: Can be scaled independently with async job queue
- **Collaboration**: Hocuspocus supports clustering for multiple instances
- **Database**: pgvector queries scale with proper index maintenance
