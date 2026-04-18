# Lab 7: Table Maintenance and Operations

## 🎯 Learning Objectives

After completing this lab, you will be able to:
- Perform file compaction and optimization strategies
- Manage snapshots and expire old data
- Clean up orphan files and reclaim storage
- Collect and analyze table statistics
- Optimize table metadata
- Perform table migrations and rollbacks
- Implement backup and restore strategies
- Monitor table health and performance
- Automate maintenance procedures

## 🛠️ Prerequisites

- Completed Lab 6: Performance & UI
- Sample database loaded (Lab 0)
- Understanding of Iceberg table structure
- Spark shell configured with Iceberg

## 📋 Lab Steps

### Step 1: File Compaction Strategies

Iceberg tables can accumulate many small files over time. Compaction merges them for better performance.

#### 1.1 Analyze File Distribution

```sql
-- Analyze file sizes in sample_orders table
SELECT 
    file,
    record_count,
    file_size_in_bytes,
    file_size_in_bytes / (1024 * 1024) as file_size_mb
FROM iceberg.sample_orders.files
ORDER BY file_size_in_bytes DESC
LIMIT 20;
```

```sql
-- Count files by size ranges
SELECT 
    CASE 
        WHEN file_size_in_bytes < 1024 * 1024 THEN 'small (<1MB)'
        WHEN file_size_in_bytes < 10 * 1024 * 1024 THEN 'medium (1-10MB)'
        WHEN file_size_in_bytes < 100 * 1024 * 1024 THEN 'large (10-100MB)'
        ELSE 'very_large (>100MB)'
    END as size_category,
    COUNT(*) as file_count,
    SUM(record_count) as total_records,
    SUM(file_size_in_bytes) / (1024 * 1024) as total_size_mb
FROM iceberg.sample_orders.files
GROUP BY size_category
ORDER BY total_size_mb DESC;
```

**Assertion 1**: File distribution analysis completed

#### 1.2 Bin-Packing Compaction

```sql
-- Perform bin-packing compaction
CALL iceberg.system.rewrite_data_files(
  'iceberg.sample_orders',
  map(
    'min-input-files', '5',
    'target-size-bytes', str(256 * 1024 * 1024)
  )
);
```

```sql
-- Verify compaction results
SELECT 
    COUNT(*) as file_count_after,
    SUM(record_count) as total_records,
    SUM(file_size_in_bytes) / (1024 * 1024) as total_size_mb
FROM iceberg.sample_orders.files;
```

**Assertion 2**: Bin-packing compaction reduces file count and increases average file size

#### 1.3 Sort-Based Compaction

```sql
-- Perform sort-based compaction for better clustering
CALL iceberg.system.rewrite_data_files(
  'iceberg.sample_orders',
  map(
    'sort-order', 'order_date,customer_id',
    'min-input-files', '5',
    'target-size-bytes', str(256 * 1024 * 1024)
  )
);
```

```sql
-- Verify data is sorted
SELECT 
    order_date,
    customer_id,
    total_amount
FROM iceberg.sample_orders
WHERE region = 'west'
ORDER BY order_date, customer_id
LIMIT 10;
```

**Assertion 3**: Sort-based compaction improves data clustering

#### 1.4 Z-Order Compaction

```sql
-- Perform Z-order compaction for multi-column clustering
CALL iceberg.system.rewrite_data_files(
  'iceberg.sample_orders',
  map(
    'z-order', 'customer_id,order_date',
    'min-input-files', '5',
    'target-size-bytes', str(128 * 1024 * 1024)
  )
);
```

```sql
-- Test query performance improvement
EXPLAIN EXTENDED
SELECT customer_id, SUM(total_amount) as total_spent
FROM iceberg.sample_orders
WHERE customer_id BETWEEN 100 AND 200
GROUP BY customer_id;
```

**Assertion 4**: Z-order compaction improves multi-column query performance

### Step 2: Snapshot Management

Iceberg maintains snapshots for time travel. Managing snapshots is crucial for storage efficiency.

#### 2.1 Analyze Snapshot History

