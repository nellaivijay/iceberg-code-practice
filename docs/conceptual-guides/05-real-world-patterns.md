# Conceptual Guide: Real-World Data Patterns with Iceberg

## 🎯 Learning Objectives

This guide explains real-world data engineering patterns and how Apache Iceberg enables these patterns in a data lake environment. Understanding these patterns will help you design production-ready data pipelines.

## 📚 Core Concepts

### 1. Slowly Changing Dimensions (SCD)

**What are Slowly Changing Dimensions?**
Dimensions that change slowly over time, requiring special handling to track history.

**Why SCD Matters:**
- **Historical Analysis**: Need to analyze data as it existed at specific points in time
- **Auditing**: Track changes to dimension attributes over time
- **Regulatory Compliance**: Maintain complete audit trails
- **Business Intelligence**: Accurate historical reporting

**SCD Types:**

#### SCD Type 1: Overwrite
```sql
-- Old value
customer_id: 1, name: 'Alice', email: 'alice@example.com'

-- Update
UPDATE customer SET email = 'alice.new@example.com' WHERE customer_id = 1

-- Result (history lost)
customer_id: 1, name: 'Alice', email: 'alice.new@example.com'
```
**Use when**: History not important, only current state matters

**Iceberg Implementation**: Simple UPDATE statement

#### SCD Type 2: Add New Row
```sql
-- Initial state
customer_key: 1, customer_id: 1, name: 'Alice', email: 'alice@example.com',
valid_from: '2024-01-01', valid_to: '9999-12-31', is_current: true

-- Update (expire old record)
UPDATE customer_dim 
SET valid_to = '2024-01-15', is_current = false 
WHERE customer_id = 1 AND is_current = true

-- Insert new record
INSERT INTO customer_dim VALUES
(2, 1, 'Alice', 'alice.new@example.com',
 '2024-01-15', '9999-12-31', true)

-- Result (history preserved)
customer_key: 1, customer_id: 1, name: 'Alice', email: 'alice@example.com',
valid_from: '2024-01-01', valid_to: '2024-01-15', is_current: false

customer_key: 2, customer_id: 1, name: 'Alice', email: 'alice.new@example.com',
valid_from: '2024-01-15', valid_to: '9999-12-31', is_current: true
```
**Use when**: Complete history required

**Iceberg Implementation**: UPDATE + INSERT pattern

**Why Iceberg Makes This Easy:**
- **Schema Evolution**: Can add valid_from/valid_to columns without breaking existing data
- **Time Travel**: Can query dimension as it existed at any point
- **Partitioning**: Partition by is_current for efficient current-state queries
- **ACID Transactions**: Ensure atomic update+insert operations

#### SCD Type 2 Implementation Pattern
```scala
// 1. Expire old record
spark.sql("""
  UPDATE customer_dim
  SET valid_to = CURRENT_TIMESTAMP, is_current = false
  WHERE customer_id = ? AND is_current = true
""")

// 2. Insert new record
spark.sql("""
  INSERT INTO customer_dim
  (customer_key, customer_id, name, email, valid_from, valid_to, is_current)
  VALUES (next_key, ?, ?, ?, CURRENT_TIMESTAMP, '9999-12-31', true)
""")
```

**Why This Pattern Works:**
- **Atomic Operations**: Each step is atomic
- **Idempotent**: Can be retried if it fails
- **Queryable**: Easy to query current or historical state
- **Efficient**: Partitioning by is_current optimizes common queries

### 2. Upsert Operations

**What are Upserts?**
Insert-or-update operations that insert new records or update existing ones based on a key.

**Why Upserts Matter:**
- **Idempotent Operations**: Can be safely retried
- **Data Synchronization**: Sync data from source systems
- **Incremental Updates**: Update only changed records
- **Conflict Resolution**: Handle duplicate keys gracefully

**Upsert Patterns:**

