# Lab 8: Kafka Integration with Iceberg

## Overview

In this lab, you will learn how to integrate Apache Kafka with Apache Iceberg for real-time data ingestion. You will build a complete streaming pipeline that:

- Produces events to Kafka topics
- Consumes events from Kafka using Spark Structured Streaming
- Writes streaming data to Iceberg tables
- Performs real-time analytics on streaming data

## Prerequisites

- Complete Labs 0-7
- Docker and Docker Compose installed
- Basic understanding of Kafka concepts (topics, producers, consumers)
- Spark Structured Streaming knowledge

## Learning Objectives

By the end of this lab, you will be able to:

1. Set up and configure Kafka for real-time data streaming
2. Produce events to Kafka topics using various methods
3. Consume Kafka events using Spark Structured Streaming
4. Write streaming data to Iceberg tables with proper schema evolution
5. Implement exactly-once processing semantics
6. Monitor and debug streaming applications
7. Handle streaming data quality and validation

## Lab Setup

### 1. Start the Infrastructure

Start the complete infrastructure including Kafka:

```bash
cd /home/ramdov/projects/iceberg-practice-env
docker-compose up -d minio polaris spark-master spark-worker zookeeper kafka kafka-ui
```

Verify services are running:

```bash
docker-compose ps
```

### 2. Create Kafka Topics

Create topics for different event types:

```bash
# Create topics
docker exec kafka kafka-topics --create --topic orders --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
docker exec kafka kafka-topics --create --topic customers --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
docker exec kafka kafka-topics --create --topic products --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
docker exec kafka kafka-topics --create --topic inventory_events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
```

Verify topics:

```bash
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

### 3. Access Kafka UI

Open your browser and navigate to:
- Kafka UI: http://localhost:8085

This provides a visual interface for monitoring topics, consumers, and messages.

## Part 1: Producing Events to Kafka

### Step 1.1: Create a Python Producer

Create a Python script to produce order events:

```python
# scripts/kafka_producer.py
import json
import time
import random
from datetime import datetime
from kafka import KafkaProducer

# Configure producer
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda x: json.dumps(x).encode('utf-8')
)

# Sample customer and product data
customers = [
    {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
    {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com'},
    {'id': 3, 'name': 'Bob Johnson', 'email': 'bob@example.com'},
]

products = [
    {'id': 1, 'name': 'Laptop Pro 15"', 'price': 1299.99},
    {'id': 2, 'name': 'Wireless Mouse', 'price': 29.99},
    {'id': 3, 'name': 'Mechanical Keyboard', 'price': 149.99},
]

def generate_order():
    customer = random.choice(customers)
    product = random.choice(products)
    quantity = random.randint(1, 5)
    
    return {
        'order_id': int(time.time() * 1000),
        'customer_id': customer['id'],
        'customer_name': customer['name'],
        'customer_email': customer['email'],
        'product_id': product['id'],
        'product_name': product['name'],
        'quantity': quantity,
        'unit_price': product['price'],
        'total_amount': product['price'] * quantity,
        'order_date': datetime.utcnow().isoformat(),
        'status': random.choice(['pending', 'processing', 'shipped', 'delivered'])
    }

# Produce orders
print("Starting order producer...")
for i in range(100):
    order = generate_order()
    producer.send('orders', value=order)
    print(f"Sent order {i+1}: {order['order_id']}")
    time.sleep(random.uniform(0.1, 0.5))

producer.flush()
print("Order production complete")
```

Run the producer:

```bash
pip install kafka-python
python scripts/kafka_producer.py
```

### Step 1.2: Verify Messages in Kafka

Check messages in the orders topic:

```bash
docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic orders --from-beginning --max-messages 10
```

Or use the Kafka UI at http://localhost:8085

## Part 2: Consuming Kafka Events with Spark Structured Streaming

### Step 2.1: Create Iceberg Tables for Streaming Data

Create Iceberg tables to store streaming data:

```scala
// scripts/create_streaming_tables.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Create Streaming Tables")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Create orders table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.stream.orders (
    order_id BIGINT,
    customer_id INT,
    customer_name STRING,
    customer_email STRING,
    product_id INT,
    product_name STRING,
    quantity INT,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    order_date TIMESTAMP,
    status STRING,
    processed_timestamp TIMESTAMP
  )
  USING iceberg
  PARTITIONED BY (days(order_date))
""")

// Create customers table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.stream.customers (
    customer_id INT,
    name STRING,
    email STRING,
    phone STRING,
    address STRING,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    processed_timestamp TIMESTAMP
  )
  USING iceberg
  PARTITIONED BY (bucket(16, customer_id))
""")

