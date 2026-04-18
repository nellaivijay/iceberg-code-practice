# Conceptual Guide: Advanced Iceberg Features and Performance

## 🎯 Learning Objectives

This guide explains the advanced features of Apache Iceberg that enable high-performance data lake operations. Understanding these concepts will help you optimize your Iceberg tables for both performance and cost.

## 📚 Core Concepts

### 1. Partition Evolution

**What is Partition Evolution?**
The ability to modify a table's partitioning strategy without rewriting existing data.

**Why Partition Evolution Matters:**
- **Changing Requirements**: Query patterns evolve over time
- **Optimization**: Improve performance as you understand data access patterns
- **No Downtime**: Can evolve partitions without taking tables offline
- **Gradual Migration**: Old data uses old partitions, new data uses new partitions

**How Partition Evolution Works:**

```
Initial State:
┌─────────────────────────────┐
│ Table partitioned by region │
│ region='west', 'east'       │
└─────────────────────────────┘

After Adding Day Partition:
┌──────────────────────────────────────────┐
│ Table partitioned by region, days(date)  │
│ Old data: region='west', 'east'          │
│ New data: region='west', days(date)=...  │
└──────────────────────────────────────────┘
```

**Technical Implementation:**
```sql
-- Initial table
CREATE TABLE sales (id INT, date DATE, region STRING)
PARTITIONED BY (region)

-- Add day partition (partition evolution)
ALTER TABLE sales ADD PARTITION FIELD days(date)

-- Result: Two partition fields
-- Old data: partitioned by region only
-- New data: partitioned by region + days(date)
```

**Why This is Safe:**
- **Metadata-Only Change**: No data rewrite required
- **Backward Compatible**: Old queries still work
- **Gradual Migration**: New partitions apply to new writes
- **Automatic Pruning**: Query planner handles mixed partition schemes

**Partition Evolution Use Cases:**
1. **Initial Coarse Partitioning**: Start with broad partitions
2. **Refine Over Time**: Add more specific partitions as patterns emerge
3. **A/B Testing**: Try different partitioning strategies
4. **Cost Optimization**: Reduce scan costs with better partitioning

### 2. Z-Ordering and Data Clustering

**What is Z-Ordering?**
A multidimensional clustering technique that arranges data so that records with similar values across multiple columns are stored close together.

**Why Z-Ordering Matters:**
- **Range Query Performance**: Improves queries with range predicates
- **Multi-Column Filtering**: Effective when filtering on multiple columns
- **Skip Indexes**: Enables data skipping based on column statistics
- **Compression**: Better compression with similar values grouped together

**How Z-Ordering Works:**

```
Traditional Ordering (by single column):
┌─────────────────────────────────┐
│ Data sorted by timestamp only    │
│ Similar timestamps grouped       │
│ Other columns randomly distributed│
└─────────────────────────────────┘

Z-Ordering (by multiple columns):
┌─────────────────────────────────┐
│ Data clustered by user_id AND    │
│ timestamp simultaneously         │
│ Both columns have locality       │
└─────────────────────────────────┘
```

**Z-Order Algorithm:**
1. Interleave bits from multiple columns
2. Create a Z-order curve through multidimensional space
3. Sort data by Z-order value
4. Store data in Z-order sequence

**Practical Example:**
```sql
-- Table with Z-ordering
CREATE TABLE transactions (
  user_id INT,
  timestamp TIMESTAMP,
  amount DECIMAL
)
PARTITIONED BY (days(timestamp))
ORDER BY user_id, timestamp  -- Z-order by these columns

-- Query benefits from Z-ordering
SELECT * FROM transactions
WHERE user_id = 123
  AND timestamp BETWEEN '2024-01-01' AND '2024-01-31'
-- Both predicates benefit from data clustering
```

**Z-Ordering vs Traditional Sorting:**
| Feature | Traditional Sort | Z-Order |
|---------|------------------|---------|
| Single Column | Excellent | Good |
| Multiple Columns | Poor (only first column) | Excellent |
| Range Queries | Good on sorted column | Good on all columns |
| Implementation | Simple | Complex |

**When to Use Z-Ordering:**
- **Multi-Column Range Queries**: Frequent filtering on multiple columns
- **Data Locality**: Need data grouped by multiple dimensions
- **Skip Indexes**: Want to enable data skipping
- **Compression**: Better compression with clustered data

### 3. File Compaction

**What is File Compaction?**
Merging multiple small data files into fewer, larger files to improve performance.

