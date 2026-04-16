# Landscaping Platform Documentation

A comprehensive AI-enabled landscaping design and project management platform.


## Overview

The Landscaping Platform is a modern, full-stack application designed to streamline landscaping business operations—from initial customer engagement through project design, execution, and ongoing maintenance. The platform integrates AI-powered design tools, real-time collaboration, and comprehensive business management features.


## Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | SvelteKit, Tailwind CSS, Flowbite Svelte, TanStack Query, Konva.js (CAD/canvas) |
| **API Gateway** | Node.js with Fastify |
| **AI Services** | Python with FastAPI |
| **Database** | PostgreSQL with pgvector extension |
| **Object Storage** | MinIO (S3-compatible) |
| **Collaboration** | Y.js CRDTs via Hocuspocus WebSocket server |
| **Authentication** | Auth.js (MVP), Authentik (roadmap) |
| **Deployment** | Docker Compose |


## Key Features

### Core Business Management
- **Customer Management**: Track customers, properties, and correspondence addresses
- **Contract Management**: Support for IDIQ (Indefinite Delivery/Indefinite Quantity) contracts with task orders
- **Project Management**: Hierarchical projects with phases and jobs
- **Recurring Schedules**: Automated maintenance scheduling linked to contracts
- **Estimating**: Unified billing with line items supporting plants, materials, labor, and equipment

### Design & Reference Library
- **Plant Species Database**: USDA-aligned plant catalog with AI similarity search
- **Landscaping Styles**: Design philosophy library with plant palette associations
- **Plant Palettes**: Curated species collections organized by category
- **Design Guides**: TipTap-based wiki documentation

- **Project Canvas**: Konva.js-powered design overlay for project elements


### AI Integration
- **Image Processing**: Thumbnail generation, AI descriptions, metadata extraction
- **Semantic Search**: Vector embeddings for plants, styles, and media
- **Design Assistance**: AI-driven recommendations based on project context

### Collaboration
- **Real-Time Editing**: Y.js CRDT-based collaborative design canvas
- **Multi-User Support**: Concurrent access with conflict resolution
- **Document Persistence**: PostgreSQL-backed CRDT state storage

## Documentation Structure

```
docs/
├── README.md                    # This file
├── architecture/
│   ├── README.md                # System architecture overview
│   ├── services.md              # Service descriptions
│   ├── data-model.md            # Database schema documentation
│   └── ai-integration.md        # AI services architecture
├── development/
│   ├── getting-started.md       # Quick start guide
│   ├── local-setup.md          # Detailed local development
│   └── contributing.md          # Contribution guidelines
├── reference/
│   ├── api.md                   # API reference documentation
│   └── database.md              # Detailed database schema reference
├── roadmap/
│   └── README.md               # Project roadmap
└── runbook/
    ├── deployment.md            # Deployment procedures
    ├── backup.md               # Backup and recovery
    ├── monitoring.md           # Monitoring setup
    └── troubleshooting.md       # Common issues and solutions
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Frontend (SvelteKit)                         │
│              Port 5173 │ CAD Canvas │ Tailwind UI                  │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │ HTTP/WebSocket
┌─────────────────────────────────┴───────────────────────────────────┐
│                      API Gateway (Fastify)                         │
│                      Port 3001 │ Auth │ CRUD                        │
└──────┬─────────────────────┬───────────────────┬───────────────────┘
       │                     │                   │
┌──────┴──────┐      ┌──────┴──────┐    ┌──────┴──────┐
│ PostgreSQL  │      │ AI Service  │    │ Collaboration│
│ (pgvector)  │      │ (FastAPI)   │    │ (Hocuspocus) │
└─────────────┘      └─────────────┘    └──────────────┘
       │
┌──────┴──────┐
│   MinIO     │
│  (S3 API)   │
└─────────────┘
```

## Getting Started

See [Development Getting Started](./development/getting-started.md) for detailed setup instructions.

## Repository

https://github.com/uyehara/landscaping-platform
