# Conceptual Guide: Iceberg Table Maintenance and Operations

## 🎯 Learning Objectives

This guide explains the fundamental concepts behind Iceberg table maintenance and operational procedures. Understanding these concepts will help you design and implement effective maintenance strategies for production Iceberg deployments.

## 📚 Core Concepts

### 1. File Compaction: The Small File Problem

**What is the Small File Problem?**
In distributed data processing, operations often create many small files instead of fewer large files. This happens because:
- Each Spark task writes its own output file
- Streaming writes create many small batches
- Concurrent writes produce multiple versions

**Why Small Files Are Problematic:**

```
Many Small Files:
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│File1│File2│File3│File4│File5│File6│File7│File8│
│ 1MB │ 1MB │ 1MB │ 1MB │ 1MB │ 1MB │ 1MB │ 1MB │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
8 files = 8 S3 requests = 8 MB overhead

Single Large File:
┌─────────────────────────────────────────┐
│         Compacted File                  │
│             8MB                         │
└─────────────────────────────────────────┘
1 file = 1 S3 request = minimal overhead
```

**Impact of Small Files:**
- **Storage Overhead**: Each file has metadata (Parquet footer, Iceberg manifest)
- **Query Overhead**: More S3 API calls = higher latency and cost
- **Metadata Overhead**: Catalog must track more files
- **Performance**: Spark must open more files = slower queries

**Compaction Strategies:**

#### 1. Bin-Packing Compaction
```
Before Compaction:
┌─────┬─────┬─────┬─────┬─────┐
│File1│File2│File3│File4│File5│
└─────┴─────┴─────┴─────┴─────┘

After Bin-Packing:
┌───────────────────────────┐
│     Compacted File       │
└───────────────────────────┘
```
**How it works**: Groups small files into larger files up to target size
**When to use**: General purpose, balances file size and count
**Trade-offs**: Simple but doesn't optimize data ordering

#### 2. Sort-Based Compaction
```
Before Sorting:
┌─────┬─────┬─────┬─────┐
│ A   │ B   │ C   │ A   │
│ 2020│ 2021│ 2022│ 2023│
└─────┴─────┴─────┴─────┘

After Sorting:
┌───────────────────────────┐
│ A   │ A   │ B   │ C   │
│ 2020│ 2023│ 2021│ 2022│
└───────────────────────────┘
```
**How it works**: Sorts data during compaction for better clustering
**When to use**: When queries filter on sorted columns
**Trade-offs**: Better range queries but requires sorting overhead

#### 3. Z-Order Compaction
```
Before Z-Order:
┌─────┬─────┬─────┬─────┐
│ A,1 │ B,2 │ A,3 │ C,1 │
└─────┴─────┴─────┴─────┘

After Z-Order:
┌───────────────────────────┐
│ A,1 │ A,3 │ B,2 │ C,1 │
│ (clustered by both A and B)│
└───────────────────────────┘
```
**How it works**: Multi-dimensional clustering using Z-order curve
**When to use**: Multi-column range queries
**Trade-offs**: Best for complex predicates but higher computational cost

**When to Compact:**
- **File Count Threshold**: Compact when file count > 100
- **File Size Threshold**: Compact when average file size < 128MB
- **Time-Based**: Compact daily/weekly
- **Event-Driven**: Compact after large data loads

### 2. Snapshot Management

**What are Snapshots?**
Snapshots are point-in-time, immutable views of table data. Each write operation creates a new snapshot.

**Why Snapshot Management Matters:**
```
Snapshot Timeline:
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│Snapshot1│Snapshot2│Snapshot3│Snapshot4│Snapshot5│
│ (initial)│ (insert) │ (update) │ (delete) │ (insert) │
└────┬────┴────┬────┴────┬────┴────┬────┴────┬────
     │         │         │         │         │
     └─────────┴─────────┴─────────┴─────────┘
           All snapshots reference data files
```

**Storage Impact:**
- **Data Files**: Referenced by snapshots, can't be deleted
- **Metadata**: Each snapshot adds metadata overhead
- **Catalog Load**: More snapshots = slower catalog operations
- **Storage Cost**: Old data files consume storage indefinitely