#### Pattern 1: MERGE Statement
```scala
spark.sql("""
  MERGE INTO target_table AS target
  USING source_table AS source
  ON target.key = source.key
  WHEN MATCHED THEN
    UPDATE SET target.col1 = source.col1, target.col2 = source.col2
  WHEN NOT MATCHED THEN
    INSERT *
""")
```
**How it works**: 
- Matched rows are updated
- Unmatched rows are inserted
- Atomic operation

**Iceberg Advantage**: Native MERGE support with ACID guarantees

#### Pattern 2: Delete + Insert
```scala
// Delete existing keys
spark.sql("""
  DELETE FROM target_table
  WHERE key IN (SELECT key FROM source_table)
""")

// Insert all records (new and updated)
spark.sql("""
  INSERT INTO target_table
  SELECT * FROM source_table
""")
```
**How it works**: 
- Delete existing keys
- Insert all source records
- Simpler but less efficient

**When to use**: When MERGE not available or for simpler logic

#### Pattern 3: Staging Table Approach
```scala
// 1. Load to staging
source_data.writeTo("iceberg.staging").tableAppend()

// 2. Perform upsert using staging
spark.sql("""
  MERGE INTO target AS target
  USING staging AS source
  ON target.key = source.key
  WHEN MATCHED THEN
    UPDATE SET *
  WHEN NOT MATCHED THEN
    INSERT *
""")

// 3. Clear staging
spark.sql("TRUNCATE TABLE iceberg.staging")
```
**How it works**: 
- Load data to staging first
- Perform upsert from staging
- Clear staging for next load

**When to use**: For large data loads, allows validation before upsert

**Upsert Performance Considerations:**
- **Index on Key**: Ensure key column has statistics
- **Batch Size**: Process in batches for large datasets
- **Partition Alignment**: Align source and target partitions
- **Staging Strategy**: Use staging for validation and retry

### 3. Batch and Streaming Patterns

#### Batch Pattern: Daily Data Loading

**What is Batch Loading?**
Loading data in discrete batches at regular intervals (daily, hourly, etc.)

**Why Batch Loading Matters:**
- **Simplicity**: Easier to implement and debug
- **Cost-Effective**: Can use spot instances
- **Data Quality**: Can validate before committing
- **Predictable**: Consistent processing windows

**Daily Batch Loading Pattern:**
```scala
// 1. Load daily data
val dailyData = spark.read.parquet(s"/data/sales_$date.parquet")

// 2. Validate data
val rowCount = dailyData.count()
assert(rowCount > 0, "No data to load")

// 3. Write to Iceberg with controlled file sizes
dailyData.coalesce(10).writeTo("iceberg.sales").tableAppend()

// 4. Compact partition
spark.sql("""
  CALL iceberg.system.rewrite_data_files(
    'iceberg.sales',
    map(
      'min-input-files', '5',
      'target-size-bytes', str(256 * 1024 * 1024)
    )
  )
""")
```

**Why This Pattern Works:**
- **Validation**: Check data before loading
- **File Control**: Coalesce to control file count
- **Compaction**: Clean up small files after load
- **Idempotent**: Can be retried if it fails

#### Streaming Pattern: Micro-Batch Processing

**What is Micro-Batch Processing?**
Processing data in small batches at high frequency (seconds/minutes).

**Why Micro-Batch Matters:**
- **Low Latency**: Near real-time data availability
- **Incremental**: Only process new data
- **Scalable**: Can handle high throughput
- **Fault Tolerant**: Built-in retry and recovery

**Micro-Batch Pattern:**
```scala
// 1. Configure streaming read
val streamingData = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "localhost:9092")
  .option("subscribe", "sales-topic")
  .load()

// 2. Transform and write to Iceberg
val query = streamingData
  .writeStream
  .format("iceberg")
  .outputMode("append")
  .option("checkpointLocation", "/checkpoints/sales")
  .toTable("iceberg.sales")
  .start()
```

**Iceberg Streaming Advantages:**
- **ACID Guarantees**: Each micro-batch is atomic
- **Schema Evolution**: Can handle schema changes in stream
- **Time Travel**: Can query stream at any point
- **Partitioning**: Automatic partitioning by time

