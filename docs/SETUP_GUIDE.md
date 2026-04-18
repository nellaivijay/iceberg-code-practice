# Iceberg Practice Environment - Setup Guide

## 🚀 Quick Start

This guide will help you set up the vendor-independent Apache Iceberg practice environment using either Kubernetes (k3s) or Docker Compose.

## 📋 Prerequisites

### System Requirements
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 20GB minimum
- **CPU**: 2 cores minimum (4 cores recommended)
- **OS**: Linux, macOS, or Windows with WSL2

### Software Requirements
- **Docker** (or Podman) - version 20.10+
- **kubectl** - for Kubernetes setup (optional)
- **k3s** - for Kubernetes setup (optional)
- **Python** - 3.8+ (for some scripts)

### Network Requirements
- Port 8181 (Polaris catalog)
- Port 9000/9001 (MinIO console)
- Port 18080 (Spark History Server)
- Port 6080 (ObjectScale)

## 🎯 Setup Options

### Option 1: Kubernetes with k3s (Recommended)

#### Step 1: Install k3s

```bash
# Install k3s
curl -sfL https://get.k3s.io | sh -

# Configure kubectl
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

#### Step 2: Run Setup Script

```bash
cd iceberg-practice-env
./scripts/setup.sh
```

The setup script will:
- Check prerequisites
- Configure storage backend (ObjectScale or MinIO)
- Deploy Apache Polaris catalog
- Deploy Spark History Server
- Configure persistent logging
- Create necessary buckets and IAM permissions

#### Step 3: Verify Deployment

```bash
# Check all pods
kubectl get pods -n iceberg
kubectl get pods -n spark

# Expected output:
# iceberg namespace:
# NAME                      READY   STATUS    RESTARTS   AGE
# polaris-xxx-xxx          1/1     Running   0          2m

# spark namespace:
# NAME                      READY   STATUS    RESTARTS   AGE
# spark-history-server-xxx  1/1     Running   0          1m
```

### Option 2: Docker Compose (Lightweight)

#### Step 1: Start Services

```bash
cd iceberg-practice-env
docker-compose up -d
```

#### Step 2: Verify Services

```bash
# Check all containers
docker-compose ps

# Expected output:
# NAME              STATUS          PORTS
# minio             running (healthy)   0.0.0.0:9000->9000/tcp
# polaris           running (healthy)   0.0.0.0:8181->8181/tcp
# spark-history     running (healthy)   0.0.0.0:18080->18080/tcp
# spark-master       running
# spark-worker       running
```

#### Step 3: Access Services

- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **Polaris Catalog**: http://localhost:8181
- **Spark History Server**: http://localhost:18080

## 🔧 Configuration

### Storage Backend Selection

#### Using ObjectScale (Default)
```bash
export STORAGE_BACKEND=objectscale
export OBJECTSCALE_ENDPOINT="http://localhost:6080"
export OBJECTSCALE_ACCESS_KEY="admin"
export OBJECTSCALE_SECRET_KEY="password"
```

#### Using MinIO
```bash
export STORAGE_BACKEND=minio
export MINIO_ENDPOINT="http://localhost:9000"
export MINIO_ACCESS_KEY="minioadmin"
export MINIO_SECRET_KEY="minioadmin"
```

### Spark Configuration

```bash
# Spark History Server port
export SPARK_HISTORY_PORT=18080

# Event logs location
export SPARK_EVENT_LOGS="s3a://spark-logs/"
```

## 🧪 Verification Steps

### 1. Verify Storage Connectivity

```bash
# For MinIO
mc alias set local http://localhost:9000 minioadmin minioadmin
mc ls local/

# For ObjectScale
aws --endpoint-url=http://localhost:6080 s3 ls
```

### 2. Verify Polaris Catalog

```bash
# Health check
curl -f http://localhost:8181/health

# Expected: {"status":"healthy"}
```

### 3. Verify Spark History Server

```bash
# Access UI
curl -f http://localhost:18080

# Expected: HTML response from History Server
```

### 4. Verify Spark Event Logging

```bash
# Check if spark-logs bucket exists
mc ls local/spark-logs/  # MinIO
# or
aws --endpoint-url=http://localhost:6080 s3 ls s3://spark-logs/  # ObjectScale
```

## 🔍 Troubleshooting

### Issue: k3s Installation Fails

**Solution**:
```bash
# Try alternative installation method
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=644 sh -
```

### Issue: Docker Compose Services Won't Start

**Solution**:
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose down
docker-compose up -d
```

### Issue: Storage Connectivity Fails

**Solution**:
- Verify storage endpoint is accessible
- Check access keys and secret keys
- Ensure bucket names are correct

### Issue: Polaris Health Check Fails

**Solution**:
```bash
# Check Polaris logs
kubectl logs -n iceberg deployment/polaris  # Kubernetes
# or
docker-compose logs polaris  # Docker Compose
```

### Issue: Spark History Server Can't Read Logs

**Solution**:
- Verify IAM permissions for spark-history user
- Check S3 endpoint configuration
- Ensure spark-logs bucket exists

## 📚 Next Steps

After successful setup:

1. **Start with Lab 1**: Environment Setup and Validation
2. **Progress through Labs 2-6**: Learn Iceberg operations and optimizations
3. **Explore Spark History Server**: Inspect DAGs and query plans
4. **Experiment**: Try different configurations and optimizations

## 🎓 Learning Path

1. **Lab 1**: Environment Setup → Verify all components
2. **Lab 2**: Basic Iceberg Operations → Tables, queries, schema evolution
3. **Lab 3**: Advanced Features → Partitioning, compaction, metadata-only filtering
4. **Lab 4**: Spark Optimizations → File management, query planning
5. **Lab 5**: Real-World Patterns → SCD, upsert, CDC, star schema
6. **Lab 6**: Performance & UI → Complex joins, DAG inspection, optimization analysis

## 🆘 Support

For issues or questions:

1. Check the main README.md
2. Review specific lab documentation
3. Consult troubleshooting section
4. Check logs for error messages

---

**Your vendor-independent Apache Iceberg practice environment is ready for learning and experimentation!**