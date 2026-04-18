# Iceberg Practice Environment - Troubleshooting Guide

## 🔧 Common Issues and Solutions

### Environment Setup Issues

#### Issue: k3s Installation Fails

**Symptoms**:
- k3s installation command hangs
- k3s service won't start
- kubectl can't connect to k3s cluster

**Solutions**:
```bash
# Try alternative installation method
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=644 sh -

# Check if k3s service is running
sudo systemctl status k3s

# Restart k3s if needed
sudo systemctl restart k3s

# Check k3s logs
sudo journalctl -u k3s -f
```

#### Issue: Docker Compose Services Won't Start

**Symptoms**:
- Services fail to start
- Containers exit immediately
- Port conflicts

**Solutions**:
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose down
docker-compose up -d

# Check for port conflicts
netstat -tulpn | grep -E '9000|8181|18080|6080'

# Remove conflicting containers
docker-compose down -v
docker-compose up -d
```

#### Issue: Storage Backend Not Accessible

**Symptoms**:
- Cannot connect to ObjectScale/MinIO
- Bucket operations fail
- Authentication errors

**Solutions**:
```bash
# For MinIO
mc alias set local http://localhost:9000 minioadmin minioadmin
mc ls local/

# For ObjectScale
aws --endpoint-url=http://localhost:6080 s3 ls

# Verify credentials
echo $MINIO_ACCESS_KEY
echo $MINIO_SECRET_KEY

# Check endpoint accessibility
curl http://localhost:9000/minio/health/live
curl http://localhost:6080/health
```

### Apache Polaris Issues

#### Issue: Polaris Health Check Fails

**Symptoms**:
- `curl http://localhost:8181/health` fails
- Polaris pod/container restarting
- Cannot connect to Polaris catalog

**Solutions**:
```bash
# Check Polaris logs (Kubernetes)
kubectl logs -n iceberg deployment/polaris

# Check Polaris logs (Docker Compose)
docker-compose logs polaris

# Restart Polaris
kubectl rollout restart deployment/polaris -n iceberg
# or
docker-compose restart polaris

# Verify storage connection
# Check if Polaris can access the storage backend
```

#### Issue: Cannot Create Tables via Polaris

**Symptoms**:
- Spark SQL CREATE TABLE fails
- REST API calls to Polaris fail
- "Catalog not found" errors

**Solutions**:
```bash
# Verify Polaris is accessible
curl -f http://localhost:8181/health

# Check Polaris catalog namespace
curl http://localhost:8181/api/catalog

# Verify Spark configuration
# Check spark.sql.catalog.iceberg.uri is correct
```

### Spark Issues

#### Issue: Spark Cannot Connect to Iceberg

**Symptoms**:
- "Catalog not found" errors
- Connection refused to Polaris
- Iceberg operations fail

**Solutions**:
```bash
# Verify Spark Iceberg configuration
spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=rest
spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog

# Check if Iceberg jars are included
--packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0

# Test connectivity from Spark shell
import requests
requests.get('http://localhost:8181/health')
```

#### Issue: Spark Event Logging Not Working

**Symptoms**:
- Spark History Server shows no jobs
- Event logs not written to S3
- "Failed to write event log" errors

**Solutions**:
```bash
# Verify S3 configuration
spark.hadoop.fs.s3a.endpoint
spark.hadoop.fs.s3a.access.key
spark.hadoop.fs.s3a.secret.key

# Check if spark-logs bucket exists
mc ls local/spark-logs/

# Verify IAM permissions
# Ensure spark-history user has read access to spark-logs bucket

# Check Spark configuration
spark.eventLog.enabled=true
spark.eventLog.dir=s3a://spark-logs/
```

#### Issue: Spark History Server Cannot Read Logs

**Symptoms**:
- Spark History Server UI shows no applications
- "Failed to load event logs" errors
- Jobs not visible in UI

**Solutions**:
```bash
# Verify History Server configuration
spark.history.fs.logDirectory=s3a://spark-logs/

# Check History Server S3 configuration
# Ensure it has correct endpoint and credentials

# Verify logs are being written
mc ls local/spark-logs/

# Check History Server logs
kubectl logs -n spark deployment/spark-history-server
# or
docker-compose logs spark-history

# Port-forward if needed
kubectl port-forward -n spark svc/spark-history-server 18080:18080
```