**Snapshot Expiration Strategies:**

#### 1. Time-Based Expiration
```sql
CALL iceberg.system.expire_snapshots(
  'table',
  map('older-than', '30 days')
)
```
**How it works**: Remove snapshots older than specified time
**When to use**: Regular cleanup based on data retention policy
**Trade-offs**: Simple but may remove too many or too few snapshots

#### 2. Count-Based Expiration
```sql
CALL iceberg.system.expire_snapshots(
  'table',
  map('retain-last', '10')
)
```
**How it works**: Keep only last N snapshots
**When to use**: When you need predictable snapshot count
**Trade-offs**: Doesn't account for time, may keep very old snapshots

#### 3. Hybrid Expiration
```sql
CALL iceberg.system.expire_snapshots(
  'table',
  map('older-than', '7 days', 'retain-last', '5')
)
```
**How it works**: Remove snapshots older than X days, but keep at least Y snapshots
**When to use**: Production environments with both time and count requirements
**Trade-offs**: More complex but provides better guarantees

**Why Snapshot Expiration is Safe:**
- **Time Travel**: Retained snapshots still enable time travel
- **Rollback**: Recent snapshots allow rollback
- **Auditing**: Retained snapshots provide audit trail
- **Performance**: Fewer snapshots improve catalog performance

### 3. Orphan File Cleanup

**What are Orphan Files?**
Data files that are not referenced by any snapshot. They occur when:
- Snapshots expire without cleaning up data files
- Failed writes leave partial files
- Manual file operations create unreferenced files

**Why Orphan Files Matter:**
```
Referenced Files (Keep):
┌─────────┐  ┌─────────┐  ┌─────────┐
│ File 1  │  │ File 2  │  │ File 3  │
│ (used)  │  │ (used)  │  │ (used)  │
└─────────┘  └─────────┘  └─────────┘
     ↑            ↑            ↑
     └────────────┴────────────┘
          Snapshots reference these

Orphan Files (Delete):
┌─────────┐  ┌─────────┐
│ File X  │  │ File Y  │
│ (unused)│  │ (unused)│
└─────────┘  └─────────┘
     ↑            ↑
     └────────────┘
  No snapshots reference these
```

**Impact of Orphan Files:**
- **Storage Waste**: Consume storage without providing value
- **Cost**: Paying for unused storage
- **Confusion**: Files exist but aren't part of table data
- **Performance**: May affect file listing operations

**Orphan File Cleanup Process:**
1. **Identify**: Find files not referenced by any snapshot
2. **Verify**: Confirm files are truly orphaned
3. **Delete**: Remove files from storage
4. **Log**: Record cleanup for audit purposes

**Why Cleanup is Safe:**
- **Data Integrity**: Orphan files aren't part of table data
- **Time Travel**: Doesn't affect retained snapshots
- **Rollback**: Doesn't impact rollback capability
- **Recovery**: Data can be restored from backup if needed

### 4. Table Statistics Collection

**What are Table Statistics?**
Metadata about data distribution that enables better query planning:
- **Column Statistics**: Min/max values, null counts, distinct counts
- **File Statistics**: Record counts per file, file sizes
- **Partition Statistics**: Row counts per partition
- **Manifest Statistics**: File counts per manifest

**Why Statistics Matter:**

```
Without Statistics:
Query: SELECT * FROM table WHERE value > 100
Spark: Read all files (doesn't know value ranges)

With Statistics:
Query: SELECT * FROM table WHERE value > 100
Spark: Read only files where max_value > 100
```

**Statistics Impact:**
- **Query Planning**: Better predicate pushdown and partition pruning
- **Performance**: Faster queries due to better planning
- **Cost**: Reduced S3 reads = lower costs
- **Resource Usage**: Less data scanned = less compute

**Statistics Collection Strategies:**

#### 1. Full Table Analysis
```sql
CALL iceberg.system.analyze_table('table')
```
**How it works**: Collect statistics for all columns
**When to use**: After major data loads or schema changes
**Trade-offs**: Comprehensive but resource-intensive

