# Conceptual Guide: Performance Analysis and DAG Inspection

## 🎯 Learning Objectives

This guide explains how to analyze Apache Spark query performance, inspect Directed Acyclic Graphs (DAGs), and understand how Apache Iceberg optimizations affect query execution. Understanding these concepts will help you optimize your data pipelines and diagnose performance issues.

## 📚 Core Concepts

### 1. Spark History Server Architecture

**What is the Spark History Server?**
A web UI that displays information about completed Spark applications by reading event logs.

**Why History Server Matters:**
- **Post-Mortem Analysis**: Analyze jobs after they complete
- **Performance Debugging**: Identify bottlenecks in query execution
- **DAG Inspection**: Understand query execution plans
- **Resource Usage**: Monitor cluster resource consumption
- **Comparison**: Compare performance across different runs

**Architecture:**
```
┌─────────────────────────────────────────────────────────┐
│                  Spark Application                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │   Job 1     │  │   Job 2     │  │   Job 3     │       │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘       │
│         │                │                │               │
│         └────────────────┴────────────────┘               │
│                          │                                 │
│                    Event Logs                              │
│                          │                                 │
└──────────────────────────┼─────────────────────────────────┘
                           │
                           ▼
                   ┌───────────────┐
                   │  S3 Storage   │
                   │ spark-logs/  │
                   └───────┬───────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│              Spark History Server                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │   UI Server │  │ Log Parser  │  │   Indexer   │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
                   ┌───────────────┐
                   │   Web Browser │
                   │   (User)      │
                   └───────────────┘
```

**Event Logging Configuration:**
```scala
// Spark writes event logs during execution
spark.eventLog.enabled=true
spark.eventLog.dir=s3a://spark-logs/

// History Server reads event logs
spark.history.fs.logDirectory=s3a://spark-logs/
```

**Why S3 for Event Logs:**
- **Persistence**: Logs survive cluster restarts
- **Scalability**: Can store logs from many applications
- **Accessibility**: History Server can access from anywhere
- **Cost-Effective**: Cheaper than local storage

### 2. DAG (Directed Acyclic Graph) Fundamentals

**What is a DAG?**
A directed acyclic graph that represents the execution plan of a Spark job.

**Why DAG Matters:**
- **Execution Plan**: Shows how Spark will execute your query
- **Parallelism**: Identifies parallel and sequential operations
- **Data Movement**: Shows where data is shuffled between nodes
- **Optimization**: Reveals optimization opportunities

**DAG Structure:**
```
Query: SELECT * FROM sales WHERE region = 'west'

DAG:
┌─────────────┐
│   Scan      │  ← Read data from Iceberg
│  (sales)    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Filter    │  ← Apply region filter
│ region='west'│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Project   │  ← Select columns
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Result    │  ← Return results
└─────────────┘
```

**DAG Components:**

#### 1. Stages
- **Definition**: Groups of tasks that can be executed in parallel
- **Boundaries**: Occur at shuffle operations
- **Parallelism**: Tasks within a stage run in parallel

#### 2. Tasks
- **Definition**: Smallest unit of execution
- **Data**: Each task processes a partition of data
- **Execution**: Tasks run on executors

#### 3. Shuffle Operations
- **Definition**: Operations that redistribute data across partitions
- **Examples**: JOIN, GROUP BY, ORDER BY, DISTINCT
- **Cost**: Expensive due to network I/O

**DAG with Shuffle:**
```
Query: SELECT region, SUM(amount) FROM sales GROUP BY region

DAG:
Stage 1:
┌─────────────┐
│   Scan      │
│  (sales)    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Map        │  ← Extract region, amount
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Shuffle   │  ← Redistribute by region
└──────┬──────┘
       │
       ▼
Stage 2:
┌─────────────┐
│  Reduce     │  ← Sum amounts per region
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Result    │
└─────────────┘
```

### 3. Iceberg's Impact on DAG

**How Iceberg Changes DAG Structure:**

#### Without Iceberg (Traditional Hive):
```
Query: SELECT * FROM sales WHERE region = 'west'

DAG:
┌─────────────┐
│   Scan      │  ← Scan all files
│  (sales)    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Filter    │  ← Filter after reading all data
│ region='west'│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Result    │
└─────────────┘
```

#### With Iceberg (Partition Pruning):
```
Query: SELECT * FROM sales WHERE region = 'west'

DAG:
┌─────────────┐
│   Scan      │  ← Scan only region='west' files
│  (sales)    │     (partition pruning)
│ region='west'│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Result    │
└─────────────┘
```

**Iceberg Optimizations in DAG:**