### Iceberg Table Issues

#### Issue: Table Creation Fails

**Symptoms**:
- CREATE TABLE command fails
- "Failed to create table" errors
- Schema validation errors

**Solutions**:
```bash
# Verify catalog is accessible
curl http://localhost:8181/api/catalog

# Check if namespace exists
curl http://localhost:8181/api/catalog/default

# Verify storage is accessible
mc ls local/iceberg-warehouse/

# Check table name doesn't conflict
# Try a different table name
```

#### Issue: Data Insert Fails

**Symptoms**:
- INSERT statements fail
- "Failed to write data" errors
- File write errors

**Solutions**:
```bash
# Verify storage write permissions
# Check if bucket is writable

# Check table schema
DESCRIBE iceberg.default.your_table

# Verify data types match schema
# Check for data type mismatches

# Check storage space
df -h  # Check disk space
mc ls local/
```

#### Issue: Partition Pruning Not Working

**Symptoms**:
- Query scans all files despite partition predicates
- Query performance is slow
- No partition pruning in explain plan

**Solutions**:
```bash
# Verify partition column types match predicate types
# Example: if partition is DATE, predicate should use DATE type

# Check explain plan
EXPLAIN EXTENDED
SELECT * FROM iceberg.default.your_table WHERE partition_column = 'value'

# Verify partition column is actually partitioned
DESCRIBE EXTENDED iceberg.default.your_table

# Ensure statistics are up to date
CALL iceberg.system.rewrite_data_files('iceberg.default.your_table')
```

### Performance Issues

#### Issue: Queries Are Slow

**Symptoms**:
- Queries take too long to execute
- High resource usage
- Spark History Server shows long job durations

**Solutions**:
```bash
# Enable query planning optimization
spark.sql.iceberg.planning.enabled=true
spark.sql.iceberg.planning.mode=distributed
spark.sql.iceberg.pushdown.enabled=true

# Check file sizes
SELECT file, file_size_in_bytes, record_count
FROM iceberg.default.your_table.files
ORDER BY file_size_in_bytes DESC

# Perform compaction
CALL iceberg.system.rewrite_data_files(
  'iceberg.default.your_table',
  map(
    'min-input-files', '5',
    'target-size-bytes', str(256 * 1024 * 1024)
  )
)

# Check for too many small files
SELECT COUNT(*) as file_count
FROM iceberg.default.your_table.files
```

#### Issue: Too Many Small Files

**Symptoms**:
- Many small files in table
- Slow query performance
- High metadata overhead

**Solutions**:
```bash
# Perform bin-packing compaction
CALL iceberg.system.rewrite_data_files(
  'iceberg.default.your_table',
  map(
    'strategy', 'bin-pack',
    'min-input-files', '10',
    'target-size-bytes', str(512 * 1024 * 1024)
  )
)

# Use coalescing when writing
df.coalesce(10).writeTo("iceberg.default.your_table").tableAppend()

# Schedule regular compaction jobs
```

### Networking Issues

#### Issue: Cannot Access Services

**Symptoms**:
- Cannot connect to Polaris (8181)
- Cannot access Spark History Server (18080)
- Cannot access MinIO (9000/9001)

**Solutions**:
```bash
# Check if services are running
docker-compose ps
# or
kubectl get pods -n iceberg

# Check port bindings
netstat -tulpn | grep -E '8181|18080|9000|9001'

# Test connectivity
curl -v http://localhost:8181/health
curl -v http://localhost:18080
curl -v http://localhost:9000

# For Kubernetes, use port-forwarding
kubectl port-forward -n iceberg svc/polaris 8181:8181
kubectl port-forward -n spark svc/spark-history-server 18080:18080
```

### Memory Issues

#### Issue: Out of Memory Errors

**Symptoms**:
- OutOfMemoryError in Spark
- Container restart due to memory pressure
- Slow performance due to swapping

**Solutions**:
```bash
# Increase Spark executor memory
--executor-memory 4g

# Increase driver memory
--driver-memory 4g

# Reduce shuffle partitions
--conf spark.sql.shuffle.partitions=4

# Enable dynamic allocation
--conf spark.dynamicAllocation.enabled=true
```

### IAM and Permission Issues

#### Issue: History Server Cannot Read Logs

**Symptoms**:
- "Access denied" errors
- Permission denied when reading S3
- IAM user cannot access spark-logs bucket

