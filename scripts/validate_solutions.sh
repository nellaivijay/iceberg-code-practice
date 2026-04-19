#!/bin/bash
###############################################################################
# CI/CD Validation Script for Iceberg Practice Environment
#
# This script validates all solution notebooks by executing them against
# the ObjectScale/Polaris environment to ensure they pass 100% of the time.
#
# Usage:
#   ./scripts/validate_solutions.sh [--lab <number>] [--verbose]
#
# Examples:
#   ./scripts/validate_solutions.sh              # Validate all labs
#   ./scripts/validate_solutions.sh --lab 1       # Validate specific lab
#   ./scripts/validate_solutions.sh --verbose     # Verbose output
###############################################################################

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOLUTIONS_DIR="$PROJECT_DIR/solutions"
LOG_DIR="$PROJECT_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
LAB_NUMBER=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --lab)
            LAB_NUMBER="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create log directory
mkdir -p "$LOG_DIR"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Check if environment is running
check_environment() {
    log_step "Checking Environment Status"
    
    # Check if Polaris is accessible
    if curl -f -s http://localhost:8181/health > /dev/null 2>&1; then
        log_success "Polaris catalog is accessible"
    else
        log_error "Polaris catalog is not accessible at http://localhost:8181"
        log_info "Start the environment with: ./scripts/setup.sh"
        exit 1
    fi
    
    # Check if storage is accessible
    if curl -f -s http://localhost:9000/minio/health/live > /dev/null 2>&1; then
        log_success "MinIO storage is accessible"
    elif aws --endpoint-url=http://localhost:6080 s3 ls > /dev/null 2>&1; then
        log_success "ObjectScale storage is accessible"
    else
        log_error "Storage backend is not accessible"
        exit 1
    fi
    
    # Check if Spark History Server is accessible
    if curl -f -s http://localhost:18080 > /dev/null 2>&1; then
        log_success "Spark History Server is accessible"
    else
        log_warning "Spark History Server is not accessible (optional for validation)"
    fi
}

