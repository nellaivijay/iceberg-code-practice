#!/bin/bash
###############################################################################
# Load Sample Data into Iceberg
#
# This script loads sample business data into Iceberg tables for lab exercises.
#
# Usage:
#   ./scripts/load_sample_data.sh
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Loading Sample Data into Iceberg${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if Spark is installed
if ! command -v spark-shell &> /dev/null; then
    echo "Error: spark-shell not found. Please install Apache Spark."
    exit 1
fi

# Check if sample data exists
if [ ! -d "$PROJECT_DIR/data/sample" ]; then
    echo "Sample data not found. Generating sample data first..."
    python3 "$SCRIPT_DIR/generate_sample_data.py"
fi

# Load data into Iceberg
echo -e "\n${BLUE}Loading sample data into Iceberg tables...${NC}"

spark-shell \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0 \
  --conf spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.iceberg.type=rest \
  --conf spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog \
  --conf spark.hadoop.fs.s3a.endpoint=http://localhost:9000 \
  --conf spark.hadoop.fs.s3a.access.key=minioadmin \
  --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  -i "$SCRIPT_DIR/load_sample_data.scala"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Sample data loading complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nSample tables are now available:"
echo "  - iceberg.sample_customers"
echo "  - iceberg.sample_products"
echo "  - iceberg.sample_orders"
echo "  - iceberg.sample_transactions"
echo "  - iceberg.sample_events"