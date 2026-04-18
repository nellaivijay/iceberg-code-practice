# Sample Database Documentation

## Overview

The Iceberg practice environment includes a comprehensive sample database with realistic business data for e-commerce operations. This sample data is designed to provide hands-on experience with Iceberg features across all lab exercises.

## Data Schema

### 1. Customers Table (`iceberg.sample_customers`)

Customer dimension table with customer information and segmentation.

**Columns:**
- `customer_id` (INT): Unique customer identifier
- `customer_name` (STRING): Full customer name
- `customer_email` (STRING): Customer email address
- `region` (STRING): Geographic region (north, south, east, west)
- `city` (STRING): City name
- `segment` (STRING): Customer segment (premium, standard, bronze)
- `signup_date` (DATE): Customer signup date
- `total_purchases` (INT): Total number of purchases
- `total_spent` (DECIMAL): Total amount spent

**Partitioning:** By `region`
**Ordering:** By `customer_id`
**Records:** 1,000

**Sample Data:**
```
customer_id | customer_name    | region | segment    | total_spent
1           | James Smith      | west   | premium    | 5432.50
2           | Mary Johnson     | east   | standard   | 1234.75
```

### 2. Products Table (`iceberg.sample_products`)

Product dimension table with product catalog information.

**Columns:**
- `product_id` (INT): Unique product identifier
- `product_name` (STRING): Product name
- `category` (STRING): Product category (Electronics, Clothing, Home, Sports, Books, Beauty)
- `subcategory` (STRING): Product subcategory
- `brand` (STRING): Brand name
- `unit_price` (DECIMAL): Unit price
- `weight` (DECIMAL): Product weight in kg
- `dimensions` (STRING): Product dimensions (LxWxH)

**Partitioning:** By `category`
**Ordering:** By `product_id`
**Records:** 200

**Sample Data:**
```
product_id | product_name           | category    | brand      | unit_price
1          | Electronics Product 1  | Electronics | TechBrand  | 299.99
2          | Clothing Product 2     | Clothing    | ComfortBrand | 49.99
```

### 3. Orders Table (`iceberg.sample_orders`)

Order fact table with order transaction data.

**Columns:**
- `order_id` (INT): Unique order identifier
- `customer_id` (INT): Customer foreign key
- `product_id` (INT): Product foreign key
- `order_date` (DATE): Order date
- `quantity` (INT): Order quantity
- `unit_price` (DECIMAL): Unit price at time of order
- `total_amount` (DECIMAL): Total order amount
- `status` (STRING): Order status (pending, shipped, delivered, cancelled, returned)
- `region` (STRING): Geographic region
- `salesperson_id` (INT): Salesperson identifier

**Partitioning:** By `region`, `years(order_date)`
**Ordering:** By `order_date`, `customer_id`
**Records:** 5,000

**Sample Data:**
```
order_id | customer_id | product_id | order_date  | quantity | total_amount | status
1        | 1          | 1          | 2023-05-15 | 2        | 599.98      | shipped
2        | 2          | 2          | 2023-06-20 | 1        | 49.99       | delivered
```

### 4. Transactions Table (`iceberg.sample_transactions`)

Transaction fact table with detailed transaction data.

**Columns:**
- `transaction_id` (STRING): Unique transaction identifier
- `order_id` (INT): Order foreign key
- `customer_id` (INT): Customer foreign key
- `transaction_date` (TIMESTAMP): Transaction timestamp
- `transaction_type` (STRING): Transaction type (purchase, refund, exchange)
- `amount` (DECIMAL): Transaction amount
- `payment_method` (STRING): Payment method (credit_card, debit_card, paypal, apple_pay, google_pay)
- `merchant` (STRING): Merchant name

**Partitioning:** By `transaction_type`, `days(transaction_date)`
**Ordering:** By `transaction_date`, `customer_id`
**Records:** 10,000

**Sample Data:**
```
transaction_id | order_id | customer_id | transaction_date       | transaction_type | amount | payment_method
txn000001      | 1        | 1          | 2023-05-15 14:30:00  | purchase         | 599.98 | credit_card
txn000002      | 2        | 2          | 2023-06-20 09:15:00  | purchase         | 49.99  | paypal
```