# Validate a single solution notebook
validate_notebook() {
    local lab_number=$1
    local notebook_file="$SOLUTIONS_DIR/lab-${lab_number:0:1}-*-solution.ipynb"
    local log_file="$LOG_DIR/validation_lab_${lab_number}_${TIMESTAMP}.log"
    local temp_script="$LOG_DIR/lab_${lab_number}_temp.scala"
    
    log_step "Validating Lab $lab_number"
    
    # Find the solution notebook
    local solution_files=($(ls $notebook_file 2>/dev/null || true))
    if [ ${#solution_files[@]} -eq 0 ]; then
        log_error "Solution notebook not found for Lab $lab_number"
        return 1
    fi
    
    local solution_file="${solution_files[0]}"
    log_info "Using solution file: $solution_file"
    
    # Check if jupyter is installed
    if ! command -v jupyter &> /dev/null; then
        log_error "jupyter is not installed. Install with: pip install jupyter"
        return 1
    fi
    
    # Check if nbconvert is available
    if ! command -v jupyter-nbconvert &> /dev/null; then
        log_error "jupyter-nbconvert is not available"
        return 1
    fi
    
    # Execute the notebook
    log_info "Executing notebook..."
    
    if [ "$VERBOSE" = true ]; then
        jupyter nbconvert \
            --to notebook \
            --execute \
            --ExecutePreprocessor.timeout=600 \
            --output "$LOG_DIR/executed_lab_${lab_number}_${TIMESTAMP}.ipynb" \
            "$solution_file" \
            2>&1 | tee "$log_file"
    else
        jupyter nbconvert \
            --to notebook \
            --execute \
            --ExecutePreprocessor.timeout=600 \
            --output "$LOG_DIR/executed_lab_${lab_number}_${TIMESTAMP}.ipynb" \
            "$solution_file" \
            > "$log_file" 2>&1
    fi
    
    # Check execution result
    local execution_result=$?
    
    # Cleanup temporary files
    rm -f "$temp_script"
    
    if [ $execution_result -eq 0 ]; then
        log_success "Lab $lab_number validation passed"
        return 0
    else
        log_error "Lab $lab_number validation failed"
        log_info "Check log file: $log_file"
        return 1
    fi
}

# Alternative validation using Spark shell for Scala notebooks
validate_scala_notebook() {
    local lab_number=$1
    local notebook_file="$SOLUTIONS_DIR/lab-${lab_number:0:1}-*-solution.ipynb"
    local log_file="$LOG_DIR/validation_lab_${lab_number}_${TIMESTAMP}.log"
    local temp_script="$LOG_DIR/lab_${lab_number}_script.scala"
    
    log_step "Validating Lab $lab_number (Scala via Spark Shell)"
    
    # Extract Scala code from notebook
    python3 "$SCRIPT_DIR/extract_scala_from_notebook.py" "$notebook_file" "$temp_script"
    
    # Execute with Spark shell
    log_info "Executing Scala code with Spark shell..."
    
    spark-shell \
        --packages org.apache.iceberg:iceberg-spark-runtime-3.5:1.5.0 \
        --conf spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog \
        --conf spark.sql.catalog.iceberg.type=rest \
        --conf spark.sql.catalog.iceberg.uri=http://localhost:8181/api/catalog \
        --conf spark.hadoop.fs.s3a.endpoint=http://localhost:9000 \
        --conf spark.hadoop.fs.s3a.access.key=${MINIO_ROOT_USER:-minioadmin} \
        --conf spark.hadoop.fs.s3a.secret.key=${MINIO_ROOT_PASSWORD:-minioadmin} \
        --conf spark.hadoop.fs.s3a.path.style.access=true \
        -i "$temp_script" \
        > "$log_file" 2>&1
    
    # Check execution result
    local execution_result=$?
    
    # Cleanup temporary files
    rm -f "$temp_script"
    
    if [ $execution_result -eq 0 ]; then
        log_success "Lab $lab_number validation passed"
        return 0
    else
        log_error "Lab $lab_number validation failed"
        log_info "Check log file: $log_file"
        return 1
    fi
}

# Main validation function
main() {
    log_step "Iceberg Practice Environment - Solution Validation"
    log_info "Project directory: $PROJECT_DIR"
    log_info "Solutions directory: $SOLUTIONS_DIR"
    log_info "Log directory: $LOG_DIR"
    log_info "Timestamp: $TIMESTAMP"
    
    # Check environment
    check_environment
    
    # Determine which labs to validate
    local labs_to_validate=()
    if [ -n "$LAB_NUMBER" ]; then
        labs_to_validate=("$LAB_NUMBER")
        log_info "Validating specific lab: $LAB_NUMBER"
    else
        # Dynamically discover all available labs
        for solution_file in "$SOLUTIONS_DIR"/lab-*-solution.ipynb; do
            if [ -f "$solution_file" ]; then
                # Extract lab number from filename
                lab_num=$(basename "$solution_file" | sed 's/lab-0*\([0-9]*\)-.*/\1/')
                if [[ "$lab_num" =~ ^[0-9]+$ ]]; then
                    labs_to_validate+=("$lab_num")
                fi
            fi
        done
        
        # Sort and remove duplicates
        labs_to_validate=($(echo "${labs_to_validate[@]}" | tr ' ' '\n' | sort -n | uniq | tr '\n' ' '))
        
        if [ ${#labs_to_validate[@]} -eq 0 ]; then
            log_error "No solution notebooks found in $SOLUTIONS_DIR"
            exit 1
        fi
        
        log_info "Validating all discovered labs: ${labs_to_validate[@]}"
    fi
    
    # Validate each lab
    local passed=0
    local failed=0
    
    for lab in "${labs_to_validate[@]}"; do
        if validate_scala_notebook "$lab"; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    # Summary
    log_step "Validation Summary"
    log_info "Total labs: ${#labs_to_validate[@]}"
    log_success "Passed: $passed"
    
    if [ $failed -gt 0 ]; then
        log_error "Failed: $failed"
        log_info "Check log files in: $LOG_DIR"
        exit 1
    else
        log_success "All validations passed!"
        exit 0
    fi
}

# Run main function
main