**Why Compaction Matters:**
- **Too Many Small Files**: Each file has overhead (metadata, S3 requests)
- **Query Performance**: Fewer files = fewer S3 requests = faster queries
- **Metadata Overhead**: Less metadata to manage
- **Storage Efficiency**: Better compression with larger files

**Small File Problem:**
```
Without Compaction:
┌─────┬─────┬─────┬─────┬─────┬─────┐
│File1│File2│File3│File4│File5│File6│
│ 1MB │ 1MB │ 1MB │ 1MB │ 1MB │ 1MB │
└─────┴─────┴─────┴─────┴─────┴─────┘
Query scans 6 files = 6 S3 requests

With Compaction:
┌─────────────────────────────────┐
│         Compacted File          │
│             6MB                 │
└─────────────────────────────────┘
Query scans 1 file = 1 S3 request
```

**Compaction Strategies:**

#### 1. Bin-Packing Compaction
```sql
CALL iceberg.system.rewrite_data_files(
  'table',
  map(
    'min-input-files', '5',
    'target-size-bytes', str(256 * 1024 * 1024)
  )
)
```
**How it works**: Groups small files into larger files up to target size

**When to use**: General purpose, balances file size and count

#### 2. Sort-Based Compaction
```sql
CALL iceberg.system.rewrite_data_files(
  'table',
  map(
    'sort-order', 'column1,column2',
    'min-input-files', '5'
  )
)
```
**How it works**: Sorts data during compaction for better clustering

**When to use**: Need data sorted for specific query patterns

#### 3. Z-Order Compaction
```sql
CALL iceberg.system.rewrite_data_files(
  'table',
  map(
    'z-order', 'col1,col2',
    'min-input-files', '5'
  )
)
```
**How it works**: Applies Z-ordering during compaction

**When to use**: Multi-column range queries

**Compaction Best Practices:**
- **Target File Size**: 128MB-1GB (depends on query patterns)
- **Trigger Conditions**: File count or size thresholds
- **Frequency**: Balance between performance and cost
- **Partition-Level**: Compact partitions independently

### 4. Metadata-Only Query Optimization

**What is Metadata-Only Filtering?**
Iceberg's ability to answer queries using only metadata, without reading data files.

**Why Metadata-Only Filtering Matters:**
- **Dramatic Performance**: Can be 1000x faster than reading data
- **Cost Reduction**: Fewer S3 requests = lower costs
- **Scalability**: Doesn't depend on data size
- **Instant Counts**: COUNT(*) queries complete instantly

**How Metadata-Only Filtering Works:**

```
Query: SELECT COUNT(*) FROM sales WHERE region = 'west'

Traditional Approach:
┌─────────────────────────────┐
│ Scan all data files         │
│ Read all rows              │
│ Count rows matching filter │
└─────────────────────────────┘

Iceberg Metadata-Only:
┌─────────────────────────────┐
│ Read partition metadata     │
│ Count rows in partition    │
│ Return total count         │
└─────────────────────────────┘
```

**Metadata Stored:**
- **Partition Statistics**: Row counts per partition
- **Column Statistics**: Min/max values, null counts
- **File Statistics**: Record counts per file
- **Snapshot Information**: Data distribution

**Queries That Can Use Metadata-Only:**
```sql
-- COUNT queries
SELECT COUNT(*) FROM table WHERE partition_col = 'value'

-- MIN/MAX queries
SELECT MIN(timestamp), MAX(timestamp) FROM table

-- EXISTS queries
SELECT EXISTS(SELECT 1 FROM table WHERE partition_col = 'value')

-- Approximate queries
SELECT APPROX_COUNT_DISTINCT(user_id) FROM table
```

**Metadata-Only Filtering Conditions:**
- **Partition Predicates**: Must filter on partition columns
- **Column Statistics**: Must have min/max statistics
- **No Complex Expressions**: Simple predicates only
- **No Joins**: Single table queries only

### 5. Complex Schema Migrations

**What are Complex Schema Migrations?**
Combining multiple schema evolution operations to achieve complex transformations.

**Why Complex Migrations Matter:**
- **Real-World Changes**: Business requirements rarely change one column at a time
- **Data Quality**: Multiple related changes needed together
- **Backward Compatibility**: Maintain compatibility during migration
- **Zero Downtime**: Migrate without taking tables offline

**Migration Patterns:**

#### 1. Column Rename + Type Change
```sql
-- Step 1: Add new column with desired type
ALTER TABLE users ADD COLUMN new_email STRING

-- Step 2: Backfill data
UPDATE users SET new_email = CAST(old_email AS STRING)

-- Step 3: Verify data
SELECT COUNT(*) FROM users WHERE new_email IS NULL

-- Step 4: Drop old column
ALTER TABLE users DROP COLUMN old_email

-- Step 5: Rename new column
ALTER TABLE users RENAME COLUMN new_email TO email
```

