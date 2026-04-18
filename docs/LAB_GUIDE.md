# Iceberg Practice Environment - Lab Guide

## 🎓 Overview

This guide provides a structured learning path through the Iceberg Practice Environment, covering basic operations through advanced performance optimization and UI analysis.

## 📋 Learning Path

### Lab Sequence

1. **Lab 1**: Environment Setup and Validation
2. **Lab 2**: Basic Iceberg Operations
3. **Lab 3**: Advanced Iceberg Features
4. **Lab 4**: Iceberg + Spark Optimizations
5. **Lab 5**: Real-World Data Patterns
6. **Lab 6**: Performance & UI (DAG Inspection)

## 🚀 Getting Started

### Prerequisites

- Completed setup using `./scripts/setup.sh` or `docker-compose up -d`
- All components verified and running
- Access to Spark shell configured with Iceberg

### Quick Verification

```bash
# Check if all components are running
kubectl get pods -n iceberg  # Kubernetes
# or
docker-compose ps  # Docker Compose

# Verify storage connectivity
mc ls local/  # MinIO
# or
aws --endpoint-url=http://localhost:6080 s3 ls  # ObjectScale

# Test Polaris catalog
curl http://localhost:8181/health

# Access Spark History Server
curl http://localhost:18080
```

## 📚 Lab Details

### Lab 1: Environment Setup and Validation

**Duration**: 30-45 minutes

**Learning Objectives**:
- Verify all components are running
- Test catalog connectivity
- Validate storage access
- Configure Spark for Iceberg operations
- Run first Iceberg query

**Key Skills**:
- Environment verification
- Component troubleshooting
- Basic Spark configuration
- Iceberg table creation

**Completion Criteria**:
- [ ] All components running (Kubernetes pods or Docker containers)
- [ ] Storage accessible and spark-logs bucket created
- [ ] Polaris catalog health check successful
- [ ] Spark configuration file created
- [ ] First Iceberg table created successfully
- [ ] Data inserted and queried successfully
- [ ] Spark History Server accessible

**Next Steps**: Proceed to Lab 2 to learn basic Iceberg operations

---

### Lab 2: Basic Iceberg Operations

**Duration**: 45-60 minutes

**Learning Objectives**:
- Create Iceberg tables with different configurations
- Insert and query data using Spark SQL
- Understand Iceberg partitioning strategies
- Perform basic schema evolution
- Work with Iceberg snapshots

**Key Skills**:
- Table creation with partitioning
- Data insertion and querying
- Schema evolution operations
- Snapshot management
- Time travel queries

**Completion Criteria**:
- [ ] Three tables created with different partitioning strategies
- [ ] Data inserted into all tables successfully
- [ ] Different query patterns executed successfully
- [ ] Schema evolution performed without breaking existing data
- [ ] Snapshot operations and time travel queries working
- [ ] Update and delete operations successful

**Next Steps**: Proceed to Lab 3 to learn advanced Iceberg features

---

### Lab 3: Advanced Iceberg Features

**Duration**: 60-90 minutes

**Learning Objectives**:
- Implement advanced partitioning strategies
- Perform file compaction and maintenance
- Understand Iceberg's metadata-only query optimization
- Work with complex schema migrations
- Optimize Iceberg table performance

**Key Skills**:
- Partition evolution
- Z-ordering for data clustering
- File compaction strategies
- Metadata-only filtering
- Complex schema migrations
- Performance tuning

**Completion Criteria**:
- [ ] Partition evolution successfully implemented
- [ ] Z-ordering configured for data clustering
- [ ] File compaction reduces file count
- [ ] Metadata-only query optimization working
- [ ] Complex schema migrations preserve data integrity
- [ ] Performance tuning shows measurable improvements

**Next Steps**: Proceed to Lab 4 to learn Spark optimizations

---

### Lab 4: Iceberg + Spark Optimizations

**Duration**: 60-90 minutes

**Learning Objectives**:
- Optimize Iceberg file compaction strategies
- Manage Iceberg snapshots for performance
- Configure Spark for optimal Iceberg query planning
- Implement efficient data loading patterns
- Monitor and tune Iceberg table performance

**Key Skills**:
- File compaction strategies
- Snapshot management
- Spark query planning optimization
- Efficient data loading
- Performance monitoring
- Dynamic file pruning

**Completion Criteria**:
- [ ] File compaction strategies implemented and tested
- [ ] Snapshot management successfully removes old snapshots
- [ ] Spark query planning optimization shows partition pruning
- [ ] Efficient data loading patterns produce optimal file sizes
- [ ] Performance monitoring metrics provide optimization insights
- [ ] Dynamic file pruning reduces data scan effectively

**Next Steps**: Proceed to Lab 5 to learn real-world data patterns

---

### Lab 5: Real-World Data Patterns

**Duration**: 90-120 minutes

