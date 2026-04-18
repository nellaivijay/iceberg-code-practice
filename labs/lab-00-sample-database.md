# Lab 0: Sample Database Setup and Exploration

## 🎯 Learning Objectives

After completing this lab, you will be able to:
- Generate and load sample business data into Iceberg
- Understand the sample database schema and relationships
- Explore sample data with basic queries
- Use sample data in subsequent lab exercises

## 🛠️ Prerequisites

- Completed environment setup (Lab 1 or setup script)
- Spark shell configured with Iceberg
- Access to the practice environment

## 📋 Lab Steps

### Step 1: Generate Sample Data

The sample data generator creates realistic e-commerce data including customers, products, orders, transactions, and web events.

```bash
# Generate sample data
cd iceberg-practice-env
python3 scripts/generate_sample_data.py
```

**Expected Output:**
```
Generating sample data...
Created customers.csv with 1000 records
Created products.csv with 200 records
Created orders.csv with 5000 records
Created transactions.csv with 10000 records
Created events.csv with 19999 records

Sample data generation complete!
Data directory: /home/ramdov/projects/iceberg-practice-env/data/sample
```

**Assertion 1**: Sample data files created successfully

### Step 2: Load Sample Data into Iceberg

Load the generated sample data into Iceberg tables with proper schema and partitioning.

```bash
# Load sample data using the provided script
./scripts/load_sample_data.sh
```

Or manually in Spark shell:

```bash
spark-shell \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0 \
  --conf spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.iceberg.type=rest \
  --conf spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog \
  --conf spark.hadoop.fs.s3a.endpoint=http://localhost:9000 \
  --conf spark.hadoop.fs.s3a.access.key=minioadmin \
  --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  -i scripts/load_sample_data.scala
```

**Expected Output:**
```
================================================================================
Loading Sample Data into Iceberg Tables
================================================================================

[1/5] Loading customers data...
Loaded 1000 customer records

[2/5] Loading products data...
Loaded 200 product records

[3/5] Loading orders data...
Loaded 5000 order records

[4/5] Loading transactions data...
Loaded 10000 transaction records

[5/5] Loading events data...
Loaded 19999 event records

================================================================================
Sample Data Loading Complete
================================================================================

Sample Data Statistics:
Customers: 1000
Products: 200
Orders: 5000
Transactions: 10000
Events: 19999
```

**Assertion 2**: Sample data loaded successfully into Iceberg tables

### Step 3: Verify Sample Tables

Check that all sample tables are created and accessible.

```sql
-- Show all tables in Iceberg catalog
SHOW TABLES IN iceberg;
```

**Expected Output:**
```
+-----------+-----------+-----------+
| namespace |      name |      kind |
+-----------+-----------+-----------+
|  iceberg   | sample_customers | TABLE |
|  iceberg   | sample_products | TABLE |
|  iceberg   | sample_orders   | TABLE |
|  iceberg   | sample_transactions | TABLE |
|  iceberg   | sample_events   | TABLE |
+-----------+-----------+-----------+
```

```sql
-- Verify table schemas
DESCRIBE iceberg.sample_customers;
DESCRIBE iceberg.sample_products;
DESCRIBE iceberg.sample_orders;
DESCRIBE iceberg.sample_transactions;
DESCRIBE iceberg.sample_events;
```

**Assertion 3**: All sample tables exist with correct schemas

### Step 4: Explore Customer Data

Query the customer dimension table to understand customer distribution.

```sql
-- Count customers by region
SELECT 
    region,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_spent,
    MAX(total_spent) as max_spent
FROM iceberg.sample_customers
GROUP BY region
ORDER BY customer_count DESC;
```

```sql
-- Count customers by segment
SELECT 
    segment,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_spent
FROM iceberg.sample_customers
GROUP BY segment
ORDER BY avg_spent DESC;
```

