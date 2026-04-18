# Lab 11: Multi-Engine Lakehouse

## Overview

In this lab, you will learn how to build a true multi-engine lakehouse using Apache Iceberg. You will integrate multiple query engines (Spark, Trino, and DuckDB) to query the same Iceberg tables, demonstrating the power of the open table format for enabling diverse workloads on the same data.

## Prerequisites

- Complete Labs 0-7
- Docker and Docker Compose installed
- Basic understanding of SQL and query engines
- Knowledge of distributed computing concepts

## Learning Objectives

By the end of this lab, you will be able to:

1. Configure multiple query engines to work with Iceberg
2. Set up Trino (formerly PrestoSQL) for interactive querying
3. Configure DuckDB for local analytics
4. Ensure schema consistency across engines
5. Implement engine-specific optimizations
6. Handle data type conversions between engines
7. Monitor and optimize multi-engine workloads
8. Implement workload isolation and resource management

## Lab Setup

### 1. Update docker-compose.yaml with Additional Engines

Add Trino and DuckDB to the docker-compose.yaml:

```yaml
# Add these services to docker-compose.yaml

  # Trino (distributed SQL engine)
  trino:
    image: trinodb/trino:435
    container_name: trino
    ports:
      - "8080:8080"
    environment:
      TRINO_CATALOG: iceberg
      TRINO_CATALOG_ICEBERG_TYPE: iceberg
      TRINO_CATALOG_ICEBERG_URI: http://polaris:8181/api/catalog
      TRINO_CATALOG_ICEBERG_WAREHOUSE: s3a://iceberg-warehouse
      TRINO_CATALOG_ICEBERG_S3_ENDPOINT: http://minio:9000
      TRINO_CATALOG_ICEBERG_S3_ACCESS_KEY: minioadmin
      TRINO_CATALOG_ICEBERG_S3_SECRET_KEY: minioadmin
      TRINO_CATALOG_ICEBERG_S3_PATH_STYLE_ACCESS: true
    depends_on:
      polaris:
        condition: service_healthy
      minio:
        condition: service_healthy
    volumes:
      - ./config/trino:/etc/trino
    command: >
      sh -c "
        echo 'Configuring Trino...' &&
        cat > /etc/trino/catalog/iceberg.properties << 'EOF'
        connector.name=iceberg
        iceberg.catalog.type=rest
        iceberg.rest-catalog.uri=http://polaris:8181/api/catalog
        iceberg.rest-catalog.warehouse=s3a://iceberg-warehouse
        s3.endpoint=http://minio:9000
        s3.access-key=minioadmin
        s3.secret-key=minioadmin
        s3.path-style-access=true
        EOF
        echo 'Starting Trino...' &&
        exec /usr/lib/trino/bin/run-trino
      "
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/v1/info"]
      interval: 30s
      timeout: 10s
      retries: 3

  # DuckDB (embedded analytical database)
  duckdb:
    image: duckdb/duckdb:latest
    container_name: duckdb
    environment:
      DUCKDB_DATABASE: /data/duckdb.db
    volumes:
      - duckdb_data:/data
      - ./scripts:/scripts
    depends_on:
      polaris:
        condition: service_healthy
    command: >
      sh -c "
        echo 'DuckDB container ready for interactive use' &&
        echo 'Access via: docker exec -it duckdb duckdb /data/duckdb.db' &&
        tail -f /dev/null
      "
```

### 2. Start the Infrastructure

Start the complete multi-engine infrastructure:

```bash
cd /home/ramdov/projects/iceberg-practice-env
docker-compose up -d minio polaris spark-master spark-worker trino duckdb
```

Verify services are running:

```bash
docker-compose ps
```

## Part 1: Multi-Engine Data Ingestion

### Step 1.1: Create Sample Data with Spark

Create sample data using Spark:

```scala
// scripts/create_multi_engine_data.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Create Multi-Engine Data")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Create customers table
val customers = Seq(
  (1, "John Doe", "john@example.com", "+1-555-0101", "123 Main St, NYC, NY 10001"),
  (2, "Jane Smith", "jane@example.com", "+1-555-0102", "456 Oak Ave, LA, CA 90001"),
  (3, "Bob Johnson", "bob@example.com", "+1-555-0103", "789 Pine Rd, Chicago, IL 60601"),
  (4, "Alice Williams", "alice@example.com", "+1-555-0104", "321 Elm St, Houston, TX 77001"),
  (5, "Charlie Brown", "charlie@example.com", "+1-555-0105", "654 Maple Dr, Phoenix, AZ 85001")
).toDF("id", "name", "email", "phone", "address")

customers.write
  .format("iceberg")
  .mode("overwrite")
  .saveAsTable("iceberg.demo.customers")

// Create products table
val products = Seq(
  (1, "Laptop Pro 15\"", "High-performance laptop", 1299.99, "Electronics", 50),
  (2, "Wireless Mouse", "Ergonomic wireless mouse", 29.99, "Electronics", 200),
  (3, "Mechanical Keyboard", "RGB mechanical keyboard", 149.99, "Electronics", 100),
  (4, "USB-C Hub", "7-in-1 USB-C hub", 49.99, "Electronics", 150),
  (5, "Monitor 27\" 4K", "Ultra HD monitor", 399.99, "Electronics", 75)
).toDF("id", "name", "description", "price", "category", "stock_quantity")

products.write
  .format("iceberg")
  .mode("overwrite")
  .saveAsTable("iceberg.demo.products")

// Create orders table
import java.sql.Timestamp
val orders = Seq(
  (1, 1, Timestamp.valueOf("2024-01-15 10:30:00"), "completed", 1329.98, "123 Main St, NYC, NY 10001"),
  (2, 2, Timestamp.valueOf("2024-01-16 14:45:00"), "processing", 179.98, "456 Oak Ave, LA, CA 90001"),
  (3, 3, Timestamp.valueOf("2024-01-17 09:15:00"), "shipped", 549.97, "789 Pine Rd, Chicago, IL 60601"),
  (4, 4, Timestamp.valueOf("2024-01-18 16:20:00"), "delivered", 449.98, "321 Elm St, Houston, TX 77001"),
  (5, 5, Timestamp.valueOf("2024-01-19 11:00:00"), "pending", 1299.99, "654 Maple Dr, Phoenix, AZ 85001")
).toDF("id", "customer_id", "order_date", "status", "total_amount", "shipping_address")

orders.write
  .format("iceberg")
  .mode("overwrite")
  .saveAsTable("iceberg.demo.orders")

// Create order_items table
val orderItems = Seq(
  (1, 1, 1, 1, 1299.99, 1299.99),
  (1, 2, 2, 1, 29.99, 29.99),
  (2, 3, 1, 1, 149.99, 149.99),
  (2, 4, 2, 1, 29.99, 29.99),
  (3, 1, 1, 1, 1299.99, 1299.99),
  (3, 5, 1, 1, 399.99, 399.99),
  (3, 3, 1, 1, 149.99, 149.99),
  (4, 5, 1, 1, 399.99, 399.99),
  (4, 4, 1, 1, 49.99, 49.99),
  (5, 1, 1, 1, 1299.99, 1299.99)
).toDF("id", "order_id", "product_id", "quantity", "unit_price", "subtotal")

orderItems.write
  .format("iceberg")
  .mode("overwrite")
  .saveAsTable("iceberg.demo.order_items")

println("Multi-engine data created successfully")
```

Run the data creation:

```bash
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.0 \
  scripts/create_multi_engine_data.scala
```

## Part 2: Querying with Spark

### Step 2.1: Run Spark Queries

Query the data with Spark:

```scala
// scripts/spark_queries.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Spark Queries")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Query 1: Customer order summary
val customerOrders = spark.sql("""
  SELECT 
    c.id as customer_id,
    c.name as customer_name,
    c.email as customer_email,
    COUNT(DISTINCT o.id) as order_count,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order_value
  FROM iceberg.demo.customers c
  LEFT JOIN iceberg.demo.orders o ON c.id = o.customer_id
  GROUP BY c.id, c.name, c.email
  ORDER BY total_spent DESC
""")

println("Customer Order Summary:")
customerOrders.show()

// Query 2: Product popularity
val productPopularity = spark.sql("""
  SELECT 
    p.id as product_id,
    p.name as product_name,
    p.category,
    p.price,
    p.stock_quantity,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.subtotal) as total_revenue
  FROM iceberg.demo.products p
  LEFT JOIN iceberg.demo.order_items oi ON p.id = oi.product_id
  GROUP BY p.id, p.name, p.category, p.price, p.stock_quantity
  ORDER BY total_revenue DESC
""")

println("Product Popularity:")
productPopularity.show()

// Query 3: Daily sales trends
val dailySales = spark.sql("""
  SELECT 
    DATE(o.order_date) as sale_date,
    COUNT(*) as order_count,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value
  FROM iceberg.demo.orders o
  GROUP BY DATE(o.order_date)
  ORDER BY sale_date
""")

println("Daily Sales Trends:")
dailySales.show()

// Query 4: Category performance
val categoryPerformance = spark.sql("""
  SELECT 
    p.category,
    COUNT(DISTINCT oi.order_id) as order_count,
    SUM(oi.quantity) as total_quantity,
    SUM(oi.subtotal) as total_revenue,
    AVG(oi.unit_price) as avg_price
  FROM iceberg.demo.products p
  JOIN iceberg.demo.order_items oi ON p.id = oi.product_id
  GROUP BY p.category
  ORDER BY total_revenue DESC
""")

println("Category Performance:")
categoryPerformance.show()

println("Spark queries completed successfully")
```

Run the Spark queries:

```bash
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.0 \
  scripts/spark_queries.scala
```

## Part 3: Querying with Trino

### Step 3.1: Access Trino CLI

Access the Trino CLI:

```bash
docker exec -it trino trino
```

### Step 3.2: Run Trino Queries

Query the same data with Trino:

```sql
-- Query 1: Customer order summary
SELECT 
  c.id as customer_id,
  c.name as customer_name,
  c.email as customer_email,
  COUNT(DISTINCT o.id) as order_count,
  SUM(o.total_amount) as total_spent,
  AVG(o.total_amount) as avg_order_value
FROM iceberg.demo.customers c
LEFT JOIN iceberg.demo.orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.email
ORDER BY total_spent DESC;

-- Query 2: Product popularity
SELECT 
  p.id as product_id,
  p.name as product_name,
  p.category,
  p.price,
  p.stock_quantity,
  COUNT(DISTINCT oi.order_id) as times_ordered,
  SUM(oi.quantity) as total_quantity_sold,
  SUM(oi.subtotal) as total_revenue
FROM iceberg.demo.products p
LEFT JOIN iceberg.demo.order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.name, p.category, p.price, p.stock_quantity
ORDER BY total_revenue DESC;

-- Query 3: Daily sales trends
SELECT 
  DATE(o.order_date) as sale_date,
  COUNT(*) as order_count,
  SUM(o.total_amount) as total_revenue,
  AVG(o.total_amount) as avg_order_value
FROM iceberg.demo.orders o
GROUP BY DATE(o.order_date)
ORDER BY sale_date;

-- Query 4: Category performance
SELECT 
  p.category,
  COUNT(DISTINCT oi.order_id) as order_count,
  SUM(oi.quantity) as total_quantity,
  SUM(oi.subtotal) as total_revenue,
  AVG(oi.unit_price) as avg_price
FROM iceberg.demo.products p
JOIN iceberg.demo.order_items oi ON p.id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;
```