// Create products table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.stream.products (
    product_id INT,
    name STRING,
    description STRING,
    price DECIMAL(10, 2),
    category STRING,
    stock_quantity INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    processed_timestamp TIMESTAMP
  )
  USING iceberg
  PARTITIONED BY (category)
""")

// Create inventory_events table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.stream.inventory_events (
    event_id BIGINT,
    product_id INT,
    event_type STRING,
    quantity_change INT,
    previous_quantity INT,
    new_quantity INT,
    event_timestamp TIMESTAMP,
    reason STRING,
    processed_timestamp TIMESTAMP
  )
  USING iceberg
  PARTITIONED BY (hours(event_timestamp))
""")

println("Streaming tables created successfully")
```

Run the table creation:

```bash
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.0 \
  scripts/create_streaming_tables.scala
```

### Step 2.2: Create Spark Structured Streaming Consumer

Create a streaming consumer to read from Kafka and write to Iceberg:

```scala
// scripts/kafka_to_iceberg_stream.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("Kafka to Iceberg Stream")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/kafka-iceberg")
  .getOrCreate()

// Read from Kafka
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "orders")
  .option("startingOffsets", "latest")
  .load()

// Parse JSON and transform
val ordersDF = kafkaDF
  .select(from_json(col("value").cast("string"), 
    """
    {
      "order_id": "LONG",
      "customer_id": "INTEGER",
      "customer_name": "STRING",
      "customer_email": "STRING",
      "product_id": "INTEGER",
      "product_name": "STRING",
      "quantity": "INTEGER",
      "unit_price": "DECIMAL",
      "total_amount": "DECIMAL",
      "order_date": "STRING",
      "status": "STRING"
    }
    """).as("data"))
  .select(
    col("data.order_id"),
    col("data.customer_id"),
    col("data.customer_name"),
    col("data.customer_email"),
    col("data.product_id"),
    col("data.product_name"),
    col("data.quantity"),
    col("data.unit_price"),
    col("data.total_amount"),
    to_timestamp(col("data.order_date")).as("order_date"),
    col("data.status"),
    current_timestamp().as("processed_timestamp")
  )

// Write to Iceberg
val query = ordersDF.writeStream
  .format("iceberg")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/kafka-iceberg/orders")
  .toTable("iceberg.stream.orders")

query.awaitTermination()
```

Run the streaming consumer:

```bash
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.0,org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0 \
  scripts/kafka_to_iceberg_stream.scala
```

### Step 2.3: Monitor the Streaming Job

Monitor the streaming job through Spark UI:
- Spark Master UI: http://localhost:8080
- Spark Worker UI: http://localhost:8081

## Part 3: Real-Time Analytics on Streaming Data

### Step 3.1: Query Streaming Data in Real-Time

Create real-time analytics queries:

```scala
// scripts/streaming_analytics.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Streaming Analytics")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Real-time order statistics
val orderStats = spark.sql("""
  SELECT 
    status,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
  FROM iceberg.stream.orders
  WHERE order_date >= current_timestamp() - INTERVAL 1 HOUR
  GROUP BY status
""")

orderStats.show()

// Real-time product popularity
val productPopularity = spark.sql("""
  SELECT 
    product_id,
    product_name,
    COUNT(*) as order_count,
    SUM(quantity) as total_quantity,
    SUM(total_amount) as total_revenue
  FROM iceberg.stream.orders
  WHERE order_date >= current_timestamp() - INTERVAL 1 HOUR
  GROUP BY product_id, product_name
  ORDER BY total_revenue DESC
  LIMIT 10
""")

productPopularity.show()

