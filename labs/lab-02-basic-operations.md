# Lab 2: Basic Iceberg Operations

## 🎯 Learning Objectives

After completing this lab, you will be able to:
- Create Iceberg tables with different configurations
- Insert and query data using Spark SQL
- Understand Iceberg partitioning strategies
- Perform basic schema evolution
- Work with Iceberg snapshots

## 🛠️ Prerequisites

- Completed Lab 1: Environment Setup
- Spark shell configured with Iceberg
- Access to the practice environment

## 📋 Lab Steps

### Step 1: Create Iceberg Tables with Different Configurations

Let's create several tables to understand Iceberg's flexibility.

```scala
// Start Spark shell (from Lab 1)
spark-shell \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0 \
  --conf spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.iceberg.type=rest \
  --conf spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog \
  --conf spark.hadoop.fs.s3a.endpoint=http://localhost:9000 \
  --conf spark.hadoop.fs.s3a.access.key=minioadmin \
  --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
  --conf spark.hadoop.fs.s3a.path.style.access=true
```

#### Table 1: Simple Unpartitioned Table

```scala
spark.sql("""
  CREATE TABLE iceberg.default.users (
    user_id INT,
    username STRING,
    email STRING,
    created_at TIMESTAMP
  ) USING iceberg
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet',
    'write.metadata.compression-codec'='gzip'
  )
""")

// Assertion: Table created successfully
spark.sql("SHOW TABLES IN iceberg.default").show()
// Expected: users table listed
```

#### Table 2: Partitioned Table

```scala
spark.sql("""
  CREATE TABLE iceberg.default.orders (
    order_id INT,
    user_id INT,
    order_date DATE,
    amount DECIMAL(10,2),
    status STRING
  ) USING iceberg
  PARTITIONED BY (order_date)
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Assertion: Partitioned table created
spark.sql("SHOW PARTITIONS iceberg.default.orders").show()
```

#### Table 3: Multi-Level Partitioned Table

```scala
spark.sql("""
  CREATE TABLE iceberg.default.events (
    event_id STRING,
    user_id INT,
    event_timestamp TIMESTAMP,
    event_type STRING,
    region STRING,
    data STRING
  ) USING iceberg
  PARTITIONED BY (years(event_timestamp), region)
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Assertion: Multi-level partitioned table created
```

**Assertion 1**: All three tables created successfully with different partitioning strategies

### Step 2: Insert Data into Tables

```scala
// Insert data into users table
spark.sql("""
  INSERT INTO iceberg.default.users VALUES
    (1, 'alice', 'alice@example.com', TIMESTAMP '2024-01-01 00:00:00'),
    (2, 'bob', 'bob@example.com', TIMESTAMP '2024-01-02 00:00:00'),
    (3, 'charlie', 'charlie@example.com', TIMESTAMP '2024-01-03 00:00:00')
""")

// Insert data into orders table
spark.sql("""
  INSERT INTO iceberg.default.orders VALUES
    (1, 1, DATE '2024-01-01', 100.50, 'completed'),
    (2, 1, DATE '2024-01-02', 250.75, 'completed'),
    (3, 2, DATE '2024-01-01', 75.25, 'pending'),
    (4, 2, DATE '2024-01-03', 150.00, 'shipped'),
    (5, 3, DATE '2024-01-02', 300.00, 'completed')
""")

// Insert data into events table
spark.sql("""
  INSERT INTO iceberg.default.events VALUES
    ('evt001', 1, TIMESTAMP '2024-01-01 10:00:00', 'login', 'us-west', '{"device":"mobile"}'),
    ('evt002', 1, TIMESTAMP '2024-01-01 10:05:00', 'pageview', 'us-west', '{"page":"/home"}'),
    ('evt003', 2, TIMESTAMP '2024-01-01 11:00:00', 'login', 'us-east', '{"device":"desktop"}'),
    ('evt004', 2, TIMESTAMP '2024-01-02 09:00:00', 'purchase', 'us-east', '{"product":"item1"}')
""")

// Verify data insertion
spark.sql("SELECT COUNT(*) as user_count FROM iceberg.default.users").show()
spark.sql("SELECT COUNT(*) as order_count FROM iceberg.default.orders").show()
spark.sql("SELECT COUNT(*) as event_count FROM iceberg.default.events").show()

// Assertion 2: All tables contain expected data counts
// Expected: user_count=3, order_count=5, event_count=4
```

