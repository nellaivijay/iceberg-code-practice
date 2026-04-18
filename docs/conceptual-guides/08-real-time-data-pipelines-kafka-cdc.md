# Real-Time Data Pipelines with Kafka and CDC

## Overview

This conceptual guide explains the architecture and patterns for building real-time data pipelines using Apache Kafka and Change Data Capture (CDC) with Apache Iceberg. These technologies form the foundation of modern lakehouse architectures that support both real-time and batch processing on the same data.

## Learning Objectives

By the end of this guide, you will understand:

1. The role of Kafka in modern data architectures
2. How CDC enables real-time data synchronization
3. Streaming data patterns and best practices
4. Integration patterns between Kafka, CDC, and Iceberg
5. Performance optimization strategies
6. Operational considerations for production deployments

## Part 1: Apache Kafka Fundamentals

### What is Apache Kafka?

Apache Kafka is a distributed event streaming platform capable of handling trillions of events a day. It provides:

- **High Throughput**: Handles millions of messages per second
- **Low Latency**: Millisecond-level message delivery
- **Scalability**: Horizontal scaling across multiple brokers
- **Durability**: Replicated message storage
- **Fault Tolerance**: Automatic failover and recovery

### Key Kafka Concepts

#### Topics and Partitions

```
Topic: orders
├── Partition 0
│   ├── Message 1 (Offset 0)
│   ├── Message 2 (Offset 1)
│   └── Message 3 (Offset 2)
├── Partition 1
│   ├── Message 1 (Offset 0)
│   └── Message 2 (Offset 1)
└── Partition 2
    ├── Message 1 (Offset 0)
    └── Message 2 (Offset 1)
```

- **Topic**: Logical channel for organizing messages
- **Partition**: Ordered log within a topic
- **Offset**: Unique identifier for each message within a partition

#### Producers and Consumers

```
Producer → Kafka Topic → Consumer Group
                ↓
           Consumer Group
                ↓
           Consumer Group
```

- **Producer**: Applications that publish messages to Kafka topics
- **Consumer**: Applications that subscribe to and process messages
- **Consumer Group**: Group of consumers that share topic consumption

#### Message Ordering and Guarantees

Kafka provides ordering guarantees at the partition level:
- Messages in the same partition are delivered in order
- Consumers in the same consumer group share partitions
- Each partition is consumed by only one consumer in a group

### Kafka in Data Architecture

```
┌─────────────┐
│   Source    │
│  Systems    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Kafka     │ ← Event Streaming Layer
│   Cluster   │
└──────┬──────┘
       │
       ├──────────────┬──────────────┐
       ↓              ↓              ↓
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  Streaming  │ │   Batch     │ │   Serving   │
│  Processing │ │ Processing │ │   Layer     │
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │              │              │
       ↓              ↓              ↓
┌─────────────────────────────────────────┐
│         Iceberg Data Lakehouse          │
└─────────────────────────────────────────┘
```

## Part 2: Change Data Capture (CDC)

### What is CDC?

Change Data Capture is a technology that identifies and captures changes made to data in a database and delivers those changes in real-time to a downstream process or system.

### CDC Approaches

#### 1. Log-Based CDC (Recommended)

```
Database Binary Log → Debezium → Kafka → Iceberg
```

**Advantages:**
- Non-invasive to source database
- Captures all changes (including deletes)
- Low overhead on source system
- Provides change context (before/after values)

**Tools:**
- Debezium (Open Source)
- Oracle GoldenGate
- Attunity CDC
- Qlik Replicate

#### 2. Query-Based CDC

```
Database → Polling Queries → Iceberg
```

**Advantages:**
- Simple to implement
- Works with any database
- No special configuration needed

**Disadvantages:**
- High overhead on source database
- May miss changes between polls
- Doesn't capture deletes easily

#### 3. Trigger-Based CDC

```
Database → Triggers → Change Tables → Iceberg
```

**Advantages:**
- Real-time capture
- Customizable logic

**Disadvantages:**
- High impact on database performance
- Complex to maintain
- May not capture all changes

### Debezium Architecture

```
┌─────────────┐
│   MySQL     │
│  Database   │
└──────┬──────┘
       │
       │ Binary Log
       ↓
┌─────────────┐
│  Debezium   │ ← CDC Connector
│  Connector  │
└──────┬──────┘
       │
       │ CDC Events
       ↓
┌─────────────┐
│   Kafka     │
│   Topics    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Spark      │ ← Streaming Processing
│  Streaming  │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Iceberg   │
│   Tables    │
└─────────────┘
```

### CDC Event Format

Debezium produces events in the following format:

