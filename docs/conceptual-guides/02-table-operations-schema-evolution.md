# Conceptual Guide: Iceberg Table Operations and Schema Evolution

## 🎯 Learning Objectives

This guide explains the fundamental concepts behind Iceberg table operations and schema evolution. Understanding these concepts will help you design better data architectures and make informed decisions about table management.

## 📚 Core Concepts

### 1. Iceberg Table Structure

**What Makes an Iceberg Table Special?**
Unlike traditional database tables where data and metadata are tightly coupled, Iceberg separates them:

```
Traditional Database Table:
┌─────────────────────────────┐
│  Data + Metadata (coupled)  │
└─────────────────────────────┘

Iceberg Table:
┌─────────────────┐  ┌─────────────────┐
│   Metadata      │  │     Data        │
│  (in Catalog)   │  │  (in S3 Files)  │
└────────┬────────┘  └────────┬────────┘
         │                    │
         └────────────────────┘
              (References)
```

**Why This Matters:**
- **Independent Scaling**: Metadata can be cached separately from data
- **Multiple Engines**: Different compute engines can share the same table
- **Time Travel**: Metadata snapshots allow historical queries
- **Schema Evolution**: Metadata changes don't require data rewrites

### 2. Partitioning Strategies

**What is Partitioning?**
Partitioning divides data into smaller, more manageable pieces based on column values.

**Why Partition?**
- **Query Performance**: Only scan relevant partitions
- **Storage Efficiency**: Organize data logically
- **Parallel Processing**: Enable parallel scans across partitions

**Iceberg Partitioning vs Traditional Partitioning:**

| Feature | Traditional Hive | Iceberg |
|---------|-----------------|---------|
| Partition Evolution | Requires data rewrite | Metadata-only change |
| Hidden Partitions | User must manage | Automatic |
| Partition Pruning | Manual | Automatic |
| Partition Discovery | Slow | Fast |

**Partitioning Strategies:**

1. **Identity Partitioning**: Direct column values
   ```sql
   PARTITIONED BY (region)  -- region = 'west', 'east', etc.
   ```

2. **Transform Partitioning**: Apply functions to columns
   ```sql
   PARTITIONED BY (years(timestamp))  -- Extract year from timestamp
   PARTITIONED BY (days(timestamp))   -- Extract day from timestamp
   PARTITIONED BY (bucket(16, id))    -- Hash into 16 buckets
   ```

3. **Multi-Level Partitioning**: Multiple partition columns
   ```sql
   PARTITIONED BY (years(timestamp), region)
   ```

**Why Transform Partitioning?**
- **Cardinality Control**: Prevent too many small partitions
- **Query Patterns**: Match common query filters
- **Data Skew**: Avoid uneven data distribution

### 3. Schema Evolution

**What is Schema Evolution?**
The ability to modify table structure without breaking existing data or queries.

**Why Schema Evolution Matters:**
- **Business Changes**: Requirements evolve over time
- **Data Quality**: Discover need for additional fields
- **Integration**: New data sources have different schemas
- **Backward Compatibility**: Old queries still work

**Iceberg Schema Evolution Types:**

#### 1. Add Column
```sql
ALTER TABLE table ADD COLUMN new_column STRING
```
**How it works**: 
- New metadata snapshot references old data files
- Old files don't contain the new column (null values)
- New files include the column
- Queries handle missing values gracefully

**Why it's safe**: No data rewrite required, metadata-only change

#### 2. Drop Column
```sql
ALTER TABLE table DROP COLUMN old_column
```
**How it works**:
- Metadata updated to ignore the column
- Data still exists in files (not deleted)
- Future compactions can physically remove the column
- Old data files remain readable

**Why it's safe**: Logical deletion, physical cleanup happens later

#### 3. Rename Column
```sql
ALTER TABLE table RENAME COLUMN old_name TO new_name
```
**How it works**:
- Metadata mapping updated
- No data file changes
- Queries use new name automatically

**Why it's safe**: Metadata-only change

#### 4. Change Column Type
```sql
ALTER TABLE table ALTER COLUMN col TYPE INT
```
**How it works**:
- Metadata updated with new type
- Spark handles type conversion during reads
- May require validation for incompatible types

**Why it's safe**: Type conversion handled at read time

**Schema Evolution Safety Guarantees:**
- **Backward Compatibility**: Old queries work on new schemas
- **Forward Compatibility**: New queries work on old schemas (with nulls)
- **No Data Loss**: Original data preserved
- **Rollback**: Can revert to previous schema versions

### 4. Snapshots and Time Travel

**What are Snapshots?**
Snapshots are point-in-time, immutable views of table data.

**How Snapshots Work:**
```
Timeline:
┌─────────┬─────────┬─────────┬─────────┐
│Snapshot1│Snapshot2│Snapshot3│Snapshot4│
│ (initial)│ (insert)│ (update)│ (delete)│
└────┬────┴────┬────┴────┬────┴────┬────┘
     │         │         │         │
     ▼         ▼         ▼         ▼
  Data1    Data1+2   Data1+2+3  Data1+2+4
```

**Why Snapshots Matter:**
- **Time Travel**: Query data as it existed at any point
- **Debugging**: Investigate data issues by examining historical states
- **Auditing**: Track changes over time
- **Rollback**: Revert to previous state if needed
- **Reproducibility**: Reproduce analyses with historical data

