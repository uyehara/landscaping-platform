# Deployment Guide

## Overview

This guide covers deploying the Landscaping Platform in various environments.


## Quick Deployment (Docker Compose)

### Prerequisites
- Docker 24.0+
- Docker Compose 2.0+
- 4GB RAM minimum
- 20GB disk space

### Steps

```bash
# Clone and navigate
git clone https://github.com/uyehara/landscaping-platform.git
cd landscaping-platform

# Configure environment
cp .env.example .env
# Edit .env with production values

# Start services
docker-compose up -d

# Verify
docker-compose ps
```

---


## Environment Configuration

### Required Variables

```bash
# Database
POSTGRES_USER=landscape
POSTGRES_PASSWORD=<strong-password>
POSTGRES_DB=landscaping

# Storage
MINIO_ROOT_USER=<minio-user>
MINIO_ROOT_PASSWORD=<minio-password>

# Security
JWT_SECRET=<64-char-random-string>
```

### Production Recommendations

```bash
# Use strong, unique passwords
openssl rand -base64 32

# Enable HTTPS (reverse proxy required)
# Set CORS_ORIGIN to your domain
CORS_ORIGIN=https://your-domain.com

# Configure external services
DATABASE_URL=postgres://user:pass@external-db:5432/landscaping
MINIO_ENDPOINT=s3.amazonaws.com
```

---

## Docker Compose Configuration

### Service Definitions

```yaml
# Scale API gateway for load
api-gateway:
  deploy:
    replicas: 2
  restart: unless-stopped

# Scale frontend for load  
frontend:
  deploy:
    replicas: 2
  restart: unless-stopped
```


### Production Override

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  postgres:
    restart: unless-stopped
    volumes:
      - postgres_prod:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}


  api-gateway:
    restart: unless-stopped
    deploy:
      replicas: 2
    
  frontend:
    restart: unless-stopped
    deploy:
      replicas: 2
```


Apply:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Reverse Proxy (Production)

### Nginx Configuration

```nginx
server {
    listen 443 ssl;
    server_name landscaping.example.com;


    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    # Frontend
    location / {
        proxy_pass http://localhost:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # API Gateway
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }


    # WebSocket for Collaboration
    location /collaboration/ {
        proxy_pass http://localhost:1234/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```


### Traefik Configuration (Alternative)

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.landscaping.rule=Host(`landscaping.example.com`)"
  - "traefik.http.routers.landscaping.tls=true"
  - "traefik.http.services.landscaping.loadbalancer.server.port=5173"
```

---


## Database Migration

### Running Migrations

```bash
# Connect to database
docker-compose exec postgres psql -U landscape -d landscaping

# Run migrations manually
docker-compose exec -T postgres psql -U landscape -d landscaping < migrations/001_new_table.sql
```

### Backup Before Migration

```bash
# Create backup
docker-compose exec postgres pg_dump -U landscape landscaping > backup_$(date +%Y%m%d).sql
```


---

## Health Checks

### Verify All Services

```bash
#!/bin/bash
echo "Checking services..."

# API Gateway
curl -f http://localhost:3001/health || exit 1


# Frontend
curl -f http://localhost:5173 || exit 1

# MinIO
echo "Checking MinIO..."
docker-compose exec minio-setup mc ready local || exit 1

echo "All services healthy"
```


---


## Rolling Updates

```bash
# Pull latest images
docker-compose pull

# Rolling update (zero downtime)
docker-compose up -d --no-deps --build api-gateway
docker-compose up -d --no-deps --build frontend
```

---


## Cleanup

```bash
# Remove unused images
docker-compose rm -s
docker image prune -f

# Remove volumes (WARNING: deletes data!)
docker-compose down -v
```

---


## Kubernetes Deployment

### Helm Chart Structure (Future)

```yaml
# values.yaml
replicaCount: 2

image:
  repository: landscaping
  tag: latest


service:
  type: ClusterIP

env:
  DATABASE_URL: {{ .Values.database.url }}
  JWT_SECRET: {{ .Values.secrets.jwt }}

persistence:
  enabled: true
  size: 50Gi
```

### Resource Requirements

| Service | CPU | Memory |
|---------|-----|--------|
| postgres | 1 core | 2GB |
| minio | 0.5 core | 1GB |
| api-gateway | 1 core | 512MB |
| frontend | 0.5 core | 256MB |
| ai-service | 2 cores | 4GB |
| collaboration | 1 core | 1GB |
