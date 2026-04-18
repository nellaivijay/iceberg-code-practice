# Lab 9: Real CDC with Debezium

## Overview

In this lab, you will learn how to implement real Change Data Capture (CDC) using Debezium to capture database changes and stream them to Iceberg. This is a critical pattern for building real-time data pipelines that keep your data lakehouse in sync with operational databases.

## Prerequisites

- Complete Lab 8 (Kafka Integration)
- Docker and Docker Compose installed
- Basic understanding of database concepts (tables, primary keys, transactions)
- Knowledge of CDC concepts and Debezium

## Learning Objectives

By the end of this lab, you will be able to:

1. Configure Debezium to capture MySQL database changes
2. Set up MySQL for CDC with proper binlog configuration
3. Create Debezium connectors for different tables
4. Stream CDC events to Kafka topics
5. Consume CDC events with Spark Structured Streaming
6. Apply CDC changes to Iceberg tables (inserts, updates, deletes)
7. Handle schema evolution and data type conversions
8. Implement exactly-once CDC processing
9. Monitor and troubleshoot CDC pipelines

## Lab Setup

### 1. Start the Complete Infrastructure

Start all services including MySQL and Debezium:

```bash
cd /home/ramdov/projects/iceberg-practice-env
docker-compose up -d minio polaris spark-master spark-worker zookeeper kafka kafka-ui mysql debezium
```

Verify services are running:

```bash
docker-compose ps
```

### 2. Initialize MySQL Database

Initialize the MySQL database with sample data:

```bash
docker-compose --profile with-cdc-init up mysql-init
```

Or manually run the init script:

```bash
docker exec mysql mysql -uroot -piceberg_root cdc_source < /docker-entrypoint-initdb.d/init-cdc.sql
```

### 3. Verify MySQL Configuration

Verify MySQL is configured for CDC:

```bash
docker exec mysql mysql -uroot -piceberg_root -e "SHOW VARIABLES LIKE 'binlog%';"
docker exec mysql mysql -uroot -piceberg_root -e "SHOW MASTER STATUS;"
```

### 4. Access Debezium UI

Debezium provides a REST API for managing connectors:
- Debezium Connect API: http://localhost:8083

## Part 1: Configure Debezium Connectors

### Step 1.1: Create Debezium Connector for Customers Table

Create a connector configuration for the customers table:

```json
{
  "name": "customers-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.server.id": "184054",
    "database.server.name": "cdc-mysql",
    "database.include.list": "cdc_source",
    "table.include.list": "cdc_source.customers",
    "database.history.kafka.bootstrap.servers": "kafka:9092",
    "database.history.kafka.topic": "schema-changes.customers",
    "include.schema.changes": "true",
    "snapshot.mode": "initial",
    "snapshot.locking.mode": "minimal",
    "snapshot.fetch.size": "1000",
    "binary.handling.mode": "base64",
    "time.precision.mode": "connect",
    "decimal.handling.mode": "double",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "true"
  }
}
```

Create the connector:

```bash
curl -X POST -H "Content-Type: application/json" --data @scripts/connectors/customers-connector.json http://localhost:8083/connectors
```

Verify the connector status:

```bash
curl http://localhost:8083/connectors/customers-connector/status
```

### Step 1.2: Create Connectors for Other Tables

Create connectors for products, orders, and order_items:

**Products Connector:**

```json
{
  "name": "products-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.server.id": "184055",
    "database.server.name": "cdc-mysql",
    "database.include.list": "cdc_source",
    "table.include.list": "cdc_source.products",
    "database.history.kafka.bootstrap.servers": "kafka:9092",
    "database.history.kafka.topic": "schema-changes.products",
    "include.schema.changes": "true",
    "snapshot.mode": "initial",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "true"
  }
}
```

**Orders Connector:**

```json
{
  "name": "orders-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.server.id": "184056",
    "database.server.name": "cdc-mysql",
    "database.include.list": "cdc_source",
    "table.include.list": "cdc_source.orders",
    "database.history.kafka.bootstrap.servers": "kafka:9092",
    "database.history.kafka.topic": "schema-changes.orders",
    "include.schema.changes": "true",
    "snapshot.mode": "initial",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "true"
  }
}
```

**Order Items Connector:**

