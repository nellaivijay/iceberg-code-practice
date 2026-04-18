# Best Practices for Apache Iceberg

This guide covers production-ready patterns and tips for working with Apache Iceberg in data lakehouse environments.

## Table Design Best Practices

### 1. Partitioning Strategies

**Good Practices:**
```sql
-- Partition by date for time-series data
CREATE TABLE orders (
    order_id BIGINT,
    order_date DATE,
    customer_id BIGINT,
    amount DECIMAL(10,2)
) USING iceberg
PARTITIONED BY (years(order_date), months(order_date));

-- Partition by high-cardinality column for selective queries
CREATE TABLE events (
    event_id BIGINT,
    user_id BIGINT,
    event_timestamp TIMESTAMP,
    event_type STRING
) USING iceberg
PARTITIONED BY (bucket(16, user_id));

-- Combine partitioning strategies
CREATE TABLE transactions (
    transaction_id BIGINT,
    account_id BIGINT,
    transaction_date DATE,
    amount DECIMAL(10,2)
) USING iceberg
PARTITIONED BY (days(transaction_date), bucket(8, account_id));
```

**Avoid:**
- Over-partitioning (too many small files)
- Partitioning by low-cardinality columns
- Partitioning by columns with high null rates

### 2. Schema Evolution

**Good Practices:**
```sql
-- Add new columns at the end
ALTER TABLE my_table ADD COLUMN new_column STRING;

-- Use column types that support evolution
-- Avoid changing column types that break compatibility

-- Document schema changes
-- Maintain schema versioning
```

**Avoid:**
- Dropping columns that might be needed
- Changing column names without migration
- Incompatible type changes (e.g., INT to STRING)

### 3. Z-Ordering for Performance

```sql
-- Z-ORDER by frequently filtered columns
ALTER TABLE my_table WRITE ORDERED BY (customer_id, order_date);

-- Combine Z-ORDER with partitioning
CREATE TABLE large_table (
    id BIGINT,
    customer_id BIGINT,
    event_date DATE,
    event_type STRING
) USING iceberg
PARTITIONED BY (days(event_date))
-- Later: ALTER TABLE large_table WRITE ORDERED BY (customer_id);
```

## Query Optimization

### 1. Use Metadata Filtering

```sql
-- Iceberg can filter using metadata without reading files
-- This happens automatically for partition columns and Z-ORDERed columns

-- Good: Filter on partitioned columns
SELECT * FROM orders 
WHERE order_date >= '2026-01-01' 
  AND order_date < '2026-02-01';

-- Good: Filter on Z-ORDERed columns
SELECT * FROM events 
WHERE user_id = 12345;

-- Avoid: Non-selective filters
SELECT * FROM orders WHERE amount > 0;
```

### 2. Leverage Snapshots for Time Travel

```sql
-- Query as of specific timestamp
SELECT * FROM orders 
AS OF SYSTEM TIME '2026-04-01 12:00:00';

-- Query specific snapshot
SELECT * FROM orders 
VERSION AS OF 123456;

-- Compare snapshots
SELECT * FROM orders 
VERSION AS OF 123456
FULL OUTER JOIN 
orders VERSION AS OF 123457
USING (order_id);
```

### 3. Use Appropriate File Formats

```sql
-- Parquet for analytical workloads (default)
CREATE TABLE analytics USING iceberg AS SELECT * FROM source;

-- Consider ORC for specific use cases
-- Avro for write-heavy workloads
```

## Data Ingestion Patterns

### 1. Batch Ingestion

```python
# Good: Use append mode for idempotent operations
df.write.format("iceberg") \
    .mode("append") \
    .save("catalog.db.table")

# Good: Use overwrite partition for partial updates
df.write.format("iceberg") \
    .mode("overwrite") \
    .option("overwrite-partition", "true") \
    .partitionBy("date") \
    .save("catalog.db.table")
```

### 2. Streaming Ingestion

```python
# Good: Use exactly-once semantics
streaming_df.writeStream \
    .format("iceberg") \
    .outputMode("append") \
    .option("checkpointLocation", "/path/to/checkpoint") \
    .toTable("catalog.db.table")

# Good: Handle schema evolution
streaming_df.writeStream \
    .format("iceberg") \
    .option("mergeSchema", "true") \
    .toTable("catalog.db.table")
```

### 3. Upsert Patterns

```sql
-- Good: Use MERGE for upserts
MERGE INTO target t
USING source s
ON t.id = s.id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *

-- Good: Use row-level deletes for soft deletes
DELETE FROM target WHERE id IN (SELECT id FROM source WHERE is_deleted = true)
```

## Table Maintenance

### 1. Regular Compaction

```sql
-- Compact small files
CALL catalog.system.rewrite_data_files('catalog.db.table')

-- Compact with options
CALL catalog.system.rewrite_data_files(
    'catalog.db.table',
    map('min_input_files', '5')
)
```

