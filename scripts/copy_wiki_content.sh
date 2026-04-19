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
