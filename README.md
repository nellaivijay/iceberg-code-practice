<!--
SEO Metadata
Title: Apache Iceberg Code Practice - Free Hands-on Labs for Data Lakehouse Learning
Description: Master Apache Iceberg with free, vendor-independent hands-on labs. Practice Spark, Trino, DuckDB, Kafka, CDC, and modern data lakehouse patterns with real-world exercises.
Keywords: apache iceberg, data lakehouse, spark, trino, duckdb, kafka, cdc, data engineering, lakehouse architecture, table format, data lake, open source data
Author: Iceberg Code Practice Community
-->

# Apache Iceberg Code Practice

## 🎯 Overview

A comprehensive, vendor-independent Apache Iceberg code practice repository designed for learning and experimentation with Apache Iceberg, Apache Spark, and modern data lakehouse architectures through hands-on coding exercises.

**12 hands-on labs with 100+ exercises. Completely free and open source.**

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Iceberg Code Practice                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Apache Polaris (Iceberg REST Catalog)        │  │
│  │         Vendor-independent catalog service          │  │
│  └──────────────────────────────────────────────────────┘  │
│                              ↓                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Query Engines (Multi-Engine Lakehouse)      │  │
│  │         - Apache Spark (OSS) with Iceberg          │  │
│  │         - Trino (Interactive SQL)                   │  │
│  │         - DuckDB (Local Analytics)                  │  │
│  │         - Spark History Server (port 18080)         │  │
│  └──────────────────────────────────────────────────────┘  │
│                              ↓                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Streaming & CDC Infrastructure               │  │
│  │         - Apache Kafka (Event Streaming)            │  │
│  │         - Debezium (Change Data Capture)            │  │
│  │         - MySQL (CDC Source Database)               │  │
│  │         - Zookeeper (Kafka Coordination)             │  │
│  └──────────────────────────────────────────────────────┘  │
│                              ↓                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Storage Layer (S3-Compatible)              │  │
│  │         - ObjectScale CE (default)            │  │
│  │         - MinIO (optional alternative)             │  │
│  │         - s3a://spark-logs/ for History Server     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Core Stack

### Catalog
- **Apache Polaris (Incubating)**: Iceberg REST catalog
- Vendor-independent catalog service
- REST API for metadata management

### Storage Options
- **ObjectScale Community Edition** (Default)
- **MinIO** (Alternative)
- Both provide S3-compatible APIs

### Compute Engines
- **Apache Spark (OSS)**: Data processing engine
- **Trino**: Interactive SQL query engine
- **DuckDB**: Local analytics database
- **Spark History Server**: UI for viewing completed jobs
- **Iceberg Spark Runtime**: Iceberg table operations

### Streaming & CDC
- **Apache Kafka**: Distributed event streaming platform
- **Debezium**: Change Data Capture for database synchronization
- **MySQL**: Source database for CDC
- **Zookeeper**: Kafka coordination service

### Orchestration
- **k3s**: Lightweight Kubernetes distribution
- **Docker Compose**: Alternative non-K8s setup

## 🎓 Lab Structure

### Lab Difficulty & Time Estimates

| Level | Labs | Time per Lab | What It Tests |
|-------|------|--------------|---------------|
| Beginner | Labs 0-2 | 30-45 min | Basic setup, table operations, fundamental concepts |
| Intermediate | Labs 3-5 | 45-60 min | Advanced features, optimization patterns, real-world scenarios |
| Advanced | Labs 6-11 | 60-90 min | Performance analysis, CDC, streaming, multi-engine architecture |

### Lab 0: Sample Database Setup (NEW)
- Generate and load realistic business data
- Explore sample database schema and relationships
- Practice queries on sample data
- **Prerequisite for all subsequent labs**

### Lab 1: Environment Setup
- Verify all components are running
- Test catalog connectivity
- Validate storage access

### Lab 2: Basic Iceberg Operations
- Create Iceberg tables
- Insert and query data
- Understand schema evolution

### Lab 3: Advanced Iceberg Features
- Partitioning strategies
- Time travel queries
- Schema evolution with migrations

### Lab 4: Iceberg + Spark Optimizations
- File compaction
- Snapshot management
- Query planning optimization

### Lab 5: Real-world Data Patterns
- Slowly Changing Dimensions (SCD)
- Upsert operations
- Batch and streaming patterns

### Lab 6: Performance & UI ⭐ (NEW)
- Complex Iceberg join operations
- Spark History Server UI exploration
- DAG inspection and metadata-only filtering
- Performance analysis and optimization

### Lab 7: Table Maintenance and Operations (NEW)
- File compaction and optimization strategies
- Snapshot management and expiration
- Orphan file cleanup and storage reclamation
- Table statistics collection and analysis
- Metadata optimization
- Table migration and rollback
- Backup and restore strategies
- Monitoring and alerting setup
- Automated maintenance procedures

### Lab 8: Kafka Integration with Iceberg (NEW)
- Set up Apache Kafka for real-time data streaming
- Produce and consume events with Kafka
- Integrate Spark Structured Streaming with Iceberg
- Implement real-time analytics on streaming data
- Handle exactly-once processing semantics
- Implement data quality validation
- Handle schema evolution in streaming pipelines

