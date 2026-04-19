# Iceberg Fundamentals

This guide provides a comprehensive introduction to Apache Iceberg core concepts, architecture, and key features. Understanding these fundamentals is essential for completing the hands-on labs effectively.

## 🎯 Learning Objectives

After reading this guide, you will understand:
- What Apache Iceberg is and why it matters
- Core Iceberg architecture and components
- Key Iceberg features and benefits
- How Iceberg differs from traditional table formats
- Iceberg's role in modern data lakehouse architecture

## 📚 What is Apache Iceberg?

Apache Iceberg is an open table format for huge analytic datasets. It provides several critical features that make it ideal for modern data lakehouse architectures:

### Key Characteristics

- **Table Format**: Defines how data is organized, tracked, and managed
- **Open Source**: Apache 2.0 licensed, vendor-independent
- **Engine Agnostic**: Works with Spark, Trino, DuckDB, and more
- **Schema Evolution**: Supports schema changes without data rewriting
- **Time Travel**: Query data as it existed at any point in time
- **ACID Transactions**: Ensures data integrity with concurrent operations
- **Hidden Partitioning**: Simplifies partition management
- **File Size Optimization**: Automatic file sizing and compaction

## 🏗️ Iceberg Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Query Engine Layer                       │
│  (Spark, Trino, DuckDB, Flink, Hive, etc.)                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Iceberg Library Layer                    │
│  - Table API                                                │
│  - Catalog API                                              │
│  - Metadata Management                                      │
│  - File Organization                                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Catalog Layer                            │
│  - REST Catalog (Polaris, Nessie, etc.)                    │
│  - Hive Catalog                                             │
│  - AWS Glue Catalog                                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Storage Layer                             │
│  - S3, ADLS, GCS, HDFS                                     │
│  - Parquet, Avro, ORC files                                │
└─────────────────────────────────────────────────────────────┘
```

### Metadata Hierarchy

Iceberg organizes metadata in a hierarchical structure:

1. **Catalog**: Manages namespaces and tables
2. **Table**: Contains metadata about a specific table
3. **Snapshot**: Represents a consistent state of the table at a point in time
4. **Manifest List**: Lists all manifests for a snapshot
5. **Manifest**: Lists data files with partition information
6. **Data File**: Actual data in Parquet/Avro/ORC format

## 🔑 Key Iceberg Concepts

### Snapshots and Time Travel

Every write operation creates a new snapshot:
- **Snapshot ID**: Unique identifier for each table state
- **Snapshot Log**: History of all snapshots
- **Time Travel**: Query data as it existed at any snapshot
- **Rollback**: Revert to previous snapshot if needed

```sql
-- Query data as of a specific snapshot
SELECT * FROM my_table VERSION AS OF 'snapshot_id'

-- Query data as of a specific timestamp
SELECT * FROM my_table TIMESTAMP AS OF '2024-01-01 00:00:00'
```

### Schema Evolution

Iceberg supports schema evolution without data rewriting:

- **Add Column**: Add new columns to existing tables
- **Drop Column**: Remove columns (metadata only)
- **Rename Column**: Change column names
- **Change Type**: Modify column data types (safe conversions)
- **Reorder Columns**: Change column order

```sql
-- Add a new column
ALTER TABLE my_table ADD COLUMN email STRING

-- Drop a column
ALTER TABLE my_table DROP COLUMN old_column

-- Rename a column
ALTER TABLE my_table RENAME COLUMN old_name TO new_name
```

### Partition Evolution

Traditional partitioning requires data rewriting for schema changes. Iceberg's hidden partitioning allows:

- **Dynamic Partitioning**: Partition values derived from data
- **Partition Evolution**: Change partitioning without rewriting
- **Multiple Partition Strategies**: Combine different partition types

```sql
-- Add partition field
ALTER TABLE my_table ADD PARTITION FIELD years(created_at)

-- Change partition strategy
ALTER TABLE my_table REPLACE PARTITION FIELD days(created_at) WITH bucket(16, user_id)
```

### ACID Transactions

Iceberg provides ACID guarantees:
- **Atomicity**: Operations are all-or-nothing
- **Consistency**: Data remains valid across operations
- **Isolation**: Concurrent operations don't interfere
- **Durability**: Committed changes persist

## 📊 Iceberg vs Traditional Formats

| Feature | Iceberg | Traditional Hive | Delta Lake |
|---------|---------|-----------------|------------|
| Schema Evolution | Yes | Limited | Yes |
| Time Travel | Yes | No | Yes |
| ACID Transactions | Yes | No | Yes |
| Hidden Partitioning | Yes | No | Yes |
| File Size Optimization | Yes | Manual | Yes |
| Engine Support | Many | Limited | Spark-focused |
| Open Source | Apache 2.0 | Apache 2.0 | Apache 2.0 |

## 🎯 Iceberg in Data Lakehouse Architecture

### Lakehouse Benefits

Iceberg enables the data lakehouse architecture by combining:
- **Data Lake Benefits**: Low-cost storage, flexibility, scalability
- **Data Warehouse Benefits**: ACID transactions, schema enforcement, performance

### Typical Use Cases

1. **Batch Analytics**: Large-scale data processing
2. **Streaming Analytics**: Real-time data ingestion
3. **Machine Learning**: Feature stores and training data
4. **Data Science**: Interactive data exploration
5. **BI & Reporting**: Consistent query results

## 🔧 Iceberg Operations

### Basic Operations

```sql
-- Create a table
CREATE TABLE my_table (
    id BIGINT,
    name STRING,
    created_at TIMESTAMP
) USING iceberg