**Micro-Batch Compaction:**
```scala
// Schedule periodic compaction for streaming tables
spark.sql("""
  CALL iceberg.system.rewrite_data_files(
    'iceberg.sales',
    map(
      'min-input-files', '20',
      'target-size-bytes', str(128 * 1024 * 1024)
    )
  )
""")
```

**Why Compaction Important for Streaming**: Streaming creates many small files

### 4. CDC (Change Data Capture) Patterns

**What is CDC?**
Capturing and propagating changes from source systems to data warehouses.

**Why CDC Matters:**
- **Real-Time Sync**: Keep data warehouse in sync with source
- **Incremental Updates**: Only process changes, not full loads
- **Audit Trail**: Track all changes
- **Efficiency**: Reduce data movement

**CDC Pattern Implementation:**

#### Source Table (CDC Data)
```sql
CREATE TABLE source_transactions (
  transaction_id STRING,
  customer_id STRING,
  amount DECIMAL,
  transaction_type STRING,
  transaction_timestamp TIMESTAMP,
  cdc_operation STRING,  -- INSERT, UPDATE, DELETE
  cdc_timestamp TIMESTAMP
)
```

#### Target Table (Data Warehouse)
```sql
CREATE TABLE target_transactions (
  transaction_id STRING,
  customer_id STRING,
  amount DECIMAL,
  transaction_type STRING,
  transaction_timestamp TIMESTAMP,
  last_updated TIMESTAMP
)
```

#### CDC Processing Logic
```scala
// Process INSERT and UPDATE
spark.sql("""
  MERGE INTO target_transactions AS target
  USING (
    SELECT 
      transaction_id,
      customer_id,
      amount,
      transaction_type,
      transaction_timestamp,
      cdc_timestamp as last_updated
    FROM source_transactions
    WHERE cdc_operation IN ('INSERT', 'UPDATE')
  ) AS source
  ON target.transaction_id = source.transaction_id
  WHEN MATCHED THEN
    UPDATE SET *
  WHEN NOT MATCHED THEN
    INSERT *
""")

// Process DELETE
spark.sql("""
  DELETE FROM target_transactions
  WHERE transaction_id IN (
    SELECT transaction_id 
    FROM source_transactions 
    WHERE cdc_operation = 'DELETE'
  )
""")
```

**Why This Pattern Works:**
- **Separate Operations**: Handle INSERT/UPDATE and DELETE separately
- **Idempotent**: Can be retried safely
- **Order Preserved**: Process in CDC timestamp order
- **Audit Trail**: CDC timestamp tracks when change occurred

**CDC with Iceberg Advantages:**
- **ACID Transactions**: Ensure consistent state
- **Time Travel**: Can query warehouse at any CDC point
- **Schema Evolution**: Handle source schema changes
- **Performance**: Partition by CDC operation for efficient processing

### 5. Star Schema Implementation

**What is Star Schema?**
Dimensional modeling pattern with fact tables and dimension tables.

**Why Star Schema Matters:**
- **Query Performance**: Optimized for analytical queries
- **Simplicity**: Easy to understand and maintain
- **Scalability**: Handles large data volumes
- **Flexibility**: Easy to add new dimensions

**Star Schema Components:**

#### Fact Table
```sql
CREATE TABLE sales_fact (
  sale_id INT,
  time_id INT,
  customer_id INT,
  product_id INT,
  store_id INT,
  quantity INT,
  unit_price DECIMAL,
  total_amount DECIMAL
)
PARTITIONED BY (store_id, years(time_id))
```
**Characteristics**: 
- Large, contains measures (quantities, amounts)
- Foreign keys to dimensions
- Highly partitioned

#### Dimension Tables
```sql
-- Time Dimension
CREATE TABLE time_dim (
  time_id INT,
  date_value DATE,
  day_of_month INT,
  month INT,
  year INT,
  quarter INT,
  day_of_week INT
)
PARTITIONED BY (year, quarter)

-- Customer Dimension
CREATE TABLE customer_dim (
  customer_id INT,
  customer_name STRING,
  customer_segment STRING,
  region STRING
)
PARTITIONED BY (region)

-- Product Dimension
CREATE TABLE product_dim (
  product_id INT,
  product_name STRING,
  category STRING,
  subcategory STRING
)
PARTITIONED BY (category)
```
**Characteristics**: 
- Smaller than fact table
- Contains attributes (names, categories)
- Less partitioned

