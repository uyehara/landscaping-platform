# Troubleshooting

## Common Issues

### Services Won't Start

**Symptoms:** Containers exit immediately or fail health checks.

**Diagnosis:**
```bash
# Check container status
docker-compose ps

# View logs for specific service
docker-compose logs postgres
docker-compose logs minio
```


**Solutions:**


1. **Port conflicts:**
```bash
# Check what's using the port
lsof -i :5432
lsof -i :5173

# Kill conflicting process or change port in docker-compose.yml
```

2. **Volume permissions:**
```bash
# Reset volumes
docker-compose down -v
docker-compose up -d
```

3. **Database not ready:**
```bash
# Wait for postgres to be ready
docker-compose exec postgres pg_isready -U landscape
```

---

### Database Connection Issues

**Symptoms:** API returns 500, "Connection refused" in logs.

**Diagnosis:**
```bash
# Test connection
docker-compose exec api-gateway wget -qO- http://localhost:3001/health

# Check DATABASE_URL
docker-compose exec api-gateway printenv DATABASE_URL
```

**Solutions:**

1. **Wrong connection string:**
```bash
# Verify DATABASE_URL format
# Should be: postgres://user:password@host:port/database
```

2. **Database not initialized:**
```bash
# Check if tables exist
docker-compose exec postgres psql -U landscape -d landscaping -c "\dt"

# Re-initialize if needed
docker-compose down -v
docker-compose up -d
```

---

### MinIO Bucket Not Created

**Symptoms:** Upload fails, "Bucket does not exist" errors.

**Diagnosis:**
```bash
# Check minio-setup logs
docker-compose logs minio-setup

# List buckets
docker-compose exec minio-setup mc ls local/
```

**Solutions:**

1. **Manual bucket creation:**
```bash
docker-compose exec minio-setup mc mb local/landscaping-assets
```

2. **MinIO not healthy:**
```bash
# Check MinIO health
docker-compose exec minio-setup mc ready local
```

---

### Frontend Hot Reload Not Working

**Symptoms:** Changes don't reflect in browser.

**Solutions:**

1. **Clear cache:**
```bash
# Ctrl+Shift+R (hard refresh)
# Or clear browser cache
```

2. **Restart container:**
```bash
docker-compose restart frontend
```

3. **Check volume mount:**
```bash
docker inspect landscaping-frontend | grep -A 5 Mounts
```

---

### API Authentication Issues

**Symptoms:** 401 Unauthorized on protected routes.

**Solutions:**

1. **Check JWT_SECRET matches:**
```bash
# Compare between services
docker-compose exec frontend printenv JWT_SECRET
docker-compose exec api-gateway printenv JWT_SECRET
```

2. **Token expired:**
```bash
# Clear session and login again
# Delete localStorage/sessionStorage in browser dev tools
```

---

### Slow Vector Search

**Symptoms:** Similar plant/style search is slow.

**Solutions:**

1. **Rebuild HNSW index:**
```sql
-- In PostgreSQL
DROP INDEX IF EXISTS idx_plant_species_embedding;
CREATE INDEX idx_plant_species_embedding 
ON plant_species USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

2. **Check index exists:**
```sql
SELECT indexname FROM pg_indexes WHERE tablename = 'plant_species';
```

---

### Collaboration Server Issues

**Symptoms:** Real-time sync not working, "Connection closed" errors.

**Solutions:**

1. **Restart collaboration service:**
```bash
docker-compose restart collaboration
```

2. **Check WebSocket connection:**
```bash
# Test WebSocket manually
wscat -c ws://localhost:1234
```

3. **Verify JWT validation:**
```bash
docker-compose logs collaboration | grep -i jwt
```

---

### Media Processing Failures

**Symptoms:** Images uploaded but no thumbnails/descriptions.

**Solutions:**

1. **Check processing log:**
```sql
SELECT * FROM media_processing_log 
WHERE status = 'failed' 
ORDER BY created_at DESC 
LIMIT 10;
```

2. **Manual reprocess:**
```bash
# Via API
curl -X POST http://localhost:3001/media/{media_id}/process \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"workflows": ["thumbnail", "ai_description"]}'
```

---

### Docker Disk Space

**Symptoms:** "No space left on device" errors.


**Solutions:**

```bash
# Clean unused images
docker image prune -a

# Clean volumes (WARNING: deletes data!)
docker-compose down -v
docker volume prune

# Remove all stopped containers
docker container prune
```

---

## Debug Commands

### Full System Check

```bash
#!/bin/bash
echo "=== Service Status ==="
docker-compose ps

echo "=== Health Checks ==="
curl -sf http://localhost:3001/health && echo " API: OK"
curl -sf http://localhost:5173 && echo " Frontend: OK"

echo "=== Database ==="
docker-compose exec -T postgres psql -U landscape -d landscaping -c "SELECT count(*) as tables FROM information_schema.tables WHERE table_schema='public';"

echo "=== MinIO ==="
docker-compose exec -T minio-setup mc ls local/ 2>/dev/null || echo "MinIO not accessible"

echo "=== Recent Logs ==="
docker-compose logs --tail=20 api-gateway | tail -5
```

### Network Diagnostics

```bash
# Check Docker network
docker network inspect landscaping-platform_landscaping-net

# Test internal connectivity
docker-compose exec api-gateway ping -c 1 postgres
docker-compose exec api-gateway ping -c 1 minio
```

---

## Getting Help

If issues persist:

1. **Collect diagnostics:**
```bash
docker-compose logs > diagnostics_$(date +%Y%m%d).log
```

2. **Check GitHub issues** for similar problems
3. **Create new issue** with logs and environment details
