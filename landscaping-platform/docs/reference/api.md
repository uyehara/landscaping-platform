# API Reference

## Overview

The API Gateway exposes RESTful endpoints for all platform functionality.

**Base URL:** `http://localhost:3001`

**Authentication:** Bearer token (JWT)

## Authentication

### POST /auth/login

Authenticate user and receive JWT token.


**Request:**
```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "admin"
  }
}
```

### POST /auth/register


Register new user account.


**Request:**
```json
{
  "email": "newuser@example.com",
  "password": "securepassword",
  "name": "Jane Smith"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "email": "newuser@example.com",
  "name": "Jane Smith"
}
```

### GET /auth/me

Get current user info.

**Headers:** `Authorization: Bearer <token>`


**Response (200):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "John Doe",
  "role": {
    "id": "uuid",
    "name": "admin",
    "permissions": ["*"]
  }
}
```

---

## Customers


### GET /customers


List customers with optional filtering.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | integer | Page number (default: 1) |
| `limit` | integer | Items per page (default: 20) |
| `type` | string | Filter by customer_type |
| `search` | string | Search by name/email |


**Response (200):**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Acme Corp",
      "customer_type": "commercial",
      "email": "contact@acme.com",
      "phone": "555-0100",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "total_pages": 3
  }
}
```

### GET /customers/:id


Get customer by ID.


**Response (200):**
```json
{
  "id": "uuid",
  "name": "Acme Corp",
  "customer_type": "commercial",
  "email": "contact@acme.com",
  "phone": "555-0100",
  "correspondence_address": "123 Main St",
  "correspondence_city": "Austin",
  "correspondence_state": "TX",
  "correspondence_zip": "78701",
  "properties": [...],
  "contracts": [...]
}
```

### POST /customers

Create new customer.

**Request:**
```json
{
  "name": "New Customer",
  "customer_type": "residential",
  "email": "customer@email.com",
  "phone": "555-1234",
  "correspondence_address": "456 Oak Ave",
  "correspondence_city": "Austin",
  "correspondence_state": "TX",
  "correspondence_zip": "78702"
}
```

### PATCH /customers/:id


Update customer.


### DELETE /customers/:id

Delete customer (cascades to properties).

---


## Properties


### GET /properties


**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `customer_id` | uuid | Filter by customer |
| `zone` | string | Hardiness zone |

### GET /properties/:id

### POST /properties

**Request:**
```json
{
  "customer_id": "uuid",
  "name": "Main Campus",
  "address": "789 Business Park Dr",
  "city": "Austin",
  "state": "TX",
  "zip": "78703",
  "coordinates": {"lat": 30.2672, "lng": -97.7431},
  "lot_size": 50000,
  "zone": "8b"
}
```

### PATCH /properties/:id
### DELETE /properties/:id

---


## Projects

### GET /projects

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | draft, active, completed, archived, cancelled |
| `owner_id` | uuid | Filter by owner |
| `property_id` | uuid | Filter by property |


### GET /projects/:id

### POST /projects

**Request:**
```json
{
  "name": "Front Yard Redesign",
  "description": "Complete landscape renovation",
  "owner_id": "uuid"
}
```


**Response (201):**
```json
{
  "id": "uuid",
  "name": "Front Yard Redesign",
  "status": "draft",
  "owner_id": "uuid",
  "created_at": "2024-01-20T14:00:00Z"
}
```


### PATCH /projects/:id

Update project status, details, or link properties:

```json
{
  "status": "active",
  "properties": ["uuid1", "uuid2"]
}
```

### DELETE /projects/:id

---


## Phases


### GET /projects/:projectId/phases


### POST /projects/:projectId/phases


```json
{
  "name": "Site Preparation",
  "sort_order": 1,
  "target_start_date": "2024-03-01",
  "target_end_date": "2024-03-15"
}
```

### PATCH /phases/:id

### DELETE /phases/:id


---

## Jobs

### GET /jobs

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `phase_id` | uuid | Filter by phase |
| `status` | string | pending, in_progress, completed |
| `assigned_to` | uuid | Filter by assignee |


### GET /jobs/:id

### POST /jobs

```json
{
  "phase_id": "uuid",
  "name": "Install Irrigation",
  "description": "Drip irrigation system",
  "assigned_to": "uuid",
  "scheduled_start": "2024-04-01",
  "scheduled_end": "2024-04-05"
}
```


### PATCH /jobs/:id

Update status, assignment, or dates:

```json
{
  "status": "in_progress",
  "actual_start": "2024-04-01"
}
```


---

## Contracts

### GET /contracts

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `customer_id` | uuid | Filter by customer |
| `status` | string | draft, active, expired, cancelled |

### GET /contracts/:id

### POST /contracts

```json
{
  "customer_id": "uuid",
  "name": "Annual Maintenance Contract",
  "description": "Year-round grounds maintenance",
  "billing_frequency": "monthly",
  "term_start": "2024-01-01",
  "term_end": "2024-12-31",
  "specifications": {"mowing": true, "trimming": true}
}
```


### PATCH /contracts/:id


---

## Recurring Schedules

### GET /contracts/:contractId/schedules

### POST /contracts/:contractId/schedules