-- Insert data
INSERT INTO my_table VALUES (1, 'Alice', TIMESTAMP '2024-01-01 00:00:00')

-- Query data
SELECT * FROM my_table WHERE id = 1

-- Update data
UPDATE my_table SET name = 'Alice Smith' WHERE id = 1

-- Delete data
DELETE FROM my_table WHERE id = 1
```

### Advanced Operations

```sql
-- Time travel query
SELECT * FROM my_table VERSION AS OF 'snapshot_id'

-- Schema evolution
ALTER TABLE my_table ADD COLUMN email STRING

-- Partition evolution
ALTER TABLE my_table ADD PARTITION FIELD days(created_at)

-- Compaction
CALL iceberg.system.rewrite_data_files('my_table')

-- Snapshot expiration
CALL iceberg.system.expire_snapshots('my_table', TIMESTAMP '2024-01-01 00:00:00')
```

## 📈 Performance Features

### Metadata-Only Filtering

Iceberg can skip reading data files using only metadata:
- **Partition Pruning**: Skip entire partitions based on predicates
- **File Pruning**: Skip individual files using min/max statistics
- **Row Group Pruning**: Skip row groups within files

### Z-Ordering

Optimize file layout for query performance:
- **Clustering**: Group related data together
- **Multiple Dimensions**: Order by multiple columns
- **Automatic**: Iceberg can suggest optimal Z-ordering

```sql
-- Z-order by specific columns
ALTER TABLE my_table WRITE ORDERED BY category, created_at
```

### File Size Optimization

Iceberg automatically manages file sizes:
- **Target File Size**: Configurable target size (e.g., 512MB)
- **Bin-Packing**: Efficiently pack small files
- **Compaction**: Merge small files into larger ones

## 🔒 Security and Governance

### Catalog-Level Security

- **Authentication**: Control who can access the catalog
- **Authorization**: Manage permissions on namespaces and tables
- **Audit Logging**: Track access and modifications

### Table-Level Security

- **Row-Level Security**: Control access to specific rows
- **Column-Level Security**: Control access to specific columns
- **Masking**: Hide sensitive data

## 🌐 Ecosystem Integration

### Supported Query Engines

- **Apache Spark**: Full integration with Spark SQL
- **Trino**: Distributed SQL query engine
- **DuckDB**: Local analytics database
- **Flink**: Stream processing
- **Hive**: Batch processing (limited)
- **Impala**: Interactive queries

### Supported Catalogs

- **REST Catalog**: Apache Polaris, Nessie, Project Nessie
- **Hive Catalog**: Traditional Hive metastore
- **AWS Glue**: AWS-managed catalog
- **Google Cloud Catalog**: GCP-managed catalog
- **Azure Catalog**: Azure-managed catalog

### Supported Storage

- **Amazon S3**: AWS object storage
- **Azure Data Lake**: Azure object storage
- **Google Cloud Storage**: GCP object storage
- **HDFS**: Hadoop distributed file system
- **Local Storage**: For testing and development

## 🎓 Learning Path

### Beginner Concepts

1. **Table Operations**: Create, read, update, delete
2. **Schema Evolution**: Add, drop, rename columns
3. **Basic Queries**: Simple SELECT statements
4. **Partitioning**: Understand partition concepts

### Intermediate Concepts

1. **Time Travel**: Query historical data
2. **Snapshot Management**: Manage table snapshots
3. **File Organization**: Understand file layout
4. **Performance Basics**: Partition pruning, file sizing

### Advanced Concepts

1. **Advanced Partitioning**: Complex partition strategies
2. **Z-Ordering**: Optimize file layout
3. **Compaction Strategies**: File size optimization
4. **Multi-Engine Queries**: Cross-engine operations

## 📚 Additional Resources

### Official Documentation

- [Apache Iceberg Website](https://iceberg.apache.org/)
- [Iceberg Specification](https://iceberg.apache.org/spec/)
- [Iceberg Blog](https://iceberg.apache.org/blog/)

### Community Resources

- [Iceberg Slack](https://apache-iceberg.slack.com/)
- [Iceberg GitHub Discussions](https://github.com/apache/iceberg/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/apache-iceberg)

### Related Projects

- [Apache Spark](https://spark.apache.org/)
- [Trino](https://trino.io/)
- [DuckDB](https://duckdb.org/)
- [Apache Polaris](https://polaris.apache.org/)

## 🆘 Common Questions

### Q: When should I use Iceberg vs traditional formats?

A: Use Iceberg when you need:
- Schema evolution without rewriting data
- Time travel capabilities
- ACID transactions
- Multiple engine support
- Better performance through metadata optimization

### Q: Is Iceberg a database?

A: No, Iceberg is a table format, not a database. It works with various query engines and storage systems.

### Q: Can I use Iceberg with my existing data?

A: Yes, Iceberg can migrate existing data through import tools and supports gradual migration strategies.

### Q: How does Iceberg handle concurrent writes?

A: Iceberg uses optimistic concurrency control with snapshot isolation to handle concurrent writes safely.

---

**Next Steps**: Apply these concepts in [Lab 1: Environment Setup](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-01-setup.md) to start hands-on learning.