#### 2. Column-Specific Analysis
```sql
CALL iceberg.system.analyze_table(
  'table',
  map('columns', 'col1,col2,col3')
)
```
**How it works**: Collect statistics only for specified columns
**When to use**: When only certain columns are used in queries
**Trade-offs**: Faster but may miss optimization opportunities

#### 3. Incremental Analysis
```sql
-- Collect statistics for new partitions only
CALL iceberg.system.analyze_table('table')
WHERE partition_date >= CURRENT_DATE - INTERVAL 7 DAYS
```
**How it works**: Collect statistics only for new or modified partitions
**When to use**: Regular maintenance for large tables
**Trade-offs**: Faster but may have stale statistics for old partitions

**When to Collect Statistics:**
- **After Data Loads**: Collect after significant data ingestion
- **Before Critical Queries**: Ensure optimal planning for important queries
- **Regular Schedule**: Daily/weekly for frequently changing tables
- **Schema Changes**: After schema evolution operations

### 5. Metadata Optimization

**What is Metadata?**
Iceberg metadata includes:
- **Manifests**: Lists of data files and their metadata
- **Manifest Lists**: Lists of manifests for snapshots
- **Snapshot Metadata**: Snapshot information and statistics
- **Partition Metadata**: Partition specifications and statistics

**Why Metadata Optimization Matters:**
```
Unoptimized Metadata:
┌─────────┬─────────┬─────────┬─────────┐
│Manifest1│Manifest2│Manifest3│Manifest4│
│ 10KB    │ 10KB    │ 10KB    │ 10KB    │
│ 100 files│ 100 files│ 100 files│ 100 files│
└─────────┴─────────┴─────────┴─────────┘
Total: 40KB metadata, 400 files tracked

Optimized Metadata:
┌───────────────────────────┐
│     Combined Manifest      │
│          15KB              │
│     400 files tracked      │
└───────────────────────────┘
Total: 15KB metadata, 400 files tracked
```

**Metadata Impact:**
- **Catalog Performance**: More metadata = slower catalog operations
- **Query Planning**: Metadata size affects planning time
- **Storage**: Metadata files consume storage
- **Network**: More metadata = more S3 requests

**Metadata Optimization Strategies:**

#### 1. Manifest Rewrite
```sql
CALL iceberg.system.rewrite_manifests('table')
```
**How it works**: Combine multiple manifests into fewer, larger manifests
**When to use**: When manifest count is high (>100)
**Trade-offs**: Reduces metadata size but requires rewrite operation

#### 2. Snapshot Cleanup
```sql
CALL iceberg.system.expire_snapshots('table', map('retain-last', '10'))
```
**How it works**: Remove old snapshots and their associated metadata
**When to use**: Regular maintenance to control metadata growth
**Trade-offs**: Reduces metadata but limits time travel

#### 3. Partition Evolution Optimization
```sql
-- Add partition fields to reduce partition count
ALTER TABLE table ADD PARTITION FIELD days(date_column)
```
**How it works**: More specific partitions reduce metadata per partition
**When to use**: When partition count is too high
**Trade-offs**: More partitions but better metadata distribution

### 6. Table Migration and Rollback

**What is Table Migration?**
Moving data between table configurations while preserving data and enabling rollback.

**Why Migration Matters:**
```
Original Table:
- Simple partitioning
- Basic compression
- No Z-ordering

Migrated Table:
- Advanced partitioning
- Zstd compression
- Z-order clustering
```

**Migration Scenarios:**
- **Performance**: Migrate to better configuration
- **Storage**: Migrate to different storage backend
- **Schema**: Migrate to evolved schema
- **Catalog**: Migrate between catalog implementations

**Migration Strategies:**

#### 1. Create-and-Migrate
```sql
-- Create new table with desired configuration
CREATE TABLE table_new (...) USING iceberg
PARTITIONED BY (region, days(date))
ORDER BY customer_id;

-- Migrate data
INSERT INTO table_new SELECT * FROM table_old;

-- Switch (rename tables)
ALTER TABLE table_old RENAME TO table_backup;
ALTER TABLE table_new RENAME TO table;
```
**How it works**: Create new table, copy data, switch names
**When to use**: When you can afford downtime for large tables
**Trade-offs**: Safe but requires double storage during migration

