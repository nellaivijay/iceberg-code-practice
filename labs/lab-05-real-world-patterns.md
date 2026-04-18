# Lab 5: Real-World Data Patterns

## 🎯 Learning Objectives

After completing this lab, you will be able to:
- Implement Slowly Changing Dimensions (SCD) with Iceberg
- Perform upsert operations efficiently
- Handle batch and streaming data patterns
- Model real-world scenarios with Iceberg tables
- Apply CDC (Change Data Capture) patterns

## 🛠️ Prerequisites

- Completed Lab 4: Iceberg + Spark Optimizations
- Understanding of data modeling concepts
- Spark shell configured with Iceberg

## 📋 Lab Steps

### Step 1: Slowly Changing Dimensions (SCD)

#### SCD Type 2 Implementation

```scala
// Create customer dimension table
spark.sql("""
  CREATE TABLE iceberg.default.customer_dim (
    customer_key INT,
    customer_id STRING,
    name STRING,
    email STRING,
    address STRING,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_current BOOLEAN
  ) USING iceberg
  PARTITIONED BY (is_current)
  ORDER BY customer_id, valid_from
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Insert initial customer records (SCD Type 2)
spark.sql("""
  INSERT INTO iceberg.default.customer_dim VALUES
    (1, 'CUST001', 'Alice Johnson', 'alice@example.com', '123 Main St', 
     TIMESTAMP '2024-01-01 00:00:00', TIMESTAMP '9999-12-31 23:59:59', true),
    (2, 'CUST002', 'Bob Smith', 'bob@example.com', '456 Oak Ave', 
     TIMESTAMP '2024-01-01 00:00:00', TIMESTAMP '9999-12-31 23:59:59', true),
    (3, 'CUST003', 'Charlie Brown', 'charlie@example.com', '789 Pine Rd', 
     TIMESTAMP '2024-01-01 00:00:00', TIMESTAMP '9999-12-31 23:59:59', true)
""")

// Simulate customer change (Alice moves)
val currentTime = "2024-01-15 00:00:00"

// First, expire old record
spark.sql(s"""
  UPDATE iceberg.default.customer_dim
  SET valid_to = TIMESTAMP '$currentTime',
      is_current = false
  WHERE customer_id = 'CUST001' AND is_current = true
""")

// Then insert new record
spark.sql(s"""
  INSERT INTO iceberg.default.customer_dim VALUES
    (4, 'CUST001', 'Alice Johnson', 'alice.new@example.com', '456 New St', 
     TIMESTAMP '$currentTime', TIMESTAMP '9999-12-31 23:59:59', true)
""")

// Query customer history
spark.sql("""
  SELECT * FROM iceberg.default.customer_dim
  WHERE customer_id = 'CUST001'
  ORDER BY valid_from
""").show()

// Assertion 1: SCD Type 2 maintains history of customer changes
```

**Assertion 1**: SCD Type 2 implementation maintains complete history with valid_from/valid_to

### Step 2: Upsert Operations

```scala
// Create orders fact table for upsert operations
spark.sql("""
  CREATE TABLE iceberg.default.orders_fact (
    order_id INT,
    customer_id STRING,
    order_date DATE,
    amount DECIMAL(10,2),
    status STRING,
    last_updated TIMESTAMP
  ) USING iceberg
  PARTITIONED BY (order_date)
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet',
    'write.metadata.compression-codec'='gzip'
  )
""")

// Insert initial orders
spark.sql("""
  INSERT INTO iceberg.default.orders_fact VALUES
    (1, 'CUST001', DATE '2024-01-01', 100.50, 'pending', TIMESTAMP '2024-01-01 00:00:00'),
    (2, 'CUST002', DATE '2024-01-01', 200.75, 'pending', TIMESTAMP '2024-01-01 00:00:00'),
    (3, 'CUST003', DATE '2024-01-02', 150.25, 'pending', TIMESTAMP '2024-01-02 00:00:00')
""")

// Perform upsert (update existing, insert new)
// First, create staging table with new/updated data
spark.sql("""
  CREATE TABLE iceberg.default.orders_staging (
    order_id INT,
    customer_id STRING,
    order_date DATE,
    amount DECIMAL(10,2),
    status STRING,
    last_updated TIMESTAMP
  ) USING iceberg
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Load staging data (updates and inserts)
spark.sql("""
  INSERT INTO iceberg.default.orders_staging VALUES
    (2, 'CUST002', DATE '2024-01-01', 250.75, 'shipped', TIMESTAMP '2024-01-03 00:00:00'),  -- Update
    (4, 'CUST001', DATE '2024-01-03', 300.00, 'pending', TIMESTAMP '2024-01-03 00:00:00')   -- Insert
""")

// Perform upsert using MERGE
spark.sql("""
  MERGE INTO iceberg.default.orders_fact AS target
  USING iceberg.default.orders_staging AS source
  ON target.order_id = source.order_id
  WHEN MATCHED THEN
    UPDATE SET
      customer_id = source.customer_id,
      amount = source.amount,
      status = source.status,
      last_updated = source.last_updated
  WHEN NOT MATCHED THEN
    INSERT *
""")

// Verify upsert results
spark.sql("SELECT * FROM iceberg.default.orders_fact ORDER BY order_id").show()

// Assertion 2: Upsert correctly updates existing and inserts new records
```