**Solutions**:
```bash
# Verify IAM user exists
aws --endpoint-url=http://localhost:6080 iam get-user --user-name spark-history-user

# Check user policy
aws --endpoint-url=http://localhost:6080 iam get-user-policy --user-name spark-history-user --policy-name SparkLogsReadAccess

# For MinIO, check bucket policy
mc anonymous get download local/spark-logs

# Recreate user with correct permissions
# See setup.sh script for IAM permission setup
```

### ObjectScale-Specific Issues

#### Issue: SSL Certificate Errors with ObjectScale

**Symptoms**:
- `SSL: CERTIFICATE_VERIFY_FAILED` errors
- `SSL certificate problem` when connecting to ObjectScale
- Handshake failures

**Solutions**:
```bash
# Disable SSL verification (for testing only)
export AWS_CA_BUNDLE=
export REQUESTS_CA_BUNDLE=

# Or use --no-verify-ssl flag
aws --endpoint-url=http://localhost:6080 --no-verify-ssl s3 ls

# For production, add ObjectScale CA certificate to trust store
# Copy ObjectScale CA certificate
sudo cp /path/to/objectscale-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

#### Issue: ObjectScale Endpoint Unreachable

**Symptoms**:
- `Connection refused` when connecting to ObjectScale
- `Name or service not known` errors
- Timeout errors

**Solutions**:
```bash
# Verify ObjectScale is running
curl -v http://localhost:6080/health

# Check if ObjectScale service is running (if deployed as service)
sudo systemctl status objectscale

# Check ObjectScale logs
sudo journalctl -u objectscale -f

# Verify network connectivity
ping -c 3 localhost
telnet localhost 6080

# Check firewall rules
sudo ufw status
sudo iptables -L

# If using Docker, check container status
docker ps | grep objectscale
docker logs objectscale-container
```

#### Issue: ObjectScale Authentication Failures

**Symptoms**:
- `InvalidAccessKeyId` errors
- `SignatureDoesNotMatch` errors
- `403 Forbidden` responses

**Solutions**:
```bash
# Verify credentials are set correctly
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY

# Test with explicit credentials
aws --endpoint-url=http://localhost:6080 \
    --access-key-id YOUR_ACCESS_KEY \
    --secret-access-key YOUR_SECRET_KEY \
    s3 ls

# Check if IAM user exists and has correct permissions
aws --endpoint-url=http://localhost:6080 iam get-user --user-name YOUR_USER

# Reset credentials if needed
aws --endpoint-url=http://localhost:6080 iam create-access-key --user-name YOUR_USER
```

#### Issue: ObjectScale Bucket Creation Fails

**Symptoms**:
- `BucketAlreadyExists` errors
- `AccessDenied` when creating buckets
- `InvalidBucketName` errors

**Solutions**:
```bash
# Check if bucket already exists
aws --endpoint-url=http://localhost:6080 s3 ls

# Use unique bucket names
TIMESTAMP=$(date +%s)
aws --endpoint-url=http://localhost:6080 s3 mb s3://test-bucket-$TIMESTAMP

# Verify bucket naming rules (lowercase, no underscores, DNS-compliant)
# Valid: my-bucket, my.bucket
# Invalid: My_Bucket, MyBucket_ (uppercase, underscores)

# Check IAM permissions for bucket creation
aws --endpoint-url=http://localhost:6080 iam get-user-policy --user-name YOUR_USER --policy-name S3FullAccess
```

### Spark Connection Issues with ObjectScale

#### Issue: Spark Cannot Connect to ObjectScale

**Symptoms**:
- `NoFileSystem for scheme: s3a` errors
- `Unable to access s3a://` URLs
- `ClassNotFoundException: org.apache.hadoop.fs.s3a.S3AFileSystem`

**Solutions**:
```bash
# Ensure Hadoop AWS and S3A jars are included
spark-shell \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0 \
  --packages org.apache.hadoop:hadoop-aws:3.3.4 \
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
  --conf spark.hadoop.fs.s3a.endpoint=http://localhost:6080 \
  --conf spark.hadoop.fs.s3a.access.key=YOUR_ACCESS_KEY \
  --conf spark.hadoop.fs.s3a.secret.key=YOUR_SECRET_KEY \
  --conf spark.hadoop.fs.s3a.path.style.access=true
```

