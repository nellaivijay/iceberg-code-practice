# Troubleshooting Guide

This guide helps you solve common issues when working with the Apache Iceberg Practice Environment.

## Setup Issues

### Issue: Docker containers won't start

**Symptoms:**
- `docker-compose up` fails
- Containers stuck in "Restarting" state
- Port binding errors

**Solutions:**
```bash
# Check Docker is running
docker ps

# Check for port conflicts
netstat -tuln | grep -E '8080|8081|9000'

# Check available disk space
df -h

# Check Docker logs
docker-compose logs

# Restart Docker
sudo systemctl restart docker

# Try with increased timeout
DOCKER_COMPOSE_TIMEOUT=300 docker-compose up -d
```

### Issue: k3s pods stuck in Pending state

**Symptoms:**
- `kubectl get pods` shows Pending status
- Pods never reach Running state
- Image pull errors

**Solutions:**
```bash
# Check pod status and events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes
kubectl describe node

# Check for resource limits
kubectl get nodes -o yaml | grep -A 5 resources

# Pull images manually
docker pull <image-name>

# Check k3s status
systemctl status k3s

# Restart k3s
sudo systemctl restart k3s
```

### Issue: Out of memory errors

**Symptoms:**
- OOMKilled errors
- Containers crash
- System becomes unresponsive

**Solutions:**
```bash
# Check memory usage
free -h
docker stats

# Reduce memory limits in docker-compose.yaml
# Example:
#  mem_limit: 4g  # Change from 8g

# Increase swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Stop unused services
docker-compose stop <service-name>

# Use Docker Compose instead of k3s for lighter footprint
```

### Issue: Storage backend connection errors

**Symptoms:**
- Connection refused to storage service
- S3 API errors
- Catalog connection failures

**Solutions:**
```bash
# Check storage service is running
docker-compose ps objectscale
# or
kubectl get pods | grep storage

# Check storage logs
docker-compose logs objectscale
# or
kubectl logs <storage-pod>

# Verify environment variables
env | grep STORAGE
env | grep S3

# Test connectivity
curl -v http://localhost:9000/minio/health/live

# Check credentials
# Verify access key and secret key are correct
```

## Lab Execution Issues

### Issue: Spark SQL commands fail

**Symptoms:**
- AnalysisException errors
- Table not found errors
- Permission denied errors

**Solutions:**
```sql
-- Check catalog is configured
SHOW CATALOGS;

-- Check database exists
SHOW DATABASES;

-- Check table exists
SHOW TABLES IN sample_db;

-- Verify table schema
DESCRIBE sample_db.sample_customers;

-- Check permissions
-- Ensure you have access to the catalog and database
```

### Issue: Jupyter notebook won't connect

**Symptoms:**
- Connection refused errors
- Kernel won't start
- Notebook hangs

**Solutions:**
```bash
# Check Jupyter is running
docker-compose ps jupyter

# Check Jupyter logs
docker-compose logs jupyter

# Restart Jupyter
docker-compose restart jupyter

# Access Jupyter logs
docker-compose logs -f jupyter

# Try accessing directly
open http://localhost:8888
```

### Issue: Sample data loading fails

**Symptoms:**
- Script execution errors
- Data not appearing in tables
- Permission errors

**Solutions:**
```bash
# Check script permissions
chmod +x scripts/load_sample_data.sh

# Run script with verbose output
bash -x scripts/load_sample_data.sh

# Check sample data generation
python3 scripts/generate_sample_data.py --verbose

# Verify data files exist
ls -la data/

# Check Spark connectivity
docker-compose exec spark spark-sql
```

### Issue: Trino queries fail

**Symptoms:**
- Query timeout errors
- Catalog not found errors
- Connection refused

**Solutions:**
```bash
# Check Trino is running
docker-compose ps trino

# Check Trino logs
docker-compose logs trino

# Test Trino CLI
docker-compose exec trino trino --catalog iceberg --schema sample_db

# Verify catalog configuration
# Check etc/catalog/iceberg.properties

# Check Iceberg catalog connectivity
# Ensure catalog service is running
```

## Performance Issues

### Issue: Queries run very slowly

**Symptoms:**
- Queries take >10 minutes
- High CPU/memory usage
- Cluster appears stuck

**Solutions:**
```python
# Check query plan
df.explain()

# Use caching for repeated queries
df.cache()
df.count()  # Materialize cache

# Add filters early
df.filter(col("date") >= "2026-01-01").groupBy(...)

# Check partitioning strategy
# Ensure queries use partition filters

# Reduce data size for testing
df.limit(1000).show()

# Use appropriate file sizes
# Compact small files
```

### Issue: Too many small files

**Symptoms:**
- Slow query performance
- High metadata overhead
- Storage inefficiency

**Solutions:**
```sql
-- Compact small files
CALL catalog.system.rewrite_data_files('catalog.db.table');

-- Set appropriate file size
ALTER TABLE catalog.db.table SET TBLPROPERTIES (
    'write.target-file-size-bytes' = '134217728'  -- 128MB
);

-- Use batch writes instead of streaming small batches
```

### Issue: Memory pressure during operations

**Symptoms:**
- OOM errors
- Container crashes
- System slowdown

**Solutions:**
```python
# Increase executor memory
spark.conf.set("spark.executor.memory", "8g")

# Use broadcast joins for small tables
from pyspark.sql.functions import broadcast
df1.join(broadcast(df2), "key")

# Reduce shuffle partitions
spark.conf.set("spark.sql.shuffle.partitions", "4")

# Use sampling for testing
df.sample(fraction=0.1)
```