```json
{
  "before": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  },
  "after": {
    "id": 1,
    "name": "John Smith",
    "email": "john.smith@example.com"
  },
  "op": "u",  // c=create, r=read, u=update, d=delete
  "ts_ms": 1704067200000,
  "source": {
    "version": "2.5.0.Final",
    "connector": "mysql",
    "name": "cdc-mysql",
    "ts_ms": 1704067200000,
    "snapshot": "false",
    "db": "cdc_source",
    "table": "customers",
    "server_id": 184054
  }
}
```

## Part 3: Streaming Data Patterns

### Pattern 1: Lambda Architecture

```
┌─────────────┐
│   Data      │
│   Source    │
└──────┬──────┘
       │
       ├──────────────────┐
       ↓                  ↓
┌─────────────┐    ┌─────────────┐
│  Speed      │    │  Batch      │
│  Layer      │    │  Layer      │
│  (Real-time)│    │  (Historical)│
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                ↓
         ┌─────────────┐
         │  Serving    │
         │  Layer      │
         └─────────────┘
```

**Use Cases:**
- Real-time analytics with historical context
- Machine learning feature pipelines
- Fraud detection and prevention

### Pattern 2: Kappa Architecture

```
┌─────────────┐
│   Data      │
│   Source    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Streaming  │
│  Processing │ ← Single processing layer
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Serving    │
│  Layer      │
└─────────────┘
```

**Advantages over Lambda:**
- Simpler architecture
- Single codebase
- Easier to maintain
- Reduced operational complexity

### Pattern 3: Event Sourcing

```
┌─────────────┐
│   Command   │
│   Handler   │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Event     │
│   Store     │ ← Kafka + Iceberg
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Projection │
│  Builder    │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Read Model │
└─────────────┘
```

**Benefits:**
- Complete audit trail
- Temporal queries (time travel)
- Event replay capability
- Scalable read models

## Part 4: Integration Patterns

### Pattern 1: Direct Kafka to Iceberg

```
Kafka → Spark Streaming → Iceberg
```

**Implementation:**
```scala
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "orders")
  .load()

val processedDF = kafkaDF
  .select(from_json(col("value").cast("string"), schema).as("data"))
  .select("data.*")

processedDF.writeStream
  .format("iceberg")
  .outputMode("append")
  .toTable("iceberg.stream.orders")
```

**Use Cases:**
- Real-time data ingestion
- Stream processing with state
- Complex event processing

### Pattern 2: CDC via Kafka to Iceberg

```
Database → Debezium → Kafka → Spark Streaming → Iceberg
```

**Implementation:**
```scala
val cdcDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "cdc-mysql.cdc_source.customers")
  .load()

val parsedCDC = cdcDF
  .select(from_json(col("value").cast("string"), cdcSchema).as("data"))
  .select(
    col("data.after.id"),
    col("data.after.name"),
    col("data.op").as("__op"),
    col("data.ts_ms").as("__ts_ms")
  )

parsedCDC.writeStream
  .foreachBatch { (batchDF, batchId) =>
    // Apply CDC changes using MERGE
    batchDF.createOrReplaceTempView("cdc_changes")
    spark.sql("""
      MERGE INTO iceberg.cdc.customers AS target
      USING cdc_changes AS source
      ON target.id = source.id
      WHEN MATCHED AND source.__op = 'u' THEN UPDATE SET *
      WHEN MATCHED AND source.__op = 'd' THEN DELETE
      WHEN NOT MATCHED AND source.__op IN ('c', 'r') THEN INSERT *
    """)
  }
  .start()
```

**Use Cases:**
- Database replication
- Real-time data synchronization
- Change auditing

### Pattern 3: Multi-Topic Join

```
Kafka Topic 1 ──┐
                ├──→ Spark Streaming → Iceberg
Kafka Topic 2 ──┤
                │
Kafka Topic 3 ──┘
```

**Implementation:**
```scala
val ordersDF = spark.readStream
  .format("kafka")
  .option("subscribe", "orders")
  .load()

val customersDF = spark.readStream
  .format("kafka")
  .option("subscribe", "customers")
  .load()

val productsDF = spark.readStream
  .format("kafka")
  .option("subscribe", "products")
  .load()

val joinedDF = ordersDF
  .join(customersDF, "customer_id")
  .join(productsDF, "product_id")

joinedDF.writeStream
  .format("iceberg")
  .toTable("iceberg.enriched.orders")
```

**Use Cases:**
- Data enrichment
- Real-time joins
- Complex event processing

## Part 5: Performance Optimization

### Kafka Optimization

#### Producer Optimization

```properties
# Batch size
batch.size=16384

# Compression
compression.type=snappy

# Acknowledgment
acks=all

# Retries
retries=3

# Linger time
linger.ms=10
```

#### Consumer Optimization

```properties
# Fetch size
fetch.min.bytes=1024
fetch.max.bytes=52428800

# Session timeout
session.timeout.ms=30000

# Heartbeat interval
heartbeat.interval.ms=3000

# Max poll records
max.poll.records=500
```