#### Issue: Spark S3A Configuration Errors

**Symptoms**:
- `IllegalArgumentException: Wrong FS: s3a://` expected
- `Invalid endpoint` errors
- Connection timeout errors

**Solutions**:
```bash
# Verify S3A configuration properties
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.endpoint=http://localhost:6080  # ObjectScale endpoint
spark.hadoop.fs.s3a.access.key=YOUR_ACCESS_KEY
spark.hadoop.fs.s3a.secret.key=YOUR_SECRET_KEY
spark.hadoop.fs.s3a.path.style.access=true  # Required for S3-compatible storage

# For ObjectScale, ensure path style access is enabled
# Virtual-hosted-style may not work with non-AWS S3 implementations

# Test S3A connectivity in Spark shell
import org.apache.hadoop.fs.s3a.S3AFileSystem
val fs = new S3AFileSystem()
fs.initialize(new org.apache.hadoop.fs.Path("s3a://bucket").toUri, spark.sparkContext.hadoopConfiguration)
```

#### Issue: Spark Event Logging to ObjectScale Fails

**Symptoms**:
- Event logs not written to ObjectScale
- `Failed to write event log` errors
- `Permission denied` errors

**Solutions**:
```bash
# Verify S3A configuration for event logging
spark.eventLog.enabled=true
spark.eventLog.dir=s3a://spark-logs/
spark.history.fs.logDirectory=s3a://spark-logs/

# Ensure spark-logs bucket exists and is writable
aws --endpoint-url=http://localhost:6080 s3 mb s3://spark-logs
aws --endpoint-url=http://localhost:6080 s3 ls s3://spark-logs

# Check IAM permissions for the user running Spark
# User needs: s3:PutObject, s3:GetObject, s3:ListBucket on spark-logs bucket

# Test write permissions
aws --endpoint-url=http://localhost:6080 s3 cp /tmp/test.txt s3://spark-logs/test.txt
```

### MinIO-Specific Issues

#### Issue: MinIO Console Not Accessible

**Symptoms**:
- Cannot access MinIO console at http://localhost:9001
- `Connection refused` errors
- Console shows blank page

**Solutions**:
```bash
# Check MinIO container status
docker-compose ps minio

# Check MinIO logs
docker-compose logs minio

# Verify console port is mapped
docker-compose ps | grep 9001

# Restart MinIO
docker-compose restart minio

# Access console with default credentials
# URL: http://localhost:9001
# Username: minioadmin
# Password: minioadmin
```

#### Issue: MinIO Bucket Permission Errors

**Symptoms**:
- `AccessDenied` when accessing buckets
- `InvalidAccessKeyId` errors
- Permission denied for bucket operations

**Solutions**:
```bash
# Set bucket policy for public read (for testing)
mc anonymous set download local/spark-logs

# Or set specific bucket policy
mc policy set download local/spark-logs

# Check current bucket policy
mc policy get local/spark-logs

# Verify user permissions
mc admin user info local
```

## 🔍 Diagnostic Commands

### General Health Check

```bash
# Check all services (Docker Compose)
docker-compose ps

# Check all services (Kubernetes)
kubectl get pods -n iceberg
kubectl get pods -n spark

# Check storage connectivity
mc ls local/
# or
aws --endpoint-url=http://localhost:6080 s3 ls

# Check catalog health
curl http://localhost:8181/health

# Check Spark History Server
curl http://localhost:18080
```

### Detailed Component Checks

```bash
# Check Polaris logs
kubectl logs -n iceberg deployment/polaris -f
# or
docker-compose logs polaris -f

# Check Spark History Server logs
kubectl logs -n spark deployment/spark-history-server -f
# or
docker-compose logs spark-history -f

# Check Spark logs
kubectl logs -n spark deployment/spark-master -f
# or
docker-compose logs spark-master -f

# Check storage logs
docker-compose logs minio -f
```

## 📞 Getting Help

If you encounter issues not covered here:

1. **Check logs**: Always check component logs first
2. **Verify configuration**: Ensure all environment variables are set correctly
3. **Test connectivity**: Verify network connectivity between components
4. **Consult documentation**: Check relevant lab documentation
5. **Restart components**: Sometimes a simple restart fixes issues

---

**Most issues can be resolved by checking logs and verifying configuration.**