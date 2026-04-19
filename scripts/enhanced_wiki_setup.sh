#!/bin/bash

# Enhanced Wiki Setup Helper
# This script provides step-by-step guidance for creating wiki pages

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WIKI_DIR="$PROJECT_DIR/wiki"
GITHUB_USERNAME="nellaivijay"
REPO_NAME="iceberg-code-practice"
WIKI_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME/wiki"

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

echo "🚀 Enhanced Wiki Setup Helper"
echo "==============================="
echo ""

# Verify wiki directory exists
if [ ! -d "$WIKI_DIR" ]; then
    log_error "Wiki directory not found at $WIKI_DIR"
    exit 1
fi

log_info "Wiki directory: $WIKI_DIR"
log_info "GitHub Wiki URL: $WIKI_URL"
echo ""

# Define wiki pages in order
declare -a wiki_pages=(
    "Home.md|Home"
    "Getting-Started.md|Getting-Started"
    "Iceberg-Fundamentals.md|Iceberg-Fundamentals"
    "Lab-Guides.md|Lab-Guides"
    "Learning-Path.md|Learning-Path"
    "Best-Practices.md|Best-Practices"
    "Troubleshooting.md|Troubleshooting"
)

log_info "This will guide you through creating ${#wiki_pages[@]} wiki pages."
echo ""
log_warning "Note: You need to manually create pages on GitHub - this script provides guidance and content."
echo ""

# Function to display content for copying
show_page_content() {
    local file=$1
    local page_title=$2
    
    log_info "=== Creating page: $page_title ==="
    echo ""
    echo "📋 STEPS:"
    echo "1. Open your browser and go to: $WIKI_URL"
    echo "2. Click 'Add Page' button"
    echo "3. Enter page title exactly as: $page_title"
    echo "4. Copy the content below between the === markers"
    echo "5. Paste into the wiki editor"
    echo "6. Click 'Save'"
    echo ""
    echo "📄 CONTENT TO COPY:"
    echo "=================="
    cat "$WIKI_DIR/$file"
    echo "=================="
    echo ""
    echo "Press Enter when you have completed this page..."
    read
    echo ""
    log_success "Page '$page_title' completed!"
    echo ""
}

# Guide through each page
for page_info in "${wiki_pages[@]}"; do
    IFS='|' read -r file page_title <<< "$page_info"
    show_page_content "$file" "$page_title"
done

log_success "All wiki pages creation guidance completed!"
echo ""
log_info "📚 Summary:"
echo "  - Total pages created: ${#wiki_pages[@]}"
echo "  - Wiki URL: $WIKI_URL"
echo "  - Next: Organize pages in wiki sidebar (if available)"
echo ""
log_info "🎉 Your wiki is now set up!"
echo ""
log_info "📖 For detailed instructions, see: docs/WIKI_QUICK_SETUP.md"