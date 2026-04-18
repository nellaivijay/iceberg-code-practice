# Lab 3: Advanced Iceberg Features

## 🎯 Learning Objectives

After completing this lab, you will be able to:
- Implement advanced partitioning strategies
- Perform file compaction and maintenance
- Understand Iceberg's metadata-only query optimization
- Work with complex schema migrations
- Optimize Iceberg table performance

## 🛠️ Prerequisites

- Completed Lab 2: Basic Iceberg Operations
- Understanding of basic Iceberg concepts
- Spark shell configured with Iceberg

## 📋 Lab Steps

### Step 1: Advanced Partitioning Strategies

#### Partition Evolution

```scala
// Start with a simple partitioned table
spark.sql("""
  CREATE TABLE iceberg.default.sales (
    sale_id INT,
    product_id INT,
    sale_date DATE,
    amount DECIMAL(10,2),
    region STRING,
    salesperson STRING
  ) USING iceberg
  PARTITIONED BY (region)
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Insert initial data
spark.sql("""
  INSERT INTO iceberg.default.sales VALUES
    (1, 101, DATE '2024-01-01', 1000.50, 'east', 'alice'),
    (2, 102, DATE '2024-01-01', 750.25, 'west', 'bob'),
    (3, 103, DATE '2024-01-02', 500.75, 'east', 'alice'),
    (4, 104, DATE '2024-01-02', 1200.00, 'west', 'charlie')
""")

// Add second partition field (partition evolution)
spark.sql("""
  ALTER TABLE iceberg.default.sales
  ADD PARTITION FIELD days(sale_date)
""")

// Insert data with new partition structure
spark.sql("""
  INSERT INTO iceberg.default.sales VALUES
    (5, 105, DATE '2024-01-03', 800.00, 'east', 'bob'),
    (6, 106, DATE '2024-01-03', 950.50, 'west', 'alice')
""")

// Verify partition evolution
spark.sql("DESCRIBE EXTENDED iceberg.default.sales").show()

// Assertion 1: Partition evolution successful, table has two partition fields
```

**Assertion 1**: Partition evolution works, table now has both region and day(sale_date) partitions

### Step 2: Z-Ordering for Data Clustering

Z-ordering improves query performance by clustering related data.

```scala
// Create table with Z-ordering
spark.sql("""
  CREATE TABLE iceberg.default.transactions (
    transaction_id STRING,
    user_id INT,
    transaction_date TIMESTAMP,
    amount DECIMAL(10,2),
    merchant STRING,
    category STRING
  ) USING iceberg
  PARTITIONED BY (days(transaction_date))
  ORDER BY user_id, transaction_date
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet',
    'write.parquet.compression-codec'='gzip'
  )
""")

// Insert test data
spark.sql("""
  INSERT INTO iceberg.default.transactions VALUES
    ('txn001', 1, TIMESTAMP '2024-01-01 10:00:00', 100.00, 'amazon', 'electronics'),
    ('txn002', 1, TIMESTAMP '2024-01-01 14:00:00', 50.00, 'grocery', 'food'),
    ('txn003', 2, TIMESTAMP '2024-01-01 11:00:00', 200.00, 'amazon', 'electronics'),
    ('txn004', 2, TIMESTAMP '2024-01-02 09:00:00', 75.00, 'gas', 'fuel')
""")

// Verify data clustering
spark.sql("""
  SELECT * FROM iceberg.default.transactions
  WHERE user_id = 1
  ORDER BY transaction_date
""").show()

// Assertion 2: Z-ordering improves query performance for clustered columns
```

**Assertion 2**: Z-ordering configured successfully, data clustered by user_id and transaction_date

### Step 3: File Compaction and Maintenance

Iceberg tables can accumulate many small files over time. Compaction merges them.