### Lab 9: Real CDC with Debezium (NEW)
- Configure Debezium for MySQL CDC
- Set up MySQL for change data capture
- Create and manage Debezium connectors
- Stream CDC events to Kafka topics
- Consume CDC events with Spark Structured Streaming
- Apply CDC changes to Iceberg tables (inserts, updates, deletes)
- Handle schema evolution and data type conversions
- Monitor and troubleshoot CDC pipelines

### Lab 10: Spring Boot with Iceberg (NEW)
- Create Spring Boot applications with Iceberg integration
- Configure Iceberg catalog and table access
- Implement CRUD operations on Iceberg tables
- Build REST APIs for Iceberg data access
- Implement transaction handling and error management
- Optimize performance with caching and connection pooling
- Implement data validation and business logic
- Add monitoring and logging to applications

### Lab 11: Multi-Engine Lakehouse (NEW)
- Configure multiple query engines (Spark, Trino, DuckDB)
- Ensure schema consistency across engines
- Implement engine-specific optimizations
- Handle data type conversions between engines
- Monitor and optimize multi-engine workloads
- Implement workload isolation and resource management
- Build cross-engine ETL pipelines
- Monitor multi-engine lakehouse operations

## 💾 Sample Database

The environment includes a comprehensive sample database with realistic e-commerce data for hands-on learning:

### Sample Tables
- **sample_customers** (1,000 records): Customer dimension with segmentation
- **sample_products** (200 records): Product catalog with categories
- **sample_orders** (5,000 records): Order fact table with status tracking
- **sample_transactions** (10,000 records): Transaction details with payment methods
- **sample_events** (20,000 records): Web events for user engagement analysis

### Loading Sample Data
```bash
# Generate and load sample data
python3 scripts/generate_sample_data.py
./scripts/load_sample_data.sh
```

### Sample Data Documentation
- [Sample Database Guide](docs/SAMPLE_DATABASE.md) - Complete schema and usage documentation
- [Lab 0: Sample Database Setup](labs/lab-00-sample-database.md) - Step-by-step loading and exploration

## 🚀 Quick Start

### Option 1: Kubernetes with k3s (Recommended)
```bash
cd iceberg-practice-env
./scripts/setup.sh
kubectl apply -f k8s/
```

### Option 2: Docker Compose (Lightweight)
```bash
cd iceberg-practice-env
docker-compose up -d
```

## 📋 Requirements

- Docker or Podman
- k3s (for K8s setup) OR Docker Compose (for lightweight setup)
- 16GB RAM minimum (increased for multi-engine and streaming workloads)
- 40GB disk space (increased for additional components)

## 🔧 Configuration

### Storage Backend Selection
```bash
# Use ObjectScale (default)
export STORAGE_BACKEND=objectscale

# Use MinIO
export STORAGE_BACKEND=minio
```

### Spark Configuration
```bash
# Spark History Server port
export SPARK_HISTORY_PORT=18080

# Event logs location
export SPARK_EVENT_LOGS=s3a://spark-logs/
```

## 📚 Documentation

### Core Documentation
- [Setup Guide](docs/SETUP_GUIDE.md) - Detailed setup instructions for K8s and Docker Compose
- [Architecture Overview](docs/ARCHITECTURE.md) - System architecture and component details
- [Lab Guide](docs/LAB_GUIDE.md) - Complete lab sequence and learning path
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions (including ObjectScale-specific issues)

### 🎓 Conceptual Guides (Tutorials)
Deep-dive tutorials explaining the "Why" behind the "How":

- [Conceptual Guide 1: Environment Architecture](docs/conceptual-guides/01-environment-architecture.md) - Understanding the Iceberg environment architecture
- [Conceptual Guide 2: Table Operations & Schema Evolution](docs/conceptual-guides/02-table-operations-schema-evolution.md) - How Iceberg handles table operations and schema evolution
- [Conceptual Guide 3: Advanced Features & Performance](docs/conceptual-guides/03-advanced-features-performance.md) - Partitioning, Z-ordering, compaction, and metadata-only filtering
- [Conceptual Guide 4: Spark + Iceberg Optimization](docs/conceptual-guides/04-spark-iceberg-optimization.md) - Spark-Iceberg integration and optimization techniques
- [Conceptual Guide 5: Real-World Data Patterns](docs/conceptual-guides/05-real-world-patterns.md) - SCD, upsert, CDC, and batch/streaming patterns
- [Conceptual Guide 6: Performance Analysis & DAG Inspection](docs/conceptual-guides/06-performance-analysis-dag-inspection.md) - Understanding query execution and performance analysis
- [Conceptual Guide 7: Table Maintenance & Operations](docs/conceptual-guides/07-table-maintenance-operations.md) - Compaction, snapshots, monitoring, and automation
- [Conceptual Guide 8: Real-Time Data Pipelines with Kafka and CDC](docs/conceptual-guides/08-real-time-data-pipelines-kafka-cdc.md) - Kafka integration, CDC patterns, and streaming architectures
- [Conceptual Guide 9: Application Integration with Iceberg](docs/conceptual-guides/09-application-integration-iceberg.md) - Building applications with Iceberg, repository patterns, and transaction management
- [Conceptual Guide 10: Multi-Engine Lakehouse Architecture](docs/conceptual-guides/10-multi-engine-lakehouse-architecture.md) - Multi-engine design patterns, engine selection, and resource management

