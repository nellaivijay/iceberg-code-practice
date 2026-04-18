# Lab 4: Iceberg + Spark Optimizations

## 🎯 Learning Objectives

After completing this lab, you will be able to:
- Optimize Iceberg file compaction strategies
- Manage Iceberg snapshots for performance
- Configure Spark for optimal Iceberg query planning
- Implement efficient data loading patterns
- Monitor and tune Iceberg table performance

## 🛠️ Prerequisites

- Completed Lab 3: Advanced Iceberg Features
- Understanding of Iceberg file structure
- Spark shell configured with Iceberg

## 📋 Lab Steps

### Step 1: File Compaction Strategies

#### Bin-Packing Compaction

```scala
// Create table with many small files
spark.sql("""
  CREATE TABLE iceberg.default.compaction_test (
    id INT,
    category STRING,
    value DOUBLE,
    timestamp TIMESTAMP
  ) USING iceberg
  PARTITIONED BY (category, days(timestamp))
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Insert data in small batches (simulating streaming writes)
for (batch <- 1 to 20) {
  spark.sql(s"""
    INSERT INTO iceberg.default.compaction_test VALUES
    (${batch * 10 + 1}, 'A', 100.0 * batch, TIMESTAMP '2024-01-01 ${batch % 24}:00:00'),
    (${batch * 10 + 2}, 'A', 200.0 * batch, TIMESTAMP '2024-01-01 ${batch % 24}:05:00'),
    (${batch * 10 + 3}, 'B', 150.0 * batch, TIMESTAMP '2024-01-01 ${batch % 24}:10:00')
  """)
}

// Check file count before compaction
val filesBefore = spark.sql("""
  SELECT COUNT(*) as file_count
  FROM iceberg.default.compaction_test.files
""").collect().head.getLong(0)

println(s"File count before compaction: $filesBefore")

// Perform bin-packing compaction
spark.sql("""
  CALL iceberg.system.rewrite_data_files(
    'iceberg.default.compaction_test',
    map(
      'min-input-files', '5',
      'target-size-bytes', str(256 * 1024 * 1024)
    )
  )
""")

// Check file count after compaction
val filesAfter = spark.sql("""
  SELECT COUNT(*) as file_count
  FROM iceberg.default.compaction_test.files
""").collect().head.getLong(0)

println(s"File count after compaction: $filesAfter")

// Assertion 1: Compaction reduces file count significantly
assert(filesAfter < filesBefore, "Compaction should reduce file count")
```

**Assertion 1**: Bin-packing compaction reduces file count by merging small files

### Step 2: Snapshot Management

```scala
// Create table and generate multiple snapshots
spark.sql("""
  CREATE TABLE iceberg.default.snapshot_test (
    id INT,
    value DOUBLE,
    timestamp TIMESTAMP
  ) USING iceberg
  PARTITIONED BY (days(timestamp))
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Generate multiple snapshots through updates
for (i <- 1 to 5) {
  spark.sql(s"""
    INSERT INTO iceberg.default.snapshot_test VALUES
    ($i, 100.0 * $i, TIMESTAMP '2024-01-01 ${i}:00:00')
  """)
  
  // Update some data to create new snapshots
  spark.sql(s"""
    UPDATE iceberg.default.snapshot_test
    SET value = value * 1.1
    WHERE id = $i
  """)
}

// List all snapshots
spark.sql("""
  SELECT 
    snapshot_id,
    committed_at,
    summary['operation'] as operation,
    summary['added-files-size'] as added_files_size
  FROM iceberg.default.snapshot_test.snapshots
  ORDER BY committed_at DESC
""").show()

// Expire old snapshots (keep only recent ones)
spark.sql("""
  CALL iceberg.system.expire_snapshots(
    'iceberg.default.snapshot_test',
    map(
      'retain-last', '3'
    )
  )
""")

// Verify snapshot expiration
spark.sql("""
  SELECT COUNT(*) as snapshot_count
  FROM iceberg.default.snapshot_test.snapshots
""").show()

// Assertion 2: Snapshot expiration reduces snapshot count
```

**Assertion 2**: Snapshot management successfully removes old snapshots

### Step 3: Spark Query Planning Optimization

```scala
// Configure Spark for optimal Iceberg query planning
spark.conf.set("spark.sql.iceberg.planning.enabled", "true")
spark.conf.set("spark.sql.iceberg.planning.mode", "distributed")
spark.conf.set("spark.sql.iceberg.pushdown.enabled", "true")

// Create table for query planning tests
spark.sql("""
  CREATE TABLE iceberg.default.query_planning_test (
    user_id INT,
    product_id INT,
    purchase_date DATE,
    amount DECIMAL(10,2),
    category STRING,
    region STRING
  ) USING iceberg
  PARTITIONED BY (region, years(purchase_date))
  ORDER BY user_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Insert test data
spark.sql("""
  INSERT INTO iceberg.default.query_planning_test VALUES
    (1, 101, DATE '2024-01-01', 100.50, 'electronics', 'west'),
    (2, 102, DATE '2024-01-02', 200.75, 'electronics', 'east'),
    (3, 103, DATE '2024-01-03', 150.25, 'clothing', 'west'),
    (4, 104, DATE '2024-01-04', 300.00, 'electronics', 'east'),
    (5, 105, DATE '2024-01-05', 175.50, 'clothing', 'west')
""")

// Test query with explain plan
spark.sql("""
  EXPLAIN EXTENDED
  SELECT user_id, SUM(amount) as total_spent
  FROM iceberg.default.query_planning_test
  WHERE region = 'west'
  AND purchase_date >= DATE '2024-01-01'
  GROUP BY user_id
""").show()

// Run the actual query
spark.sql("""
  SELECT user_id, SUM(amount) as total_spent
  FROM iceberg.default.query_planning_test
  WHERE region = 'west'
  AND purchase_date >= DATE '2024-01-01'
  GROUP BY user_id
""").show()

// Assertion 3: Query plan shows partition pruning and predicate pushdown
```