**Star Schema Query Pattern:**
```scala
spark.sql("""
  SELECT 
    d.product_name,
    d.category,
    SUM(f.total_amount) as total_revenue,
    SUM(f.quantity) as total_quantity
  FROM sales_fact f
  JOIN product_dim d ON f.product_id = d.product_id
  JOIN time_dim t ON f.time_id = t.time_id
  WHERE t.year = 2024
    AND d.category = 'Electronics'
  GROUP BY d.product_name, d.category
""")
```

**Iceberg Star Schema Advantages:**
- **Partition Pruning**: Fact table partitioned by dimensions
- **Schema Evolution**: Can add new dimension attributes
- **Time Travel**: Can query star schema at any point
- **ACID Transactions**: Ensure consistent fact/dimension updates

### 6. Data Quality Patterns

#### Pattern 1: Validation Before Loading
```scala
// 1. Load to staging
val stagingData = spark.read.parquet("/data/sales.parquet")

// 2. Validate
val nullCheck = stagingData.filter(col("amount").isNull).count()
assert(nullCheck == 0, "Null amounts found")

val duplicateCheck = stagingData.groupBy("sale_id").count()
  .filter(col("count") > 1).count()
assert(duplicateCheck == 0, "Duplicate sale_ids found")

// 3. Load to production
stagingData.writeTo("iceberg.sales").tableAppend()
```

#### Pattern 2: Reconciliation
```scala
// Compare source and target counts
val sourceCount = spark.read.parquet("/data/sales.parquet").count()
val targetCount = spark.sql("SELECT COUNT(*) FROM iceberg.sales").collect()(0).getLong(0)

assert(sourceCount == targetCount, 
  s"Count mismatch: source=$sourceCount, target=$targetCount")
```

#### Pattern 3: Data Profiling
```scala
// Profile data quality metrics
spark.sql("""
  SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) as null_amounts,
    AVG(amount) as avg_amount,
    MIN(amount) as min_amount,
    MAX(amount) as max_amount
  FROM iceberg.sales
""")
```

## 💡 Pattern Selection Guide

| Pattern | Use When | Complexity | Performance |
|---------|-----------|------------|-------------|
| SCD Type 1 | History not important | Low | High |
| SCD Type 2 | Complete history required | Medium | Medium |
| Upsert (MERGE) | Idempotent updates needed | Medium | High |
| Batch Loading | Daily/hourly updates | Low | High |
| Micro-Batch | Near real-time needed | High | Medium |
| CDC | Real-time sync from source | High | Medium |
| Star Schema | Analytical queries | Medium | High |

## 🔍 Common Misconceptions

### Misconception 1: SCD Type 2 is Always Best
**Reality**: Type 2 adds complexity. Use Type 1 when history not needed.

### Misconception 2: Streaming Always Better Than Batch
**Reality**: Streaming is more complex and expensive. Use batch when latency not critical.

### Misconception 3: CDC Captures All Changes
**Reality**: CDC only captures changes from configured sources. Need source system support.

### Misconception 4: Star Schema Always Best
**Reality**: Star schema optimized for analytics. Snowflake better for complex hierarchies.

## 🚀 Next Steps

With this understanding, you're ready to:
1. **Implement SCD patterns** for dimension management
2. **Design upsert strategies** for idempotent operations
3. **Choose between batch and streaming** based on latency requirements
4. **Implement CDC** for real-time data synchronization
5. **Model star schemas** for analytical workloads
6. **Apply data quality patterns** for reliable pipelines

---

**Remember**: Real-world data patterns are about matching the right approach to your requirements. Start simple (batch loading, SCD Type 1) and evolve to more complex patterns (CDC, SCD Type 2) as needed. Iceberg's flexibility allows you to start simple and add complexity incrementally.