## Data Quality Issues

### Issue: Null values causing errors

**Symptoms:**
- Results contain unexpected nulls
- Aggregations return null
- Joins produce unexpected results

**Solutions:**
```sql
-- Check for nulls
SELECT COUNT(*) FROM table WHERE column IS NULL;

-- Handle nulls explicitly
SELECT COALESCE(column, 'default') FROM table;

-- Filter nulls
SELECT * FROM table WHERE column IS NOT NULL;

-- Use appropriate join types
-- INNER vs LEFT vs FULL
```

### Issue: Duplicate records

**Symptoms:**
- Count higher than expected
- Duplicate rows in results
- Incorrect aggregations

**Solutions:**
```sql
-- Check for duplicates
SELECT id, COUNT(*) 
FROM table 
GROUP BY id 
HAVING COUNT(*) > 1;

-- Remove duplicates
SELECT DISTINCT * FROM table;

-- Use primary keys
-- Ensure tables have appropriate constraints
```

### Issue: Schema mismatch errors

**Symptoms:**
```
AnalysisException: Column 'name' is not compatible
```

**Solutions:**
```sql
-- Check schema
DESCRIBE table;

-- Use schema evolution
ALTER TABLE table ADD COLUMN new_column STRING;

-- Cast columns to correct types
SELECT CAST(column AS INT) FROM table;

-- Use mergeSchema option
df.write.option("mergeSchema", "true").mode("append").save()
```

## Streaming Issues

### Issue: Kafka consumer fails

**Symptoms:**
- Consumer won't start
- No messages received
- Offset errors

**Solutions:**
```bash
# Check Kafka is running
docker-compose ps kafka

# Check Kafka logs
docker-compose logs kafka

# List topics
docker-compose exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Test producer/consumer
docker-compose exec kafka kafka-console-producer --topic test --bootstrap-server localhost:9092
docker-compose exec kafka kafka-console-consumer --topic test --bootstrap-server localhost:9092 --from-beginning
```

### Issue: Debezium connector fails

**Symptoms:**
- Connector status shows failed
- No CDC events
- Database connection errors

**Solutions:**
```bash
# Check connector status
curl -X GET http://localhost:8083/connectors/

# Check connector logs
docker-compose logs debezium

# Verify MySQL is running
docker-compose ps mysql

# Test MySQL connectivity
docker-compose exec mysql mysql -u root -p

# Check connector configuration
curl -X GET http://localhost:8083/connectors/<connector-name>/config
```

### Issue: Streaming query fails

**Symptoms:**
- Streaming job fails
- Checkpoint errors
- Schema evolution issues

**Solutions:**
```python
# Check checkpoint location
# Ensure it exists and is accessible

# Handle schema evolution
stream.writeStream \
    .option("mergeSchema", "true") \
    .toTable("catalog.db.table")

# Use outputMode appropriately
# "append" for new records only
# "complete" for full output
# "update" for updated records

# Monitor streaming query
query.status()
query.lastProgress()
```

## Multi-Engine Issues

### Issue: Schema inconsistency across engines

**Symptoms:**
- Different results in Spark vs Trino
- Type conversion errors
- Column name mismatches

**Solutions:**
```sql
-- Verify schema in each engine
-- Spark: DESCRIBE table
-- Trino: DESCRIBE table
-- DuckDB: DESCRIBE table

-- Use Iceberg schema evolution
-- All engines see the same schema

-- Test data types across engines
-- Some types may have different representations
```

### Issue: Performance varies by engine

**Symptoms:**
- Fast in Spark, slow in Trino
- Different execution plans
- Resource utilization differences

**Solutions:**
```python
# Understand engine strengths
# Spark: ETL, batch processing
# Trino: Interactive queries
# DuckDB: Local analytics

# Use appropriate engine for workload
# Don't force one engine for everything

# Optimize per engine
# Each has different optimization techniques
```

## Getting Help

### Before Asking for Help

1. **Check this guide**: Look for similar issues
2. **Review solution notebooks**: Check the solutions folder
3. **Search error messages**: Google exact error text
4. **Simplify the problem**: Isolate the failing code
5. **Reproduce consistently**: Note steps to reproduce

### When to Open an Issue

Open a GitHub issue if:
- You've tried all solutions in this guide
- The issue seems to be a bug in the lab
- You found an error in the lab documentation
- You have a suggestion for improvement

### What to Include in Issue

When reporting issues, include:
1. **Error message**: Full error text
2. **Lab name**: Which lab you're working on
3. **Steps to reproduce**: What you did before the error
4. **Expected vs actual**: What you expected vs what happened
5. **Environment**: Docker Compose or k3s, OS, resources
6. **Code snippet**: Minimal reproducible example

### Additional Resources

- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Trino Documentation](https://trino.io/docs/current/)
- [DuckDB Documentation](https://duckdb.org/docs/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/apache-iceberg)
- [Iceberg Community Slack](https://apache-iceberg.slack.com/)
- Open an issue on GitHub for project-specific help

## Common Error Messages

### "Table not found"
→ Run Lab 0 to load sample data, verify catalog/database

### "Connection refused"
→ Check service is running, verify ports, check firewall

### "OutOfMemoryError"
→ Increase memory limits, reduce data size, use caching

### "AnalysisException"
→ Check SQL syntax, verify table/column names exist

### "Permission denied"
→ Check user permissions, verify catalog configuration

### "Schema mismatch"
→ Use schema evolution, cast types, check table schema

---

**Still stuck?** [Open an issue on GitHub](https://github.com/nellaivijay/iceberg-code-practice/issues) and we'll help you out! 🆘