```json
{
  "name": "order-items-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.server.id": "184057",
    "database.server.name": "cdc-mysql",
    "database.include.list": "cdc_source",
    "table.include.list": "cdc_source.order_items",
    "database.history.kafka.bootstrap.servers": "kafka:9092",
    "database.history.kafka.topic": "schema-changes.order_items",
    "include.schema.changes": "true",
    "snapshot.mode": "initial",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "true"
  }
}
```

Create all connectors:

```bash
curl -X POST -H "Content-Type: application/json" --data @scripts/connectors/products-connector.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" --data @scripts/connectors/orders-connector.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" --data @scripts/connectors/order-items-connector.json http://localhost:8083/connectors
```

### Step 1.3: Verify Connectors

List all connectors:

```bash
curl http://localhost:8083/connectors
```

Check connector status:

```bash
curl http://localhost:8083/connectors/customers-connector/status
curl http://localhost:8083/connectors/products-connector/status
curl http://localhost:8083/connectors/orders-connector/status
curl http://localhost:8083/connectors/order-items-connector/status
```

### Step 1.4: Verify Kafka Topics

Check that Debezium created the Kafka topics:

```bash
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

You should see topics like:
- `cdc-mysql.cdc_source.customers`
- `cdc-mysql.cdc_source.products`
- `cdc-mysql.cdc_source.orders`
- `cdc-mysql.cdc_source.order_items`

## Part 2: Create Iceberg Tables for CDC Data

### Step 2.1: Create CDC Tables in Iceberg

Create Iceberg tables to store CDC data:

```scala
// scripts/create_cdc_tables.scala
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("Create CDC Tables")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Create customers CDC table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.cdc.customers (
    id INT,
    name STRING,
    email STRING,
    phone STRING,
    address STRING,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    __op STRING,
    __ts_ms TIMESTAMP,
    __source STRING,
    __table STRING
  )
  USING iceberg
  PARTITIONED BY (days(__ts_ms))
""")

// Create products CDC table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.cdc.products (
    id INT,
    name STRING,
    description STRING,
    price DECIMAL(10, 2),
    category STRING,
    stock_quantity INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    __op STRING,
    __ts_ms TIMESTAMP,
    __source STRING,
    __table STRING
  )
  USING iceberg
  PARTITIONED BY (category)
""")

// Create orders CDC table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.cdc.orders (
    id INT,
    customer_id INT,
    order_date TIMESTAMP,
    status STRING,
    total_amount DECIMAL(10, 2),
    shipping_address STRING,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    __op STRING,
    __ts_ms TIMESTAMP,
    __source STRING,
    __table STRING
  )
  USING iceberg
  PARTITIONED BY (days(order_date))
""")

// Create order_items CDC table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.cdc.order_items (
    id INT,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10, 2),
    subtotal DECIMAL(10, 2),
    created_at TIMESTAMP,
    __op STRING,
    __ts_ms TIMESTAMP,
    __source STRING,
    __table STRING
  )
  USING iceberg
  PARTITIONED BY (order_id)
""")

println("CDC tables created successfully")
```

Run the table creation:

```bash
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.0 \
  scripts/create_cdc_tables.scala
```

## Part 3: Stream CDC Data to Iceberg

### Step 3.1: Create CDC Streaming Consumer

Create a streaming consumer to process CDC events:

```scala
// scripts/cdc_to_iceberg_stream.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("CDC to Iceberg Stream")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/cdc")
  .getOrCreate()