**Assertion 2**: MERGE operation performs upsert correctly, updating existing and inserting new records

### Step 3: Batch and Streaming Patterns

#### Batch Pattern - Daily Data Loading

```scala
// Create table for daily batch loading
spark.sql("""
  CREATE TABLE iceberg.default.daily_sales (
    sale_date DATE,
    product_id INT,
    quantity INT,
    revenue DECIMAL(10,2),
    region STRING,
    load_timestamp TIMESTAMP
  ) USING iceberg
  PARTITIONED BY (sale_date)
  ORDER BY product_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Simulate daily batch loads
val dates = Seq("2024-01-01", "2024-01-02", "2024-01-03")

for (date <- dates) {
  spark.sql(s"""
    INSERT INTO iceberg.default.daily_sales VALUES
    (DATE '$date', 101, 10, 1000.00, 'west', CURRENT_TIMESTAMP),
    (DATE '$date', 102, 15, 1500.00, 'east', CURRENT_TIMESTAMP),
    (DATE '$date', 103, 8, 800.00, 'west', CURRENT_TIMESTAMP)
  """)
  
  // Simulate daily compaction
  spark.sql("""
    CALL iceberg.system.rewrite_data_files(
      'iceberg.default.daily_sales',
      map(
        'min-input-files', '3',
        'target-size-bytes', str(128 * 1024 * 1024)
      )
    )
  """)
}

// Query daily sales
spark.sql("""
  SELECT 
    sale_date, 
    SUM(quantity) as total_quantity,
    SUM(revenue) as total_revenue
  FROM iceberg.default.daily_sales
  GROUP BY sale_date
  ORDER BY sale_date
""").show()

// Assertion 3: Batch loading with daily compaction works correctly
```

**Assertion 3**: Daily batch loading with compaction produces clean partition structure

#### Streaming Pattern - Micro-batch Processing

```scala
// Create table for micro-batch processing
spark.sql("""
  CREATE TABLE iceberg.default.stream_events (
    event_id STRING,
    event_timestamp TIMESTAMP,
    event_type STRING,
    user_id INT,
    data STRING,
    processed_timestamp TIMESTAMP
  ) USING iceberg
  PARTITIONED BY (event_type, hours(event_timestamp))
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Simulate micro-batch processing
val batchSizes = Seq(5, 3, 4, 6, 3)
var eventIdCounter = 1

for (batchSize <- batchSizes) {
  val batchValues = (1 to batchSize).map { i =>
    s"(${eventIdCounter + i}, TIMESTAMP '2024-01-01 ${10 + i}:00:00', 'click', ${i}, '{\"page\":\"/product\"}', CURRENT_TIMESTAMP)"
  }.mkString(",")
  
  spark.sql(s"""
    INSERT INTO iceberg.default.stream_events VALUES $batchValues
  """)
  
  eventIdCounter += batchSize
  
  // Simulate micro-batch delay
  Thread.sleep(100)
}

// Query streaming data
spark.sql("""
  SELECT 
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
  FROM iceberg.default.stream_events
  GROUP BY event_type
""").show()

// Assertion 4: Micro-batch processing handles incremental data correctly
```