#### 1. Partition Pruning
```
Query: SELECT * FROM sales WHERE region = 'west'

DAG Impact:
- Fewer files to scan
- Smaller scan stage
- Less data movement
- Faster execution
```

#### 2. Predicate Pushdown
```
Query: SELECT * FROM sales WHERE amount > 100

DAG Impact:
- Filter pushed to scan
- Files skipped based on statistics
- Smaller data volume
- Faster execution
```

#### 3. Projection Pushdown
```
Query: SELECT id, amount FROM sales

DAG Impact:
- Only required columns read
- Smaller data volume
- Less I/O
- Faster execution
```

#### 4. Metadata-Only Queries
```
Query: SELECT COUNT(*) FROM sales WHERE region = 'west'

DAG Impact:
- No file scan stage
- Only metadata read
- Instant execution
```

### 4. Query Plan Analysis

**How to Read Query Plans:**

#### Explain Plan Output:
```
== Physical Plan ==
*Scan iceberg.sales
+- PushedFilters: [IsNotNull(region), EqualTo(region,west)]
+- PartitionFilters: [IsNotNull(region), EqualTo(region,west)]
+- Partition Values: [region=west]
```

**What Each Section Means:**

| Section | Meaning | Iceberg Benefit |
|---------|---------|-----------------|
| `*Scan` | File scan operation | Indicates Iceberg scan |
| `PushedFilters` | Filters pushed to data source | Iceberg skips files |
| `PartitionFilters` | Partition-level filters | Iceberg prunes partitions |
| `Partition Values` | Actual partition values | Shows partition pruning |

#### Extended Explain Plan:
```
== Physical Plan ==
*Scan iceberg.sales
+- PushedFilters: [IsNotNull(region), EqualTo(region,west)]
+- PartitionFilters: [IsNotNull(region), EqualTo(region,west)]
+- ConvertedSupplementaryScan: [amount > 100]
+- Partition Values: [region=west]
+- FileScan: [path=..., size=..., records=...]
```

**Additional Sections:**

| Section | Meaning | Iceberg Benefit |
|---------|---------|-----------------|
| `ConvertedSupplementaryScan` | Supplementary filters | Iceberg data skipping |
| `FileScan` | File scan details | Shows files scanned |
| `size` | File size | Shows data volume |
| `records` | Record count | Shows rows processed |

### 5. Performance Metrics Analysis

**Key Performance Metrics:**

#### 1. Job Duration
```
Total Job Time: 5.2s
- Stage 1 (Scan): 3.1s
- Stage 2 (Filter): 1.5s
- Stage 3 (Project): 0.6s
```
**Analysis**: Scan is the bottleneck (60% of time)

**Optimization**: Improve partitioning or add filters

#### 2. Stage Duration
```
Stage 1:
- Duration: 3.1s
- Tasks: 10
- Avg Task Duration: 0.31s
- Max Task Duration: 0.5s
- Min Task Duration: 0.2s
```
**Analysis**: Task duration variance indicates data skew

**Optimization**: Repartition to reduce skew

#### 3. Shuffle Metrics
```
Shuffle Read:
- Total Bytes: 1.2GB
- Total Records: 10M
- Remote Bytes: 800MB (67%)
```
**Analysis**: High remote shuffle indicates network bottleneck

**Optimization**: Reduce shuffle data or use broadcast join

#### 4. I/O Metrics
```
File Scan:
- Files Scanned: 50
- Total Bytes: 5.2GB
- Records Read: 50M
- Bytes Read: 5.2GB
```
**Analysis**: Large scan indicates poor partitioning

**Optimization**: Improve partition pruning

### 6. Performance Comparison Patterns

#### Pattern 1: With vs Without Partition Pruning
```
Query 1 (No Partition Predicate):
SELECT * FROM sales WHERE date >= '2024-01-01'
- Files Scanned: 100
- Duration: 10.5s

Query 2 (With Partition Predicate):
SELECT * FROM sales WHERE date >= '2024-01-01' AND region = 'west'
- Files Scanned: 10
- Duration: 1.2s

Speedup: 8.75x
```

#### Pattern 2: Metadata-Only vs Full Scan
```
Query 1 (Full Scan):
SELECT COUNT(*) FROM sales WHERE date >= '2024-01-01'
- Files Scanned: 50
- Duration: 5.3s

Query 2 (Metadata-Only):
SELECT COUNT(*) FROM sales WHERE region = 'west'
- Files Scanned: 0
- Duration: 0.05s

Speedup: 106x
```