### Step 3.3: Use Trino Web UI

Access the Trino Web UI:
- Trino UI: http://localhost:8080

## Part 4: Querying with DuckDB

### Step 4.1: Access DuckDB

Access DuckDB:

```bash
docker exec -it duckdb duckdb /data/duckdb.db
```

### Step 4.2: Install Iceberg Extension

Install the Iceberg extension for DuckDB:

```sql
INSTALL iceberg;
LOAD iceberg;
```

### Step 4.3: Configure Iceberg Catalog

Configure the Iceberg catalog:

```sql
CREATE iceberg_catalog iceberg_catalog TYPE rest 
  URI 'http://polaris:8181/api/catalog' 
  WAREHOUSE 's3a://iceberg-warehouse';
```

### Step 4.4: Run DuckDB Queries

Query the same data with DuckDB:

```sql
-- Query 1: Customer order summary
SELECT 
  c.id as customer_id,
  c.name as customer_name,
  c.email as customer_email,
  COUNT(DISTINCT o.id) as order_count,
  SUM(o.total_amount) as total_spent,
  AVG(o.total_amount) as avg_order_value
FROM iceberg_catalog.demo.customers c
LEFT JOIN iceberg_catalog.demo.orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.email
ORDER BY total_spent DESC;

-- Query 2: Product popularity
SELECT 
  p.id as product_id,
  p.name as product_name,
  p.category,
  p.price,
  p.stock_quantity,
  COUNT(DISTINCT oi.order_id) as times_ordered,
  SUM(oi.quantity) as total_quantity_sold,
  SUM(oi.subtotal) as total_revenue
FROM iceberg_catalog.demo.products p
LEFT JOIN iceberg_catalog.demo.order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.name, p.category, p.price, p.stock_quantity
ORDER BY total_revenue DESC;

-- Query 3: Daily sales trends
SELECT 
  DATE(o.order_date) as sale_date,
  COUNT(*) as order_count,
  SUM(o.total_amount) as total_revenue,
  AVG(o.total_amount) as avg_order_value
FROM iceberg_catalog.demo.orders o
GROUP BY DATE(o.order_date)
ORDER BY sale_date;

-- Query 4: Category performance
SELECT 
  p.category,
  COUNT(DISTINCT oi.order_id) as order_count,
  SUM(oi.quantity) as total_quantity,
  SUM(oi.subtotal) as total_revenue,
  AVG(oi.unit_price) as avg_price
FROM iceberg_catalog.demo.products p
JOIN iceberg_catalog.demo.order_items oi ON p.id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;
```

## Part 5: Cross-Engine Consistency

### Step 5.1: Verify Schema Consistency

Verify that all engines see the same schema:

```scala
// scripts/verify_schema_consistency.scala
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("Verify Schema Consistency")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

println("Spark Schema - Customers:")
spark.sql("DESCRIBE iceberg.demo.customers").show()

println("Spark Schema - Products:")
spark.sql("DESCRIBE iceberg.demo.products").show()

println("Spark Schema - Orders:")
spark.sql("DESCRIBE iceberg.demo.orders").show()

println("Spark Schema - Order Items:")
spark.sql("DESCRIBE iceberg.demo.order_items").show()
```

### Step 5.2: Verify Data Consistency

Verify that all engines return the same results:

```bash
# Spark
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.0 \
  -e "spark.sql('SELECT COUNT(*) FROM iceberg.demo.customers').show()"

# Trino
docker exec trino trino -c "SELECT COUNT(*) FROM iceberg.demo.customers"

# DuckDB
docker exec duckdb duckdb /data/duckdb.db -c "SELECT COUNT(*) FROM iceberg_catalog.demo.customers"
```

## Part 6: Engine-Specific Optimizations

### Step 6.1: Spark Optimizations

Implement Spark-specific optimizations:

```scala
// scripts/spark_optimizations.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Spark Optimizations")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  // Spark optimizations
  .config("spark.sql.adaptive.enabled", "true")
  .config("spark.sql.adaptive.coalescePartitions.enabled", "true")
  .config("spark.sql.adaptive.skewJoin.enabled", "true")
  .config("spark.sql.shuffle.partitions", "200")
  .getOrCreate()

// Use file pruning
spark.sql("REFRESH TABLE iceberg.demo.orders")

// Use partition pruning
val recentOrders = spark.sql("""
  SELECT * FROM iceberg.demo.orders
  WHERE order_date >= DATE_SUB(CURRENT_DATE(), 7)
""")

println("Recent Orders (partition pruning):")
recentOrders.show()

// Use predicate pushdown
val highValueOrders = spark.sql("""
  SELECT * FROM iceberg.demo.orders
  WHERE total_amount > 1000
""")

println("High Value Orders (predicate pushdown):")
highValueOrders.show()

println("Spark optimizations applied successfully")
```

### Step 6.2: Trino Optimizations

Implement Trino-specific optimizations:

```sql
-- Use statistics
ANALYZE iceberg.demo.customers;

-- Use partition pruning
SELECT * FROM iceberg.demo.orders
WHERE order_date >= DATE('2024-01-15');

-- Use predicate pushdown
SELECT * FROM iceberg.demo.orders
WHERE total_amount > 1000;

-- Use join optimization
SET SESSION join_distribution_type='PARTITIONED';
```

### Step 6.3: DuckDB Optimizations

Implement DuckDB-specific optimizations:

```sql
-- Use parallel queries
PRAGMA threads=4;

-- Use memory mapping
PRAGMA memory_limit='2GB';

-- Use columnar operations
SELECT 
  customer_id,
  SUM(total_amount) as total_spent
FROM iceberg_catalog.demo.orders
GROUP BY customer_id;

-- Use vectorized operations
SELECT 
  product_id,
  COUNT(*) as order_count,
  SUM(quantity) as total_quantity
FROM iceberg_catalog.demo.order_items
GROUP BY product_id;
```

## Part 7: Workload Isolation

### Step 7.1: Separate Workloads by Engine

Implement workload isolation:

```scala
// Spark: Batch processing
val batchProcessing = spark.sql("""
  INSERT INTO iceberg.demo.daily_sales_summary
  SELECT 
    DATE(order_date) as sale_date,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
  FROM iceberg.demo.orders
  WHERE order_date >= CURRENT_DATE - INTERVAL 1 DAY
  GROUP BY DATE(order_date)
""")
```

```sql
-- Trino: Interactive queries
SELECT 
  c.name,
  c.email,
  o.id as order_id,
  o.total_amount,
  o.status
FROM iceberg.demo.customers c
JOIN iceberg.demo.orders o ON c.id = o.customer_id
WHERE c.email = 'john@example.com';
```

```sql
-- DuckDB: Local analytics
SELECT 
  category,
  COUNT(*) as product_count,
  AVG(price) as avg_price,
  SUM(stock_quantity) as total_stock
FROM iceberg_catalog.demo.products
GROUP BY category;
```

### Step 7.2: Resource Management

Configure resource limits for each engine:

```yaml
# Add to docker-compose.yaml for Spark
spark-master:
  environment:
    SPARK_DRIVER_MEMORY: "2g"
    SPARK_EXECUTOR_MEMORY: "4g"
    SPARK_EXECUTOR_CORES: "2"

# Add to docker-compose.yaml for Trino
trino:
  environment:
    TRINO_MEMORY_HEAP_HEAD: "2G"
    TRINO_MEMORY_QUERY_MAX_PER_NODE: "1G"

# DuckDB is already memory-efficient by default
```

## Part 8: Multi-Engine ETL Pipeline

### Step 8.1: Create Cross-Engine Pipeline