#### 2. In-Place Migration
```sql
-- Evolve table configuration in place
ALTER TABLE table ADD PARTITION FIELD days(date);
ALTER TABLE table SET TBLPROPERTIES('write.format.default'='parquet');
```
**How it works**: Modify existing table configuration
**When to use**: When configuration changes are backward compatible
**Trade-offs**: Faster but may affect existing queries

**Rollback Strategies:**
- **Snapshot Rollback**: Use `VERSION AS OF` to revert to previous snapshot
- **Table Swap**: Keep backup table and swap names back
- **Selective Rollback**: Rollback specific partitions or data ranges

### 7. Backup and Restore Strategies

**Why Backup Matters:**
- **Data Protection**: Protect against accidental deletion
- **Disaster Recovery**: Recover from system failures
- **Testing**: Test changes safely with rollback capability
- **Compliance**: Meet data retention requirements

**Backup Strategies:**

#### 1. Full Table Backup
```sql
CREATE TABLE table_backup AS SELECT * FROM table;
```
**How it works**: Copy entire table to backup table
**When to use**: Before major changes or regularly scheduled
**Trade-offs**: Complete but resource-intensive

#### 2. Incremental Backup
```sql
CREATE TABLE table_incremental AS 
SELECT * FROM table 
WHERE updated_at >= DATE '2024-01-01';
```
**How it works**: Backup only recently modified data
**When to use**: Regular backups for large tables
**Trade-offs**: Faster but requires full backup for full restore

#### 3. Snapshot-Based Backup
```sql
-- Retain specific snapshot for backup
-- No explicit action needed during snapshot expiration
CALL iceberg.system.expire_snapshots(
  'table',
  map('older-than', '30 days', 'retain-last', '5')
);
```
**How it works**: Use Iceberg's built-in snapshot retention
**When to use**: Leverage Iceberg's time travel capability
**Trade-offs**: Efficient but relies on Iceberg functionality

**Restore Strategies:**
- **Snapshot Restore**: Use `VERSION AS OF` to restore from snapshot
- **Table Restore**: Restore from backup table
- **Incremental Restore**: Apply incremental backups to full backup
- **Point-in-Time Restore**: Restore to specific point in time

### 8. Monitoring and Alerting

**Why Monitoring Matters:**
- **Proactive Detection**: Identify issues before they become problems
- **Performance Tracking**: Monitor query performance trends
- **Capacity Planning**: Plan storage and compute resources
- **SLA Compliance**: Ensure service level agreements are met

**Key Metrics to Monitor:**

#### 1. File Metrics
```sql
SELECT 
  COUNT(*) as file_count,
  AVG(file_size_in_bytes) as avg_file_size,
  SUM(file_size_in_bytes) as total_size
FROM table.files;
```
**Alert Thresholds**:
- File count > 1000: Trigger compaction
- Average file size < 10MB: Trigger compaction
- Total size > 1TB: Review storage capacity

#### 2. Snapshot Metrics
```sql
SELECT 
  COUNT(*) as snapshot_count,
  MIN(committed_at) as oldest_snapshot,
  MAX(committed_at) as newest_snapshot
FROM table.snapshots;
```
**Alert Thresholds**:
- Snapshot count > 50: Trigger expiration
- Oldest snapshot > 90 days: Review retention policy

#### 3. Query Performance Metrics
```sql
-- Track query duration over time
-- (Use Spark History Server or monitoring system)
```
**Alert Thresholds**:
- Query duration > 5 minutes: Investigate performance
- Error rate > 1%: Investigate errors

#### 4. Storage Metrics
```sql
SELECT 
  SUM(file_size_in_bytes) / (1024 * 1024 * 1024) as total_size_gb
FROM table.files;
```
**Alert Thresholds**:
- Storage > 80% of capacity: Plan capacity expansion
- Growth rate > 10% per week: Investigate data growth

### 9. Automated Maintenance Procedures

**Why Automation Matters:**
- **Consistency**: Ensures maintenance is performed regularly
- **Efficiency**: Reduces manual effort and human error
- **Reliability**: Scheduled maintenance is more reliable
- **Scalability**: Can scale to many tables

