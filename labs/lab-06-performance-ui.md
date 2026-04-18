# Lab 6: Performance & UI - DAG Inspection and Metadata-Only Filtering

## 🎯 Learning Objectives

After completing this lab, you will be able to:
- Run complex Iceberg join operations
- Access and navigate the Spark History Server UI (port 18080)
- Inspect DAG (Directed Acyclic Graph) for Spark jobs
- Understand how Iceberg's metadata-only filtering reduces S3 scans
- Analyze query performance and optimization opportunities
- Compare query plans with and without Iceberg optimizations

## 🛠️ Prerequisites

- Completed Lab 5: Real-World Data Patterns
- Spark History Server running (port 18080)
- Access to Spark History Server UI
- Understanding of query execution plans

## 📋 Lab Steps

### Step 1: Access Spark History Server UI

```bash
# Port-forward to access Spark History Server
kubectl port-forward -n spark svc/spark-history-server 18080:18080

# Or for Docker Compose, it's already available at http://localhost:18080
```

Open your browser to: **http://localhost:18080**

**Assertion 1**: Spark History Server UI is accessible and shows completed jobs

### Step 2: Create Complex Iceberg Tables for Performance Testing

```scala
// Start Spark shell with event logging enabled
spark-shell \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0 \
  --conf spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.iceberg.type=rest \
  --conf spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog \
  --conf spark.hadoop.fs.s3a.endpoint=http://localhost:9000 \
  --conf spark.hadoop.fs.s3a.access.key=minioadmin \
  --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://spark-logs/ \
  --conf spark.history.fs.logDirectory=s3a://spark-logs/
```

#### Create large fact tables for complex joins

```scala
// Sales fact table with many records
spark.sql("""
  CREATE TABLE iceberg.default.large_sales (
    sale_id INT,
    customer_id INT,
    product_id INT,
    store_id INT,
    sale_date DATE,
    quantity INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    discount DECIMAL(10,2),
    salesperson_id INT
  ) USING iceberg
  PARTITIONED BY (store_id, years(sale_date))
  ORDER BY sale_date, customer_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet',
    'write.parquet.compression-codec'='zstd'
  )
""")

// Generate substantial test data (simulating real-world volume)
for (storeId <- 1 to 5) {
  for (year <- 2022 to 2024) {
    for (month <- 1 to 12) {
      val baseDate = s"$year-$month-01"
      for (i <- 1 to 100) {
        spark.sql(s"""
          INSERT INTO iceberg.default.large_sales VALUES
          (${storeId * 10000 + year * 1000 + month * 100 + i},
           ${100 + i % 50},
           ${200 + i % 30},
           $storeId,
           DATE '$baseDate',
           ${1 + i % 10},
           ${(10.0 + i % 100).setScale(2)},
           ${(10.0 + i % 100) * (1 + i % 10).setScale(2)},
           ${(i % 20) * 0.1},
           ${50 + i % 10})
        """)
      }
    }
  }
}

// Create customer dimension table
spark.sql("""
  CREATE TABLE iceberg.default.large_customers (
    customer_id INT,
    customer_name STRING,
    customer_email STRING,
    customer_segment STRING,
    region STRING,
    signup_date DATE,
    total_purchases INT,
    total_spent DECIMAL(12,2)
  ) USING iceberg
  PARTITIONED BY (region, years(signup_date))
  ORDER BY customer_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Generate customer data
for (region <- Seq("west", "east", "north", "south")) {
  for (year <- 2020 to 2023) {
    for (i <- 1 to 50) {
      spark.sql(s"""
        INSERT INTO iceberg.default.large_customers VALUES
        (${i + region.length * 1000},
         'Customer_${region}_${i}',
         'customer${i}@example.com',
         '${List("premium", "standard", "bronze")(i % 3)}',
         '$region',
         DATE '$year-01-01',
         ${10 + i * 5},
         ${(1000.0 + i * 100).setScale(2)})
      """)
    }
  }
}

// Create product dimension table
spark.sql("""
  CREATE TABLE iceberg.default.large_products (
    product_id INT,
    product_name STRING,
    category STRING,
    subcategory STRING,
    brand STRING,
    unit_price DECIMAL(10,2),
    weight DECIMAL(8,2),
    dimensions STRING
  ) USING iceberg
  PARTITIONED BY (category)
  ORDER BY product_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Generate product data
val categories = Seq("Electronics", "Clothing", "Home", "Sports")
for (category <- categories) {
  for (i <- 1 to 30) {
    spark.sql(s"""
      INSERT INTO iceberg.default.large_products VALUES
      (${i + categories.indexOf(category) * 100},
       'Product_${category}_${i}',
       '$category',
       '${category}_Sub${i % 5}',
       'Brand${i % 10}',
       ${(10.0 + i * 5).setScale(2)},
       ${(1.0 + i * 0.1).setScale(2)},
         '${i * 10}x${i * 10}x${i * 10}')
    """)
  }
}

// Assertion 2: Large fact and dimension tables created successfully
```