// Real-time customer activity
val customerActivity = spark.sql("""
  SELECT 
    customer_id,
    customer_name,
    customer_email,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
  FROM iceberg.stream.orders
  WHERE order_date >= current_timestamp() - INTERVAL 24 HOURS
  GROUP BY customer_id, customer_name, customer_email
  ORDER BY total_spent DESC
  LIMIT 10
""")

customerActivity.show()
```

### Step 3.2: Create Streaming Aggregations

Create streaming aggregation queries:

```scala
// scripts/streaming_aggregations.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("Streaming Aggregations")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/aggregations")
  .getOrCreate()

// Read from Kafka
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "orders")
  .option("startingOffsets", "latest")
  .load()

// Parse and transform
val ordersDF = kafkaDF
  .select(from_json(col("value").cast("string"), 
    """
    {
      "order_id": "LONG",
      "customer_id": "INTEGER",
      "customer_name": "STRING",
      "customer_email": "STRING",
      "product_id": "INTEGER",
      "product_name": "STRING",
      "quantity": "INTEGER",
      "unit_price": "DECIMAL",
      "total_amount": "DECIMAL",
      "order_date": "STRING",
      "status": "STRING"
    }
    """).as("data"))
  .select(
    col("data.order_id"),
    col("data.customer_id"),
    col("data.product_id"),
    col("data.total_amount"),
    to_timestamp(col("data.order_date")).as("order_date"),
    col("data.status")
  )

// 1-minute window aggregation
val oneMinuteAgg = ordersDF
  .withWatermark("order_date", "1 minutes")
  .groupBy(
    window(col("order_date"), "1 minute"),
    col("status")
  )
  .agg(
    count("*").as("order_count"),
    sum("total_amount").as("total_revenue")
  )

val query1 = oneMinuteAgg.writeStream
  .format("console")
  .outputMode("update")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/aggregations/1min")
  .start()

// 5-minute window aggregation
val fiveMinuteAgg = ordersDF
  .withWatermark("order_date", "5 minutes")
  .groupBy(
    window(col("order_date"), "5 minutes"),
    col("product_id")
  )
  .agg(
    count("*").as("order_count"),
    sum("total_amount").as("total_revenue"),
    avg("total_amount").as("avg_order_value")
  )

val query2 = fiveMinuteAgg.writeStream
  .format("console")
  .outputMode("update")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/aggregations/5min")
  .start()

query1.awaitTermination()
query2.awaitTermination()
```

## Part 4: Exactly-Once Processing

### Step 4.1: Configure Exactly-Once Semantics

Configure the streaming job for exactly-once processing:

```scala
// scripts/exactly_once_stream.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("Exactly-Once Stream")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/exactly-once")
  // Exactly-once configuration
  .config("spark.sql.streaming.forceDeleteTempCheckpointLocation", "true")
  .getOrCreate()

// Read from Kafka with isolation level
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "orders")
  .option("startingOffsets", "latest")
  .option("isolation.level", "read_committed")
  .option("failOnDataLoss", "false")
  .load()

// Parse and transform with deduplication
val ordersDF = kafkaDF
  .select(
    col("key").cast("string").as("kafka_key"),
    from_json(col("value").cast("string"), 
    """
    {
      "order_id": "LONG",
      "customer_id": "INTEGER",
      "customer_name": "STRING",
      "customer_email": "STRING",
      "product_id": "INTEGER",
      "product_name": "STRING",
      "quantity": "INTEGER",
      "unit_price": "DECIMAL",
      "total_amount": "DECIMAL",
      "order_date": "STRING",
      "status": "STRING"
    }
    """).as("data"),
    col("topic"),
    col("partition"),
    col("offset")
  )
  .select(
    col("data.order_id"),
    col("data.customer_id"),
    col("data.customer_name"),
    col("data.customer_email"),
    col("data.product_id"),
    col("data.product_name"),
    col("data.quantity"),
    col("data.unit_price"),
    col("data.total_amount"),
    to_timestamp(col("data.order_date")).as("order_date"),
    col("data.status"),
    current_timestamp().as("processed_timestamp"),
    col("topic"),
    col("partition"),
    col("offset")
  )

