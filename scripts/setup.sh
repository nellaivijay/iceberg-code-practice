#!/bin/bash
set -e

# Apache Iceberg Practice Environment Setup Script
# This script automates the setup of a vendor-independent Iceberg practice environment

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🏗️  Setting up Apache Iceberg Practice Environment..."
echo "Project directory: $PROJECT_DIR"

# Configuration
STORAGE_BACKEND="${STORAGE_BACKEND:-minio}"
SPARK_HISTORY_PORT="${SPARK_HISTORY_PORT:-18080}"
SPARK_EVENT_LOGS="${SPARK_EVENT_LOGS:-s3a://spark-logs/}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_prerequisites=0
    
    if command -v docker &> /dev/null; then
        log_info "✓ Docker found"
    else
        log_error "Docker not found. Please install Docker first."
        missing_prerequisites=$((missing_prerequisites + 1))
    fi
    
    if command -v kubectl &> /dev/null; then
        log_info "✓ kubectl found"
    else
        log_warn "kubectl not found. Kubernetes setup will be skipped."
    fi
    
    if command -v k3s &> /dev/null; then
        log_info "✓ k3s found"
    else
        log_warn "k3s not found. Will use Docker Compose setup."
    fi
    
    if command -v docker-compose &> /dev/null || command -v docker &> /dev/null && docker compose version &> /dev/null; then
        log_info "✓ Docker Compose found"
    else
        log_warn "Docker Compose not found. Install Docker Compose for Docker setup."
    fi
    
    if [ $missing_prerequisites -gt 0 ]; then
        log_error "Missing $missing_prerequisites required prerequisite(s). Please install them and try again."
        exit 1
    fi
}

# Setup storage backend
setup_storage() {
    log_info "Setting up storage backend: $STORAGE_BACKEND"
    
    if [ "$STORAGE_BACKEND" = "objectscale" ]; then
        setup_objectscale || {
            log_error "Failed to setup ObjectScale. Falling back to MinIO."
            STORAGE_BACKEND="minio"
            setup_minio || {
                log_error "Failed to setup MinIO as fallback."
                exit 1
            }
        }
    elif [ "$STORAGE_BACKEND" = "minio" ]; then
        setup_minio || {
            log_error "Failed to setup MinIO."
            exit 1
        }
    else
        log_error "Unknown storage backend: $STORAGE_BACKEND"
        log_info "Valid options: objectscale, minio"
        exit 1
    fi
}

# Setup ObjectScale Community Edition
setup_objectscale() {
    log_info "Configuring ObjectScale Community Edition..."
    
    # ObjectScale connection details (adjust based on your setup)
    OBJECTSCALE_ENDPOINT="${OBJECTSCALE_ENDPOINT:-http://localhost:6080}"
    OBJECTSCALE_ACCESS_KEY="${OBJECTSCALE_ACCESS_KEY:-admin}"
    OBJECTSCALE_SECRET_KEY="${OBJECTSCALE_SECRET_KEY:-password}"
    
    # Create spark-logs bucket using AWS CLI compatible tool
    log_info "Creating spark-logs bucket in ObjectScale..."
    
    if command -v aws &> /dev/null; then
        aws --endpoint-url="$OBJECTSCALE_ENDPOINT" s3 mb s3://spark-logs \
            --access-key="$OBJECTSCALE_ACCESS_KEY" \
            --secret-key="$OBJECTSCALE_SECRET_KEY" || log_warn "Bucket may already exist"
        
        log_info "Setting IAM permissions for History Server..."
        
        # Create IAM user for History Server (simplified for practice environment)
        # In production, use proper IAM policies
        aws --endpoint-url="$OBJECTSCALE_ENDPOINT" iam create-user \
            --user-name spark-history-server || true
        
        # Attach policy for reading spark-logs
        cat > /tmp/spark-history-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::spark-logs",
                "arn:aws:s3:::spark-logs/*"
            ]
        }
    ]
}
EOF
        
        aws --endpoint-url="$OBJECTSCALE_ENDPOINT" iam put-user-policy \
            --user-name spark-history-server \
            --policy-name SparkLogsReadAccess \
            --policy-document file:///tmp/spark-history-policy.json || true
        
        log_info "✓ ObjectScale storage configured"
    else
        log_warn "AWS CLI not found. Please create spark-logs bucket manually."
        log_info "  Endpoint: $OBJECTSCALE_ENDPOINT"
        log_info "  Access Key: $OBJECTSCALE_ACCESS_KEY"
    fi
}

# Setup MinIO
setup_minio() {
    log_info "Configuring MinIO..."
    
    MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://localhost:9000}"
    MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY:-minioadmin}"
    MINIO_SECRET_KEY="${MINIO_SECRET_KEY:-minioadmin}"
    
    # Create spark-logs bucket using MinIO client
    log_info "Creating spark-logs bucket in MinIO..."
    
    if command -v mc &> /dev/null; then
        mc alias set local "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"
        mc mb local/spark-logs || log_warn "Bucket may already exist"
        
        # Set policy for public read (simplified for practice)
        mc anonymous set download local/spark-logs
        
        log_info "✓ MinIO storage configured"
    else
        log_warn "MinIO client not found. Please create spark-logs bucket manually."
        log_info "  Endpoint: $MINIO_ENDPOINT"
        log_info "  Access Key: $MINIO_ACCESS_KEY"
        log_info "  Secret Key: $MINIO_SECRET_KEY"
    fi
}