**Assertion 2**: Large tables created with substantial data for performance testing

### Step 3: Run Complex Iceberg Join Query

```scala
// Complex join query with multiple predicates
val complexQuery = spark.sql("""
  SELECT 
    c.customer_segment,
    p.category,
    s.store_id,
    YEAR(s.sale_date) as sale_year,
    MONTH(s.sale_date) as sale_month,
    SUM(s.total_amount) as total_revenue,
    SUM(s.quantity) as total_quantity,
    AVG(s.unit_price) as avg_unit_price,
    COUNT(DISTINCT c.customer_id) as unique_customers
  FROM iceberg.default.large_sales s
  JOIN iceberg.default.large_customers c ON s.customer_id = c.customer_id
  JOIN iceberg.default.large_products p ON s.product_id = p.product_id
  WHERE s.sale_date >= DATE '2023-01-01'
    AND s.sale_date < DATE '2024-01-01'
    AND c.region IN ('west', 'east')
    AND p.category IN ('Electronics', 'Clothing')
    AND s.total_amount > 50.00
  GROUP BY 
    c.customer_segment,
    p.category,
    s.store_id,
    YEAR(s.sale_date),
    MONTH(s.sale_date)
  ORDER BY total_revenue DESC
""")

// Time the query execution
val startTime = System.currentTimeMillis()
complexQuery.collect()
val duration = System.currentTimeMillis() - startTime

println(s"Complex join query duration: ${duration}ms")

// Show results
complexQuery.show()

// Assertion 3: Complex join query executes successfully
```

**Assertion 3**: Complex join query completes successfully with results

### Step 4: Inspect DAG in Spark History Server

Now let's inspect the DAG for the job we just ran:

1. **Go to Spark History Server**: http://localhost:18080
2. **Find your application**: Look for the application that just ran
3. **Click on the application ID**
4. **Select the job that executed the complex query**
5. **Click on "DAG Visualization"**

**What to look for in the DAG:**

1. **Query Stages**: Notice how Spark breaks down the complex query into stages
2. **Join Operations**: Identify the join nodes in the DAG
3. **Shuffle Operations**: Look for exchange nodes (shuffles)
4. **Scan Operations**: Identify where Iceberg tables are scanned

**Assertion 4**: DAG shows the query execution plan with join, shuffle, and scan operations

### Step 5: Analyze Query Plan for Iceberg Optimizations

```scala
// Get detailed query execution plan
val queryPlan = spark.sql("""
  EXPLAIN EXTENDED
  SELECT 
    c.customer_segment,
    p.category,
    s.store_id,
    YEAR(s.sale_date) as sale_year,
    MONTH(s.sale_date) as sale_month,
    SUM(s.total_amount) as total_revenue
  FROM iceberg.default.large_sales s
  JOIN iceberg.default.large_customers c ON s.customer_id = c.customer_id
  JOIN iceberg.default.large_products p ON s.product_id = p.product_id
  WHERE s.sale_date >= DATE '2023-01-01'
    AND s.sale_date < DATE '2024-01-01'
    AND c.region IN ('west', 'east')
    AND p.category IN ('Electronics', 'Clothing')
    AND s.total_amount > 50.00
  GROUP BY 
    c.customer_segment,
    p.category,
    s.store_id,
    YEAR(s.sale_date),
    MONTH(s.sale_date)
""")

queryPlan.show(truncate = false)

// Look for Iceberg-specific optimizations:
// - PushedFilters: Filters pushed down to Iceberg
// - PartitionFilters: Partition pruning applied
// - ConvertedSupplementaryScan: Metadata-only scans
// - FileScan: Actual file scans performed
```