```sql
-- Top 10 customers by spending
SELECT 
    customer_name,
    region,
    segment,
    total_purchases,
    total_spent
FROM iceberg.sample_customers
ORDER BY total_spent DESC
LIMIT 10;
```

**Assertion 4**: Customer data queries execute successfully

### Step 5: Explore Product Data

Query the product dimension table to understand product catalog.

```sql
-- Count products by category
SELECT 
    category,
    COUNT(*) as product_count,
    AVG(unit_price) as avg_price,
    MIN(unit_price) as min_price,
    MAX(unit_price) as max_price
FROM iceberg.sample_products
GROUP BY category
ORDER BY product_count DESC;
```

```sql
-- Products by brand
SELECT 
    brand,
    COUNT(*) as product_count
FROM iceberg.sample_products
GROUP BY brand
ORDER BY product_count DESC;
```

```sql
-- Sample products from each category
SELECT 
    category,
    product_name,
    brand,
    unit_price
FROM iceberg.sample_products
WHERE (category, product_id) IN (
    SELECT category, MIN(product_id)
    FROM iceberg.sample_products
    GROUP BY category
)
ORDER BY category;
```

**Assertion 5**: Product data queries execute successfully

### Step 6: Explore Order Data

Query the order fact table to understand order patterns.

```sql
-- Orders by status
SELECT 
    status,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM iceberg.sample_orders
GROUP BY status
ORDER BY order_count DESC;
```

```sql
-- Orders by region
SELECT 
    region,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM iceberg.sample_orders
GROUP BY region
ORDER BY total_revenue DESC;
```

```sql
-- Monthly order trends
SELECT 
    YEAR(order_date) as year,
    MONTH(order_date) as month,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue
FROM iceberg.sample_orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year, month;
```

**Assertion 6**: Order data queries execute successfully

### Step 7: Explore Transaction Data

Query the transaction fact table to understand transaction patterns.

```sql
-- Transactions by type
SELECT 
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM iceberg.sample_transactions
GROUP BY transaction_type
ORDER BY transaction_count DESC;
```

```sql
-- Transactions by payment method
SELECT 
    payment_method,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount
FROM iceberg.sample_transactions
GROUP BY payment_method
ORDER BY total_amount DESC;
```

```sql
-- Transaction trends over time
SELECT 
    DATE(transaction_date) as transaction_date,
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount
FROM iceberg.sample_transactions
GROUP BY DATE(transaction_date), transaction_type
ORDER BY transaction_date DESC, transaction_count DESC
LIMIT 20;
```

**Assertion 7**: Transaction data queries execute successfully

### Step 8: Explore Event Data

Query the web events table to understand user engagement patterns.

```sql
-- Events by type
SELECT 
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM iceberg.sample_events
GROUP BY event_type
ORDER BY event_count DESC;
```

```sql
-- Events by region
SELECT 
    region,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM iceberg.sample_events
GROUP BY region
ORDER BY event_count DESC;
```

```sql
-- Hourly event patterns
SELECT 
    HOUR(event_timestamp) as hour,
    event_type,
    COUNT(*) as event_count
FROM iceberg.sample_events
GROUP BY HOUR(event_timestamp), event_type
ORDER BY hour, event_count DESC;
```

**Assertion 8**: Event data queries execute successfully

### Step 9: Practice Join Queries

Practice joining sample tables to answer business questions.

```sql
-- Customer order analysis
SELECT 
    c.customer_name,
    c.region,
    c.segment,
    COUNT(o.order_id) as order_count,
    SUM(o.total_amount) as total_spent
FROM iceberg.sample_customers c
JOIN iceberg.sample_orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name, c.region, c.segment
ORDER BY total_spent DESC
LIMIT 10;
```

