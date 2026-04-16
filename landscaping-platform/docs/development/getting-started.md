# Getting Started

## Prerequisites

Before setting up the Landscaping Platform, ensure you have:

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Docker** | 24.0+ | Required for all services |
| **Docker Compose** | 2.0+ | Included with Docker Desktop |
| **Git** | 2.0+ | For cloning the repository |
| **Node.js** | 20+ | For local frontend development (optional) |
| **Python** | 3.11+ | For local AI service development (optional) |

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/uyehara/landscaping-platform.git
cd landscaping-platform
```


### 2. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

### 3. Start Services

Launch all services with Docker Compose:

```bash
docker-compose up -d
```

### 4. Verify Health

Check that all services are healthy:

```bash
docker-compose ps
```

Expected output:

| Service | Status | Port |
|---------|--------|------|
| landscaping-postgres | healthy | 5432 |
| landscaping-minio | healthy | 9000/9001 |
| landscaping-api-gateway | running | 3001 |
| landscaping-frontend | running | 5173 |
| landscaping-ai-service | running | 8000 |
| landscaping-collaboration | running | 1234 |

### 5. Access the Application

Open your browser to:

| URL | Service |
|-----|---------|
| http://localhost:5173 | Frontend (SvelteKit) |
| http://localhost:9001 | MinIO Console |
| http://localhost:3001/health | API Health Check |

## Environment Variables

### Required Variables

```bash
# Database
POSTGRES_USER=landscape
POSTGRES_PASSWORD=postgres
POSTGRES_DB=landscaping

# MinIO Storage
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin

# Security
JWT_SECRET=your-secret-key-change-in-production
```

### Optional Variables

```bash
# AI Service (required for AI features)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# API Gateway
CORS_ORIGIN=http://localhost:5173
API_GATEWAY_PORT=3001

# Logging
LOG_LEVEL=INFO
```

## Initial Data

The database is automatically initialized with:

- **Extensions**: uuid-ossp, vector
- **Enums**: All custom types (customer_type, project_status, etc.)
- **Tables**: All schema tables with relationships
- **Seed Data**: Default roles and permissions

### Default Users

| Role | Email | Password |
|------|-------|----------|
| admin | admin@example.com | (set during first login) |


## Common First Steps

### 1. Create Your First Customer

```bash
curl -X POST http://localhost:3001/customers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "name": "Acme Landscaping",
    "customer_type": "commercial",
    "email": "contact@acme.com"
  }'
```

### 2. Upload Plant Images

1. Navigate to http://localhost:9001 (MinIO Console)
2. Login with credentials from .env
3. Upload images to `landscaping-assets` bucket
4. Create media records via API

### 3. Generate Plant Embeddings

```bash
curl -X POST http://localhost:8000/embeddings/batch \
  -H "Content-Type: application/json" \
  -d '{"entity_type": "plant_species", "limit": 100}'
```

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker-compose logs postgres
docker-compose logs minio

# Verify ports are available
lsof -i :5432
lsof -i :5173
```

### Database Connection Issues

```bash
# Test database connection
docker-compose exec postgres psql -U landscape -d landscaping -c "SELECT 1"

# Check connection string
docker-compose config | grep DATABASE_URL
```

### MinIO Bucket Not Created

```bash
# Manually create bucket
docker-compose exec minio-setup mc mb local/landscaping-assets
```

## Next Steps

- Read [Local Development Setup](./local-setup.md) for IDE configuration
- Review [API Reference](../reference/api.md) for endpoint documentation
- See [Contributing Guide](./contributing.md) for code standards

## Development vs Production

| Setting | Development | Production |
|---------|-------------|------------|
| Database | Docker volume | Managed (RDS) |
| Storage | MinIO local | AWS S3/GCS |
| AI Service | Local | Kubernetes |
| Collaboration | In-memory | PostgreSQL |
| Scaling | Single instance | Multi-instance |
| SSL/TLS | HTTP only | HTTPS required |