# Setup Kubernetes environment
setup_kubernetes() {
    log_info "Setting up Kubernetes environment..."
    
    if command -v k3s &> /dev/null; then
        log_info "k3s is already installed"
    else
        log_info "Installing k3s..."
        curl -sfL https://get.k3s.io | sh -
        sudo chmod 644 /etc/rancher/k3s/k3s.yaml
        mkdir -p ~/.kube
        cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    fi
    
    # Wait for k3s to be ready
    log_info "Waiting for k3s to be ready..."
    kubectl wait --for=condition=ready node --all --timeout=300s || true
    
    log_info "✓ Kubernetes environment ready"
}

# Deploy Apache Polaris
deploy_polaris() {
    log_info "Deploying Apache Polaris catalog..."
    
    # Check if Polaris is already deployed
    if kubectl get deployment polaris -n iceberg &> /dev/null; then
        log_info "Polaris already deployed"
        return
    fi
    
    # Create namespace
    kubectl create namespace iceberg || true
    
    # Deploy Polaris (simplified deployment)
    kubectl apply -f k8s/polaris-deployment.yaml
    
    log_info "Waiting for Polaris to be ready..."
    kubectl wait --for=condition=available deployment/polaris -n iceberg --timeout=300s
    
    log_info "✓ Polaris catalog deployed"
}

# Deploy Spark History Server
deploy_spark_history_server() {
    log_info "Deploying Spark History Server..."
    
    # Create namespace if not exists
    kubectl create namespace spark || true
    
    # Deploy History Server
    kubectl apply -f k8s/spark-history-server.yaml
    
    log_info "Waiting for History Server to be ready..."
    kubectl wait --for=condition=available deployment/spark-history-server -n spark --timeout=300s
    
    log_info "✓ Spark History Server deployed"
    log_info "  Access UI at: http://localhost:$SPARK_HISTORY_PORT"
}

# Configure Spark for persistent logging
configure_spark_logging() {
    log_info "Configuring Spark for persistent logging..."
    
    # Create Spark configuration directory
    mkdir -p "$PROJECT_DIR/config/spark"
    
    # Generate spark-defaults.conf with event logging
    cat > "$PROJECT_DIR/config/spark/spark-defaults.conf" <<EOF
# Spark Event Logging
spark.eventLog.enabled=true
spark.eventLog.dir=$SPARK_EVENT_LOGS
spark.history.fs.logDirectory=$SPARK_EVENT_LOGS

# Iceberg Configuration
spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=rest
spark.sql.catalog.iceberg.uri=http://polaris.iceberg.svc.cluster.local:8181/api/catalog

# S3 Configuration (adjust based on storage backend)
spark.hadoop.fs.s3a.endpoint=$([ "$STORAGE_BACKEND" = "objectscale" ] && echo "$OBJECTSCALE_ENDPOINT" || echo "$MINIO_ENDPOINT")
spark.hadoop.fs.s3a.access.key=$([ "$STORAGE_BACKEND" = "objectscale" ] && echo "$OBJECTSCALE_ACCESS_KEY" || echo "$MINIO_ACCESS_KEY")
spark.hadoop.fs.s3a.secret.key=$([ "$STORAGE_BACKEND" = "objectscale" ] && echo "$OBJECTSCALE_SECRET_KEY" || echo "$MINIO_SECRET_KEY")
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
EOF
    
    log_info "✓ Spark configuration created at $PROJECT_DIR/config/spark/spark-defaults.conf"
}

# Main setup process
main() {
    log_info "Starting Apache Iceberg Practice Environment setup..."
    
    check_prerequisites
    setup_storage
    
    # Setup Kubernetes if available
    if command -v kubectl &> /dev/null && command -v k3s &> /dev/null; then
        setup_kubernetes
        deploy_polaris
        deploy_spark_history_server
        configure_spark_logging
    else
        log_warn "Kubernetes not available. Use Docker Compose setup instead."
        log_info "To start with Docker Compose:"
        log_info "  1. Copy .env.example to .env and configure your credentials"
        log_info "  2. Run: docker-compose up -d"
    fi
    
    log_info "🎉 Setup complete!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Configure environment variables:"
    log_info "   cp .env.example .env"
    log_info "   # Edit .env with your credentials"
    log_info ""
    log_info "2. Start the environment:"
    if command -v kubectl &> /dev/null && command -v k3s &> /dev/null; then
        log_info "   - Kubernetes setup is configured"
        log_info "   - Verify deployment: kubectl get pods -n iceberg"
    else
        log_info "   - docker-compose up -d"
    fi
    log_info ""
    log_info "3. Generate sample data (optional):"
    log_info "   python3 scripts/generate_sample_data.py"
    log_info ""
    log_info "4. Start with Lab 1:"
    log_info "   - See labs/lab-01-setup.md"
}

# Run main function
main