**Snapshot Lifecycle:**
1. **Creation**: Each write operation creates a new snapshot
2. **Retention**: Old snapshots can be expired to save space
3. **Expiration**: Data files not referenced by any snapshot are deleted
4. **Cleanup**: Garbage collection removes orphaned files

**Time Travel Syntax:**
```sql
-- Query at specific snapshot ID
SELECT * FROM table VERSION AS OF <snapshot_id>

-- Query at specific timestamp
SELECT * FROM table TIMESTAMP AS OF '2024-01-01 00:00:00'

-- Query specific snapshot
SELECT * FROM table SNAPSHOT '<snapshot_id>'
```

### 5. ACID Transactions

**What are ACID Transactions?**
ACID stands for Atomicity, Consistency, Isolation, Durability - guarantees that database transactions are processed reliably.

**Why ACID Matters for Data Lakes:**
- **Data Integrity**: Prevent partial updates or corrupted data
- **Concurrent Access**: Multiple users can modify data safely
- **Rollback**: Failed operations don't leave data in inconsistent state
- **Reliability**: System crashes don't corrupt data

**Iceberg ACID Implementation:**

#### Atomicity
```sql
-- Either all rows are updated, or none are
UPDATE table SET status = 'shipped' WHERE order_id = 1
```
**How it works**: 
- Writes to new files
- Updates metadata atomically
- If metadata update fails, new files are ignored

#### Consistency
```sql
-- All constraints and validations are enforced
INSERT INTO table VALUES (...)
```
**How it works**:
- Schema validation during writes
- Referential integrity checks
- Data type validation

#### Isolation
```sql
-- Concurrent writes don't interfere
-- User A: INSERT INTO table VALUES (...)
-- User B: UPDATE table SET ...
```
**How it works**:
- Optimistic concurrency control
- Snapshot isolation
- Write serialization

#### Durability
```sql
-- Once committed, changes survive system failures
COMMIT
```
**How it works**:
- Metadata written to durable storage
- Data files written before metadata update
- Crash recovery uses metadata to determine valid state

### 6. Update and Delete Operations

**How Iceberg Handles Updates:**
Unlike traditional databases that modify data in-place, Iceberg:

```
Traditional Database Update:
┌─────────────────┐
│  Row 1 (old)    │ ──┐
│  Row 2 (old)    │   │ Modify in-place
│  Row 3 (old)    │ ──┘
└─────────────────┘

Iceberg Update:
┌─────────────────┐     ┌─────────────────┐
│  File 1 (old)    │ ──▶ │  File 1 (old)    │ (marked for deletion)
│  File 2 (new)    │ ◀── │  File 2 (new)    │ (with updated row)
└─────────────────┘     └─────────────────┘
```

**Why Copy-on-Write?**
- **Immutable Files**: Safer for distributed storage
- **Time Travel**: Old versions preserved
- **Concurrent Access**: No locking required
- **Simpler Recovery**: Easier to recover from failures

**Delete Operations:**
```sql
DELETE FROM table WHERE id = 1
```
**How it works**:
- Metadata marks file as containing deleted rows
- Data not immediately removed from files
- Future compaction physically removes deleted data
- Time travel still shows deleted rows in old snapshots

## 💡 Design Patterns

### 1. Partitioning Best Practices

**Do:**
- Partition on frequently filtered columns
- Use transform functions to control cardinality
- Consider query patterns when choosing partitions
- Monitor partition sizes

**Don't:**
- Partition on high-cardinality columns (like IDs)
- Create too many small partitions
- Partition on columns that change frequently
- Use single-value partitions

### 2. Schema Evolution Strategy

**Gradual Migration:**
```sql
-- Step 1: Add new column (nullable)
ALTER TABLE table ADD COLUMN new_field STRING

-- Step 2: Backfill data
UPDATE table SET new_field = 'default' WHERE new_field IS NULL

-- Step 3: Make column required (if needed)
ALTER TABLE table ALTER COLUMN new_field DROP NOT NULL
```

### 3. Snapshot Management

**Retention Policy:**
```sql
-- Keep last 7 days of snapshots
CALL iceberg.system.expire_snapshots(
  'table',
  map('older-than', '7 days')
)
```

**Why**: Balance between time travel capability and storage cost

## 🔍 Common Misconceptions

### Misconception 1: Schema Evolution is Expensive
**Reality**: Most schema evolution operations are metadata-only and don't require data rewrites.

### Misconception 2: More Partitions = Better Performance
**Reality**: Too many small partitions hurt performance. Aim for 100MB-1GB per partition.

### Misconception 3: Deletes Immediately Free Space
**Reality**: Deletes are metadata-only. Space is freed during compaction.

### Misconception 4: Time Travel Stores Full Copies
**Reality**: Time travel uses copy-on-write. Only changed data is stored.

## 🚀 Next Steps

With this understanding, you're ready to:
1. **Design effective partitioning strategies** for your use cases
2. **Plan schema evolution** for changing requirements
3. **Use time travel** for debugging and auditing
4. **Implement ACID transactions** for data integrity
5. **Choose appropriate update/delete patterns** for your workload

---

**Remember**: Schema evolution and time travel are not just features - they're fundamental capabilities that change how you think about data management. They enable agile data engineering practices that were previously impossible with traditional data lakes.