**Learning Objectives**:
- Implement Slowly Changing Dimensions (SCD) with Iceberg
- Perform upsert operations efficiently
- Handle batch and streaming data patterns
- Model real-world scenarios with Iceberg tables
- Apply CDC (Change Data Capture) patterns

**Key Skills**:
- SCD Type 2 implementation
- Upsert operations with MERGE
- Batch data loading patterns
- Micro-batch processing
- CDC pattern implementation
- Star schema modeling

**Completion Criteria**:
- [ ] SCD Type 2 maintains complete customer history
- [ ] Upsert operations using MERGE work correctly
- [ ] Batch loading with daily compaction produces clean partitions
- [ ] Micro-batch processing handles incremental data correctly
- [ ] CDC pattern correctly synchronizes changes from source to target
- [ ] Star schema supports complex analytical queries

**Next Steps**: Proceed to Lab 6 to learn performance analysis and UI inspection

---

### Lab 6: Performance & UI - DAG Inspection ⭐

**Duration**: 60-90 minutes

**Learning Objectives**:
- Run complex Iceberg join operations
- Access and navigate the Spark History Server UI
- Inspect DAG (Directed Acyclic Graph) for Spark jobs
- Understand how Iceberg's metadata-only filtering reduces S3 scans
- Analyze query performance and optimization opportunities
- Compare query plans with and without Iceberg optimizations

**Key Skills**:
- Spark History Server navigation
- DAG inspection and analysis
- Query plan interpretation
- Performance measurement and comparison
- Metadata-only filtering verification
- Partition pruning analysis

**Completion Criteria**:
- [ ] Spark History Server UI accessible on port 18080
- [ ] Complex Iceberg join query executed successfully
- [ ] DAG inspected showing query execution plan
- [ ] Query plan shows Iceberg optimizations
- [ ] Partition pruning provides measurable performance improvement
- [ ] File scan metrics confirm reduced data scan
- [ ] Metadata-only filtering eliminates unnecessary file scans
- [ ] Different query patterns produce different DAG structures
- [ ] Performance analysis shows significant speedup ratios

**Key Takeaway**: Iceberg's metadata-only filtering significantly reduces S3 object scans, which you can verify through the Spark History Server's DAG inspection.

---

## 🎓 Learning Outcomes

By completing all labs, you will be able to:

1. **Set up** a complete Iceberg environment from scratch
2. **Create and manage** Iceberg tables with various configurations
3. **Perform** schema evolution without breaking existing data
4. **Optimize** Iceberg tables for better query performance
5. **Implement** real-world data patterns like SCD and CDC
6. **Analyze** query performance using Spark History Server
7. **Understand** how Iceberg's metadata-only filtering reduces data scans

## 🔧 Common Issues and Solutions

### Environment Issues

**Issue**: Components not starting
- **Solution**: Check logs with `kubectl logs -n iceberg <pod-name>` or `docker-compose logs <service>`

**Issue**: Storage connectivity fails
- **Solution**: Verify storage endpoint and credentials in configuration

**Issue**: Polaris health check fails
- **Solution**: Check Polaris logs and ensure it can connect to storage

### Iceberg Issues

**Issue**: Table creation fails
- **Solution**: Check Polaris catalog status and storage connectivity

**Issue**: Partition pruning not working
- **Solution**: Verify partition column types and query predicates

**Issue**: Schema evolution fails
- **Solution**: Ensure new columns are compatible with existing data

### Spark Issues

**Issue**: Spark cannot connect to Iceberg
- **Solution**: Verify Iceberg REST catalog URL and Spark configuration

**Issue**: Event logging not working
- **Solution**: Check S3 permissions and endpoint configuration

### Performance Issues

**Issue**: Queries are slow
- **Solution**: Enable partition predicates, check file sizes, consider compaction

**Issue**: Too many small files
- **Solution**: Implement file compaction with appropriate parameters

## 📊 Progress Tracking

Track your progress through the labs:

- [ ] Lab 1: Environment Setup and Validation
- [ ] Lab 2: Basic Iceberg Operations  
- [ ] Lab 3: Advanced Iceberg Features
- [ ] Lab 4: Iceberg + Spark Optimizations
- [ ] Lab 5: Real-World Data Patterns
- [ ] Lab 6: Performance & UI (DAG Inspection)

## 🎯 Tips for Success

1. **Complete labs in order** - Each builds on the previous
2. **Read the assertions carefully** - They validate your understanding
3. **Experiment freely** - Try different configurations and parameters
4. **Use the Spark History Server** - It's a powerful learning tool
5. **Ask questions** - Why does a query perform better with partitioning?
6. **Document your findings** - Keep notes on what works and what doesn't

## 🚀 Next Steps After Labs

After completing all labs:

1. **Experiment** with your own data and use cases
2. **Optimize** the environment for your specific needs
3. **Extend** the labs with additional scenarios
4. **Share** your learnings with others
5. **Contribute** improvements to the environment

---

**This lab guide provides a structured path to master Apache Iceberg concepts through hands-on practice in a vendor-independent environment.**