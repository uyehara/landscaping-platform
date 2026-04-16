# Data Model

## Database Overview

PostgreSQL 16 with pgvector extension for vector similarity search.


## Schema Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USERS & RBAC                                    │
│                                                                             │
│  ┌─────────┐      ┌──────────────────┐      ┌────────────────┐            │
│  │  users  │──────│      roles       │──────│  permissions   │            │
│  └─────────┘      └──────────────────┘      └────────────────┘            │
│       │                   │                         │                        │
│       │                   └─────────────────────────┤                        │
│       │                     role_permissions        │                        │
│       └─────────────────────────────────────────────┘                        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           CORE BUSINESS ENTITIES                             │
│                                                                             │
│  ┌────────────┐      ┌────────────┐                                        │
│  │ customers │──────│ properties │◄──── project_properties ────┐            │
│  └────────────┘      └────────────┘                               │            │
│       │                   │                                  ┌─────┴─────┐    │
│       │                   │                                  │ projects  │    │
│       │                   │                                  └─────┬─────┘    │
│       │                   │                                        │          │
│       │                   │                                  ┌───────┴─────┐   │
│       └───────────────────┼──────────────────────────────────│  phases    │   │
│                           │                                  └─────┬─────┘   │
│                           │                                        │         │
│                           └────────────────────────────────────┌────┴────┐   │
│                                                                │  jobs    │   │
│                                                                └─────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                          CONTRACTS & SCHEDULING                              │
│                                                                             │
│  ┌───────────┐      ┌──────────────────┐      ┌─────────────────────┐     │
│  │ contracts │──────│ recurring_       │──────│     task_orders     │     │
│  └───────────┘      │ schedules        │      │   (IDIQ templates)   │     │
│       │             └──────────────────┘      └─────────────────────┘     │
│       │                   │                                                 │
│       └───────────────────┴─────────────────────────┐                        │
│                                                     │                        │
│  ┌─────────────────┐      ┌─────────────────┐      │                        │
│  │contract_properties│    │ contract_projects│     │                        │
│  └─────────────────┘      └─────────────────┘      │                        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           REFERENCE LIBRARY                                  │
│                        (with vector embeddings)                              │
│                                                                             │
│  ┌─────────────────┐                    ┌─────────────────┐                 │
│  │landscaping_styles│◄─────────────────►│  plant_palettes │                 │
│  │   (embedding)    │   style_palettes   │                 │                 │
│  └─────────────────┘                    └────────┬────────┘                 │
│                                                 │                           │
│                                                 ▼                           │
│                                    ┌─────────────────────┐                 │
│                                    │  palette_categories │                 │
│                                    └─────────┬───────────┘                 │
│                                               │                             │
│                                    ┌──────────┴──────────┐                 │
│                                    │   palette_items     │                 │
│                                    └──────────┬──────────┘                 │
│                                               │                             │
│                                    ┌──────────┴──────────┐                 │
│                                    │  plant_species     │                 │
│                                    │    (embedding)      │                 │
│                                    └─────────────────────┘                 │
│                                                                             │
│  ┌─────────────────┐                                                       │
│  │  design_guides  │  (TipTap JSONB content)                              │
│  └─────────────────┘                                                       │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              MEDIA & STORAGE                                 │
│                                                                             │
│  ┌─────────────┐      ┌─────────────────┐      ┌──────────────────────┐   │
│  │attachments  │      │  media_files    │      │media_processing_log  │   │
│  │ (documents) │      │   (images)      │──────│  (async workflows)   │   │
│  └─────────────┘      └────────┬────────┘      └──────────────────────┘   │
│                                 │                                          │
│                                 ▼                                          │
│                          ┌─────────────┐                                    │
│                          │   MinIO     │  (S3-compatible storage)            │
│                          └─────────────┘                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                               BILLING                                        │
│                                                                             │
│  ┌───────────┐      ┌─────────────────┐      ┌─────────────────────┐       │
│  │ estimates │──────│   line_items    │      │    project_elements │       │
│  └───────────┘      │ (polymorphic)   │      │    (design canvas)  │       │
│                     └─────────────────┘      └─────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                            COLLABORATION                                     │
│                                                                             │
│  ┌─────────────────┐                                                       │
│  │  yjs_documents  │  (CRDT state - BYTEA)                                 │
│  └─────────────────┘                                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Design Patterns