**Assertion 4**: Micro-batch processing pattern handles incremental data correctly

### Step 4: CDC (Change Data Capture) Pattern

```scala
// Create source table (simulating operational system)
spark.sql("""
  CREATE TABLE iceberg.default.source_transactions (
    transaction_id STRING,
    customer_id STRING,
    amount DECIMAL(10,2),
    transaction_type STRING,
    transaction_timestamp TIMESTAMP,
    cdc_operation STRING,  -- INSERT, UPDATE, DELETE
    cdc_timestamp TIMESTAMP
  ) USING iceberg
  PARTITIONED BY (cdc_operation)
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Create target table (data warehouse)
spark.sql("""
  CREATE TABLE iceberg.default.target_transactions (
    transaction_id STRING,
    customer_id STRING,
    amount DECIMAL(10,2),
    transaction_type STRING,
    transaction_timestamp TIMESTAMP,
    last_updated TIMESTAMP
  ) USING iceberg
  PARTITIONED BY (transaction_type)
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Simulate CDC data stream
spark.sql("""
  INSERT INTO iceberg.default.source_transactions VALUES
  ('txn001', 'CUST001', 100.50, 'purchase', TIMESTAMP '2024-01-01 10:00:00', 'INSERT', TIMESTAMP '2024-01-01 10:00:00'),
  ('txn002', 'CUST002', 200.75, 'purchase', TIMESTAMP '2024-01-01 11:00:00', 'INSERT', TIMESTAMP '2024-01-01 11:00:00'),
  ('txn001', 'CUST001', 105.50, 'purchase', TIMESTAMP '2024-01-01 10:00:00', 'UPDATE', TIMESTAMP '2024-01-01 12:00:00'),
  ('txn003', 'CUST003', 150.25, 'purchase', TIMESTAMP '2024-01-01 13:00:00', 'INSERT', TIMESTAMP '2024-01-01 13:00:00')
""")

// Process CDC changes
spark.sql("""
  MERGE INTO iceberg.default.target_transactions AS target
  USING (
    SELECT 
      transaction_id,
      customer_id,
      amount,
      transaction_type,
      transaction_timestamp,
      cdc_timestamp as last_updated
    FROM iceberg.default.source_transactions
    WHERE cdc_operation IN ('INSERT', 'UPDATE')
  ) AS source
  ON target.transaction_id = source.transaction_id
  WHEN MATCHED THEN
    UPDATE SET
      customer_id = source.customer_id,
      amount = source.amount,
      transaction_type = source.transaction_type,
      transaction_timestamp = source.transaction_timestamp,
      last_updated = source.last_updated
  WHEN NOT MATCHED THEN
    INSERT *
""")

// Handle CDC deletes
spark.sql("""
  DELETE FROM iceberg.default.target_transactions
  WHERE transaction_id IN (
    SELECT transaction_id 
    FROM iceberg.default.source_transactions 
    WHERE cdc_operation = 'DELETE'
  )
""")

// Verify CDC processing
spark.sql("SELECT * FROM iceberg.default.target_transactions ORDER BY transaction_timestamp").show()

// Assertion 5: CDC pattern correctly handles INSERT, UPDATE, DELETE operations
```

**Assertion 5**: CDC pattern correctly synchronizes changes from source to target

### Step 5: Real-World Data Modeling