// Function to process CDC events
def processCDC(topic: String, tableName: String) = {
  val kafkaDF = spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", "kafka:9092")
    .option("subscribe", topic)
    .option("startingOffsets", "earliest")
    .option("isolation.level", "read_committed")
    .load()

  val cdcDF = kafkaDF
    .select(from_json(col("value").cast("string"), 
      """
      {
        "before": "STRUCT<id: INT, name: STRING, email: STRING, phone: STRING, address: STRING, created_at: STRING, updated_at: STRING>",
        "after": "STRUCT<id: INT, name: STRING, email: STRING, phone: STRING, address: STRING, created_at: STRING, updated_at: STRING>",
        "op": "STRING",
        "ts_ms": "LONG",
        "source": "STRUCT<version: STRING, connector: STRING, name: STRING, ts_ms: LONG, snapshot: STRING, db: STRING, table: STRING, server_id: INT>"
      }
      """).as("data"))
    .select(
      col("data.after.id"),
      col("data.after.name"),
      col("data.after.email"),
      col("data.after.phone"),
      col("data.after.address"),
      to_timestamp(col("data.after.created_at")).as("created_at"),
      to_timestamp(col("data.after.updated_at")).as("updated_at"),
      col("data.op").as("__op"),
      to_timestamp(col("data.ts_ms") / 1000).as("__ts_ms"),
      col("data.source.name").as("__source"),
      col("data.source.table").as("__table")
    )

  cdcDF.writeStream
    .format("iceberg")
    .outputMode("append")
    .trigger(Trigger.ProcessingTime("10 seconds"))
    .option("checkpointLocation", s"s3a://spark-checkpoints/cdc/$tableName")
    .toTable(s"iceberg.cdc.$tableName")
}

// Process customers CDC
val customersQuery = processCDC("cdc-mysql.cdc_source.customers", "customers")

// Process products CDC
val productsQuery = processCDC("cdc-mysql.cdc_source.products", "products")

// Process orders CDC
val ordersQuery = processCDC("cdc-mysql.cdc_source.orders", "orders")

// Process order_items CDC
val orderItemsQuery = processCDC("cdc-mysql.cdc_source.order_items", "order_items")

customersQuery.awaitTermination()
productsQuery.awaitTermination()
ordersQuery.awaitTermination()
orderItemsQuery.awaitTermination()
```

Run the CDC streaming consumer:

```bash
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.0,org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0 \
  scripts/cdc_to_iceberg_stream.scala
```

### Step 3.2: Apply CDC Changes to Iceberg Tables

Create a more sophisticated CDC processor that applies changes correctly:

```scala
// scripts/apply_cdc_changes.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("Apply CDC Changes")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/cdc-apply")
  .getOrCreate()

// Read CDC events
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "cdc-mysql.cdc_source.orders")
  .option("startingOffsets", "earliest")
  .option("isolation.level", "read_committed")
  .load()

// Parse CDC events
val cdcDF = kafkaDF
  .select(from_json(col("value").cast("string"), 
    """
    {
      "before": "STRUCT<id: INT, customer_id: INT, order_date: STRING, status: STRING, total_amount: DECIMAL, shipping_address: STRING, created_at: STRING, updated_at: STRING>",
      "after": "STRUCT<id: INT, customer_id: INT, order_date: STRING, status: STRING, total_amount: DECIMAL, shipping_address: STRING, created_at: STRING, updated_at: STRING>",
      "op": "STRING",
      "ts_ms": "LONG",
      "source": "STRUCT<version: STRING, connector: STRING, name: STRING, ts_ms: LONG, snapshot: STRING, db: STRING, table: STRING, server_id: INT>"
    }
    """).as("data"))
  .select(
    col("data.before").as("before_data"),
    col("data.after").as("after_data"),
    col("data.op").as("__op"),
    to_timestamp(col("data.ts_ms") / 1000).as("__ts_ms"),
    col("data.source.table").as("__table")
  )

