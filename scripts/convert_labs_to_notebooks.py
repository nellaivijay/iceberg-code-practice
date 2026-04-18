#!/usr/bin/env python3
"""
Script to convert lab Markdown files to Jupyter notebooks.
This script reads the lab Markdown files and creates corresponding Jupyter notebooks.
"""

import json
import re
from pathlib import Path

def markdown_to_notebook(md_file, output_file):
    """Convert a Markdown file to a Jupyter notebook."""
    
    # Read the Markdown file
    with open(md_file, 'r') as f:
        content = f.read()
    
    # Create notebook structure
    notebook = {
        "cells": [],
        "metadata": {
            "kernelspec": {
                "display_name": "Scala",
                "language": "scala",
                "name": "scala"
            },
            "language_info": {
                "codemirror_mode": {
                    "name": "text/x-scala"
                },
                "file_extension": ".scala",
                "mimetype": "text/x-scala",
                "name": "scala"
            }
        },
        "nbformat": 4,
        "nbformat_minor": 4
    }
    
    # Split content into sections
    lines = content.split('\n')
    current_cell = []
    in_code_block = False
    cell_type = "markdown"  # markdown or code
    
    for line in lines:
        # Check for code block markers
        if line.strip().startswith('```'):
            if not in_code_block:
                # Starting code block
                if current_cell:
                    # Save current markdown cell
                    notebook["cells"].append({
                        "cell_type": "markdown",
                        "metadata": {},
                        "source": current_cell
                    })
                    current_cell = []
                in_code_block = True
                cell_type = "code"
                # Extract language if present
                lang = line.strip().replace('```', '').strip()
                if lang and lang not in ['scala', 'python', 'sql', 'bash']:
                    # If it's not a known language, treat as markdown
                    in_code_block = False
                    cell_type = "markdown"
                    current_cell.append(line)
            else:
                # Ending code block
                if current_cell:
                    notebook["cells"].append({
                        "cell_type": cell_type,
                        "execution_count": None,
                        "metadata": {},
                        "outputs": [],
                        "source": current_cell
                    })
                    current_cell = []
                in_code_block = False
                cell_type = "markdown"
        else:
            current_cell.append(line + '\n')
    
    # Don't forget the last cell
    if current_cell:
        notebook["cells"].append({
            "cell_type": cell_type,
            "execution_count": None if cell_type == "code" else None,
            "metadata": {},
            "outputs": [] if cell_type == "code" else [],
            "source": current_cell
        })
    
    # Write the notebook
    with open(output_file, 'w') as f:
        json.dump(notebook, f, indent=2)
    
    print(f"Created notebook: {output_file}")

if __name__ == "__main__":
    # Convert all lab files to notebooks
    labs_dir = Path("/home/ramdov/projects/iceberg-practice-env/labs")
    notebooks_dir = Path("/home/ramdov/projects/iceberg-practice-env/notebooks")
    
    notebooks_dir.mkdir(exist_ok=True)
    
    for lab_file in sorted(labs_dir.glob("lab-*.md")):
        output_file = notebooks_dir / f"{lab_file.stem}.ipynb"
        markdown_to_notebook(lab_file, output_file)
    
    print("\nAll lab files converted to Jupyter notebooks!")