```sql
-- Product sales analysis
SELECT 
    p.product_name,
    p.category,
    p.brand,
    COUNT(o.order_id) as order_count,
    SUM(o.total_amount) as total_revenue,
    SUM(o.quantity) as total_quantity
FROM iceberg.sample_products p
JOIN iceberg.sample_orders o ON p.product_id = o.product_id
GROUP BY p.product_name, p.category, p.brand
ORDER BY total_revenue DESC
LIMIT 10;
```

```sql
-- Regional performance analysis
SELECT 
    c.region,
    COUNT(DISTINCT c.customer_id) as unique_customers,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as total_revenue
FROM iceberg.sample_customers c
JOIN iceberg.sample_orders o ON c.customer_id = o.customer_id
GROUP BY c.region
ORDER BY total_revenue DESC;
```

**Assertion 9**: Join queries execute successfully

### Step 10: Verify Data Integrity

Perform data integrity checks on the sample database.

```sql
-- Check referential integrity: orders -> customers
SELECT COUNT(*) as orphaned_orders
FROM iceberg.sample_orders o
LEFT JOIN iceberg.sample_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

```sql
-- Check referential integrity: orders -> products
SELECT COUNT(*) as orphaned_orders
FROM iceberg.sample_orders o
LEFT JOIN iceberg.sample_products p ON o.product_id = p.product_id
WHERE p.product_id IS NULL;
```

```sql
-- Check for null values in key columns
SELECT 
    'customers' as table_name,
    COUNT(*) - COUNT(customer_id) as null_customer_id,
    COUNT(*) - COUNT(customer_name) as null_customer_name
FROM iceberg.sample_customers
UNION ALL
SELECT 
    'orders' as table_name,
    COUNT(*) - COUNT(order_id) as null_order_id,
    COUNT(*) - COUNT(customer_id) as null_customer_id
FROM iceberg.sample_orders;
```

**Assertion 10**: Data integrity checks pass (no orphaned records, no null key values)

## ✅ Lab Completion Checklist

- [ ] Sample data generated successfully
- [ ] Sample data loaded into Iceberg tables
- [ ] All sample tables verified
- [ ] Customer data explored successfully
- [ ] Product data explored successfully
- [ ] Order data explored successfully
- [ ] Transaction data explored successfully
- [ ] Event data explored successfully
- [ ] Join queries practiced successfully
- [ ] Data integrity verified

## 🔍 Troubleshooting

### Issue: Sample data generation fails
**Solution**: Ensure Python 3 is installed and required packages are available

### Issue: Data loading fails
**Solution**: Check Iceberg catalog connectivity and S3 storage accessibility

### Issue: Tables already exist
**Solution**: Drop existing tables before reloading or use `IF NOT EXISTS` in table creation

### Issue: Query performance is slow
**Solution**: Verify partitioning is working and consider compaction for large tables

## 🎓 Key Concepts Learned

1. **Sample Data Generation**: Creating realistic business data for learning
2. **Data Loading**: Importing CSV data into Iceberg with proper schema
3. **Table Design**: Dimension and fact table design patterns
4. **Data Exploration**: Querying sample data to understand patterns
5. **Data Integrity**: Checking referential integrity and data quality
6. **Join Operations**: Practicing joins across dimension and fact tables

## 🚀 Next Steps

With the sample database loaded, you can now:
- **Lab 1**: Use sample data for environment validation
- **Lab 2**: Practice basic operations on realistic data
- **Lab 3**: Apply advanced features to real-world scenarios
- **Lab 4**: Optimize queries on sample data
- **Lab 5**: Implement real-world patterns with sample data
- **Lab 6**: Analyze performance on realistic workloads

## 📚 Additional Resources

- [Sample Database Documentation](docs/SAMPLE_DATABASE.md) - Detailed schema and usage information
- [Sample Data Generator](scripts/generate_sample_data.py) - Python script for data generation
- [Data Loading Script](scripts/load_sample_data.scala) - Scala script for loading data

---

**The sample database provides realistic business data that makes learning Iceberg concepts more practical and engaging.**