```sql
-- List all snapshots with details
SELECT 
    snapshot_id,
    committed_at,
    summary['operation'] as operation,
    summary['added-files-size'] as added_files_size,
    summary['removed-files-size'] as removed_files_size,
    summary['added-records-count'] as added_records,
    summary['removed-records-count'] as removed_records
FROM iceberg.sample_orders.snapshots
ORDER BY committed_at DESC
LIMIT 20;
```

```sql
-- Calculate snapshot storage usage
SELECT 
    COUNT(*) as snapshot_count,
    SUM(CAST(summary['added-files-size'] AS BIGINT)) as total_added_size,
    SUM(CAST(summary['removed-files-size'] AS BIGINT)) as total_removed_size
FROM iceberg.sample_orders.snapshots;
```

**Assertion 5**: Snapshot history analysis completed

#### 2.2 Expire Old Snapshots

```sql
-- Expire snapshots older than 30 days
CALL iceberg.system.expire_snapshots(
  'iceberg.sample_orders',
  map(
    'older-than', '30 days'
  )
);
```

```sql
-- Verify snapshot expiration
SELECT COUNT(*) as remaining_snapshots
FROM iceberg.sample_orders.snapshots;
```

```sql
-- Keep only last 10 snapshots
CALL iceberg.system.expire_snapshots(
  'iceberg.sample_orders',
  map(
    'retain-last', '10'
  )
);
```

**Assertion 6**: Snapshot expiration reduces snapshot count

#### 2.3 Snapshot Retention Policy

```sql
-- Implement time-based retention with minimum snapshot count
CALL iceberg.system.expire_snapshots(
  'iceberg.sample_orders',
  map(
    'older-than', '7 days',
    'retain-last', '5'
  )
);
```

```sql
-- Verify retention policy
SELECT 
    committed_at,
    DATEDIFF(CURRENT_DATE, committed_at) as days_old
FROM iceberg.sample_orders.snapshots
ORDER BY committed_at;
```

**Assertion 7**: Retention policy maintains recent snapshots while expiring old ones

### Step 3: Orphan File Cleanup

Orphan files are data files not referenced by any snapshot. They waste storage and should be cleaned up.

#### 3.1 Identify Orphan Files

```sql
-- Iceberg automatically tracks orphan files during snapshot expiration
-- After expiration, check for remaining orphan files
SELECT 
    file,
    file_size_in_bytes
FROM iceberg.sample_orders.orphan_files
LIMIT 10;
```

```sql
-- Calculate orphan file storage usage
SELECT 
    COUNT(*) as orphan_file_count,
    SUM(file_size_in_bytes) / (1024 * 1024) as total_orphan_size_mb
FROM iceberg.sample_orders.orphan_files;
```

**Assertion 8**: Orphan file identification completed

#### 3.2 Remove Orphan Files

```sql
-- Remove orphan files to reclaim storage
CALL iceberg.system.remove_orphan_files(
  'iceberg.sample_orders'
);
```

```sql
-- Verify orphan file removal
SELECT COUNT(*) as remaining_orphan_files
FROM iceberg.sample_orders.orphan_files;
```

**Assertion 9**: Orphan files successfully removed

### Step 4: Table Statistics Collection

Statistics enable better query planning and performance optimization.

#### 4.1 Analyze Current Statistics

```sql
-- Check current column statistics
SELECT 
    column,
    record_count,
    null_value_count,
    nan_value_count,
    lower_bound,
    upper_bound
FROM iceberg.sample_orders.history
WHERE snapshot_id = (
    SELECT snapshot_id 
    FROM iceberg.sample_orders.snapshots 
    ORDER BY committed_at DESC 
    LIMIT 1
)
LIMIT 20;
```

```sql
-- Check manifest statistics
SELECT 
    manifest_path,
    length,
    partition_summaries,
    added_files_count,
    added_records_count,
    deleted_files_count,
    deleted_records_count
FROM iceberg.sample_orders.all_manifests
ORDER BY length DESC
LIMIT 10;
```

**Assertion 10**: Current statistics analysis completed

#### 4.2 Collect New Statistics

```sql
-- Collect statistics for all columns
CALL iceberg.system.analyze_table(
  'iceberg.sample_orders'
);
```