**Assertion 3**: Spark query planning optimization shows partition pruning and predicate pushdown

### Step 4: Efficient Data Loading Patterns

```scala
// Batch data loading with coalescing
val largeDataset = spark.range(100000)
  .withColumn("id", col("id") + 1)
  .withColumn("category", when(col("id") % 3 === 0, "A")
    .when(col("id") % 3 === 1, "B")
    .otherwise("C"))
  .withColumn("value", col("id") * 1.0)
  .withColumn("timestamp", current_timestamp())

// Coalesce partitions before writing (control file size)
largeDataset.coalesce(10).writeTo("iceberg.default.efficient_loading")
  .tableAppend()

// Check file sizes after controlled loading
spark.sql("""
  SELECT file, record_count, file_size_in_bytes
  FROM iceberg.default.efficient_loading.files
  ORDER BY file_size_in_bytes DESC
""").show()

// Assertion 4: Controlled partitioning results in optimal file sizes
```

**Assertion 4**: Data loading with controlled partitioning produces optimal file sizes

### Step 5: Performance Monitoring

```scala
// Monitor table performance metrics
spark.sql("""
  SELECT 
    file,
    record_count,
    file_size_in_bytes,
    column_size,
    value_count,
    null_value_count,
    nan_value_count
  FROM iceberg.default.efficient_loading.files
""").show()

// Check manifest statistics
spark.sql("""
  SELECT 
    manifest_path,
    length,
    partition_summaries,
    added_files_count,
    added_records_count,
    deleted_files_count,
    deleted_records_count
  FROM iceberg.default.efficient_loading.all_manifests
  ORDER BY length DESC
  LIMIT 5
""").show()

// Assertion 5: Performance metrics provide insights into table optimization
```

**Assertion 5**: Performance monitoring metrics show table optimization opportunities

### Step 6: Dynamic File Pruning

```scala
// Create table for dynamic file pruning test
spark.sql("""
  CREATE TABLE iceberg.default.dynamic_pruning_test (
    event_id STRING,
    user_id INT,
    event_timestamp TIMESTAMP,
    event_type STRING,
    page_url STRING,
    session_id STRING
  ) USING iceberg
  PARTITIONED BY (event_type, days(event_timestamp))
  ORDER BY user_id, event_timestamp
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Insert test data
spark.sql("""
  INSERT INTO iceberg.default.dynamic_pruning_test VALUES
    ('evt001', 1, TIMESTAMP '2024-01-01 10:00:00', 'pageview', '/home', 'session1'),
    ('evt002', 1, TIMESTAMP '2024-01-01 10:05:00', 'click', '/product/1', 'session1'),
    ('evt003', 2, TIMESTAMP '2024-01-01 11:00:00', 'pageview', '/home', 'session2'),
    ('evt004', 2, TIMESTAMP '2024-01-02 09:00:00', 'purchase', '/checkout', 'session2'),
    ('evt005', 1, TIMESTAMP '2024-01-02 14:00:00', 'pageview', '/products', 'session1')
""")

// Query with dynamic file pruning
spark.sql("""
  EXPLAIN EXTENDED
  SELECT user_id, COUNT(*) as event_count
  FROM iceberg.default.dynamic_pruning_test
  WHERE event_type = 'pageview'
  AND event_timestamp >= TIMESTAMP '2024-01-01 00:00:00'
  AND event_timestamp < TIMESTAMP '2024-01-03 00:00:00'
  GROUP BY user_id
""").show()

// Run actual query
spark.sql("""
  SELECT user_id, COUNT(*) as event_count
  FROM iceberg.default.dynamic_pruning_test
  WHERE event_type = 'pageview'
  AND event_timestamp >= TIMESTAMP '2024-01-01 00:00:00'
  AND event_timestamp < TIMESTAMP '2024-01-03 00:00:00'
  GROUP BY user_id
""").show()

// Assertion 6: Dynamic file pruning reduces data scan based on query predicates
```

**Assertion 6**: Dynamic file pruning optimizes query performance by reducing data scan

## ✅ Lab Completion Checklist

- [ ] File compaction strategies implemented and tested
- [ ] Snapshot management successfully removes old snapshots
- [ ] Spark query planning optimization shows partition pruning
- [ ] Efficient data loading patterns produce optimal file sizes
- [ ] Performance monitoring metrics provide optimization insights
- [ ] Dynamic file pruning reduces data scan effectively

## 🔍 Troubleshooting

### Issue: Compaction doesn't reduce file count
**Solution**: Adjust min-input-files and target-size-bytes parameters

### Issue: Snapshot expiration fails
**Solution**: Ensure snapshots are not referenced by active queries

### Issue: Query planning not optimizing
**Solution**: Verify Iceberg planning configuration and Spark version compatibility

### Issue: Data loading produces too many small files
**Solution**: Use coalesce() or repartition() before writing

## 🎓 Key Concepts Learned

1. **File Compaction**: Bin-packing and sorting strategies for file optimization
2. **Snapshot Management**: Expiring old snapshots to maintain performance
3. **Query Planning**: Spark optimization for Iceberg queries
4. **Data Loading**: Efficient patterns for controlled file sizes
5. **Performance Monitoring**: Metrics and statistics for optimization
6. **Dynamic File Pruning**: Reducing data scan based on query predicates

## 🚀 Next Steps

Proceed to **Lab 5: Real-World Data Patterns** to learn about:
- Slowly Changing Dimensions (SCD)
- Upsert operations
- Batch and streaming patterns
- Real-world data modeling with Iceberg