**Assertion 5**: Query plan shows Iceberg optimizations (partition pruning, metadata filtering)

### Step 6: Compare Performance With and Without Partition Pruning

#### Query WITHOUT partition predicates (full scan):

```scala
val startTime1 = System.currentTimeMillis()
spark.sql("""
  SELECT 
    p.category,
    SUM(s.total_amount) as total_revenue
  FROM iceberg.default.large_sales s
  JOIN iceberg.default.large_products p ON s.product_id = p.product_id
  WHERE s.sale_date >= DATE '2023-01-01'
    AND s.sale_date < DATE '2024-01-01'
  GROUP BY p.category
  ORDER BY total_revenue DESC
""").collect()
val duration1 = System.currentTimeMillis() - startTime1

println(s"Query without partition pruning: ${duration1}ms")
```

#### Query WITH partition predicates (optimized):

```scala
val startTime2 = System.currentTimeMillis()
spark.sql("""
  SELECT 
    p.category,
    SUM(s.total_amount) as total_revenue
  FROM iceberg.default.large_sales s
  JOIN iceberg.default.large_products p ON s.product_id = p.product_id
  WHERE s.sale_date >= DATE '2023-01-01'
    AND s.sale_date < DATE '2024-01-01'
    AND s.store_id = 1  -- Partition predicate
  GROUP BY p.category
  ORDER BY total_revenue DESC
""").collect()
val duration2 = System.currentTimeMillis() - startTime2

println(s"Query with partition pruning: ${duration2}ms")

// Calculate performance improvement
val improvement = ((duration1 - duration2).toDouble / duration1 * 100)
println(s"Performance improvement: ${improvement}%")

// Assertion 6: Partition pruning provides measurable performance improvement
```

**Assertion 6**: Partition pruning significantly improves query performance

### Step 7: Inspect File Scan Metrics

```scala
// Check how many files were scanned
spark.sql("""
  SELECT 
    file,
    record_count,
    file_size_in_bytes,
    partition
  FROM iceberg.default.large_sales.files
  WHERE partition LIKE '%store_id=1%'
  ORDER BY file_size_in_bytes DESC
  LIMIT 10
""").show()

// Check file scan statistics for the query
spark.sql("""
  SELECT 
    metric_name,
    metric_value
  FROM iceberg.default.large_sales.history
  ORDER BY timestamp DESC
  LIMIT 10
""").show()

// Assertion 7: File scan metrics show reduced scan with partition pruning
```

**Assertion 7**: File scan metrics confirm reduced data scan with partition pruning

### Step 8: Test Metadata-Only Filtering

```scala
// Query that should use metadata-only filtering
spark.sql("""
  EXPLAIN
  SELECT COUNT(*) as record_count
  FROM iceberg.default.large_sales
  WHERE store_id = 1
    AND sale_date >= DATE '2023-01-01'
    AND sale_date < DATE '2024-01-01'
""").show()

// Run the actual query
val metadataQuery = spark.sql("""
  SELECT COUNT(*) as record_count
  FROM iceberg.default.large_sales
  WHERE store_id = 1
    AND sale_date >= DATE '2023-01-01'
    AND sale_date < DATE '2024-01-01'
""")

val startTime3 = System.currentTimeMillis()
metadataQuery.collect()
val duration3 = System.currentTimeMillis() - startTime3

println(s"Metadata-only filtered query duration: ${duration3}ms")

// Check if the query used metadata-only filtering
// In the explain plan, look for "PushedFilters" and "PartitionFilters"
```

**Assertion 8**: Metadata-only filtering eliminates unnecessary file scans

### Step 9: Analyze DAG for Different Query Patterns

Let's run different query patterns and compare their DAGs:

#### Pattern 1: Simple Scan
```scala
spark.sql("""
  SELECT * FROM iceberg.default.large_sales
  WHERE store_id = 1
  LIMIT 100
""").collect()
```

#### Pattern 2: Aggregation
```scala
spark.sql("""
  SELECT 
    store_id,
    SUM(total_amount) as total_revenue
  FROM iceberg.default.large_sales
  WHERE store_id = 1
  GROUP BY store_id
""").collect()
```

#### Pattern 3: Join
```scala
spark.sql("""
  SELECT 
    c.customer_name,
    SUM(s.total_amount) as total_spent
  FROM iceberg.default.large_sales s
  JOIN iceberg.default.large_customers c ON s.customer_id = c.customer_id
  WHERE s.store_id = 1
  GROUP BY c.customer_name
""").collect()
```

