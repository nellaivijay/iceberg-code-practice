# Lab 1: Environment Setup and Validation

## 🎯 Learning Objectives

After completing this lab, you will be able to:
- Verify all components of the Iceberg practice environment
- Test connectivity to the Apache Polaris catalog
- Validate S3-compatible storage access
- Configure Spark for Iceberg operations
- Run your first Iceberg query

## 🛠️ Prerequisites

- Completed the setup process using `./scripts/setup.sh` or `docker-compose up -d`
- Basic understanding of command-line tools
- Spark installed locally or access to Spark cluster

## 📋 Lab Steps

### Step 1: Verify Component Status

First, let's verify that all components are running correctly.

#### For Kubernetes Setup:
```bash
# Check all pods in iceberg namespace
kubectl get pods -n iceberg

# Expected output:
# NAME                      READY   STATUS    RESTARTS   AGE
# polaris-xxx-xxx          1/1     Running   0          2m
```

#### For Docker Compose Setup:
```bash
# Check all containers
docker-compose ps

# Expected output:
# NAME              STATUS          PORTS
# minio             running (healthy)   0.0.0.0:9000->9000/tcp, 0.0.0.0:9001->9001/tcp
# polaris           running (healthy)   0.0.0.0:8181->8181/tcp
# spark-history     running (healthy)   0.0.0.0:18080->18080/tcp
```

**Assertion 1**: All components should show as "Running" or "healthy"

### Step 2: Test Storage Connectivity

Verify that we can access the S3-compatible storage.

```bash
# For MinIO (Docker Compose):
mc alias set local http://localhost:9000 minioadmin minioadmin
mc ls local/

# For ObjectScale (Kubernetes):
aws --endpoint-url=http://localhost:6080 s3 ls

# Create spark-logs bucket if it doesn't exist
mc mb local/spark-logs  # MinIO
# or
aws --endpoint-url=http://localhost:6080 s3 mb s3://spark-logs  # ObjectScale
```

**Assertion 2**: Storage should be accessible and spark-logs bucket should exist

### Step 3: Test Polaris Catalog Connectivity

Test the Apache Polaris REST catalog endpoint.

```bash
# Test health endpoint
curl -f http://localhost:8181/health

# Expected output:
# {"status":"healthy"}
```

**Assertion 3**: Polaris health check should return healthy status

### Step 4: Configure Spark for Iceberg

Create a Spark configuration file for Iceberg operations.

```bash
# Create spark configuration directory
mkdir -p ~/iceberg-labs/config

# Create spark-defaults.conf
cat > ~/iceberg-labs/config/spark-defaults.conf << 'EOF'
# Iceberg Configuration
spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=rest
spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog

# S3 Configuration (for MinIO)
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.endpoint=http://localhost:9000
spark.hadoop.fs.s3a.access.key=minioadmin
spark.hadoop.fs.s3a.secret.key=minioadmin

# Event Logging
spark.eventLog.enabled=true
spark.eventLog.dir=s3a://spark-logs/
spark.history.fs.logDirectory=s3a://spark-logs/
EOF
```

**Assertion 4**: Spark configuration file should be created successfully

### Step 5: Run First Iceberg Query

Now let's run our first Iceberg operation using Spark.

```python
# Start Spark shell with Iceberg configuration
spark-shell \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0 \
  --conf spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.iceberg.type=rest \
  --conf spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog \
  --conf spark.hadoop.fs.s3a.endpoint=http://localhost:9000 \
  --conf spark.hadoop.fs.s3a.access.key=minioadmin \
  --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
  --conf spark.hadoop.fs.s3a.path.style.access=true
```

Once in the Spark shell, run:

```scala
// Create a simple Iceberg table
spark.sql("""
  CREATE TABLE iceberg.default.test_table (
    id INT,
    name STRING,
    value DOUBLE
  ) USING iceberg
  PARTITIONED BY (name)
  TBLPROPERTIES (
    'format-version'='2'
  )
""")

// Insert test data
spark.sql("""
  INSERT INTO iceberg.default.test_table VALUES
    (1, 'Alice', 100.0),
    (2, 'Bob', 200.0),
    (3, 'Charlie', 300.0)
""")

// Query the table
val result = spark.sql("SELECT * FROM iceberg.default.test_table")
result.show()

// Expected output:
// +---+-------+-----+
// | id|   name|value|
// +---+-------+-----+
// |  1|  Alice|100.0|
// |  2|    Bob|200.0|
// |  3|Charlie|300.0|
// +---+-------+-----+
```

**Assertion 5**: Table creation, data insertion, and query should all succeed

### Step 6: Verify Spark History Server

Check that the Spark History Server is accessible and can read logs.

```bash
# Access Spark History Server UI
# Open browser to: http://localhost:18080

# Or test via curl
curl -f http://localhost:18080

# Expected: HTML response from History Server UI
```

**Assertion 6**: Spark History Server should be accessible on port 18080

## ✅ Lab Completion Checklist

- [ ] All components running (Kubernetes pods or Docker containers)
- [ ] Storage accessible and spark-logs bucket created
- [ ] Polaris catalog health check successful
- [ ] Spark configuration file created
- [ ] First Iceberg table created successfully
- [ ] Data inserted and queried successfully
- [ ] Spark History Server accessible

## 🔍 Troubleshooting

### Issue: Components not starting
**Solution**: Check logs with `kubectl logs -n iceberg <pod-name>` or `docker-compose logs <service>`

### Issue: Storage connectivity fails
**Solution**: Verify storage endpoint and credentials in configuration

### Issue: Polaris health check fails
**Solution**: Check Polaris logs and ensure it can connect to storage

### Issue: Spark cannot connect to Iceberg
**Solution**: Verify Iceberg REST catalog URL and Spark configuration

## 🎓 Key Concepts Learned

1. **Apache Polaris**: REST-based Iceberg catalog service
2. **S3-Compatible Storage**: MinIO and ObjectScale as alternatives to AWS S3
3. **Spark History Server**: UI for viewing completed Spark jobs
4. **Iceberg Tables**: Apache Iceberg table format and operations
5. **Configuration Management**: Spark configuration for Iceberg operations

## 🚀 Next Steps

Proceed to **Lab 2: Basic Iceberg Operations** to learn more about Iceberg table operations and schema evolution.