```json
{
  "name": "Monthly Mowing",
  "frequency": "monthly",
  "recurrence_pattern": {"interval": 1},
  "next_run_date": "2024-02-01"
}
```


### PATCH /schedules/:id


```json
{
  "status": "paused"
}
```


---


## Reference Library


### Plant Species

#### GET /library/plants

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `search` | string | Text search |
| `zone_min` | integer | Minimum hardiness zone |
| `zone_max` | integer | Maximum hardiness zone |
| `sun` | string | full_sun, partial_shade, full_shade |
| `water` | string | low, moderate, high |
| `native` | boolean | Filter native species |
| `limit` | integer | Max results (default: 20) |


**Response (200):**
```json
{
  "data": [
    {
      "id": "uuid",
      "common_name": "Texas Sage",
      "scientific_name": "Leucophyllum frutescens",
      "description": "Drought-tolerant evergreen shrub",
      "mature_height": 8,
      "mature_spread": 6,
      "zone_min": 7,
      "zone_max": 11,
      "sun_requirement": "full_sun",
      "water_requirement": "low",
      "is_native": true,
      "images": [...]
    }
  ]
}
```

#### GET /library/plants/:id

#### POST /library/plants

```json
{
  "common_name": "Creeping Oregon Grape",
  "scientific_name": "Mahonia repens",
  "description": "Low-growing native groundcover",
  "mature_height": 1,
  "mature_spread": 3,
  "zone_min": 5,
  "zone_max": 9,
  "sun_requirement": "partial_shade",
  "water_requirement": "moderate",
  "is_native": true
}
```

#### GET /library/plants/similar

Find similar plants via vector search.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Search description |
| `limit` | integer | Max results |
| `threshold` | float | Similarity threshold (0-1) |

---


### Landscaping Styles

#### GET /library/styles

#### GET /library/styles/:id


#### POST /library/styles


```json
{
  "name": "Xeriscape",
  "slug": "xeriscape",
  "design_philosophy": "Water-wise landscaping principles",
  "plant_palette_structure": "Drought-tolerant species focus",
  "tags": ["water-conservation", "native-plants"]
}
```

#### GET /library/styles/similar

Find similar styles via vector search.


---


### Plant Palettes

#### GET /library/palettes

#### GET /library/palettes/:id

#### POST /library/palettes

```json
{
  "name": "Texas Native Meadow",
  "description": "Native wildflower and grass mix"
}
```

#### POST /library/palettes/:id/categories

```json
{
  "category_name": "Structural Trees",
  "description": "Large canopy trees",
  "sort_order": 1
}
```


#### POST /library/palettes/:id/items


```json
{
  "category_id": "uuid",
  "species_id": "uuid",
  "role_description": "Primary shade provider",
  "proportion": "dominant"
}
```

---

## Media

### GET /media


**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `entity_type` | string | plant_species, style, property, etc. |
| `entity_id` | uuid | Filter by entity |

### POST /media/upload

Upload media file. Returns pre-signed URL for direct upload to MinIO.

**Request:**
```json
{
  "entity_type": "plant_species",
  "entity_id": "uuid",
  "filename": "texas-sage.jpg",
  "mime_type": "image/jpeg"
}
```

**Response (200):**
```json
{
  "upload_url": "https://minio:9000/landscaping-assets/...",
  "media_id": "uuid"
}
```

### GET /media/:id


### DELETE /media/:id

### POST /media/:id/process


Trigger AI processing (thumbnail, description, embeddings).


```json
{
  "workflows": ["thumbnail", "ai_description", "embeddings"]
}
```


---

## Estimates

### GET /estimates

### GET /estimates/:id

### POST /estimates

```json
{
  "entity_type": "project",
  "entity_id": "uuid",
  "name": "Phase 1 Estimate"
}
```

### POST /estimates/:id/items

Add line item to estimate:

```json
{
  "line_type": "plant",
  "description": "Texas Sage - 5 gallon",
  "quantity": 10,
  "unit": "gallon",
  "unit_cost": 25.00,
  "attributes": {
    "species_id": "uuid",
    "size": "5 gallon"
  }
}
```

### GET /estimates/:id/export


Export as PDF or CSV.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `format` | string | pdf, csv |


---

## Storage

### POST /storage/presign

Generate pre-signed URL for direct browser upload.

**Request:**
```json
{
  "filename": "document.pdf",
  "mime_type": "application/pdf",
  "expires_in": 3600
}
```

**Response (200):**
```json
{
  "upload_url": "https://minio:9000/...",
  "storage_key": "uploads/2024/01/document.pdf",
  "download_url": "https://minio:9000/...?X-Amz-..."
}
```


---

## Health Check

### GET /health

**Response (200):**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-20T14:00:00Z",
  "services": {
    "database": "connected",
    "storage": "connected",
    "ai_service": "connected"
  }
}
```


---

## Error Responses

All errors follow a consistent format:

```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "details": [
    {"field": "email", "message": "Invalid email format"}
  ]
}
```

### Common Status Codes

| Code | Meaning |
|------|---------|
| 400 | Bad Request - Validation error |
| 401 | Unauthorized - Missing/invalid token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 409 | Conflict - Duplicate resource |
| 500 | Internal Server Error |