### Lab Materials
- [Lab 0: Sample Database Setup](labs/lab-00-sample-database.md) - Generate and load sample data
- [Lab 1: Environment Setup](labs/lab-01-setup.md) - Component verification and first Iceberg query
- [Lab 2: Basic Operations](labs/lab-02-basic-operations.md) - Tables, queries, schema evolution
- [Lab 3: Advanced Features](labs/lab-03-advanced-features.md) - Partitioning, compaction, metadata filtering
- [Lab 4: Spark Optimizations](labs/lab-04-optimizations.md) - File management, query planning
- [Lab 5: Real-World Patterns](labs/lab-05-real-world-patterns.md) - SCD, upsert, CDC, star schema
- [Lab 6: Performance & UI](labs/lab-06-performance-ui.md) - DAG inspection, metadata-only filtering analysis
- [Lab 7: Table Maintenance](labs/lab-07-table-maintenance.md) - Compaction, snapshots, monitoring, automation
- [Lab 8: Kafka Integration](labs/lab-08-kafka-integration.md) - Real-time streaming with Kafka and Iceberg
- [Lab 9: Real CDC with Debezium](labs/lab-09-cdc-debezium.md) - Change data capture with Debezium
- [Lab 10: Spring Boot with Iceberg](labs/lab-10-spring-boot-iceberg.md) - Building applications with Iceberg
- [Lab 11: Multi-Engine Lakehouse](labs/lab-11-multi-engine-lakehouse.md) - Multi-engine architecture and optimization

### 💡 Jupyter Notebooks
Interactive Jupyter notebooks for hands-on learning:

- [Lab Notebooks](notebooks/) - Student notebooks with exercises
- [Solution Helper](notebooks/SOLUTION_HELPER_INSTRUCTIONS.md) - How to use the solution helper when stuck

### 🔧 Solutions Framework
Complete solution notebooks for reference and validation:

- [Lab 1 Solution](solutions/lab-01-setup-solution.ipynb) - Environment setup solution
- [Lab 2 Solution](solutions/lab-02-basic-operations-solution.ipynb) - Basic operations solution
- [Lab 3 Solution](solutions/lab-03-advanced-features-solution.ipynb) - Advanced features solution
- [Lab 4 Solution](solutions/lab-04-optimizations-solution.ipynb) - Optimizations solution
- [Lab 5 Solution](solutions/lab-05-real-world-patterns-solution.ipynb) - Real-world patterns solution
- [Lab 6 Solution](solutions/lab-06-performance-ui-solution.ipynb) - Performance & UI solution
- [Lab 7 Solution](solutions/lab-07-table-maintenance-solution.ipynb) - Table maintenance solution
- [Lab 8 Solution](solutions/lab-08-kafka-integration-solution.ipynb) - Kafka integration solution
- [Lab 9 Solution](solutions/lab-09-cdc-debezium-solution.ipynb) - CDC with Debezium solution
- [Lab 10 Solution](solutions/lab-10-spring-boot-iceberg-solution.ipynb) - Spring Boot with Iceberg solution
- [Lab 11 Solution](solutions/lab-11-multi-engine-lakehouse-solution.ipynb) - Multi-engine lakehouse solution

### 🤖 Automation Scripts
- [Solution Helper](scripts/solution_helper.py) - Python helper for accessing solutions and hints
- [Validate Solutions](scripts/validate_solutions.sh) - CI/CD validation script for solution notebooks
- [Convert Labs to Notebooks](scripts/convert_labs_to_notebooks.py) - Convert Markdown labs to Jupyter notebooks
- [Generate Sample Data](scripts/generate_sample_data.py) - Generate realistic business data
- [Load Sample Data](scripts/load_sample_data.sh) - Load sample data into Iceberg

## 🆘 Vendor Independence

This environment uses only Apache-licensed tools:
- Apache Spark (Apache 2.0)
- Apache Iceberg (Apache 2.0)
- Apache Polaris (Apache 2.0)
- Apache Kafka (Apache 2.0)
- Trino (Apache 2.0)
- DuckDB (MIT)
- Debezium (Apache 2.0)
- MySQL Community Server (GPL)
- k3s (MIT)
- MinIO (AGPL)
- ObjectScale CE (Apache 2.0)

No proprietary cloud services or consoles required.

## 🤝 Contributing

This is a practice environment for learning. Feel free to extend labs, add examples, or improve the setup process.

> **Disclaimer**: This is an independent educational resource for learning Apache Iceberg and data lakehouse concepts. It is not affiliated with, endorsed by, or sponsored by Apache Iceberg or any vendor.

## 👥 Contributors

This repository welcomes contributions from the data engineering community. Special thanks to contributors who help improve labs, fix bugs, and add new exercises.

**Contact**: nellaivijay@gmail.com

## 📄 License

Apache License 2.0