```scala
// Create table that will need compaction
spark.sql("""
  CREATE TABLE iceberg.default.log_events (
    event_id STRING,
    timestamp TIMESTAMP,
    level STRING,
    message STRING,
    service STRING
  ) USING iceberg
  PARTITIONED BY (service, days(timestamp))
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Insert data in multiple small batches (simulating real-world scenario)
for (i <- 1 to 10) {
  spark.sql(s"""
    INSERT INTO iceberg.default.log_events VALUES
    ('evt${i}001', TIMESTAMP '2024-01-01 ${i}:00:00', 'INFO', 'Service started', 'api'),
    ('evt${i}002', TIMESTAMP '2024-01-01 ${i}:05:00', 'DEBUG', 'Request received', 'api'),
    ('evt${i}003', TIMESTAMP '2024-01-01 ${i}:10:00', 'INFO', 'Response sent', 'api')
  """)
}

// Check file count before compaction
spark.sql("""
  SELECT file, record_count, file_size_in_bytes
  FROM iceberg.default.log_events.files
  ORDER BY file
""").show()

// Perform compaction using Spark rewrite
spark.sql("""
  CALL iceberg.system.rewrite_data_files(
    'iceberg.default.log_events',
    map(
      'min-input-files', '5',
      'target-size-bytes', str(128 * 1024 * 1024)
    )
  )
""")

// Check file count after compaction
spark.sql("""
  SELECT file, record_count, file_size_in_bytes
  FROM iceberg.default.log_events.files
  ORDER BY file
""").show()

// Assertion 3: Compaction reduces file count and increases file sizes
```

**Assertion 3**: File compaction successful, fewer and larger files after rewrite

### Step 4: Metadata-Only Query Optimization

Iceberg can skip entire files based on metadata without reading data.

```scala
// Create large table for metadata optimization demo
spark.sql("""
  CREATE TABLE iceberg.default.sensor_data (
    sensor_id INT,
    reading_time TIMESTAMP,
    temperature DOUBLE,
    humidity DOUBLE,
    pressure DOUBLE,
    location STRING
  ) USING iceberg
  PARTITIONED BY (location, days(reading_time))
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Insert data with clear partition boundaries
spark.sql("""
  INSERT INTO iceberg.default.sensor_data VALUES
    (1, TIMESTAMP '2024-01-01 00:00:00', 20.5, 45.0, 1013.25, 'warehouse'),
    (2, TIMESTAMP '2024-01-01 01:00:00', 21.0, 46.0, 1013.30, 'warehouse'),
    (3, TIMESTAMP '2024-01-01 02:00:00', 20.8, 45.5, 1013.20, 'warehouse'),
    (4, TIMESTAMP '2024-01-02 00:00:00', 18.5, 50.0, 1012.80, 'office'),
    (5, TIMESTAMP '2024-01-02 01:00:00', 19.0, 49.0, 1012.90, 'office'),
    (6, TIMESTAMP '2024-01-03 00:00:00', 22.0, 40.0, 1014.00, 'warehouse')
""")

// Query that should use metadata-only filtering
spark.sql("""
  EXPLAIN EXTENDED
  SELECT * FROM iceberg.default.sensor_data
  WHERE location = 'office'
  AND reading_time >= TIMESTAMP '2024-01-02 00:00:00'
  AND reading_time < TIMESTAMP '2024-01-03 00:00:00'
""").show()

// Run the actual query
spark.sql("""
  SELECT * FROM iceberg.default.sensor_data
  WHERE location = 'office'
  AND reading_time >= TIMESTAMP '2024-01-02 00:00:00'
  AND reading_time < TIMESTAMP '2024-01-03 00:00:00'
""").show()

// Assertion 4: Query plan shows partition pruning and metadata-only filtering
```

**Assertion 4**: Metadata-only filtering reduces file scans, query plan shows partition pruning

### Step 5: Complex Schema Migrations