### 5. Events Table (`iceberg.sample_events`)

Web events table with user interaction data.

**Columns:**
- `event_id` (STRING): Unique event identifier
- `user_id` (INT): User foreign key
- `event_timestamp` (TIMESTAMP): Event timestamp
- `event_type` (STRING): Event type (pageview, click, login, purchase, add_to_cart, search)
- `page_url` (STRING): Page URL
- `session_id` (STRING): Session identifier
- `region` (STRING): Geographic region

**Partitioning:** By `event_type`, `hours(event_timestamp)`
**Ordering:** By `event_timestamp`, `user_id`
**Records:** 20,000

**Sample Data:**
```
event_id | user_id | event_timestamp      | event_type | page_url   | session_id
evt000001 | 1      | 2023-05-15 10:00:00  | pageview   | /home      | session_123
evt000002 | 1      | 2023-05-15 10:05:00  | click      | /products  | session_123
```

## Data Relationships

```
┌──────────────┐
│   Customers  │
│  (Dimension) │
└──────┬───────┘
       │
       │ 1:N
       ↓
┌──────────────┐     ┌──────────────┐
│    Orders    │────→│  Transactions │
│   (Fact)     │     │   (Fact)     │
└──────┬───────┘     └──────────────┘
       │
       │ N:1
       ↓
┌──────────────┐
│   Products   │
│  (Dimension) │
└──────────────┘

┌──────────────┐
│    Events    │
│   (Fact)     │
└──────┬───────┘
       │
       │ N:1
       ↓
┌──────────────┐
│   Customers  │
│  (Dimension) │
└──────────────┘
```

## Loading Sample Data

### Method 1: Using the Loading Script

```bash
cd iceberg-practice-env
./scripts/load_sample_data.sh
```

This script will:
1. Check if sample data exists (generate if needed)
2. Load data into Iceberg tables with proper schema
3. Display loading statistics
4. Show sample queries

### Method 2: Manual Loading in Spark Shell

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

### Method 3: Regenerating Sample Data

If you want to regenerate the sample data with different parameters:

```bash
# Edit the configuration in scripts/generate_sample_data.py
# Then run:
python3 scripts/generate_sample_data.py
```

## Using Sample Data in Labs

### Lab 1: Environment Setup
```sql
-- Verify sample tables are loaded
SHOW TABLES IN iceberg;

-- Query sample data
SELECT * FROM iceberg.sample_customers LIMIT 10;
```

### Lab 2: Basic Operations
```sql
-- Practice queries on sample data
SELECT c.customer_name, o.order_date, o.total_amount
FROM iceberg.sample_customers c
JOIN iceberg.sample_orders o ON c.customer_id = o.customer_id
WHERE o.status = 'delivered'
LIMIT 10;
```

### Lab 3: Advanced Features
```sql
-- Practice partitioning with sample data
SELECT region, COUNT(*) as order_count
FROM iceberg.sample_orders
WHERE order_date >= DATE '2023-01-01'
GROUP BY region;
```

### Lab 4: Optimizations
```sql
-- Practice compaction on sample data
CALL iceberg.system.rewrite_data_files(
  'iceberg.sample_orders',
  map(
    'min-input-files', '5',
    'target-size-bytes', str(256 * 1024 * 1024)
  )
);
```

### Lab 5: Real-World Patterns
```sql
-- Practice SCD Type 2 with sample customers
-- Practice upsert with sample orders
-- Practice CDC with sample transactions
```

### Lab 6: Performance & UI
```sql
-- Complex join query for performance testing
SELECT 
    c.region,
    p.category,
    SUM(o.total_amount) as total_revenue,
    COUNT(*) as order_count
FROM iceberg.sample_orders o
JOIN iceberg.sample_customers c ON o.customer_id = c.customer_id
JOIN iceberg.sample_products p ON o.product_id = p.product_id
WHERE o.order_date >= DATE '2023-01-01'
GROUP BY c.region, p.category
ORDER BY total_revenue DESC;
```

## Sample Queries

