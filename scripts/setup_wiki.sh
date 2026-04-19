#!/bin/bash

# Wiki Setup Script for Apache Iceberg Code Practice
# This script helps copy wiki markdown files to GitHub Wiki

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WIKI_DIR="$PROJECT_DIR/wiki"
GITHUB_USERNAME="nellaivijay"
REPO_NAME="iceberg-code-practice"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "📚 Wiki Setup Script for Apache Iceberg Code Practice"
echo "======================================================"
echo ""

# Check if wiki directory exists
if [ ! -d "$WIKI_DIR" ]; then
    log_warning "Wiki directory not found at $WIKI_DIR"
    exit 1
fi

log_info "Found wiki directory at $WIKI_DIR"
log_info "GitHub username: $GITHUB_USERNAME"
log_info "Repository: $REPO_NAME"
echo ""

# List all wiki markdown files
log_info "Available wiki markdown files:"
echo ""
ls -1 "$WIKI_DIR"/*.md 2>/dev/null || log_warning "No markdown files found in wiki directory"
echo ""

# Instructions for manual wiki setup
log_info "To set up your GitHub Wiki manually:"
echo ""
echo "1. Go to your repository on GitHub:"
echo "   https://github.com/$GITHUB_USERNAME/$REPO_NAME/wiki"
echo ""
echo "2. For each markdown file in the wiki directory:"
echo "   - Click 'Add Page' or edit existing pages"
echo "   - Copy the content from the corresponding .md file"
echo "   - Paste it into the wiki page editor"
echo "   - Save the page"
echo ""
echo "3. Organize pages using the sidebar (if available)"
echo ""
echo "4. Recommended page order:"
echo "   - Home.md (main landing page)"
echo "   - Getting-Started.md"
echo "   - Iceberg-Fundamentals.md"
echo "   - Lab-Guides.md"
echo "   - Learning-Path.md"
echo "   - Best-Practices.md"
echo "   - Troubleshooting.md"
echo ""

# Create a simple script to copy file contents
log_info "Creating helper script to copy wiki content..."

cat > "$PROJECT_DIR/scripts/copy_wiki_content.sh" << 'EOF'
#!/bin/bash

# Helper script to display wiki file content for easy copying

WIKI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../wiki && pwd)"

echo "Available wiki files:"
echo ""
select file in "$WIKI_DIR"/*.md "Quit"; do
    case $file in
        "Quit")
            break
            ;;
        *)
            if [ -f "$file" ]; then
                echo "========================================"
                echo "Content of: $(basename "$file")"
                echo "========================================"
                cat "$file"
                echo ""
                echo "========================================"
                echo "Copy the content above to your GitHub Wiki"
                echo "Press Enter to continue..."
                read
            fi
            ;;
    esac
done
EOF

chmod +x "$PROJECT_DIR/scripts/copy_wiki_content.sh"

log_success "Created helper script: scripts/copy_wiki_content.sh"
echo ""

log_warning "Note: This script cannot automatically push to GitHub Wiki."
log_warning "You need to manually copy the content to your GitHub Wiki pages."
echo ""

log_info "Quick reference for wiki setup:"
echo "📖 Wiki URL: https://github.com/$GITHUB_USERNAME/$REPO_NAME/wiki"
echo "📁 Wiki directory: $WIKI_DIR"
echo "🔧 Helper script: $PROJECT_DIR/scripts/copy_wiki_content.sh"
echo ""

log_success "Wiki setup guide complete!"
echo ""
echo "Next steps:"
echo "1. Visit your wiki: https://github.com/$GITHUB_USERNAME/$REPO_NAME/wiki"
echo "2. Use the helper script: ./scripts/copy_wiki_content.sh"
echo "3. Copy content to create wiki pages"
echo "4. Organize pages in the wiki sidebar"
