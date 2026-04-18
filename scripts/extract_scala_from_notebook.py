#!/usr/bin/env python3
"""
Extract Scala code cells from Jupyter notebooks for validation.
This script extracts code cells from a notebook and saves them to a Scala file.
"""

import json
import sys
from pathlib import Path

def extract_scala_from_notebook(notebook_path, output_path):
    """
    Extract Scala code cells from a Jupyter notebook.
    
    Args:
        notebook_path: Path to the notebook file
        output_path: Path to save the extracted Scala code
    """
    # Read the notebook
    with open(notebook_path, 'r') as f:
        notebook = json.load(f)
    
    # Extract code cells
    code_cells = []
    for cell in notebook['cells']:
        if cell['cell_type'] == 'code':
            source = ''.join(cell['source'])
            # Skip empty cells and import statements that will be handled by Spark shell
            if source.strip() and not source.strip().startswith('//'):
                code_cells.append(source)
    
    # Write to output file
    with open(output_path, 'w') as f:
        f.write("// Auto-generated from notebook validation\n")
        f.write(f"// Source: {notebook_path}\n\n")
        
        for i, code in enumerate(code_cells, 1):
            f.write(f"// Cell {i}\n")
            f.write(code)
            if not code.endswith('\n'):
                f.write('\n')
            f.write('\n')
    
    print(f"Extracted {len(code_cells)} code cells to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: extract_scala_from_notebook.py <notebook_path> <output_path>")
        sys.exit(1)
    
    notebook_path = sys.argv[1]
    output_path = sys.argv[2]
    
    extract_scala_from_notebook(notebook_path, output_path)