// Apply CDC changes using foreachBatch
val query = cdcDF.writeStream
  .foreachBatch { (batchDF: org.apache.spark.sql.DataFrame, batchId: Long) =>
    // Filter inserts (op = 'c' or 'r')
    val inserts = batchDF.filter(col("__op").isin("c", "r"))
      .select(
        col("after_data.id"),
        col("after_data.customer_id"),
        to_timestamp(col("after_data.order_date")).as("order_date"),
        col("after_data.status"),
        col("after_data.total_amount"),
        col("after_data.shipping_address"),
        to_timestamp(col("after_data.created_at")).as("created_at"),
        to_timestamp(col("after_data.updated_at")).as("updated_at"),
        col("__op"),
        col("__ts_ms"),
        lit("mysql").as("__source"),
        col("__table")
      )
    
    if (!inserts.isEmpty) {
      inserts.write
        .format("iceberg")
        .mode("append")
        .saveAsTable("iceberg.cdc.orders")
    }
    
    // Filter updates (op = 'u')
    val updates = batchDF.filter(col("__op") === "u")
      .select(
        col("after_data.id"),
        col("after_data.customer_id"),
        to_timestamp(col("after_data.order_date")).as("order_date"),
        col("after_data.status"),
        col("after_data.total_amount"),
        col("after_data.shipping_address"),
        to_timestamp(col("after_data.created_at")).as("created_at"),
        to_timestamp(col("after_data.updated_at")).as("updated_at"),
        col("__op"),
        col("__ts_ms"),
        lit("mysql").as("__source"),
        col("__table")
      )
    
    if (!updates.isEmpty) {
      // For updates, we use MERGE INTO
      updates.createOrReplaceTempView("updates")
      spark.sql("""
        MERGE INTO iceberg.cdc.orders AS target
        USING updates AS source
        ON target.id = source.id
        WHEN MATCHED THEN UPDATE SET
          customer_id = source.customer_id,
          order_date = source.order_date,
          status = source.status,
          total_amount = source.total_amount,
          shipping_address = source.shipping_address,
          updated_at = source.updated_at,
          __op = source.__op,
          __ts_ms = source.__ts_ms
        WHEN NOT MATCHED THEN INSERT *
      """)
    }
    
    // Filter deletes (op = 'd')
    val deletes = batchDF.filter(col("__op") === "d")
      .select(col("before_data.id"))
    
    if (!deletes.isEmpty) {
      deletes.createOrReplaceTempView("deletes")
      spark.sql("""
        DELETE FROM iceberg.cdc.orders
        WHERE id IN (SELECT id FROM deletes)
      """)
    }
  }
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/cdc-apply/orders")
  .start()

query.awaitTermination()
```

## Part 4: Test CDC Pipeline

### Step 4.1: Make Database Changes

Make changes to the MySQL database to test CDC:

```bash
# Insert a new customer
docker exec mysql mysql -uroot -piceberg_root cdc_source -e "
  INSERT INTO customers (name, email, phone, address) 
  VALUES ('Test Customer', 'test@example.com', '+1-555-9999', '123 Test St, Test City, TC 12345');
"

# Update an existing customer
docker exec mysql mysql -uroot -piceberg_root cdc_source -e "
  UPDATE customers SET phone = '+1-555-8888' WHERE email = 'john.doe@example.com';
"

# Delete a customer
docker exec mysql mysql -uroot -piceberg_root cdc_source -e "
  DELETE FROM customers WHERE email = 'bob.johnson@example.com';
"

# Insert a new order
docker exec mysql mysql -uroot -piceberg_root cdc_source -e "
  INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_address) 
  VALUES (1, NOW(), 'pending', 149.99, '456 New Order St, Order City, OC 67890');
"

# Update an order status
docker exec mysql mysql -uroot -piceberg_root cdc_source -e "
  UPDATE orders SET status = 'shipped' WHERE id = 6;
"
```

### Step 4.2: Verify CDC Events in Kafka

Check CDC events in Kafka topics:

```bash
# Check customers CDC events
docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic cdc-mysql.cdc_source.customers --from-beginning --max-messages 5

# Check orders CDC events
docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic cdc-mysql.cdc_source.orders --from-beginning --max-messages 5
```

### Step 4.3: Verify Data in Iceberg

Query the Iceberg CDC tables to verify changes:

```scala
// scripts/verify_cdc_data.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Verify CDC Data")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Check customers CDC data
println("Customers CDC Data:")
spark.sql("SELECT * FROM iceberg.cdc.customers ORDER BY __ts_ms DESC LIMIT 10").show()

// Check orders CDC data
println("Orders CDC Data:")
spark.sql("SELECT * FROM iceberg.cdc.orders ORDER BY __ts_ms DESC LIMIT 10").show()

// Check CDC operation types
println("CDC Operation Distribution:")
spark.sql("""
  SELECT __op, COUNT(*) as count 
  FROM iceberg.cdc.customers 
  GROUP BY __op
""").show()

// Check latest changes
println("Latest Changes:")
spark.sql("""
  SELECT 
    __op,
    __table,
    COUNT(*) as change_count,
    MIN(__ts_ms) as first_change,
    MAX(__ts_ms) as latest_change
  FROM (
    SELECT __op, __table, __ts_ms FROM iceberg.cdc.customers
    UNION ALL
    SELECT __op, __table, __ts_ms FROM iceberg.cdc.products
    UNION ALL
    SELECT __op, __table, __ts_ms FROM iceberg.cdc.orders
  ) all_changes
  GROUP BY __op, __table
  ORDER BY latest_change DESC
""").show()
```

## Part 5: CDC Monitoring and Troubleshooting

### Step 5.1: Monitor Debezium Connectors

Monitor connector status and metrics:

```bash
# Get connector status
curl http://localhost:8083/connectors/customers-connector/status | jq