Create a pipeline that uses multiple engines:

```scala
// scripts/multi_engine_pipeline.scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("Multi-Engine Pipeline")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Step 1: Spark - Raw data processing
val rawData = spark.read
  .format("csv")
  .option("header", "true")
  .load("s3a://raw-data/orders.csv")

val cleanedData = rawData
  .filter(col("customer_id").isNotNull)
  .filter(col("total_amount") > 0)
  .withColumn("order_date", to_timestamp(col("order_date")))

// Step 2: Write to staging table
cleanedData.write
  .format("iceberg")
  .mode("append")
  .saveAsTable("iceberg.staging.orders")

println("Data staged by Spark successfully")

// Step 3: Trigger Trino for data quality checks
// This would be called via REST API or CLI
// trino -c "SELECT COUNT(*) FROM iceberg.staging.orders WHERE total_amount < 0"

// Step 4: DuckDB for local analytics and validation
// This would be called via Python script or CLI
// duckdb -c "SELECT * FROM iceberg_catalog.staging.orders LIMIT 10"

// Step 5: Spark - Move to production
val stagingData = spark.table("iceberg.staging.orders")

stagingData.write
  .format("iceberg")
  .mode("append")
  .saveAsTable("iceberg.production.orders")

println("Data moved to production successfully")
```

## Part 9: Monitoring and Observability

### Step 9.1: Monitor Spark Jobs

Monitor Spark jobs through Spark UI:
- Spark Master UI: http://localhost:8080
- Spark Worker UI: http://localhost:8081

### Step 9.2: Monitor Trino Queries

Monitor Trino queries through Trino UI:
- Trino UI: http://localhost:8080

### Step 9.3: Monitor Iceberg Metadata

Monitor Iceberg metadata and snapshots:

```scala
// scripts/monitor_iceberg_metadata.scala
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("Monitor Iceberg Metadata")
  .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog")
  .config("spark.sql.catalog.iceberg.type", "rest")
  .config("spark.sql.catalog.iceberg.uri", "http://polaris:8181/api/catalog")
  .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
  .getOrCreate()

// Check snapshots
println("Orders Table Snapshots:")
spark.sql("CALL iceberg.system.history('iceberg.demo.orders')").show()

// Check table statistics
println("Orders Table Statistics:")
spark.sql("SELECT * FROM iceberg.demo.orders.files").show()

// Check partition information
println("Orders Table Partitions:")
spark.sql("SELECT * FROM iceberg.demo.orders.partitions").show()
```

## Cleanup

### Stop the Multi-Engine Infrastructure

```bash
cd /home/ramdov/projects/iceberg-practice-env
docker-compose down
```

### Clean up Data

```bash
# Remove volumes (optional)
docker-compose down -v
```

## Challenges

### Challenge 1: Engine-Specific Functions

Implement queries that use engine-specific functions while maintaining compatibility across engines.

### Challenge 2: Performance Comparison

Benchmark the same queries across all three engines and analyze performance characteristics.

### Challenge 3: Data Type Conversion

Handle complex data type conversions between engines (e.g., timestamps, decimals, arrays).

### Challenge 4: Real-Time Multi-Engine

Implement a real-time pipeline where data written by one engine is immediately visible to other engines.

## Verification

Verify your implementation:

1. Check that all engines can connect to the Iceberg catalog
2. Verify that all engines see the same schema
3. Confirm that all engines return consistent query results
4. Test engine-specific optimizations
5. Validate workload isolation
6. Monitor resource usage across engines
7. Test cross-engine data consistency

## Next Steps

Congratulations! You have completed all labs. You now have a comprehensive understanding of Apache Iceberg and how to build a multi-engine lakehouse architecture.

Consider exploring:
- Advanced partitioning strategies
- Materialized views
- Time travel queries
- Fine-grained access control
- Cost optimization strategies
- Production deployment patterns