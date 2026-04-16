# Backup and Recovery

## Overview

This guide covers backup strategies and recovery procedures for the Landscaping Platform.


## Backup Types

### 1. Database Backup

#### Full Dump
```bash
# Create full database backup
docker-compose exec postgres pg_dump -U landscape -d landscaping > backup_$(date +%Y%m%d_%H%M%S).sql

# Compress for storage
gzip backup_20240120_120000.sql
```


#### Schema Only
```bash
docker-compose exec postgres pg_dump -U landscape -d landscaping --schema-only > schema_backup.sql
```


#### Custom Format (Recommended for large databases)
```bash
docker-compose exec postgres pg_dump -U landscape -d landscaping -F c -b > custom_backup.dump
```


### 2. MinIO Storage Backup

```bash
# Sync MinIO bucket to local directory
docker-compose exec minio-setup mc mirror local/landscaping-assets /backups/minio/

# Or use AWS CLI for cloud backup
aws s3 sync s3://landscaping-assets s3://landscaping-backup/
```

### 3. Volume Backup

```bash
# Backup Docker volumes
docker run --rm -v landscaping-platform_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_data.tar.gz /data
```


---

## Automated Backup Script

Create `/scripts/backup.sh`:

```bash
#!/bin/bash
set -e

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
echo "Backing up database..."
docker-compose exec -T postgres pg_dump -U landscape -d landscaping | gzip > $BACKUP_DIR/db_${DATE}.sql.gz

# MinIO backup
echo "Backing up MinIO storage..."
docker-compose exec -T minio-setup mc mirror local/landscaping-assets $BACKUP_DIR/minio_${DATE}/

# Cleanup old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -type f -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -type d -mtime +$RETENTION_DAYS -empty -delete

echo "Backup completed: $DATE"
```

### Cron Schedule

```bash
# Add to crontab
0 2 * * * /path/to/scripts/backup.sh >> /var/log/backup.log 2>&1
```

---

## Recovery Procedures

### Database Recovery

#### Point-in-Time Recovery

```bash
# Stop services
docker-compose stop api-gateway frontend ai-service


# Drop and recreate database
docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS landscaping;"
docker-compose exec postgres psql -U postgres -c "CREATE DATABASE landscaping;"

# Restore from backup
gunzip -c backup_20240120_120000.sql.gz | docker-compose exec -T postgres psql -U landscape -d landscaping


# Restart services
docker-compose start api-gateway frontend ai-service
```

#### Table-Level Recovery

```bash
# Restore specific table
docker-compose exec postgres pg_dump -U landscape -d landscaping -t plant_species > plant_species_backup.sql
# ... after table corruption ...
docker-compose exec -T postgres psql -U landscape -d landscaping < plant_species_backup.sql
```


### MinIO Recovery

```bash
# Restore single object
docker-compose exec minio-setup mc cp /backup/minio/object-key local/landscaping-assets/

# Full bucket restore
docker-compose exec minio-setup mc rm -r --force local/landscaping-assets/
docker-compose exec minio-setup mc mirror /backup/minio_latest/ local/landscaping-assets/
```


### Volume Recovery

```bash
# Stop containers using volume
docker-compose down

# Restore volume
docker run --rm -v landscaping-platform_postgres_data:/data -v $(pwd):/backup alpine tar xzf /backup/postgres_data.tar.gz -C /

# Restart
docker-compose up -d
```

---

## Disaster Recovery Plan

### RTO (Recovery Time Objective)
- Database: 1 hour
- File storage: 2 hours
- Full system: 4 hours

### RPO (Recovery Point Objective)
- Database: 24 hours (daily backups)
- File storage: 24 hours

### Recovery Steps Checklist

1. [ ] Provision new infrastructure
2. [ ] Restore PostgreSQL from latest backup
3. [ ] Restore MinIO data from backup
4. [ ] Verify service health
5. [ ] Update DNS/load balancer
6. [ ] Test critical functionality
7. [ ] Notify stakeholders

---


## Testing Backups

### Quarterly Restore Test

```bash
# Create test environment
docker-compose up -d postgres

# Restore to test database
gunzip -c latest_backup.sql.gz | docker-compose exec -T postgres psql -U landscape -d landscaping_test

# Verify data integrity
docker-compose exec postgres psql -U landscape -d landscaping_test -c "SELECT COUNT(*) FROM users;"
```


### Backup Verification

```bash
# Verify backup file exists and has content
test -s backup.sql && echo "Backup OK" || echo "Backup failed"


# Verify gzip compression
gunzip -t backup.sql.gz && echo "Compression OK" || echo "Corrupted backup"
```
