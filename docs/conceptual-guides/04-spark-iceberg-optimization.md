# Conceptual Guide: Spark + Iceberg Integration and Optimization

## 🎯 Learning Objectives

This guide explains how Apache Spark integrates with Apache Iceberg and how to optimize this integration for maximum performance. Understanding these concepts will help you design efficient data pipelines and avoid common pitfalls.

## 📚 Core Concepts

### 1. Spark-Iceberg Integration Architecture

**How Spark Uses Iceberg:**
Spark doesn't "use" Iceberg directly - it uses Iceberg's metadata to optimize data access.

```
Query Execution Flow:
┌─────────────┐
│   Spark SQL │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│   Spark Query Planner            │
│   (Catalyst Optimizer)          │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│   Iceberg Source                 │
│   (Reads Iceberg metadata)       │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│   Iceberg Catalog (Polaris)     │
│   (Returns snapshot info)        │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│   Iceberg Metadata (in S3)      │
│   (Manifests, partition stats)   │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│   Data Files (Parquet in S3)    │
│   (Actual data)                  │
└─────────────────────────────────┘
```

**Key Integration Points:**
1. **Spark Catalog**: Maps SQL table names to Iceberg tables
2. **Iceberg Source**: Custom Spark data source that understands Iceberg metadata
3. **Query Planning**: Spark Catalyst optimizer uses Iceberg metadata
4. **File Reading**: Spark reads Parquet files identified by Iceberg

### 2. Spark Configuration for Iceberg

**Required Configuration:**
```scala
// Catalog configuration
spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=rest
spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog

// S3 configuration
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.endpoint=http://localhost:9000
spark.hadoop.fs.s3a.access.key=minioadmin
spark.hadoop.fs.s3a.secret.key=minioadmin
```

**Why Each Configuration Matters:**

| Configuration | Purpose | Impact |
|---------------|---------|--------|
| `spark.sql.catalog.iceberg` | Register Iceberg catalog | Enables `iceberg.db.table` syntax |
| `spark.sql.catalog.iceberg.type` | Catalog implementation | Determines how metadata is accessed |
| `spark.sql.catalog.iceberg.uri` | Catalog endpoint | Where to fetch table metadata |
| `fs.s3a.impl` | S3 filesystem implementation | How to read/write S3 objects |
| `fs.s3a.path.style.access` | S3 path style | Compatibility with S3-compatible storage |
| `fs.s3a.endpoint` | S3 endpoint | Which S3 service to use |

**Optional Performance Configuration:**
```scala
// Query planning optimization
spark.sql.iceberg.planning.enabled=true
spark.sql.iceberg.planning.mode=distributed
spark.sql.iceberg.pushdown.enabled=true

// File reading optimization
spark.sql.iceberg.vectorization.enabled=true
spark.sql.iceberg.vectorization.batch-size=2048
```

### 3. Query Planning and Optimization

**How Spark Plans Iceberg Queries:**

```
SQL Query:
SELECT * FROM iceberg.sales WHERE region = 'west'

Planning Steps:
1. Parse SQL → Logical Plan
2. Catalog Lookup → Table Metadata
3. Iceberg Optimization → Partition Pruning
4. Physical Planning → File Scan Plan
5. Execution → Read Data Files
```

**Iceberg-Specific Optimizations:**

#### 1. Partition Pruning
```sql
-- Query
SELECT * FROM sales WHERE region = 'west' AND date >= '2024-01-01'

-- Spark Plan
*Scan iceberg.sales
+- PushedFilters: [IsNotNull(region), EqualTo(region,west)]
+- PartitionFilters: [IsNotNull(region), EqualTo(region,west)]
+- Partition Values: [region=west, date=2024-01-01]
```
**How it works**: Spark uses Iceberg partition metadata to skip irrelevant partitions

**Impact**: Can reduce scan by 90-99%

#### 2. Predicate Pushdown
```sql
-- Query
SELECT * FROM sales WHERE amount > 100

-- Spark Plan
*Scan iceberg.sales
+- PushedFilters: [IsNotNull(amount), GreaterThan(amount,100)]
+- ConvertedSupplementaryScan: [amount > 100]
```
**How it works**: Filters pushed to file level using column statistics

**Impact**: Skips files that can't contain matching rows

#### 3. Metadata-Only Queries
```sql
-- Query
SELECT COUNT(*) FROM sales WHERE region = 'west'

-- Spark Plan
*Scan iceberg.sales
+- PartitionFilters: [IsNotNull(region), EqualTo(region,west)]
+- Metadata Only: true
```
**How it works**: Uses partition statistics instead of reading data

**Impact**: 1000x faster than full scan

#### 4. Projection Pushdown
```sql
-- Query
SELECT id, amount FROM sales

-- Spark Plan
*Scan iceberg.sales
+- ProjectedColumns: [id, amount]
```
**How it works**: Only reads required columns from Parquet files