# Get connector metrics
curl http://localhost:8083/connectors/customers-connector/metrics | jq

# Get connector configuration
curl http://localhost:8083/connectors/customers-connector/config | jq
```

### Step 5.2: Monitor Kafka Lag

Monitor consumer lag for CDC topics:

```bash
# Create a consumer group
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --create --group cdc-monitor --topic cdc-mysql.cdc_source.customers

# Check lag
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group cdc-monitor
```

### Step 5.3: Monitor Iceberg Snapshots

Monitor Iceberg snapshots for CDC tables:

```scala
// scripts/monitor_cdc_snapshots.scala
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("Monitor CDC Snapshots")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Check customers snapshots
println("Customers Snapshots:")
spark.sql("CALL iceberg.system.history('iceberg.cdc.customers')").show()

// Check orders snapshots
println("Orders Snapshots:")
spark.sql("CALL iceberg.system.history('iceberg.cdc.orders')").show()

// Check snapshot sizes
println("Snapshot Sizes:")
spark.sql("""
  SELECT 
    table_name,
    COUNT(*) as snapshot_count,
    SUM(summary['total-records']::BIGINT) as total_records
  FROM (
    SELECT 'customers' as table_name, * FROM iceberg.cdc.customers.snapshots
    UNION ALL
    SELECT 'orders' as table_name, * FROM iceberg.cdc.orders.snapshots
  ) all_snapshots
  GROUP BY table_name
""").show()
```

## Part 6: Advanced CDC Patterns

### Step 6.1: Handle Schema Evolution

Handle schema evolution in CDC:

```scala
// scripts/cdc_schema_evolution.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("CDC Schema Evolution")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/cdc-evolution")
  .config("spark.sql.streaming.schemaInference", "true")
  .getOrCreate()

// Read CDC events with schema evolution
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "cdc-mysql.cdc_source.customers")
  .option("startingOffsets", "earliest")
  .load()

// Parse with flexible schema
val cdcDF = kafkaDF
  .select(from_json(col("value").cast("string"), 
    """
    {
      "before": "STRUCT<id: INT, name: STRING, email: STRING, phone: STRING, address: STRING, created_at: STRING, updated_at: STRING, loyalty_points: INT>",
      "after": "STRUCT<id: INT, name: STRING, email: STRING, phone: STRING, address: STRING, created_at: STRING, updated_at: STRING, loyalty_points: INT>",
      "op": "STRING",
      "ts_ms": "LONG",
      "source": "STRUCT<version: STRING, connector: STRING, name: STRING, ts_ms: LONG, snapshot: STRING, db: STRING, table: STRING, server_id: INT>"
    }
    """).as("data"))
  .select(
    col("data.after.id"),
    col("data.after.name"),
    col("data.after.email"),
    col("data.after.phone"),
    col("data.after.address"),
    to_timestamp(col("data.after.created_at")).as("created_at"),
    to_timestamp(col("data.after.updated_at")).as("updated_at"),
    coalesce(col("data.after.loyalty_points"), lit(0)).as("loyalty_points"),
    col("data.op").as("__op"),
    to_timestamp(col("data.ts_ms") / 1000).as("__ts_ms"),
    lit("mysql").as("__source"),
    col("data.source.table").as("__table")
  )

// Write to Iceberg
val query = cdcDF.writeStream
  .format("iceberg")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/cdc-evolution/customers")
  .toTable("iceberg.cdc.customers")

query.awaitTermination()
```

### Step 6.2: Implement CDC Data Quality

Add data quality checks to CDC pipeline:

```scala
// scripts/cdc_data_quality.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val spark = SparkSession.builder()
  .appName("CDC Data Quality")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .config("spark.sql.streaming.checkpointLocation", "s3a://spark-checkpoints/cdc-quality")
  .getOrCreate()

