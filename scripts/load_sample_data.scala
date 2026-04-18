// ============================================================================
// Sample Data Loading Script for Apache Iceberg
// ============================================================================
// This script loads sample business data into Iceberg tables
// Run this in Spark shell with Iceberg configuration
//
// Usage:
//   spark-shell \
//     --packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0 \
//     --conf spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog \
//     --conf spark.sql.catalog.iceberg.type=rest \
//     --conf spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog \
//     --conf spark.hadoop.fs.s3a.endpoint=http://localhost:9000 \
//     --conf spark.hadoop.fs.s3a.access.key=minioadmin \
//     --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
//     --conf spark.hadoop.fs.s3a.path.style.access=true \
//     -i scripts/load_sample_data.scala
// ============================================================================

import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

// Configuration
val SAMPLE_DATA_PATH = "/home/ramdov/projects/iceberg-practice-env/data/sample"

println("=" * 80)
println("Loading Sample Data into Iceberg Tables")
println("=" * 80)

// ============================================================================
// Load Customers Data
// ============================================================================
println("\n[1/5] Loading customers data...")

val customersSchema = StructType(Seq(
    StructField("customer_id", IntegerType, false),
    StructField("customer_name", StringType, false),
    StructField("customer_email", StringType, false),
    StructField("region", StringType, false),
    StructField("city", StringType, false),
    StructField("segment", StringType, false),
    StructField("signup_date", DateType, false),
    StructField("total_purchases", IntegerType, false),
    StructField("total_spent", DecimalType(12, 2), false)
))

val customersDF = spark.read
    .option("header", "true")
    .schema(customersSchema)
    .csv(s"$SAMPLE_DATA_PATH/customers.csv")

// Create Iceberg table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.sample_customers (
    customer_id INT,
    customer_name STRING,
    customer_email STRING,
    region STRING,
    city STRING,
    segment STRING,
    signup_date DATE,
    total_purchases INT,
    total_spent DECIMAL(12,2)
  ) USING iceberg
  PARTITIONED BY (region)
  ORDER BY customer_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Write data
customersDF.writeTo("iceberg.sample_customers").tableAppend()
println(s"Loaded ${customersDF.count()} customer records")

// ============================================================================
// Load Products Data
// ============================================================================
println("\n[2/5] Loading products data...")

val productsSchema = StructType(Seq(
    StructField("product_id", IntegerType, false),
    StructField("product_name", StringType, false),
    StructField("category", StringType, false),
    StructField("subcategory", StringType, false),
    StructField("brand", StringType, false),
    StructField("unit_price", DecimalType(10, 2), false),
    StructField("weight", DecimalType(8, 2), false),
    StructField("dimensions", StringType, false)
))

val productsDF = spark.read
    .option("header", "true")
    .schema(productsSchema)
    .csv(s"$SAMPLE_DATA_PATH/products.csv")

// Create Iceberg table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.sample_products (
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

// Write data
productsDF.writeTo("iceberg.sample_products").tableAppend()
println(s"Loaded ${productsDF.count()} product records")

// ============================================================================
// Load Orders Data
// ============================================================================
println("\n[3/5] Loading orders data...")

val ordersSchema = StructType(Seq(
    StructField("order_id", IntegerType, false),
    StructField("customer_id", IntegerType, false),
    StructField("product_id", IntegerType, false),
    StructField("order_date", DateType, false),
    StructField("quantity", IntegerType, false),
    StructField("unit_price", DecimalType(10, 2), false),
    StructField("total_amount", DecimalType(10, 2), false),
    StructField("status", StringType, false),
    StructField("region", StringType, false),
    StructField("salesperson_id", IntegerType, false)
))

val ordersDF = spark.read
    .option("header", "true")
    .schema(ordersSchema)
    .csv(s"$SAMPLE_DATA_PATH/orders.csv")

// Create Iceberg table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.sample_orders (
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
  PARTITIONED BY (region, years(order_date))
  ORDER BY order_date, customer_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet',
    'write.parquet.compression-codec'='zstd'
  )
