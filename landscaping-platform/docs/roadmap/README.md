# Project Roadmap

## Overview

The Landscaping Platform roadmap outlines planned development across three phases:
- **Phase 1 (MVP)**: Core functionality for single-tenancy
- **Phase 2 (Post-MVP)**: Enhanced features and multi-tenancy
- **Phase 3 (Future)**: Advanced capabilities and enterprise features

---

## Phase 1: MVP (Current)

### Core Business Features
- [x] Database schema with dynamic RBAC
- [x] User authentication (Auth.js)
- [x] Customer management
- [x] Property management
- [x] Project/Phase/Job hierarchy
- [x] Contract management with IDIQ support
- [x] Recurring schedules
- [x] Task orders (IDIQ templates)
- [ ] Billing estimates with line items
- [ ] PDF/CSV export for estimates


### Reference Library
- [x] Plant species catalog with USDA alignment
- [x] Landscaping styles library
- [x] Plant palettes
- [x] Design guides (TipTap)
- [x] Vector embeddings for similarity search
- [ ] Plant data population (USDA import)
- [ ] Style gallery population

### AI Integration
- [x] AI service architecture (FastAPI)
- [x] Image processing pipeline
- [x] Text embeddings
- [x] Vector similarity search (pgvector HNSW)
- [ ] AI plant recommendations
- [ ] AI property analysis
- [ ] Design suggestions

### Collaboration
- [x] Y.js CRDT integration
- [x] Hocuspocus WebSocket server
- [x] Document persistence (in-memory MVP)
- [ ] PostgreSQL persistence
- [ ] Design canvas integration

### Media Management
- [x] MinIO S3 storage
- [x] Media files with metadata
- [x] Attachments
- [x] Async processing queue
- [x] Thumbnail generation
- [ ] Image gallery UI

---

## Phase 2: Post-MVP Features

### Enhanced Business Logic
- [ ] Workflow engine for project lifecycle
- [ ] Automated recurring project generation
- [ ] Payment/invoicing integration
- [ ] Supplier catalog and pricing
- [ ] Equipment tracking
- [ ] Crew scheduling and dispatch


### Advanced AI Features
- [ ] GPT-4V image analysis for plant identification
- [ ] Automated plant tagging from photos
- [ ] Site analysis from satellite/property photos
- [ ] Design proposal generation
- [ ] Cost estimation assistance
- [ ] Native/invasive plant alerts


### Enhanced Collaboration
- [ ] Real-time design canvas (Konva.js)
- [ ] Multi-user concurrent editing
- [ ] Version history and undo
- [ ] Comments and annotations
- [ ] Design review workflow
- [ ] Customer collaboration portal


### Data Enrichment
- [ ] USDA PLANTS database sync
- [ ] Native plant society data import
- [ ] Climate zone API integration
- [ ] Weather data integration
- [ ] Supplier API integrations

### Authentication & Security
- [ ] Authentik SSO integration
- [ ] Two-factor authentication
- [ ] Audit logging
- [ ] IP-based access control
- [ ] Session management

---

## Phase 3: Future Considerations

### Multi-Tenancy
- [ ] Organization/tenant isolation
- [ ] White-label support
- [ ] Tenant-specific configurations
- [ ] Resource quotas
- [ ] Cross-tenant collaboration (opt-in)

### Enterprise Features
- [ ] ERP integration (QuickBooks, SAP)
- [ ] GIS integration (PostGIS)
- [ ] Advanced reporting
- [ ] Business intelligence dashboards
- [ ] API rate limiting
- [ ] Webhook notifications

### Advanced Planning
- [ ] 3D visualization
- [ ] AR mobile app
- [ ] Drone/satellite imagery analysis
- [ ] IoT sensor integration
- [ ] Automated irrigation control

### Platform Expansion
- [ ] Mobile native apps (iOS/Android)
- [ ] Desktop application
- [ ] Public API for third-party integrations
- [ ] Marketplace for plant palettes
- [ ] Community design templates

---

## Technical Debt

### Infrastructure
- [ ] Implement proper logging (ELK/Graylog)
- [ ] Distributed tracing setup
- [ ] Feature flags system
- [ ] Configuration management
- [ ] Secrets rotation

### Code Quality
- [ ] API rate limiting
- [ ] Request/response caching
- [ ] Database query optimization
- [ ] Unit test coverage targets
- [ ] Integration test suite

### Documentation
- [x] Architecture documentation
- [x] API reference
- [x] Database schema docs
- [ ] Deployment runbook
- [ ] User guides

---

## Deprecations & Migrations

| Item | Migration Path | Target Phase |
|------|----------------|-------------|
| Auth.js | Authentik OIDC | Phase 2 |
| In-memory Y.js | PostgreSQL persistence | Phase 1 complete |
| MinIO local | AWS S3/GCS | Phase 2 |
| Single-tenant | Multi-tenant | Phase 3 |
| Basic scheduling | Cron + workflow engine | Phase 2 |

---

## Release Cadence

- **MVP**: Single stable release
- **Phase 2**: Monthly releases with feature flags
- **Phase 3**: Weekly releases for beta features


---

## Contribution Priorities

1. **High Priority** (MVP blockers):
   - Estimate builder completion
   - Design canvas integration
   - Auth flow testing

2. **Medium Priority** (Enhanced UX):
   - Plant data import
   - Image gallery UI
   - PDF export

3. **Lower Priority** (Nice to have):
   - Advanced reporting
   - Mobile optimization
   - Third-party integrations