### Spark Streaming Optimization

#### Checkpointing

```scala
spark.sql.streaming.checkpointLocation
```

- Store checkpoints in durable storage
- Use S3/GCS for checkpoint durability
- Implement checkpoint cleanup

#### Backpressure Handling

```scala
spark.streaming.backpressure.enabled=true
spark.streaming.backpressure.initialRate=1000
spark.streaming.backpressure.maxRate=10000
```

#### State Management

```scala
// Use stateful operations
val statefulDF = inputStream
  .withWatermark("timestamp", "10 minutes")
  .groupBy(
    window(col("timestamp"), "5 minutes"),
    col("key")
  )
  .agg(count("*"))
```

### Iceberg Optimization

#### Partitioning Strategy

```scala
// Time-based partitioning
PARTITIONED BY (days(order_date))

// Category-based partitioning
PARTITIONED BY (category)

// Composite partitioning
PARTITIONED BY (days(order_date), category)
```

#### File Size Optimization

```properties
# Target file size
write.target-file-size-bytes=536870912

# File format
write.format.default=parquet

# Compression
write.compression.codec=zstd
```

## Part 6: Operational Considerations

### Monitoring

#### Kafka Monitoring

- **Broker Metrics**: Messages per second, byte rate, request latency
- **Topic Metrics**: Partition size, consumer lag, message throughput
- **Consumer Metrics**: Commit rate, fetch rate, lag

#### CDC Monitoring

- **Connector Status**: Connector health, snapshot progress
- **Event Metrics**: Events per second, event latency, error rate
- **Database Metrics**: Binlog lag, database load

#### Iceberg Monitoring

- **Table Metrics**: Snapshot count, file count, data size
- **Query Metrics**: Query latency, scan statistics, planning time
- **Storage Metrics**: Storage usage, file size distribution

### Error Handling

#### Kafka Error Handling

```scala
val stream = kafkaDF
  .writeStream
  .foreachBatch { (batchDF, batchId) =>
    try {
      batchDF.write.format("iceberg").saveAsTable("...")
    } catch {
      case e: Exception =>
        // Log error
        // Write to dead letter topic
        kafkaDLT.send(batchDF)
    }
  }
  .option("checkpointLocation", "...")
  .start()
```

#### CDC Error Handling

- Implement retry logic for transient failures
- Use dead letter queues for failed events
- Monitor connector health and restart if needed
- Validate data quality before applying changes

### Exactly-Once Semantics

#### Kafka Exactly-Once

```properties
enable.idempotence=true
max.in.flight.requests.per.connection=5
transactional.id=unique-id
```

#### Spark Exactly-Once

```scala
spark.sql.streaming.forceDeleteTempCheckpointLocation=true
```

#### Iceberg Exactly-Once

- Use atomic commits
- Implement idempotent operations
- Use snapshot isolation for reads

## Part 7: Best Practices

### Design Principles

1. **Schema Evolution**: Design schemas to evolve over time
2. **Idempotency**: Ensure operations can be safely retried
3. **Backward Compatibility**: Maintain compatibility with existing consumers
4. **Data Quality**: Validate data at ingestion time
5. **Monitoring**: Implement comprehensive monitoring

### Operational Best Practices

1. **Testing**: Test streaming pipelines thoroughly before production
2. **Gradual Rollout**: Roll out changes gradually with canary deployments
3. **Capacity Planning**: Plan for peak loads and growth
4. **Documentation**: Document pipeline architecture and dependencies
5. **Disaster Recovery**: Implement backup and recovery procedures

### Security Considerations

1. **Authentication**: Use proper authentication for all components
2. **Authorization**: Implement fine-grained access control
3. **Encryption**: Encrypt data in transit and at rest
4. **Auditing**: Log all data access and modifications
5. **Compliance**: Ensure compliance with data protection regulations

## Summary

This guide covered:

1. **Kafka Fundamentals**: Understanding Kafka architecture and concepts
2. **CDC Patterns**: Different approaches to change data capture
3. **Streaming Patterns**: Lambda, Kappa, and Event Sourcing architectures
4. **Integration Patterns**: How to integrate Kafka, CDC, and Iceberg
5. **Performance Optimization**: Strategies for optimizing each component
6. **Operational Considerations**: Monitoring, error handling, and exactly-once semantics
7. **Best Practices**: Design principles and operational guidelines

By understanding these concepts and patterns, you can design and implement robust real-time data pipelines that leverage Kafka, CDC, and Iceberg to build modern lakehouse architectures.

## Related Labs

- Lab 8: Kafka Integration with Iceberg
- Lab 9: Real CDC with Debezium
- Lab 11: Multi-Engine Lakehouse