### Customer Analytics
```sql
-- Top 10 customers by spending
SELECT 
    customer_name,
    region,
    segment,
    total_spent,
    total_purchases
FROM iceberg.sample_customers
ORDER BY total_spent DESC
LIMIT 10;
```

### Product Analytics
```sql
-- Products by category
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

### Order Analytics
```sql
-- Orders by status and region
SELECT 
    status,
    region,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM iceberg.sample_orders
GROUP BY status, region
ORDER BY order_count DESC;
```

### Transaction Analysis
```sql
-- Transaction trends by payment method
SELECT 
    payment_method,
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM iceberg.sample_transactions
GROUP BY payment_method, transaction_type
ORDER BY total_amount DESC;
```

### Event Analysis
```sql
-- User engagement by event type
SELECT 
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM iceberg.sample_events
GROUP BY event_type
ORDER BY event_count DESC;
```

## Data Characteristics

### Time Range
- **Orders:** January 1, 2023 - December 31, 2024
- **Transactions:** January 1, 2023 - December 31, 2024
- **Events:** January 1, 2023 - December 31, 2024
- **Customers:** Signups from 2022-2023

### Geographic Distribution
- **Regions:** North, South, East, West
- **Cities:** 4 cities per region
- **Distribution:** Approximately equal across regions

### Customer Segments
- **Premium:** High-value customers (top 33% by spending)
- **Standard:** Medium-value customers (middle 33%)
- **Bronze:** Low-value customers (bottom 33%)

### Order Status Distribution
- **Delivered:** ~40%
- **Shipped:** ~25%
- **Pending:** ~15%
- **Cancelled:** ~10%
- **Returned:** ~10%

## Performance Considerations

### Table Sizes
- **Customers:** Small dimension table (1K rows)
- **Products:** Small dimension table (200 rows)
- **Orders:** Medium fact table (5K rows)
- **Transactions:** Medium fact table (10K rows)
- **Events:** Large fact table (20K rows)

### Partitioning Strategy
- **Dimension tables:** Partitioned by high-cardinality columns (region, category)
- **Fact tables:** Partitioned by time and relevant dimensions
- **Events table:** Partitioned by event type and time for efficient filtering

### Optimization Opportunities
- **Join performance:** Proper partitioning enables efficient joins
- **Filtering:** Partition pruning works well for region, category, and time-based queries
- **Compaction:** Tables benefit from periodic compaction to merge small files

## Troubleshooting

### Data Loading Fails
```bash
# Check if sample data files exist
ls -la data/sample/

# Regenerate sample data if needed
python3 scripts/generate_sample_data.py

# Check Iceberg catalog connectivity
curl http://localhost:8181/health
```

### Tables Already Exist
```sql
-- Drop existing tables before reloading
DROP TABLE IF EXISTS iceberg.sample_customers;
DROP TABLE IF EXISTS iceberg.sample_products;
DROP TABLE IF EXISTS iceberg.sample_orders;
DROP TABLE IF EXISTS iceberg.sample_transactions;
DROP TABLE IF EXISTS iceberg.sample_events;
```

### Query Performance Issues
```sql
-- Check table statistics
SELECT * FROM iceberg.sample_orders.files;

-- Perform compaction
CALL iceberg.system.rewrite_data_files('iceberg.sample_orders', map('min-input-files', '5'));

-- Verify partitioning
DESCRIBE EXTENDED iceberg.sample_orders;
```

## Extending Sample Data

### Adding More Data
Edit `scripts/generate_sample_data.py` to increase:
- `NUM_CUSTOMERS`: Number of customer records
- `NUM_PRODUCTS`: Number of product records
- `NUM_ORDERS`: Number of order records
- `NUM_TRANSACTIONS`: Number of transaction records

### Adding New Tables
1. Define schema in `generate_sample_data.py`
2. Add data generation logic
3. Create table in `load_sample_data.scala`
4. Update documentation

### Adding New Columns
1. Update schema definitions
2. Add data generation for new columns
3. Update Iceberg table definitions
4. Reload data

---

**The sample database provides realistic business data for hands-on learning with Apache Iceberg across all lab exercises.**