**Impact**: Reduces I/O by skipping unused columns

### 4. File Compaction Strategies

**Why Compaction Matters in Spark:**
- **Spark Creates Many Small Files**: Each task writes its own file
- **Small Files Hurt Performance**: More S3 requests, more metadata overhead
- **Compaction Merges Files**: Reduces file count, increases file size

**Compaction Strategies:**

#### 1. Bin-Packing Compaction
```scala
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
**How it works**: Groups small files into larger files

**When to use**: General purpose, after bulk loads or streaming writes

#### 2. Sort-Based Compaction
```scala
spark.sql("""
  CALL iceberg.system.rewrite_data_files(
    'iceberg.sales',
    map(
      'sort-order', 'date,amount',
      'min-input-files', '5'
    )
  )
""")
```
**How it works**: Sorts data during compaction

**When to use**: Need data sorted for specific query patterns

#### 3. Z-Order Compaction
```scala
spark.sql("""
  CALL iceberg.system.rewrite_data_files(
    'iceberg.sales',
    map(
      'z-order', 'user_id,timestamp',
      'min-input-files', '5'
    )
  )
""")
```
**How it works**: Applies Z-ordering during compaction

**When to use**: Multi-column range queries

**Compaction in Spark Jobs:**
```scala
// Schedule compaction as Spark job
spark.sql("""
  CALL iceberg.system.rewrite_data_files(
    'iceberg.sales',
    map(
      'min-input-files', '10',
      'target-size-bytes', str(512 * 1024 * 1024)
    )
  )
""").collect()
```

**Why run as Spark job**: Leverages Spark's distributed processing for large tables

### 5. Snapshot Management

**Why Snapshot Management Matters:**
- **Unlimited Snapshots = Unlimited Storage**: Each snapshot references data files
- **Old Snapshots Block Cleanup**: Data files can't be deleted if referenced
- **Metadata Bloat**: Too many snapshots slow down catalog operations

**Snapshot Expiration:**
```scala
spark.sql("""
  CALL iceberg.system.expire_snapshots(
    'iceberg.sales',
    map(
      'retain-last', '7'  // Keep last 7 snapshots
    )
  )
""")
```

**How it works:**
1. Identifies snapshots older than retention period
2. Removes snapshot references from metadata
3. Identifies orphaned data files (not referenced by any snapshot)
4. Deletes orphaned files from storage

**Snapshot Retention Strategies:**
- **Time-Based**: Keep snapshots for N days
- **Count-Based**: Keep last N snapshots
- **Hybrid**: Keep N snapshots or N days, whichever is greater

**Impact of Snapshot Expiration:**
- **Storage Savings**: Frees space from orphaned files
- **Performance**: Reduces metadata size
- **Time Travel Limits**: Can't query data older than retention period

### 6. Efficient Data Loading Patterns

**Spark Data Loading Anti-Patterns:**

#### Anti-Pattern 1: Too Many Small Files
```scala
// BAD: Each partition writes its own file
df.writeTo("iceberg.sales").tableAppend()
// Results in 200 files (one per partition)
```

**Problem**: Too many files hurt query performance

#### Anti-Pattern 2: Uncontrolled File Sizes
```scala
// BAD: No control over file size
df.repartition(1000).writeTo("iceberg.sales").tableAppend()
// Results in 1000 small files
```

**Problem**: Unpredictable file sizes

**Best Practices:**

#### Pattern 1: Controlled Partitioning
```scala
// GOOD: Control file count with coalesce
df.coalesce(10).writeTo("iceberg.sales").tableAppend()
// Results in 10 reasonably sized files
```

**Why**: Predictable file count and size

#### Pattern 2: Target File Size
```scala
// GOOD: Use target file size property
spark.conf.set("spark.sql.iceberg.write.target-file-size-bytes", 
              str(256 * 1024 * 1024))
df.writeTo("iceberg.sales").tableAppend()
// Spark creates files around 256MB
```

**Why**: Automatic file size control

#### Pattern 3: Partition-Aware Loading
```scala
// GOOD: Load by partition to avoid cross-partition shuffles
val dates = Seq("2024-01-01", "2024-01-02", "2024-01-03")
for (date <- dates) {
  val dailyData = spark.read.parquet(s"/data/sales_$date.parquet")
  dailyData.writeTo("iceberg.sales").tableAppend()
}
```

**Why**: Each partition loaded independently, no cross-partition shuffle

#### Pattern 4: Batch Loading with Coalescing
```scala
// GOOD: Load in batches with controlled file sizes
val batchSize = 1000000
val totalRows = df.count()
val batches = (totalRows / batchSize) + 1

