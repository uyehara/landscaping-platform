# Monitoring

## Overview

This guide covers monitoring setup and metrics collection for the Landscaping Platform.

## Health Checks

### Service Health Endpoints

| Service | Endpoint | Expected Response |
|---------|----------|-------------------|
| API Gateway | `GET /health` | `{"status": "healthy"}` |
| AI Service | `GET /health` | `{"status": "healthy"}` |
| PostgreSQL | `pg_isready` | OK |
| MinIO | `mc ready local` | OK |

### Health Check Script

```bash
#!/bin/bash
# scripts/health-check.sh

SERVICES=(
  "API Gateway|http://localhost:3001/health"
  "Frontend|http://localhost:5173"
  "MinIO API|http://localhost:9000/minio/health/live"
)

for service in "${SERVICES[@]}"; do
  name="${service%%|*}"
  url="${service##*|}"
  
  if curl -sf "$url" > /dev/null 2>&1; then
    echo "$name: OK"
  else
    echo "$name: FAILED"
    exit 1
  fi
done
```

---

## Logging

### Container Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api-gateway
docker-compose logs -f postgres

# Last 100 lines
docker-compose logs --tail=100 ai-service
```


### Log Aggregation (Future)

For production, forward logs to a centralized system:

```yaml
# docker-compose.yml addition
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

---

## Metrics

### PostgreSQL Metrics

```sql
-- Active connections
SELECT count(*) FROM pg_stat_activity WHERE datname = 'landscaping';


-- Slow queries (> 100ms)
SELECT query, mean_time 
FROM pg_stat_statements 
WHERE mean_time > 100 
ORDER BY mean_time DESC 
LIMIT 10;


-- Table sizes
SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;

-- Index usage
SELECT indexname, idx_scan, idx_tup_read 
FROM pg_stat_user_indexes;
```

### MinIO Metrics

```bash
# Check bucket usage
docker-compose exec minio-setup mc du local/landscaping-assets

# List objects
docker-compose exec minio-setup mc ls local/landscaping-assets/

# Server info
docker-compose exec minio-setup mc info local
```


---

## Alerting

### Basic Alerting Script

Create `/scripts/alert-check.sh`:

```bash
#!/bin/bash

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
  echo "WARNING: Disk usage at ${DISK_USAGE}%"
fi

# Check memory
MEMORY=$(free -m | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')
if [ "$MEMORY" -gt 90 ]; then
  echo "WARNING: Memory usage at ${MEMORY}%"
fi

# Check database connections
DB_CONNECTIONS=$(docker-compose exec -T postgres psql -U landscape -d landscaping -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | tr -d ' ')
if [ "$DB_CONNECTIONS" -gt 80 ]; then
  echo "WARNING: Database connections at ${DB_CONNECTIONS}"
fi
```

### Cron Alerts

```bash
# Add to crontab
*/5 * * * * /path/to/scripts/alert-check.sh >> /var/log/alerts.log 2>&1
```


---

## Prometheus Metrics (Future)

For production monitoring, expose Prometheus metrics:

```yaml
# docker-compose.metrics.yml
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
```

---

## Dashboard Recommendations

### Grafana Dashboard Panels

1. **Service Health**: Green/Yellow/Red status for each service
2. **Request Rate**: Requests per second by service
3. **Error Rate**: 4xx/5xx errors over time
4. **Database Connections**: Active connections pool usage
5. **MinIO Storage**: Bucket usage over time
6. **AI Service Latency**: Processing time for embeddings