#### 2. Nested Schema Evolution
```sql
-- Add nested field
ALTER TABLE users
ADD COLUMN contact STRUCT<
  email STRING,
  phone STRING,
  address STRUCT<
    street STRING,
    city STRING,
    zip STRING
  >
>

-- Update nested field
ALTER TABLE users
RENAME COLUMN contact.email TO contact.primary_email
```

#### 3. Default Value Migration
```sql
-- Add column with default
ALTER TABLE users
ADD COLUMN status STRING DEFAULT 'active'

-- Backfill specific values
UPDATE users
SET status = 'premium'
WHERE total_spent > 1000
```

**Migration Best Practices:**
- **Test First**: Validate migration on test data
- **Gradual Rollout**: Apply migration incrementally
- **Rollback Plan**: Know how to revert if needed
- **Monitor**: Watch for errors during migration

### 6. Performance Tuning

**Performance Tuning Dimensions:**

#### 1. File Size Tuning
```sql
-- Target file size: 256MB
TBLPROPERTIES (
  'write.target-file-size-bytes' = str(256 * 1024 * 1024)
)
```
**Why**: Balance between parallelism and overhead

#### 2. Compression Tuning
```sql
-- Use Zstandard compression
TBLPROPERTIES (
  'write.parquet.compression-codec' = 'zstd',
  'write.parquet.compression-level' = '9'
)
```
**Why**: Better compression ratio vs CPU tradeoff

#### 3. Metadata Compression
```sql
-- Compress metadata files
TBLPROPERTIES (
  'write.metadata.compression-codec' = 'gzip'
)
```
**Why**: Reduce metadata size for faster catalog operations

#### 4. Partition Count Tuning
```sql
-- Use bucketing to control partition count
PARTITIONED BY (bucket(16, user_id))
```
**Why**: Prevent too many small partitions

#### 5. Statistics Collection
```sql
-- Collect column statistics
ALTER TABLE sales
SET TBLPROPERTIES (
  'statistics.col.user_id.enabled' = 'true'
)
```
**Why**: Better query planning with accurate statistics

## 💡 Performance Optimization Strategy

### Query Performance Optimization Hierarchy

```
1. Partition Pruning (Biggest Impact)
   └─ Filter on partition columns

2. Metadata-Only Filtering (Huge Impact)
   └─ Use partition statistics for COUNT/MIN/MAX

3. Data Skipping (Large Impact)
   └─ Leverage column statistics (min/max)

4. Z-Ordering (Medium Impact)
   └─ Cluster data for range queries

5. File Compaction (Medium Impact)
   └─ Reduce file count and increase file size

6. Compression (Small Impact)
   └─ Reduce I/O with better compression

7. Statistics Collection (Small Impact)
   └─ Better query planning
```

### Cost vs Performance Trade-offs

| Optimization | Performance Gain | Cost Impact | Implementation Effort |
|--------------|------------------|-------------|----------------------|
| Partition Pruning | High | Low | Low |
| Metadata-Only Filtering | Very High | Very Low | Low |
| File Compaction | Medium | Medium | Medium |
| Z-Ordering | Medium | Medium | High |
| Compression | Low | Low | Low |

## 🔍 Common Misconceptions

### Misconception 1: More Partitions Always Better
**Reality**: Too many partitions hurt performance. Aim for 100MB-1GB per partition.

### Misconception 2: Compaction Should Run Continuously
**Reality**: Balance compaction frequency with cost. Too frequent = wasted compute.

### Misconception 3: Metadata-Only Works for All Queries
**Reality**: Only works for specific query patterns (COUNT, MIN/MAX, EXISTS).

### Misconception 4: Z-Ordering is Always Better Than Sorting
**Reality**: Z-Ordering helps with multi-column queries, but single-column sorting is simpler.

## 🚀 Next Steps

With this understanding, you're ready to:
1. **Design partitioning strategies** that evolve with your needs
2. **Apply Z-ordering** for multi-column query optimization
3. **Implement compaction** strategies for optimal file sizes
4. **Leverage metadata-only filtering** for instant analytics
5. **Plan complex schema migrations** for real-world scenarios
6. **Tune performance** based on your specific workload

---

**Remember**: Performance optimization is about understanding your query patterns and applying the right techniques. Start with partition pruning and metadata-only filtering (biggest impact, lowest cost), then move to more complex techniques as needed.