""")

// Write data
ordersDF.writeTo("iceberg.sample_orders").tableAppend()
println(s"Loaded ${ordersDF.count()} order records")

// ============================================================================
// Load Transactions Data
// ============================================================================
println("\n[4/5] Loading transactions data...")

val transactionsSchema = StructType(Seq(
    StructField("transaction_id", StringType, false),
    StructField("order_id", IntegerType, false),
    StructField("customer_id", IntegerType, false),
    StructField("transaction_date", TimestampType, false),
    StructField("transaction_type", StringType, false),
    StructField("amount", DecimalType(10, 2), false),
    StructField("payment_method", StringType, false),
    StructField("merchant", StringType, false)
))

val transactionsDF = spark.read
    .option("header", "true")
    .schema(transactionsSchema)
    .csv(s"$SAMPLE_DATA_PATH/transactions.csv")

// Create Iceberg table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.sample_transactions (
    transaction_id STRING,
    order_id INT,
    customer_id INT,
    transaction_date TIMESTAMP,
    transaction_type STRING,
    amount DECIMAL(10,2),
    payment_method STRING,
    merchant STRING
  ) USING iceberg
  PARTITIONED BY (transaction_type, days(transaction_date))
  ORDER BY transaction_date, customer_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Write data
transactionsDF.writeTo("iceberg.sample_transactions").tableAppend()
println(s"Loaded ${transactionsDF.count()} transaction records")

// ============================================================================
// Load Events Data
// ============================================================================
println("\n[5/5] Loading events data...")

val eventsSchema = StructType(Seq(
    StructField("event_id", StringType, false),
    StructField("user_id", IntegerType, false),
    StructField("event_timestamp", TimestampType, false),
    StructField("event_type", StringType, false),
    StructField("page_url", StringType, false),
    StructField("session_id", StringType, false),
    StructField("region", StringType, false)
))

val eventsDF = spark.read
    .option("header", "true")
    .schema(eventsSchema)
    .csv(s"$SAMPLE_DATA_PATH/events.csv")

// Create Iceberg table
spark.sql("""
  CREATE TABLE IF NOT EXISTS iceberg.sample_events (
    event_id STRING,
    user_id INT,
    event_timestamp TIMESTAMP,
    event_type STRING,
    page_url STRING,
    session_id STRING,
    region STRING
  ) USING iceberg
  PARTITIONED BY (event_type, hours(event_timestamp))
  ORDER BY event_timestamp, user_id
  TBLPROPERTIES (
    'format-version'='2',
    'write.format.default'='parquet'
  )
""")

// Write data
eventsDF.writeTo("iceberg.sample_events").tableAppend()
println(s"Loaded ${eventsDF.count()} event records")

// ============================================================================
// Verify Data Loading
// ============================================================================
println("\n" + "=" * 80)
println("Sample Data Loading Complete")
println("=" * 80)

println("\nTable Summary:")
spark.sql("SHOW TABLES IN iceberg").show()

println("\nSample Data Statistics:")
println(s"Customers: ${spark.sql(\"SELECT COUNT(*) FROM iceberg.sample_customers\").collect()(0).getLong(0)}")
println(s"Products: ${spark.sql(\"SELECT COUNT(*) FROM iceberg.sample_products\").collect()(0).getLong(0)}")
println(s"Orders: ${spark.sql(\"SELECT COUNT(*) FROM iceberg.sample_orders\").collect()(0).getLong(0)}")
println(s"Transactions: ${spark.sql(\"SELECT COUNT(*) FROM iceberg.sample_transactions\").collect()(0).getLong(0)}")
println(s"Events: ${spark.sql(\"SELECT COUNT(*) FROM iceberg.sample_events\").collect()(0).getLong(0)}")

println("\nSample Queries:")
println("\nTop 5 customers by spending:")
spark.sql("""
  SELECT customer_name, region, segment, total_spent
  FROM iceberg.sample_customers
  ORDER BY total_spent DESC
  LIMIT 5
""").show()

println("\nOrders by status:")
spark.sql("""
  SELECT status, COUNT(*) as order_count, SUM(total_amount) as total_revenue
  FROM iceberg.sample_orders
  GROUP BY status
  ORDER BY order_count DESC
""").show()

println("\n" + "=" * 80)
println("Sample data is now available in Iceberg tables!")
println("Use these tables for lab exercises and experiments.")
println("=" * 80)