### 1. Dynamic RBAC
Permissions are stored in a junction table allowing runtime role customization:
```
roles ← role_permissions → permissions
```
- Admin can create custom roles
- System roles cannot be deleted
- Permissions grouped by resource + action

### 2. Hierarchical Billing
Unified `line_items` table with polymorphic relationship:
```sql
line_items (entity_type, entity_id)
  └── entity_type: 'contract' | 'project' | 'job'
  └── entity_id: UUID of parent entity
  └── attributes JSONB for type-specific data
```

### 3. Contract as Separate Entity
Contracts exist independently from projects:
- Contract → Projects relationship (many-to-many via contract_projects)
- Supports IDIQ contracts: pre-negotiated terms with task orders instantiated on demand

### 4. Recurring Schedules
Maintenance contracts generate recurring projects:
```sql
recurring_schedules.hidden_key → links to generated projects
```

### 5. IDIQ Task Orders
Templates instantiated when customer requests specific work:
```sql
task_orders.template_id → references originating template
```

### 6. Many-to-Many Relationships
- `project_properties`: Projects can span multiple properties
- `style_palettes`: Styles can reference multiple palettes

### 7. Plant & Style Embeddings
AI similarity search via pgvector:
```sql
CREATE INDEX idx_plant_species_embedding ON plant_species USING hnsw (embedding vector_cosine_ops);
```

### 8. Design Guides
TipTap JSONB format for rich content:
```sql
design_guides.content JSONB  -- TipTap document format
```

### 9. Correspondence Address
Customer address separate from property locations:
```sql
customers.correspondence_address  -- Mailing address
properties.address               -- Site location
```

## Enumerated Types

```sql
customer_type:     'residential' | 'commercial' | 'government' | 'other'
project_status:    'draft' | 'active' | 'completed' | 'archived' | 'cancelled'
job_status:        'pending' | 'in_progress' | 'completed' | 'cancelled'
line_type:         'plant' | 'material' | 'labor' | 'equipment' | 'other'
contract_status:   'draft' | 'active' | 'expired' | 'cancelled'
schedule_status:   'active' | 'paused' | 'completed'
schedule_frequency:'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'custom'
processing_status: 'pending' | 'running' | 'completed' | 'failed'
media_entity_type: 'plant_species' | 'style' | 'palette' | 'guide' | 'property' | 'contract' | 'project' | 'job'
```

## Indexes Summary

| Table | Index | Type | Purpose |
|-------|-------|------|---------|
| properties | idx_properties_customer | B-tree | Customer lookups |
| project_properties | idx_project_properties_* | B-tree | Join optimization |
| phases | idx_phases_project | B-tree | Phase lookups |
| jobs | idx_jobs_phase, status, assigned | B-tree | Job queries |
| contracts | idx_contracts_customer, status | B-tree | Contract queries |
| plant_species | idx_plant_species_scientific, common, native, invasive | B-tree | Plant searches |
| plant_species | idx_plant_species_embedding | HNSW | Vector similarity |
| landscaping_styles | idx_landscaping_styles_slug | B-tree | Style lookups |
| landscaping_styles | idx_landscaping_styles_embedding | HNSW | Vector similarity |
| media_files | idx_media_files_entity | B-tree | Media queries |
| media_files | idx_media_files_embedding | HNSW | Image similarity |
| recurring_schedules | idx_recurring_schedules_hidden_key | B-tree (partial) | Schedule linking |
| attachments | idx_attachments_entity | B-tree | Attachment queries |
| line_items | idx_line_items_entity, type, sort | B-tree | Billing queries |
| yjs_documents | idx_yjs_documents_name | B-tree | Document lookups |

## Seed Data

### Default Roles
```sql
admin, manager, designer, field_crew, estimator, viewer, customer
```

### Default Permissions (by resource)
- **users**: read, create, update, delete
- **roles**: manage
- **customers**: read, create, update, delete
- **properties**: read, create, update, delete
- **projects**: read, create, update, delete, manage
- **contracts**: read, create, update, delete, confirm
- **reference_library**: read, curate, manage
- **estimates**: read, create, approve
- **jobs**: read, create, update, assign
- **media**: upload, delete, process