```scala
// Create table with initial schema
spark.sql("""
  CREATE TABLE iceberg.default.customer_profile (
    customer_id INT,
    name STRING,
    email STRING,
    phone STRING
  ) USING iceberg
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Insert initial data
spark.sql("""
  INSERT INTO iceberg.default.customer_profile VALUES
    (1, 'Alice', 'alice@example.com', '555-0101'),
    (2, 'Bob', 'bob@example.com', '555-0102')
""")

// Add new column with default value
spark.sql("""
  ALTER TABLE iceberg.default.customer_profile
  ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
""")

// Drop column
spark.sql("""
  ALTER TABLE iceberg.default.customer_profile
  DROP COLUMN phone
""")

// Rename column
spark.sql("""
  ALTER TABLE iceberg.default.customer_profile
  RENAME COLUMN email TO contact_email
""")

// Verify schema changes
spark.sql("DESCRIBE iceberg.default.customer_profile").show()

// Query to verify data integrity after migrations
spark.sql("SELECT * FROM iceberg.default.customer_profile").show()

// Assertion 5: Complex schema migrations preserve data integrity
```

**Assertion 5**: Complex schema migrations (add, drop, rename) work correctly

### Step 6: Performance Tuning

```scala
// Create table with performance optimizations
spark.sql("""
  CREATE TABLE iceberg.default.optimized_table (
    id INT,
    category STRING,
    value DOUBLE,
    timestamp TIMESTAMP,
    metadata STRING
  ) USING iceberg
  PARTITIONED BY (category, days(timestamp))
  ORDER BY id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet',
    'write.parquet.compression-codec'='zstd',
    'write.metadata.compression-codec'='gzip',
    'write.summary.partition.limit' = '10',
    'write.summary.target-size-bytes' = str(64 * 1024 * 1024)
  )
""")

// Insert test data
spark.sql("""
  INSERT INTO iceberg.default.optimized_table VALUES
    (1, 'A', 100.0, TIMESTAMP '2024-01-01 00:00:00', 'test'),
    (2, 'A', 200.0, TIMESTAMP '2024-01-01 01:00:00', 'test'),
    (3, 'B', 150.0, TIMESTAMP '2024-01-01 02:00:00', 'test'),
    (4, 'B', 250.0, TIMESTAMP '2024-01-02 00:00:00', 'test')
""")

// Compare query performance
import org.apache.spark.sql.functions._

// Query without optimizations
val startTime1 = System.currentTimeMillis()
spark.sql("""
  SELECT category, AVG(value) as avg_value
  FROM iceberg.default.optimized_table
  GROUP BY category
""").collect()
val duration1 = System.currentTimeMillis() - startTime1

// Query with optimizations (partition pruning)
val startTime2 = System.currentTimeMillis()
spark.sql("""
  SELECT category, AVG(value) as avg_value
  FROM iceberg.default.optimized_table
  WHERE category = 'A'
  GROUP BY category
""").collect()
val duration2 = System.currentTimeMillis() - startTime2

println(s"Query 1 duration: ${duration1}ms")
println(s"Query 2 duration: ${duration2}ms")

// Assertion 6: Optimized queries show performance improvement
```

**Assertion 6**: Performance optimizations (compression, partitioning, ordering) improve query speed

## ✅ Lab Completion Checklist

- [ ] Partition evolution successfully implemented
- [ ] Z-ordering configured for data clustering
- [ ] File compaction reduces file count
- [ ] Metadata-only query optimization working
- [ ] Complex schema migrations preserve data integrity
- [ ] Performance tuning shows measurable improvements

## 🔍 Troubleshooting

### Issue: Partition evolution fails
**Solution**: Ensure new partition field is compatible with existing data

### Issue: Compaction doesn't reduce file count
**Solution**: Adjust min-input-files and target-size-bytes parameters

### Issue: Metadata-only filtering not working
**Solution**: Verify partition predicates and Iceberg version compatibility

### Issue: Schema migration breaks queries
**Solution**: Check for existing data that conflicts with new schema

## 🎓 Key Concepts Learned

1. **Partition Evolution**: Adding partition fields to existing tables
2. **Z-Ordering**: Data clustering for improved query performance
3. **File Compaction**: Merging small files for better performance
4. **Metadata-Only Filtering**: Skipping files based on partition metadata
5. **Schema Migrations**: Complex schema changes while preserving data
6. **Performance Tuning**: Compression, partitioning, and ordering strategies

## 🚀 Next Steps

Proceed to **Lab 4: Iceberg + Spark Optimizations** to learn about:
- File compaction strategies
- Snapshot management
- Query planning optimization
- Advanced performance tuning