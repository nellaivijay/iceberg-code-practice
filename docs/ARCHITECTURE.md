# Iceberg Practice Environment - Architecture Overview

## 🏗️ System Architecture

The Iceberg Practice Environment implements a vendor-independent, Apache-licensed data lakehouse architecture optimized for learning and experimentation with Apache Iceberg.

## 📊 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   User Access Layer                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Spark Shell   │  │ Jupyter Lab   │  │ CLI Tools     │  │
│  │ (Python/Scala)│  │ (Notebooks)   │  │ (mc, aws CLI)│  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Compute Layer                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Apache Spark (OSS) with Iceberg Runtime      │  │
│  │         - Spark Master                               │  │
│  │         - Spark Workers                               │  │
│  │         - Spark History Server (port 18080)          │  │
│  │         - Event Logging to S3                         │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Catalog Layer                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Apache Polaris (Iceberg REST Catalog)        │  │
│  │         - REST API for metadata                      │  │
│  │         - Table management                           │  │
│  │         - Namespace management                       │  │
│  │         - Schema evolution support                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Storage Layer                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         S3-Compatible Storage                       │  │
│  │         - ObjectScale CE (default)             │  │
│  │         - MinIO (alternative)                       │  │
│  │         - s3a://spark-logs/ for History Server        │  │
│  │         - s3a://iceberg-warehouse/ for data           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Orchestration Layer                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         k3s (Lightweight Kubernetes)                │  │
│  │         - Container orchestration                   │  │
│  │         - Service discovery                         │  │
│  │         - Load balancing                               │  │
│  │         - Persistent storage                          │  │
│  │         - Docker Compose (alternative)              │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Component Details

### Apache Polaris (Catalog)

**Purpose**: REST-based Iceberg catalog service

**Key Features**:
- REST API for metadata operations
- Namespace and table management
- Schema evolution support
- Multi-catalog support
- Vendor-independent design

**Configuration**:
- Port: 8181
- Storage: S3-compatible backend
- Authentication: Basic (disabled for practice environment)

**API Endpoints**:
- `/health` - Health check
- `/api/catalog` - Catalog operations
- `/api/v1/{namespace}/tables` - Table management

### Apache Spark with Iceberg

**Purpose**: Data processing and query engine

**Components**:
- **Spark Master**: Resource allocation and job scheduling
- **Spark Workers**: Task execution
- **Spark History Server**: Job history and UI (port 18080)
- **Iceberg Runtime**: Iceberg table operations

**Configuration**:
- Event logging: `s3a://spark-logs/`
- Catalog: REST catalog at Polaris endpoint
- Storage: S3-compatible backend
- Memory: 1-2GB per executor

### Storage Layer

**ObjectScale Community Edition** (Default):
- S3-compatible object storage
- Self-hosted, vendor-independent
- Supports IAM-like access control
- Optimized for on-premises

**MinIO** (Alternative):
- S3-compatible object storage
- Lightweight, easy to deploy
- Supports all S3 operations
- Ideal for development/testing

**Storage Structure**:
```
s3://
├── iceberg-warehouse/     # Iceberg table data
│   ├── default/
│   │   ├── users/
│   │   ├── orders/
│   │   └── events/
├── spark-logs/            # Spark event logs
│   ├── application_1/
│   └── application_2/
└── minio/                 # MinIO internal (if using MinIO)
```

### Orchestration Layer

**k3s** (Kubernetes):
- Lightweight Kubernetes distribution
- Single-node deployment
- Minimal resource requirements
- Production-grade features

**Docker Compose** (Alternative):
- Container orchestration without K8s
- Simple deployment model
- Ideal for development/testing
- Easy to start/stop services

## 🔄 Data Flow

### Query Execution Flow

```
User Query (Spark SQL)
    ↓
Spark Catalyst (Query Planning)
    ↓
Iceberg Catalog (Metadata Lookup)
    ↓
Partition Pruning + Metadata Filtering
    ↓
File Scan (from S3-compatible storage)
    ↓
Spark Execution Engine
    ↓
Results Returned to User
```