```sql
-- Collect statistics for specific columns
CALL iceberg.system.analyze_table(
  'iceberg.sample_orders',
  map(
    'columns', 'customer_id,product_id,total_amount'
  )
);
```

```sql
-- Verify updated statistics
SELECT 
    column,
    record_count,
    null_value_count
FROM iceberg.sample_orders.history
WHERE snapshot_id = (
    SELECT snapshot_id 
    FROM iceberg.sample_orders.snapshots 
    ORDER BY committed_at DESC 
    LIMIT 1
);
```

**Assertion 11**: Statistics collection completed successfully

### Step 5: Metadata Optimization

Optimizing metadata improves catalog operations and query planning.

#### 5.1 Analyze Metadata Size

```sql
-- Check manifest file sizes
SELECT 
    manifest_path,
    length,
    added_files_count + deleted_files_count as total_file_changes
FROM iceberg.sample_orders.all_manifests
ORDER BY length DESC
LIMIT 10;
```

```sql
-- Calculate total metadata size
SELECT 
    SUM(length) / (1024 * 1024) as total_metadata_mb,
    COUNT(*) as manifest_count
FROM iceberg.sample_orders.all_manifests;
```

**Assertion 12**: Metadata size analysis completed

#### 5.2 Rewrite Manifests

```sql
-- Rewrite manifests to reduce metadata size
CALL iceberg.system.rewrite_manifests(
  'iceberg.sample_orders'
);
```

```sql
-- Verify manifest rewrite
SELECT 
    COUNT(*) as manifest_count_after,
    SUM(length) / (1024 * 1024) as total_metadata_mb_after
FROM iceberg.sample_orders.all_manifests;
```

**Assertion 13**: Manifest rewrite reduces metadata size

### Step 6: Table Migration and Rollback

Migrate tables between catalogs or configurations with rollback capability.

#### 6.1 Create Table Migration

```sql
-- Create a new table with optimized configuration
CREATE TABLE iceberg.sample_orders_optimized (
  order_id INT,
  customer_id INT,
  product_id INT,
  order_date DATE,
  quantity INT,
  unit_price DECIMAL(10,2),
  total_amount DECIMAL(10,2),
  status STRING,
  region STRING,
  salesperson_id INT
) USING iceberg
PARTITIONED BY (region, bucket(16, customer_id))
ORDER BY order_date, customer_id
TBLPROPERTIES (
  'format-version'='2',
  'write.format.default'='parquet',
  'write.parquet.compression-codec'='zstd',
  'write.metadata.compression-codec'='gzip'
);
```

```sql
-- Migrate data from original table
INSERT INTO iceberg.sample_orders_optimized
SELECT * FROM iceberg.sample_orders;
```

```sql
-- Verify migration
SELECT COUNT(*) as record_count
FROM iceberg.sample_orders_optimized;
```

**Assertion 14**: Table migration completed successfully

#### 6.2 Verify Migration Integrity

```sql
-- Compare record counts
SELECT 
    (SELECT COUNT(*) FROM iceberg.sample_orders) as original_count,
    (SELECT COUNT(*) FROM iceberg.sample_orders_optimized) as optimized_count;
```

```sql
-- Compare data integrity
SELECT 
    COUNT(*) as matching_records
FROM iceberg.sample_orders o
INNER JOIN iceberg.sample_orders_optimized oo 
  ON o.order_id = oo.order_id
WHERE o.customer_id = oo.customer_id
  AND o.product_id = oo.product_id
  AND o.order_date = oo.order_date
  AND o.total_amount = oo.total_amount;
```

**Assertion 15**: Migration integrity verified

#### 6.3 Rollback to Previous State

```sql
-- Save current snapshot for rollback
SELECT snapshot_id, committed_at
FROM iceberg.sample_orders.snapshots
ORDER BY committed_at DESC
LIMIT 1;
```

```sql
-- Rollback to specific snapshot if needed
-- (In production, you would use snapshot_id from above)
-- SELECT * FROM iceberg.sample_orders VERSION AS OF <snapshot_id>;
```

**Assertion 16**: Rollback capability verified

### Step 7: Backup and Restore Strategies