for (i <- 0 until batches) {
  val startRow = i * batchSize
  val endRow = startRow + batchSize
  val batch = df.limit(endRow).except(df.limit(startRow))
  batch.coalesce(10).writeTo("iceberg.sales").tableAppend()
}
```

**Why**: Controlled batch sizes and file counts

### 7. Dynamic File Pruning

**What is Dynamic File Pruning?**
Spark's ability to prune files at runtime based on join keys and filter conditions.

**How Dynamic File Pruning Works:**

```
Query:
SELECT s.*, c.region
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE c.region = 'west'

Without Dynamic Pruning:
1. Scan all sales files
2. Join with customers
3. Filter by region

With Dynamic Pruning:
1. Scan customers for region='west'
2. Extract customer_ids
3. Prune sales files using customer_ids
4. Scan only relevant sales files
5. Join
```

**Dynamic Pruning Configuration:**
```scala
spark.conf.set("spark.sql.optimizer.dynamicPartitionPruning.enabled", true)
spark.conf.set("spark.sql.optimizer.dynamicPartitionPruning.reuseBroadcastOnly", false)
```

**When Dynamic Pruning Helps:**
- **Star Schema Joins**: Fact tables joined to dimension tables
- **Selective Filters**: Dimension tables filtered heavily
- **Large Fact Tables**: Fact table much larger than dimension table

**Impact**: Can reduce fact table scan by 50-90%

### 8. Performance Monitoring

**Monitoring Metrics:**

#### 1. File-Level Metrics
```scala
spark.sql("""
  SELECT 
    file,
    record_count,
    file_size_in_bytes,
    column_size,
    value_count,
    null_value_count
  FROM iceberg.sales.files
  ORDER BY file_size_in_bytes DESC
  LIMIT 10
""")
```
**What to look for**: Too many small files, uneven file sizes

#### 2. Partition-Level Metrics
```scala
spark.sql("""
  SELECT 
    partition,
    COUNT(*) as file_count,
    SUM(record_count) as total_records,
    SUM(file_size_in_bytes) as total_size
  FROM iceberg.sales.files
  GROUP BY partition
  ORDER BY total_size DESC
""")
```
**What to look for**: Skewed partitions, uneven data distribution

#### 3. Snapshot Metrics
```scala
spark.sql("""
  SELECT 
    snapshot_id,
    committed_at,
    summary['operation'] as operation,
    summary['added-files-size'] as added_files_size,
    summary['removed-files-size'] as removed_files_size
  FROM iceberg.sales.snapshots
  ORDER BY committed_at DESC
  LIMIT 10
""")
```
**What to look for**: Large snapshots, frequent operations

#### 4. Query Metrics (Spark UI)
- **Scan Time**: Time spent reading data
- **Shuffle Time**: Time spent on shuffles
- **Task Duration**: Individual task performance
- **Data Read**: Amount of data read from storage

## 💡 Optimization Strategy

### Optimization Priority

```
1. Partitioning (Highest Impact)
   └─ Design partitions for query patterns

2. File Size Control (High Impact)
   └─ Target 128MB-1GB files

3. Compaction (High Impact)
   └─ Merge small files regularly

4. Predicate Pushdown (Medium Impact)
   └─ Ensure filters are pushed down

5. Dynamic Pruning (Medium Impact)
   └─ Enable for star schema joins

6. Vectorization (Low Impact)
   └─ Enable for columnar processing

7. Statistics Collection (Low Impact)
   └─ Collect accurate column statistics
```

### Performance Tuning Checklist

- [ ] Partitions designed for query patterns
- [ ] File sizes in 128MB-1GB range
- [ ] Compaction scheduled regularly
- [ ] Predicate pushdown enabled
- [ ] Dynamic pruning enabled for joins
- [ ] Statistics collected regularly
- [ ] Vectorization enabled for columnar data
- [ ] Compression configured appropriately
- [ ] Snapshot expiration configured
- [ ] Monitoring metrics reviewed regularly

## 🔍 Common Misconceptions

### Misconception 1: More Spark Partitions = Better Performance
**Reality**: More partitions = more files = worse performance. Use coalesce().

### Misconception 2: Compaction Should Run After Every Write
**Reality**: Too frequent compaction wastes compute. Run based on file count thresholds.

### Misconception 3: Dynamic Pruning Always Helps
**Reality**: Only helps for star schema joins with selective dimension filters.

### Misconception 4: Larger Files Always Better
**Reality**: Too large files reduce parallelism. Balance size and parallelism.

## 🚀 Next Steps

With this understanding, you're ready to:
1. **Configure Spark** for optimal Iceberg performance
2. **Design efficient data loading** patterns
3. **Implement compaction** strategies
4. **Monitor performance** metrics
5. **Optimize query execution** through planning
6. **Balance trade-offs** between performance and cost

---

**Remember**: Spark-Iceberg optimization is about understanding the interaction between Spark's execution model and Iceberg's metadata architecture. Focus on partitioning and file size control first (biggest impact), then move to more advanced optimizations as needed.