### Event Logging Flow

```
Spark Job Execution
    ↓
Event Logs Generated
    ↓
Written to s3a://spark-logs/
    ↓
Spark History Server Reads Logs
    ↓
UI Display at http://localhost:18080
```

## 🔒 Security Model

### Access Control

**Practice Environment** (Simplified):
- No authentication on Polaris catalog
- Default storage credentials
- Open Spark History Server access

**Production Considerations**:
- Enable Polaris authentication
- Implement proper IAM policies
- Use secrets management
- Enable TLS/SSL for all endpoints

### Network Security

**Kubernetes**:
- Network policies for pod communication
- Service mesh optional
- Ingress for external access

**Docker Compose**:
- Isolated network per environment
- Port mapping for external access
- Volume isolation for data

## 📈 Scalability Considerations

### Horizontal Scaling

**Spark Cluster**:
- Add more Spark workers
- Increase executor memory
- Scale based on workload

**Storage**:
- Use distributed storage clusters
- Implement data tiering (hot/cold)
- Use compression for cost optimization

### Vertical Scaling

**Resources**:
- Increase CPU allocation
- Add more memory to executors
- Use GPU for ML workloads

## 🎯 Performance Optimizations

### Iceberg Optimizations

1. **Partition Pruning**: Eliminate entire partitions from scans
2. **Metadata-Only Filtering**: Skip files without reading data
3. **Z-Ordering**: Cluster related data for better scans
4. **File Compaction**: Merge small files for better performance
5. **Compression**: Reduce storage I/O with compression codecs

### Spark Optimizations

1. **Query Planning**: Enable Iceberg query planning
2. **Predicate Pushdown**: Push filters to Iceberg
3. **Caching**: Cache frequently accessed data
4. **Memory Management**: Tune executor memory
5. **Parallelism**: Adjust shuffle partitions

## 🧪 Testing and Validation

### Component Health Checks

```bash
# Polaris catalog
curl http://localhost:8181/health

# MinIO/ObjectScale
mc ls local/
# or
aws --endpoint-url=http://localhost:6080 s3 ls

# Spark History Server
curl http://localhost:18080
```

### Integration Tests

1. **Catalog Connectivity**: Create/drop tables via REST API
2. **Storage Access**: Read/write files to S3-compatible storage
3. **Spark Operations**: Run Spark jobs with Iceberg tables
4. **Event Logging**: Verify logs written to S3
5. **History Server**: Verify logs readable by History Server

## 📊 Monitoring

### Component Monitoring

- **Polaris**: Health endpoint, request metrics
- **Spark**: Spark UI, History Server UI
- **Storage**: Bucket usage, request metrics
- **Kubernetes**: Pod status, resource usage

### Query Performance Monitoring

- **Spark History Server**: Job duration, stage breakdown
- **Iceberg Metrics**: File scan counts, query planning
- **Storage Metrics**: I/O operations, data transfer

## 🔄 Data Lifecycle

### Snapshots and Time Travel

Iceberg maintains snapshots for:
- Time travel queries
- Rollback capabilities
- Audit trail
- Performance analysis

### Compaction Strategy

- **Bin-Packing**: Merge small files
- **Size-Based**: Target file size optimization
- **Time-Based**: Scheduled compaction jobs

## 🎓 Learning Path Integration

### Lab Architecture Alignment

1. **Lab 1**: Environment Setup → Component verification
2. **Lab 2**: Basic Operations → Simple queries and table operations
3. **Lab 3**: Advanced Features → Partitioning, compaction, metadata filtering
4. **Lab 4**: Spark Optimizations → File management, query planning
5. **Lab 5**: Real-World Patterns → SCD, upsert, CDC, star schema
6. **Lab 6**: Performance & UI → DAG inspection, optimization analysis

---

**This architecture provides a complete, vendor-independent foundation for learning Apache Iceberg and modern data lakehouse concepts.**