Implement backup and restore procedures for data protection.

#### 7.1 Table Backup

```sql
-- Create backup table
CREATE TABLE iceberg.sample_orders_backup AS
SELECT * FROM iceberg.sample_orders;
```

```sql
-- Verify backup
SELECT COUNT(*) as backup_record_count
FROM iceberg.sample_orders_backup;
```

**Assertion 17**: Table backup created successfully

#### 7.2 Incremental Backup

```sql
-- Create incremental backup for recent changes
CREATE TABLE iceberg.sample_orders_incremental AS
SELECT * FROM iceberg.sample_orders
WHERE order_date >= DATE '2024-01-01';
```

```sql
-- Verify incremental backup
SELECT 
    MIN(order_date) as min_date,
    MAX(order_date) as max_date,
    COUNT(*) as record_count
FROM iceberg.sample_orders_incremental;
```

**Assertion 18**: Incremental backup created successfully

#### 7.3 Restore from Backup

```sql
-- Restore from backup (if needed)
-- DROP TABLE IF EXISTS iceberg.sample_orders;
-- CREATE TABLE iceberg.sample_orders AS SELECT * FROM iceberg.sample_orders_backup;
```

**Assertion 19**: Restore procedure documented

### Step 8: Monitoring and Alerting

Monitor table health and set up maintenance alerts.

#### 8.1 Table Health Check

```sql
-- Comprehensive table health check
SELECT 
    'file_count' as metric,
    COUNT(*) as value
FROM iceberg.sample_orders.files
UNION ALL
SELECT 
    'snapshot_count' as metric,
    COUNT(*) as value
FROM iceberg.sample_orders.snapshots
UNION ALL
SELECT 
    'orphan_file_count' as metric,
    COUNT(*) as value
FROM iceberg.sample_orders.orphan_files
UNION ALL
SELECT 
    'manifest_count' as metric,
    COUNT(*) as value
FROM iceberg.sample_orders.all_manifests;
```

**Assertion 20**: Table health check completed

#### 8.2 Performance Monitoring

```sql
-- Monitor query performance over time
SELECT 
    snapshot_id,
    committed_at,
    CAST(summary['added-files-size'] AS BIGINT) as added_size,
    CAST(summary['added-records-count'] AS BIGINT) as added_records
FROM iceberg.sample_orders.snapshots
ORDER BY committed_at DESC
LIMIT 10;
```

```sql
-- Calculate file size trends
SELECT 
    DATE(committed_at) as date,
    COUNT(*) as snapshot_count,
    AVG(CAST(summary['added-files-size'] AS BIGINT)) as avg_file_size
FROM iceberg.sample_orders.snapshots
GROUP BY DATE(committed_at)
ORDER BY date DESC
LIMIT 7;
```

**Assertion 21**: Performance monitoring completed

#### 8.3 Maintenance Alerts Setup

```sql
-- Create maintenance alert thresholds
-- These would be implemented in your monitoring system
-- Example thresholds:
-- - File count > 100: Trigger compaction
-- - Snapshot count > 20: Trigger expiration
-- - Orphan files > 10: Trigger cleanup
-- - Metadata size > 100MB: Trigger manifest rewrite
```

**Assertion 22**: Maintenance alert thresholds defined

### Step 9: Automated Maintenance Procedures

Create automated maintenance procedures for regular table maintenance.

#### 9.1 Daily Maintenance Procedure

```sql
-- Daily maintenance script (would be scheduled)
-- 1. Compact files
CALL iceberg.system.rewrite_data_files(
  'iceberg.sample_orders',
  map('min-input-files', '10', 'target-size-bytes', str(256 * 1024 * 1024))
);

-- 2. Collect statistics
CALL iceberg.system.analyze_table('iceberg.sample_orders');

-- 3. Check for orphan files
SELECT COUNT(*) as orphan_count
FROM iceberg.sample_orders.orphan_files;
```

**Assertion 23**: Daily maintenance procedure defined

#### 9.2 Weekly Maintenance Procedure