### 2. Snapshot Management

```sql
-- Expire old snapshots
CALL catalog.system.expire_snapshots(
    'catalog.db.table',
    TIMESTAMP '2026-01-01 00:00:00'
)

-- Keep last N snapshots
CALL catalog.system.expire_snapshots(
    'catalog.db.table',
    TIMESTAMP '2026-01-01 00:00:00',
    10  -- retain last 10 snapshots
)
```

### 3. Orphan File Cleanup

```sql
-- Clean up orphaned files
CALL catalog.system.remove_orphan_files(
    'catalog.db.table',
    TIMESTAMP '2026-01-01 00:00:00'
)
```

## Multi-Engine Considerations

### 1. Schema Consistency

```sql
-- Use Iceberg's schema evolution across engines
-- All engines will see the same schema

-- Be aware of engine-specific type mappings
-- Test data types across all engines you use
```

### 2. Engine-Specific Optimizations

```python
# Spark: Use DataFrame API for complex transformations
df.filter(col("date") >= "2026-01-01") \
  .groupBy("customer_id") \
  .agg(sum("amount"))

# Trino: Use SQL for interactive queries
SELECT customer_id, SUM(amount) 
FROM orders 
WHERE date >= DATE '2026-01-01' 
GROUP BY customer_id

# DuckDB: Use for local analytics and testing
# Great for quick prototyping
```

### 3. Cross-Engine Best Practices

- Test queries in multiple engines
- Understand performance characteristics
- Use appropriate engine for workload:
  - Spark: ETL, batch processing
  - Trino: Interactive analytics
  - DuckDB: Local analysis, prototyping

## Performance Monitoring

### 1. Query Planning

```python
# Explain query plan
df.explain()

# Check for metadata-only queries
# These should be very fast
```

### 2. File Size Monitoring

```sql
-- Check file sizes and counts
SELECT file_path, file_size_in_bytes, record_count
FROM catalog.db.table.files;

-- Aim for 128MB-1GB file sizes
-- Avoid too many small files
```

### 3. Snapshot Analysis

```sql
-- Analyze snapshot sizes
SELECT snapshot_id, summary['added-data-files'] as files_added,
       summary['added-records'] as records_added,
       summary['total-data-files'] as total_files
FROM catalog.db.table.snapshots;
```

## Security and Governance

### 1. Catalog-Level Security

```sql
-- Use catalog-level permissions where possible
-- Implement row-level security via views
-- Leverage Apache Ranger or similar for fine-grained access
```

### 2. Data Encryption

```python
# Use encryption at rest
# Configure in catalog properties
# Use encrypted storage (S3, ADLS, etc.)
```

### 3. Audit Logging

```sql
-- Enable audit logging for sensitive operations
-- Monitor table access patterns
-- Track schema changes
```

## Production Deployment

### 1. Environment Configuration

```python
# Configure appropriate catalog properties
catalog = "your_catalog"
database = "your_database"
warehouse = "s3://your-bucket/warehouse"

# Set appropriate table properties
CREATE TABLE production_table (
    id BIGINT,
    data STRING
) USING iceberg
TBLPROPERTIES (
    'write.format.default' = 'parquet',
    'write.parquet.compression-codec' = 'snappy',
    'write.metadata.compression-codec' = 'gzip'
)
```

### 2. Resource Management

```python
# Configure Spark appropriately
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")

# Monitor resource usage
# Scale based on workload
```

### 3. Backup and Recovery

```sql
-- Use snapshots for point-in-time recovery
-- Export table metadata
-- Implement regular backup procedures
```

## Common Mistakes to Avoid

### 1. Over-Partitioning
```sql
-- Bad: Too many partitions
PARTITIONED BY (customer_id, order_date, region)

-- Good: Strategic partitioning
PARTITIONED BY (days(order_date), bucket(8, customer_id))
```

### 2. Ignoring File Sizes
```python
# Bad: Many small files
# Write frequently without compaction

# Good: Manage file sizes
# Regular compaction
# Appropriate write batching
```

### 3. Not Using Metadata Filtering
```sql
-- Bad: Scanning all data
SELECT * FROM large_table

-- Good: Leverage metadata
SELECT * FROM large_table 
WHERE partition_column = 'value'
```

### 4. Inefficient Upserts
```sql
# Bad: Delete + Insert
DELETE FROM target WHERE id IN (SELECT id FROM source)
INSERT INTO target SELECT * FROM source

-- Good: Use MERGE
MERGE INTO target USING source ON target.id = source.id
```

## Additional Resources

- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [Iceberg Best Practices Blog](https://iceberg.apache.org/blog/)
- [Spark + Iceberg Optimization](https://spark.apache.org/docs/latest/sql-datasources-iceberg.html)
- [Trino Iceberg Connector](https://trino.io/docs/current/connector/iceberg.html)

---

**Follow these practices to build production-ready Iceberg solutions!** 🚀