# Local Development Setup

## IDE Configuration

### VS Code

Recommended extensions:
```json
{
  "recommendations": [
    "svelte.svelte-vscode",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-python.python",
    "charliermarsh.ruff",
    "mtxs.sqltools",
    "mtxs.sqltools-postgresql"
  ]
}
```

Recommended settings (`.vscode/settings.json`):
```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "svelte.plugin.enable-ts-plugin": true,
  "python.linting.ruffEnabled": true,
  "sqltools.format.onComma": true
}
```

### JetBrains IDEs

- **WebStorm**: SvelteKit support included
- **DataGrip**: PostgreSQL database tool
- **PyCharm**: Python AI service development


## Running Services Locally

### Option A: Full Docker (Recommended)

All services run in Docker, frontend code mounted for hot-reload:

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f api-gateway

# Restart specific service
docker-compose restart frontend
```

### Option B: Hybrid (Frontend Native)

Frontend runs natively with hot-reload, backend in Docker:

```bash
# Start backend services only
docker-compose up -d postgres minio api-gateway ai-service collaboration

# Frontend setup
cd packages/frontend
npm install
npm run dev
```

### Option C: Full Native

All services run natively for debugging:

#### PostgreSQL
```bash
# Install PostgreSQL 16
brew install postgresql@16

# Create database
createdb landscaping

# Enable extensions
psql landscaping -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
psql landscaping -c "CREATE EXTENSION IF NOT EXISTS \"vector\";"


# Run schema
psql landscaping -f postgres/init-scripts/01-init.sql
```

#### MinIO
```bash
# Download and run MinIO
docker run -p 9000:9000 -p 9001:9001 \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  minio/minio server /data --console-address ":9001"
```

#### API Gateway
```bash
cd packages/api-gateway
npm install
npm run dev
```

#### Frontend
```bash
cd packages/frontend
npm install
npm run dev
```

#### AI Service
```bash
cd packages/ai-service
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn src.main:app --reload
```

#### Collaboration
```bash
cd packages/collaboration
npm install
npx tsx src/index.ts
```


## Database Access

### Direct Connection

```bash
# Docker exec
docker-compose exec postgres psql -U landscape -d landscaping

# Local psql
psql -h localhost -U landscape -d landscaping
```

### SQLTools (VS Code)

Connection configuration:
```json
{
  "sqltools": {
    "connections": [
      {
        "name": "Landscaping Local",
        "driver": "PostgreSQL",
        "connectionDetails": {
          "host": "localhost",
          "port": 5432,
          "database": "landscaping",
          "username": "landscape",
          "password": "postgres"
        }
      }
    ]
  }
}
```

### Useful Queries

```sql
-- List all tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- List roles and permissions
SELECT r.name as role, p.resource, p.action 
FROM roles r
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON p.id = rp.permission_id
ORDER BY r.name, p.resource;

-- Check vector embeddings exist
SELECT COUNT(*) as total, 
       SUM(CASE WHEN embedding IS NOT NULL THEN 1 ELSE 0 END) as embedded
FROM plant_species;

-- Find similar plants using vector search
SELECT id, common_name, scientific_name,
       1 - (embedding <=> '[0.1, 0.2, ...]'::vector) as similarity
FROM plant_species
WHERE embedding IS NOT NULL
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 10;
```


## Testing

### API Gateway Tests

```bash
cd packages/api-gateway
npm test

# With coverage
npm run test:coverage

# Watch mode
npm run test:watch
```

### Frontend Tests

```bash
cd packages/frontend
npm test

# Visual regression (if enabled)
npm run test:visual
```

### AI Service Tests

```bash
cd packages/ai-service
pytest

# Specific test file
pytest tests/test_embeddings.py -v

# With coverage
pytest --cov=src --cov-report=html
```

### Integration Tests

```bash
# Run full stack integration tests
./scripts/integration-tests.sh
```


## Debugging

### API Gateway (Node.js)

```javascript
// Add breakpoint in route handler
routes/projects.ts
import fastify from 'fastify';

// Debug logging
fastify.addHook('onRequest', async (request) => {
  console.log('Request:', request.method, request.url);
});
```

### AI Service (Python)

```python
# Add breakpoint
import pdb; pdb.set_trace()

# Debug logging
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Database Queries

```sql
-- Enable query logging
ALTER DATABASE landscaping SET log_statement = 'all';

-- Check slow queries
SELECT query, calls, mean_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```


## Hot Reload Configuration

### Frontend (SvelteKit)

The frontend container mounts the source directory for hot-reload:
```yaml
volumes:
  - ./packages/frontend:/app
  - /app/node_modules
```

### API Gateway

For development, you can mount source:
```yaml
api-gateway:
  volumes:
    - ./packages/api-gateway:/app
    - /app/node_modules
  command: npm run dev
```


## Environment-Specific Configuration

### Development (.env)

```bash
NODE_ENV=development
DATABASE_URL=postgres://landscape:postgres@localhost:5432/landscaping
MINIO_ENDPOINT=localhost:9000
JWT_SECRET=dev-secret-key
LOG_LEVEL=DEBUG
```


### Test

```bash
NODE_ENV=test
DATABASE_URL=postgres://landscape:postgres@localhost:5432/landscaping_test
JWT_SECRET=test-secret
```

### Production

```bash
NODE_ENV=production
DATABASE_URL=postgres://user:password@rds.amazonaws.com:5432/landscaping
MINIO_ENDPOINT=s3.amazonaws.com
JWT_SECRET=<from-secrets-manager>
LOG_LEVEL=INFO
```


## Common Issues

### Port Conflicts

```bash
# Check what's using a port
lsof -i :5173
lsof -i :3001

# Kill process
kill -9 <PID>
```

### Node Module Issues

```bash
# Clean install
cd packages/frontend
rm -rf node_modules package-lock.json
npm install
```

### Database Migrations

If schema changes are needed:
```bash
# Reset database (development only!)
docker-compose down -v
docker-compose up -d
```