// Write to Iceberg with exactly-once semantics
val query = ordersDF.writeStream
  .format("iceberg")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/exactly-once/orders")
  .option("fanout.enabled", "true")
  .toTable("iceberg.stream.orders")

query.awaitTermination()
```

## Part 5: Data Quality and Validation

### Step 5.1: Add Data Quality Checks

Implement data quality validation in the streaming pipeline:

```scala
// scripts/streaming_data_quality.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("Streaming Data Quality")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/data-quality")
  .getOrCreate()

// Read from Kafka
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "orders")
  .option("startingOffsets", "latest")
  .load()

// Parse and validate
val ordersDF = kafkaDF
  .select(from_json(col("value").cast("string"), 
    """
    {
      "order_id": "LONG",
      "customer_id": "INTEGER",
      "customer_name": "STRING",
      "customer_email": "STRING",
      "product_id": "INTEGER",
      "product_name": "STRING",
      "quantity": "INTEGER",
      "unit_price": "DECIMAL",
      "total_amount": "DECIMAL",
      "order_date": "STRING",
      "status": "STRING"
    }
    """).as("data"))
  .select(
    col("data.order_id"),
    col("data.customer_id"),
    col("data.customer_name"),
    col("data.customer_email"),
    col("data.product_id"),
    col("data.product_name"),
    col("data.quantity"),
    col("data.unit_price"),
    col("data.total_amount"),
    to_timestamp(col("data.order_date")).as("order_date"),
    col("data.status")
  )

// Data quality checks
val validatedOrders = ordersDF
  .filter(col("order_id").isNotNull)
  .filter(col("customer_id").isNotNull)
  .filter(col("product_id").isNotNull)
  .filter(col("quantity") > 0)
  .filter(col("unit_price") > 0)
  .filter(col("total_amount") > 0)
  .filter(col("order_date").isNotNull)
  .filter(col("status").isNotNull)
  .filter(col("customer_email").rlike("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"))
  .withColumn("quality_score", lit(1.0))
  .withColumn("validation_timestamp", current_timestamp())

// Capture invalid records
val invalidOrders = ordersDF
  .join(validatedOrders, Seq("order_id"), "left_anti")
  .withColumn("error_reason", lit("Data validation failed"))
  .withColumn("error_timestamp", current_timestamp())

// Write valid orders to main table
val validQuery = validatedOrders
  .withColumn("processed_timestamp", current_timestamp())
  .writeStream
  .format("iceberg")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/data-quality/valid")
  .toTable("iceberg.stream.orders")

// Write invalid orders to error table
val invalidQuery = invalidOrders.writeStream
  .format("iceberg")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/data-quality/invalid")
  .toTable("iceberg.stream.orders_errors")

validQuery.awaitTermination()
invalidQuery.awaitTermination()
```

### Step 5.2: Monitor Data Quality

Create data quality monitoring queries:

```scala
// scripts/data_quality_monitoring.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Data Quality Monitoring")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Data quality metrics
val qualityMetrics = spark.sql("""
  SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(DISTINCT product_id) as unique_products,
    AVG(quantity) as avg_quantity,
    AVG(total_amount) as avg_order_value,
    MIN(order_date) as earliest_order,
    MAX(order_date) as latest_order
  FROM iceberg.stream.orders
""")

qualityMetrics.show()

// Error monitoring
val errorMetrics = spark.sql("""
  SELECT 
    COUNT(*) as error_count,
    error_reason,
    COUNT(DISTINCT order_id) as affected_orders,
    MIN(error_timestamp) as first_error,
    MAX(error_timestamp) as last_error
  FROM iceberg.stream.orders_errors
  GROUP BY error_reason
""")

errorMetrics.show()

// Data freshness
val dataFreshness = spark.sql("""
  SELECT 
    current_timestamp() - MAX(processed_timestamp) as processing_lag_seconds,
    current_timestamp() - MAX(order_date) as data_lag_seconds
  FROM iceberg.stream.orders
""")

dataFreshness.show()
```

## Part 6: Schema Evolution

### Step 6.1: Handle Schema Evolution

Implement schema evolution for streaming data:

```scala
// scripts/schema_evolution_stream.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("Schema Evolution Stream")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/schema-evolution")
  // Schema evolution configuration
  .config("spark.sql.streaming.schemaInference", "true")
  .getOrCreate()