**Maintenance Schedule:**

#### Daily Maintenance (2:00 AM)
```sql
-- 1. Compact small files
CALL iceberg.system.rewrite_data_files(
  'table',
  map('min-input-files', '10', 'target-size-bytes', str(256 * 1024 * 1024))
);

-- 2. Collect statistics
CALL iceberg.system.analyze_table('table');

-- 3. Check for orphan files
SELECT COUNT(*) FROM table.orphan_files;
```
**Purpose**: Maintain optimal file sizes and query planning

#### Weekly Maintenance (Sunday 3:00 AM)
```sql
-- 1. Expire old snapshots
CALL iceberg.system.expire_snapshots(
  'table',
  map('older-than', '30 days', 'retain-last', '10')
);

-- 2. Remove orphan files
CALL iceberg.system.remove_orphan_files('table');

-- 3. Rewrite manifests
CALL iceberg.system.rewrite_manifests('table');
```
**Purpose**: Control metadata growth and reclaim storage

#### Monthly Maintenance (First Sunday 4:00 AM)
```sql
-- 1. Full table analysis
CALL iceberg.system.analyze_table('table');

-- 2. Comprehensive compaction
CALL iceberg.system.rewrite_data_files(
  'table',
  map('min-input-files', '5', 'target-size-bytes', str(512 * 1024 * 1024))
);

-- 3. Performance review
-- (Review query performance metrics, adjust configurations)
```
**Purpose**: Deep maintenance and performance optimization

### 10. Production Best Practices

#### 1. Maintenance Scheduling
- **Low-Traffic Periods**: Schedule during off-peak hours
- **Staggered Maintenance**: Don't maintain all tables simultaneously
- **Testing**: Test maintenance procedures in non-production first
- **Monitoring**: Monitor maintenance operations for failures

#### 2. Rollback Planning
- **Snapshot Preservation**: Keep snapshots before major operations
- **Backup Creation**: Create backups before destructive operations
- **Rollback Testing**: Test rollback procedures regularly
- **Documentation**: Document rollback steps

#### 3. Monitoring and Logging
- **Operation Logging**: Record all maintenance operations
- **Metrics Collection**: Track before/after metrics
- **Alerting**: Set up alerts for maintenance failures
- **Audit Trail**: Maintain audit trail of maintenance operations

#### 4. Capacity Planning
- **Storage Growth**: Monitor storage growth trends
- **Performance Trends**: Track query performance over time
- **Resource Planning**: Plan for increased maintenance load
- **Cost Optimization**: Optimize maintenance to reduce costs

## 💡 Design Principles

### 1. Safety First
- Always have rollback capability
- Test in non-production first
- Monitor operations during execution
- Document all procedures

### 2. Performance-Driven
- Focus on high-impact optimizations
- Measure before and after
- Balance maintenance cost with benefit
- Automate routine tasks

### 3. Scalability
- Design procedures that scale to many tables
- Use automation for consistency
- Consider parallel maintenance for large tables
- Plan for increased data volumes

### 4. Observability
- Monitor all maintenance operations
- Log operations for audit trail
- Set up alerts for failures
- Review metrics regularly

## 🔍 Common Misconceptions

### Misconception 1: More Compaction is Always Better
**Reality**: Over-compaction wastes resources and can reduce parallelism. Find the right balance.

### Misconception 2: Snapshots Don't Cost Anything
**Reality**: Snapshots consume storage and metadata. Unmanaged snapshots cause performance issues.

### Misconception 3: Statistics Collection is Free
**Reality**: Statistics collection uses resources. Collect only what you need.

### Misconception 4: Maintenance Can Be Done Anytime
**Reality**: Maintenance during peak hours can impact performance. Schedule carefully.

## 🚀 Next Steps

With this understanding, you can:
1. **Design maintenance schedules** for your production environment
2. **Implement monitoring** to track table health
3. **Automate routine maintenance** to reduce manual effort
4. **Plan for growth** as your data volumes increase
5. **Optimize maintenance** based on actual usage patterns

---

**Table maintenance is essential for production Iceberg deployments. Understanding these concepts helps you design effective maintenance strategies that keep your tables performant and cost-effective.**