**Assertion 2**: Data inserted successfully with expected row counts

### Step 3: Query Data with Different Patterns

```scala
// Simple query
spark.sql("SELECT * FROM iceberg.default.users WHERE username = 'alice'").show()

// Join query
spark.sql("""
  SELECT u.username, o.order_id, o.amount, o.status
  FROM iceberg.default.users u
  JOIN iceberg.default.orders o ON u.user_id = o.user_id
  ORDER BY o.order_date
""").show()

// Aggregation query
spark.sql("""
  SELECT 
    order_date,
    COUNT(*) as order_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
  FROM iceberg.default.orders
  GROUP BY order_date
  ORDER BY order_date
""").show()

// Assertion 3: All query patterns execute successfully
```

**Assertion 3**: Different query patterns work correctly

### Step 4: Schema Evolution

Iceberg supports schema evolution without breaking existing data.

```scala
// Add a new column to users table
spark.sql("""
  ALTER TABLE iceberg.default.users
  ADD COLUMN last_login TIMESTAMP
""")

// Insert data with new column
spark.sql("""
  INSERT INTO iceberg.default.users VALUES
    (4, 'david', 'david@example.com', TIMESTAMP '2024-01-04 00:00:00', TIMESTAMP '2024-01-05 12:00:00')
""")

// Verify new column exists and data is accessible
spark.sql("DESCRIBE iceberg.default.users").show()
spark.sql("SELECT * FROM iceberg.default.users WHERE user_id = 4").show()

// Assertion 4: Schema evolution works without breaking existing data
```

**Assertion 4**: Schema evolution successful, old data still accessible

### Step 5: Work with Snapshots

Iceberg maintains snapshots for time travel and rollback.

```scala
// List snapshots for orders table
spark.sql("""
  SELECT 
    snapshot_id,
    committed_at,
    summary
  FROM iceberg.default.orders.snapshots
  ORDER BY committed_at DESC
""").show()

// Query data at specific snapshot
val snapshotId = "your_snapshot_id_here" // Get from previous query

// Time travel query
spark.sql(s"""
  SELECT * FROM iceberg.default.orders
  VERSION AS OF $snapshotId
""").show()

// Assertion 5: Snapshot queries work correctly
```

**Assertion 5**: Snapshot operations and time travel queries successful

### Step 6: Update and Delete Operations

Iceberg supports ACID transactions with update and delete operations.

```scala
// Update operation
spark.sql("""
  UPDATE iceberg.default.orders
  SET status = 'shipped'
  WHERE order_id = 3
""")

// Verify update
spark.sql("SELECT * FROM iceberg.default.orders WHERE order_id = 3").show()

// Delete operation
spark.sql("""
  DELETE FROM iceberg.default.users
  WHERE user_id = 4
""")

// Verify deletion
spark.sql("SELECT * FROM iceberg.default.users WHERE user_id = 4").show()

// Assertion 6: Update and delete operations work correctly
```

**Assertion 6**: Update and delete operations successful

## ✅ Lab Completion Checklist

- [ ] Three tables created with different partitioning strategies
- [ ] Data inserted into all tables successfully
- [ ] Different query patterns executed successfully
- [ ] Schema evolution performed without breaking existing data
- [ ] Snapshot operations and time travel queries working
- [ ] Update and delete operations successful

## 🔍 Troubleshooting

### Issue: Table creation fails
**Solution**: Check Polaris catalog status and storage connectivity

### Issue: Partition pruning not working
**Solution**: Verify partition column types and query predicates

### Issue: Schema evolution fails
**Solution**: Ensure new columns are compatible with existing data

### Issue: Snapshot queries fail
**Solution**: Verify snapshot ID format and Iceberg version compatibility

## 🎓 Key Concepts Learned

1. **Table Creation**: Different partitioning strategies (unpartitioned, single, multi-level)
2. **Data Operations**: Insert, update, delete with ACID guarantees
3. **Schema Evolution**: Add columns without breaking existing data
4. **Snapshots**: Time travel and rollback capabilities
5. **Query Patterns**: Joins, aggregations, and filtering with Iceberg tables

## 🚀 Next Steps

Proceed to **Lab 3: Advanced Iceberg Features** to learn about:
- Advanced partitioning strategies
- File compaction and optimization
- Complex schema migrations
- Performance tuning