// Read from Kafka with schema evolution
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "orders")
  .option("startingOffsets", "latest")
  .load()

// Parse JSON with flexible schema
val ordersDF = kafkaDF
  .select(from_json(col("value").cast("string"), 
    """
    {
      "order_id": "LONG",
      "customer_id": "INTEGER",
      "customer_name": "STRING",
      "customer_email": "STRING",
      "product_id": "INTEGER",
      "product_name": "STRING",
      "quantity": "INTEGER",
      "unit_price": "DECIMAL",
      "total_amount": "DECIMAL",
      "order_date": "STRING",
      "status": "STRING",
      "discount_code": "STRING",
      "shipping_method": "STRING",
      "payment_method": "STRING"
    }
    """).as("data"))
  .select(
    col("data.order_id"),
    col("data.customer_id"),
    col("data.customer_name"),
    col("data.customer_email"),
    col("data.product_id"),
    col("data.product_name"),
    col("data.quantity"),
    col("data.unit_price"),
    col("data.total_amount"),
    to_timestamp(col("data.order_date")).as("order_date"),
    col("data.status"),
    col("data.discount_code"),
    col("data.shipping_method"),
    col("data.payment_method"),
    current_timestamp().as("processed_timestamp")
  )

// Handle schema evolution
val finalDF = ordersDF
  .withColumn("discount_code", coalesce(col("discount_code"), lit("NONE")))
  .withColumn("shipping_method", coalesce(col("shipping_method"), lit("STANDARD")))
  .withColumn("payment_method", coalesce(col("payment_method"), lit("CREDIT_CARD")))

// Write to Iceberg
val query = finalDF.writeStream
  .format("iceberg")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/schema-evolution/orders")
  .toTable("iceberg.stream.orders")

query.awaitTermination()
```

### Step 6.2: Evolve Schema

Add new columns to the Iceberg table:

```scala
// scripts/evolve_schema.scala
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("Evolve Schema")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Add new columns
spark.sql("""
  ALTER TABLE iceberg.stream.orders 
  ADD COLUMN discount_code STRING
""")

spark.sql("""
  ALTER TABLE iceberg.stream.orders 
  ADD COLUMN shipping_method STRING
""")

spark.sql("""
  ALTER TABLE iceberg.stream.orders 
  ADD COLUMN payment_method STRING
""")

spark.sql("""
  ALTER TABLE iceberg.stream.orders 
  ADD COLUMN customer_segment STRING
""")

println("Schema evolved successfully")
```

## Cleanup

### Stop the Streaming Infrastructure

```bash
# Stop all services
docker-compose down

# Remove volumes (optional)
docker-compose down -v
```

### Clean up Kafka Topics

```bash
docker exec kafka kafka-topics --delete --topic orders --bootstrap-server localhost:9092
docker exec kafka kafka-topics --delete --topic customers --bootstrap-server localhost:9092
docker exec kafka kafka-topics --delete --topic products --bootstrap-server localhost:9092
docker exec kafka kafka-topics --delete --topic inventory_events --bootstrap-server localhost:9092
```

## Challenges

### Challenge 1: Multi-Topic Streaming

Extend your streaming application to consume from multiple Kafka topics (orders, customers, products) simultaneously and join the data in real-time.

### Challenge 2: Late Data Handling

Implement handling for late-arriving data using watermarking and update strategies.

### Challenge 3: Streaming ML

Implement a simple machine learning model that predicts order status based on streaming order data.

### Challenge 4: Backpressure Handling

Configure your streaming application to handle backpressure when Kafka produces data faster than it can be processed.

## Verification

Verify your implementation:

1. Check that Kafka topics are receiving events
2. Verify that Spark Structured Streaming is consuming events
3. Confirm that Iceberg tables are being populated with streaming data
4. Validate that real-time analytics queries return correct results
5. Test data quality checks are working
6. Verify schema evolution doesn't break the streaming pipeline

## Next Steps

- Lab 9: Real CDC with Debezium
- Lab 10: Spring Boot with Iceberg
- Lab 11: Multi-Engine Lakehouse