// Read CDC events
val kafkaDF = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "kafka:9092")
  .option("subscribe", "cdc-mysql.cdc_source.orders")
  .option("startingOffsets", "earliest")
  .load()

// Parse and validate
val cdcDF = kafkaDF
  .select(from_json(col("value").cast("string"), 
    """
    {
      "before": "STRUCT<id: INT, customer_id: INT, order_date: STRING, status: STRING, total_amount: DECIMAL, shipping_address: STRING, created_at: STRING, updated_at: STRING>",
      "after": "STRUCT<id: INT, customer_id: INT, order_date: STRING, status: STRING, total_amount: DECIMAL, shipping_address: STRING, created_at: STRING, updated_at: STRING>",
      "op": "STRING",
      "ts_ms": "LONG",
      "source": "STRUCT<version: STRING, connector: STRING, name: STRING, ts_ms: LONG, snapshot: STRING, db: STRING, table: STRING, server_id: INT>"
    }
    """).as("data"))
  .select(
    col("data.after.id"),
    col("data.after.customer_id"),
    to_timestamp(col("data.after.order_date")).as("order_date"),
    col("data.after.status"),
    col("data.after.total_amount"),
    col("data.after.shipping_address"),
    to_timestamp(col("data.after.created_at")).as("created_at"),
    to_timestamp(col("data.after.updated_at")).as("updated_at"),
    col("data.op").as("__op"),
    to_timestamp(col("data.ts_ms") / 1000).as("__ts_ms"),
    lit("mysql").as("__source"),
    col("data.source.table").as("__table")
  )

// Data quality checks
val validatedCDC = cdcDF
  .filter(col("id").isNotNull)
  .filter(col("customer_id").isNotNull)
  .filter(col("order_date").isNotNull)
  .filter(col("status").isNotNull)
  .filter(col("total_amount").isNotNull)
  .filter(col("total_amount") > 0)
  .filter(col("__op").isNotNull)

// Capture invalid records
val invalidCDC = cdcDF
  .join(validatedCDC, Seq("id"), "left_anti")
  .withColumn("error_reason", lit("CDC data validation failed"))
  .withColumn("error_timestamp", current_timestamp())

// Write valid CDC
val validQuery = validatedCDC.writeStream
  .format("iceberg")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/cdc-quality/valid")
  .toTable("iceberg.cdc.orders")

// Write invalid CDC
val invalidQuery = invalidCDC.writeStream
  .format("iceberg")
  .outputMode("append")
  .trigger(Trigger.ProcessingTime("10 seconds"))
  .option("checkpointLocation", "s3a://spark-checkpoints/cdc-quality/invalid")
  .toTable("iceberg.cdc.orders_errors")

validQuery.awaitTermination()
invalidQuery.awaitTermination()
```

## Cleanup

### Stop the CDC Infrastructure

```bash
# Stop all services
docker-compose down

# Remove volumes (optional)
docker-compose down -v
```

### Clean up Debezium Connectors

```bash
curl -X DELETE http://localhost:8083/connectors/customers-connector
curl -X DELETE http://localhost:8083/connectors/products-connector
curl -X DELETE http://localhost:8083/connectors/orders-connector
curl -X DELETE http://localhost:8083/connectors/order-items-connector
```

## Challenges

### Challenge 1: Multi-Database CDC

Extend your CDC pipeline to capture changes from multiple MySQL databases and consolidate them in Iceberg.

### Challenge 2: CDC with SCD Type 2

Implement Slowly Changing Dimension (SCD) Type 2 handling for dimension tables using CDC.

### Challenge 3: CDC Backfill

Implement a backfill strategy to handle historical data before CDC was enabled.

### Challenge 4: CDC Monitoring Dashboard

Create a monitoring dashboard to track CDC pipeline health, lag, and data quality metrics.

## Verification

Verify your implementation:

1. Check that Debezium connectors are running and healthy
2. Verify that CDC events are being captured in Kafka topics
3. Confirm that Spark Structured Streaming is consuming CDC events
4. Validate that Iceberg tables are being updated correctly
5. Test that inserts, updates, and deletes are handled properly
6. Verify data quality checks are working
7. Test schema evolution doesn't break the CDC pipeline

## Next Steps

- Lab 10: Spring Boot with Iceberg
- Lab 11: Multi-Engine Lakehouse