```scala
// Implement star schema with Iceberg
// Dimensions: customer_dim, product_dim, time_dim
// Facts: sales_fact

// Time dimension
spark.sql("""
  CREATE TABLE iceberg.default.time_dim (
    time_id INT,
    date_value DATE,
    day_of_month INT,
    month INT,
    year INT,
    quarter INT,
    day_of_week INT,
    is_holiday BOOLEAN
  ) USING iceberg
  PARTITIONED BY (year, quarter)
  ORDER BY date_value
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Populate time dimension
spark.sql("""
  INSERT INTO iceberg.default.time_dim VALUES
  (1, DATE '2024-01-01', 1, 1, 2024, 1, 1, true),
  (2, DATE '2024-01-02', 2, 1, 2024, 1, 2, false),
  (3, DATE '2024-01-03', 3, 1, 2024, 1, 3, false),
  (4, DATE '2024-01-04', 4, 1, 2024, 1, 4, false)
""")

// Product dimension
spark.sql("""
  CREATE TABLE iceberg.default.product_dim (
    product_id INT,
    product_name STRING,
    category STRING,
    subcategory STRING,
    brand STRING,
    unit_price DECIMAL(10,2),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN
  ) USING iceberg
  PARTITIONED BY (category, is_current)
  ORDER BY product_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Populate product dimension
spark.sql("""
  INSERT INTO iceberg.default.product_dim VALUES
    (101, 'Laptop Pro', 'Electronics', 'Computers', 'TechBrand', 999.99, 
     TIMESTAMP '2024-01-01 00:00:00', TIMESTAMP '9999-12-31 23:59:59', true),
    (102, 'Wireless Mouse', 'Electronics', 'Accessories', 'TechBrand', 29.99, 
     TIMESTAMP '2024-01-01 00:00:00', TIMESTAMP '9999-12-31 23:59:59', true),
    (103, 'Office Chair', 'Furniture', 'Seating', 'ComfortBrand', 199.99, 
     TIMESTAMP '2024-01-01 00:00:00', TIMESTAMP '9999-12-31 23:59:59', true)
""")

// Sales fact table
spark.sql("""
  CREATE TABLE iceberg.default.sales_fact (
    sale_id INT,
    time_id INT,
    customer_id INT,
    product_id INT,
    store_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    discount_amount DECIMAL(10,2)
  ) USING iceberg
  PARTITIONED BY (store_id)
  ORDER BY time_id, customer_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Populate sales fact
spark.sql("""
  INSERT INTO iceberg.default.sales_fact VALUES
  (1, 1, 1, 101, 1, 2, 999.99, 1999.98, 0.00),
  (2, 2, 1, 102, 1, 5, 29.99, 149.95, 10.00),
  (3, 3, 2, 103, 1, 1, 199.99, 199.99, 0.00),
  (4, 1, 2, 101, 2, 3, 999.99, 2999.97, 0.00),
  (5, 2, 3, 102, 2, 2, 29.99, 59.98, 0.00)
""")

// Query star schema
spark.sql("""
  SELECT 
    d.product_name,
    d.category,
    SUM(f.total_amount) as total_revenue,
    SUM(f.quantity) as total_quantity
  FROM iceberg.default.sales_fact f
  JOIN iceberg.default.product_dim d ON f.product_id = d.product_id
  JOIN iceberg.default.time_dim t ON f.time_id = t.time_id
  WHERE d.is_current = true
  GROUP BY d.product_name, d.category
  ORDER BY total_revenue DESC
""").show()

// Assertion 6: Star schema with Iceberg dimensions and fact table works correctly
```

**Assertion 6**: Star schema implementation supports complex analytical queries

## ✅ Lab Completion Checklist

- [ ] SCD Type 2 maintains complete customer history
- [ ] Upsert operations using MERGE work correctly
- [ ] Batch loading with daily compaction produces clean partitions
- [ ] Micro-batch processing handles incremental data correctly
- [ ] CDC pattern synchronizes changes from source to target
- [ ] Star schema supports complex analytical queries

## 🔍 Troubleshooting

### Issue: SCD Type 2 creates duplicate records
**Solution**: Ensure proper expiration logic before inserting new records

### Issue: MERGE operation fails with constraint violations
**Solution**: Check for duplicate keys in staging data

### Issue: Batch loading creates too many small files
**Solution**: Increase batch size or implement file coalescing

### Issue: CDC processing misses updates
**Solution**: Verify CDC operation types and timestamp handling

## 🎓 Key Concepts Learned

1. **SCD Type 2**: Maintaining historical dimension data with valid_from/valid_to
2. **Upsert Operations**: Using MERGE for insert-or-update logic
3. **Batch Patterns**: Daily data loading with compaction
4. **Streaming Patterns**: Micro-batch processing for incremental data
5. **CDC Pattern**: Change data capture for synchronizing operational systems
6. **Star Schema**: Dimensional modeling with Iceberg for analytical queries

## 🚀 Next Steps

Proceed to **Lab 6: Performance & UI** to learn about:
- Complex Iceberg join operations
- Spark History Server UI exploration
- DAG inspection and metadata-only filtering
- Performance analysis and optimization