#### Pattern 3: Simple vs Complex Join
```
Query 1 (Simple Join):
SELECT s.*, c.name FROM sales s JOIN customers c ON s.customer_id = c.customer_id
- Stages: 3
- Shuffles: 1
- Duration: 8.2s

Query 2 (Complex Join):
SELECT s.*, c.name, p.category FROM sales s 
JOIN customers c ON s.customer_id = c.customer_id
JOIN products p ON s.product_id = p.product_id
- Stages: 5
- Shuffles: 2
- Duration: 15.7s

Overhead: 1.9x
```

### 7. DAG Inspection Workflow

#### Step 1: Identify the Job
```
1. Go to Spark History Server UI
2. Find your application
3. Click on application ID
4. List of jobs appears
```

#### Step 2: Examine the Job
```
1. Click on the job of interest
2. Job details appear
3. Stage information shown
4. DAG visualization available
```

#### Step 3: Inspect the DAG
```
1. Click on "DAG Visualization"
2. Graph shows execution plan
3. Hover over nodes for details
4. Identify bottlenecks
```

#### Step 4: Analyze Stages
```
1. Click on each stage
2. Stage details appear
3. Task metrics shown
4. Identify slow tasks
```

#### Step 5: Compare Plans
```
1. Run query with different filters
2. Compare DAGs
3. Identify optimization opportunities
4. Measure performance differences
```

### 8. Iceberg-Specific Performance Indicators

#### Indicators of Good Iceberg Performance:
- **Partition Pruning Active**: `PartitionFilters` in explain plan
- **Predicate Pushdown**: `PushedFilters` in explain plan
- **Metadata-Only Queries**: No file scan for COUNT queries
- **Few Files Scanned**: File count much less than total files
- **Low I/O**: Bytes read much less than total data size

#### Indicators of Poor Iceberg Performance:
- **Full Table Scan**: No partition filters
- **Many Files Scanned**: File count close to total files
- **High I/O**: Bytes read close to total data size
- **No Predicate Pushdown**: Filters not pushed to scan
- **Data Skew**: Uneven task durations

## 💡 Performance Optimization Strategy

### Optimization Hierarchy (by Impact):

```
1. Partition Pruning (Highest Impact)
   └─ Add partition predicates to queries
   └─ Reduces files scanned by 90-99%

2. Metadata-Only Queries (Very High Impact)
   └─ Use partition statistics for COUNT/MIN/MAX
   └─ Can be 1000x faster

3. Predicate Pushdown (High Impact)
   └─ Ensure filters are pushed to Iceberg
   └─ Skips files based on statistics

4. File Size Optimization (Medium Impact)
   └─ Target 128MB-1GB files
   └─ Reduces file count overhead

5. Z-Ordering (Medium Impact)
   └─ Cluster data for range queries
   └─ Improves data skipping

6. Compaction (Medium Impact)
   └─ Merge small files
   └─ Reduces file count

7. Compression (Low Impact)
   └─ Reduce I/O with better compression
   └─ Reduces data volume
```

### Performance Debugging Checklist:

- [ ] Check explain plan for partition pruning
- [ ] Verify predicate pushdown is active
- [ ] Count files scanned vs total files
- [ ] Measure bytes read vs total data size
- [ ] Inspect DAG for bottlenecks
- [ ] Analyze stage durations
- [ ] Check for data skew
- [ ] Review shuffle metrics
- [ ] Compare with and without optimizations
- [ ] Monitor file sizes and counts

## 🔍 Common Misconceptions

### Misconception 1: More Complex DAG = Slower Query
**Reality**: Complex DAG can be faster if it enables parallelism. Simpler DAG with full scan is slower.

### Misconception 2: DAG Visualization Shows Everything
**Reality**: DAG shows logical plan. Physical execution may differ due to runtime optimizations.

### Misconception 3: Longest Stage is Always the Bottleneck
**Reality**: Network I/O (shuffles) can be bottleneck even if stages are fast.

### Misconception 4: Metadata-Only Queries Work for All COUNT Queries
**Reality**: Only works for COUNT queries with partition predicates.

## 🚀 Next Steps

With this understanding, you're ready to:
1. **Inspect DAGs** to understand query execution
2. **Analyze performance metrics** to identify bottlenecks
3. **Compare query plans** to measure optimization impact
4. **Debug performance issues** using History Server
5. **Optimize queries** based on DAG analysis
6. **Monitor Iceberg-specific performance indicators**

---

**Remember**: Performance analysis is about understanding the interaction between your query, Iceberg's metadata, and Spark's execution model. The DAG is your window into this interaction. Use it to identify where time is spent and apply the right optimizations to improve performance.