```sql
-- Weekly maintenance script (would be scheduled)
-- 1. Expire old snapshots
CALL iceberg.system.expire_snapshots(
  'iceberg.sample_orders',
  map('older-than', '30 days', 'retain-last', '10')
);

-- 2. Remove orphan files
CALL iceberg.system.remove_orphan_files('iceberg.sample_orders');

-- 3. Rewrite manifests
CALL iceberg.system.rewrite_manifests('iceberg.sample_orders');
```

**Assertion 24**: Weekly maintenance procedure defined

#### 9.3 Monthly Maintenance Procedure

```sql
-- Monthly maintenance script (would be scheduled)
-- 1. Full table analysis
CALL iceberg.system.analyze_table('iceberg.sample_orders');

-- 2. Comprehensive compaction
CALL iceberg.system.rewrite_data_files(
  'iceberg.sample_orders',
  map('min-input-files', '5', 'target-size-bytes', str(512 * 1024 * 1024))
);

-- 3. Performance review
-- (Review query performance metrics, adjust configurations)
```

**Assertion 25**: Monthly maintenance procedure defined

### Step 10: Maintenance Best Practices

Implement maintenance best practices for production environments.

#### 10.1 Maintenance Scheduling

```sql
-- Schedule maintenance during low-traffic periods
-- Example schedule:
-- - Daily: 2:00 AM - File compaction, statistics collection
-- - Weekly: Sunday 3:00 AM - Snapshot expiration, orphan cleanup
-- - Monthly: First Sunday 4:00 AM - Full maintenance
```

**Assertion 26**: Maintenance schedule defined

#### 10.2 Monitoring and Logging

```sql
-- Log all maintenance operations
-- Example logging approach:
-- - Record operation type, timestamp, table, parameters
-- - Record operation duration, success/failure status
-- - Record before/after metrics for comparison
```

**Assertion 27**: Monitoring and logging approach defined

#### 10.3 Rollback Planning

```sql
-- Always have rollback plan before maintenance
-- Example rollback considerations:
-- - Save snapshot ID before major operations
-- - Test rollback procedure in non-production
-- - Document rollback steps
-- - Set up alerts for maintenance failures
```

**Assertion 28**: Rollback planning documented

## ✅ Lab Completion Checklist

- [ ] File compaction strategies implemented and tested
- [ ] Snapshot management with expiration policies
- [ ] Orphan file cleanup performed
- [ ] Table statistics collected and analyzed
- [ ] Metadata optimization completed
- [ ] Table migration and rollback tested
- [ ] Backup and restore procedures implemented
- [ ] Monitoring and alerting configured
- [ ] Automated maintenance procedures defined
- [ ] Maintenance best practices documented

## 🔍 Troubleshooting

### Issue: Compaction doesn't reduce file count
**Solution**: Adjust min-input-files and target-size-bytes parameters

### Issue: Snapshot expiration fails
**Solution**: Ensure snapshots are not referenced by active queries or backups

### Issue: Orphan files remain after cleanup
**Solution**: Verify snapshot expiration completed successfully first

### Issue: Statistics collection is slow
**Solution**: Collect statistics for specific columns instead of all columns

### Issue: Maintenance operations affect query performance
**Solution**: Schedule maintenance during low-traffic periods

## 🎓 Key Concepts Learned

1. **File Compaction**: Merging small files for better performance
2. **Snapshot Management**: Expiring old snapshots to maintain performance
3. **Orphan Cleanup**: Removing unreferenced files to reclaim storage
4. **Statistics Collection**: Enabling better query planning
5. **Metadata Optimization**: Reducing catalog overhead
6. **Table Migration**: Moving tables with rollback capability
7. **Backup Strategies**: Protecting data with backup procedures
8. **Monitoring**: Tracking table health and performance
9. **Automation**: Creating scheduled maintenance procedures
10. **Best Practices**: Implementing production-ready maintenance

## 🚀 Next Steps

With table maintenance skills, you can now:
- Implement production-ready maintenance procedures
- Monitor and optimize table performance
- Ensure data protection with backup strategies
- Automate routine maintenance tasks
- Troubleshoot maintenance issues

---

**Table maintenance is crucial for production Iceberg deployments. This lab provides the skills needed to maintain healthy, performant Iceberg tables.**