**Go to Spark History Server and compare the DAGs:**
- Notice how each pattern produces different DAG structures
- Simple scans have fewer stages
- Joins require shuffle operations
- Aggregations have different execution strategies

**Assertion 9**: Different query patterns produce distinctly different DAG structures

### Step 10: Performance Analysis Dashboard

Create a simple performance analysis:

```scala
// Performance comparison
val queries = Map(
  "full_scan" -> spark.sql("""
    SELECT COUNT(*) FROM iceberg.default.large_sales
    WHERE sale_date >= DATE '2023-01-01'
  """),
  "partition_pruned" -> spark.sql("""
    SELECT COUNT(*) FROM iceberg.default.large_sales
    WHERE store_id = 1 AND sale_date >= DATE '2023-01-01'
  """),
  "metadata_only" -> spark.sql("""
    SELECT COUNT(*) FROM iceberg.default.large_sales
    WHERE store_id = 1
  """)
)

val results = queries.map { case (name, query) =>
  val start = System.currentTimeMillis()
  query.collect()
  val duration = System.currentTimeMillis() - start
  name -> duration
}

results.foreach { case (name, duration) =>
  println(s"$name: ${duration}ms")
}

// Calculate speedup ratios
val fullScanTime = results("full_scan")
val partitionPrunedTime = results("partition_pruned")
val metadataOnlyTime = results("metadata_only")

println(s"\nSpeedup Analysis:")
println(s"Partition pruning speedup: ${fullScanTime.toDouble / partitionPrunedTime}x")
println(s"Metadata-only speedup: ${fullScanTime.toDouble / metadataOnlyTime}x")

// Assertion 10: Performance analysis shows significant improvements with Iceberg optimizations
```

**Assertion 10**: Performance analysis demonstrates significant speedup with Iceberg optimizations

## ✅ Lab Completion Checklist

- [ ] Spark History Server UI accessible on port 18080
- [ ] Complex Iceberg join query executed successfully
- [ ] DAG inspected showing query execution plan
- [ ] Query plan shows Iceberg optimizations
- [ ] Partition pruning provides measurable performance improvement
- [ ] File scan metrics confirm reduced data scan
- [ ] Metadata-only filtering eliminates unnecessary file scans
- [ ] Different query patterns produce different DAG structures
- [ ] Performance analysis shows significant speedup ratios

## 🔍 Troubleshooting

### Issue: Spark History Server not accessible
**Solution**: Check port-forwarding or Docker Compose network configuration

### Issue: DAG not showing recent jobs
**Solution**: Verify event logging is configured and logs are written to S3

### Issue: Partition pruning not working
**Solution**: Check partition predicates match partition column types

### Issue: Metadata-only filtering not active
**Solution**: Ensure Iceberg version supports metadata-only queries

## 🎓 Key Concepts Learned

1. **Spark History Server UI**: Web interface for viewing completed Spark jobs
2. **DAG Inspection**: Understanding query execution plans and optimization
3. **Metadata-Only Filtering**: Iceberg's ability to skip files based on metadata
4. **Partition Pruning**: Reducing data scan by eliminating entire partitions
5. **Performance Analysis**: Measuring and comparing query performance
6. **Query Patterns**: How different SQL patterns affect execution plans

## 🚀 Key Takeaways

### Iceberg Performance Benefits:

1. **Partition Pruning**: Eliminates entire partitions from scans
2. **Metadata-Only Filtering**: Skips files without reading data
3. **Z-Ordering**: Clusters related data for better scan performance
4. **File Statistics**: Enables intelligent query planning

### DAG Analysis Insights:

1. **Complex Joins**: Require shuffle operations and multiple stages
2. **Aggregations**: Can use different execution strategies
3. **Scans**: Iceberg scans are optimized with metadata
4. **Bottlenecks**: Identify performance issues in execution plans

### Performance Optimization:

1. **Always use partition predicates** when possible
2. **Leverage metadata-only filtering** for count queries
3. **Monitor file sizes** and compact when needed
4. **Use Z-ordering** for frequently joined columns

---

**This lab demonstrates the power of Iceberg's metadata-only filtering and how it reduces S3 scans, which you can verify through the Spark History Server's DAG inspection!**