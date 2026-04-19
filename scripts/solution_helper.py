#!/usr/bin/env python3
"""
Helper functions for Iceberg practice environment labs.
This module provides utility functions for checking solutions and getting hints.
"""

import os
import json
from pathlib import Path

class SolutionHelper:
    """Helper class for accessing solution code and hints."""
    
    def __init__(self, lab_number):
        """
        Initialize the helper for a specific lab.
        
        Args:
            lab_number: Lab number (1-11)
        """
        self.lab_number = lab_number
        self.solutions_dir = Path(__file__).parent.parent.absolute() / "solutions"
        self.solution_file = self.solutions_dir / f"lab-{lab_number:02d}-*-solution.ipynb"
        
    def get_solution_notebook(self):
        """Load the solution notebook for this lab."""
        solution_files = list(self.solutions_dir.glob(f"lab-{self.lab_number:02d}-*-solution.ipynb"))
        if not solution_files:
            raise FileNotFoundError(f"No solution file found for lab {self.lab_number}")
        
        solution_file = solution_files[0]
        with open(solution_file, 'r') as f:
            return json.load(f)
    
    def get_hint(self, step_number):
        """
        Get a hint for a specific step in the lab.
        
        Args:
            step_number: Step number to get hint for
        """
        hints = {
            1: {
                1: "Use kubectl or docker-compose to check component status",
                2: "Use mc (MinIO Client) or aws CLI for ObjectScale",
                3: "Use curl to test the Polaris health endpoint",
                4: "Create spark-defaults.conf with Iceberg and S3 configuration",
                5: "Start spark-shell with --packages and --conf options",
                6: "Access http://localhost:18080 in your browser"
            },
            2: {
                1: "Create three tables: unpartitioned, partitioned by date, and multi-level partitioned",
                2: "Use INSERT INTO with VALUES to add test data",
                3: "Try simple SELECT, JOIN, and aggregation queries",
                4: "Use ALTER TABLE ... ADD COLUMN to evolve schema",
                5: "Query the snapshots table and use VERSION AS OF",
                6: "Use UPDATE and DELETE statements"
            },
            3: {
                1: "Use ALTER TABLE ... ADD PARTITION FIELD to add partitions",
                2: "Use ORDER BY clause for Z-ordering",
                3: "Use CALL iceberg.system.rewrite_data_files() for compaction",
                4: "Create partitioned table and query with partition predicates",
                5: "Use ALTER TABLE for add, drop, and rename operations"
            },
            4: {
                1: "Insert data in small batches, then use rewrite_data_files",
                2: "Generate snapshots, then use CALL iceberg.system.expire_snapshots",
                3: "Set spark.sql.iceberg.* configuration properties",
                4: "Use coalesce() before writing to control file sizes"
            },
            5: {
                1: "Implement valid_from/valid_to columns with is_current flag",
                2: "Use MERGE statement for upsert operations",
                3: "Load data daily with coalescing and periodic compaction",
                4: "Use cdc_operation column to track INSERT/UPDATE/DELETE"
            },
            6: {
                1: "Use kubectl port-forward or access directly for Docker Compose",
                2: "Create large tables with substantial test data",
                3: "Run complex multi-table JOIN query",
                4: "Use EXPLAIN EXTENDED to analyze query plan",
                5: "Compare queries with and without partition predicates",
                6: "Use COUNT queries with partition predicates for metadata-only filtering"
            },
            7: {
                1: "Use CALL iceberg.system.rewrite_data_files() for compaction",
                2: "Use CALL iceberg.system.expire_snapshots() to manage snapshots",
                3: "Use CALL iceberg.system.remove_orphan_files() for cleanup",
                4: "Use ALTER TABLE ... SET TBLPROPERTIES to collect statistics",
                5: "Use CALL iceberg.system.rewrite_manifests() for metadata optimization"
            },
            8: {
                1: "Use kafka-console-producer and kafka-console-consumer for basic Kafka operations",
                2: "Use Spark Structured Streaming with readStream.format('kafka')",
                3: "Use writeStream.format('iceberg') for streaming to Iceberg",
                4: "Enable checkpointing for exactly-once processing",
                5: "Use foreachBatch for complex streaming operations"
            },
            9: {
                1: "Configure Debezium connector via REST API",
                2: "Use MySQL binlog for change data capture",
                3: "Consume CDC events from Kafka topics",
                4: "Apply CDC changes using MERGE operations",
                5: "Handle schema evolution in streaming pipelines"
            },
            10: {
                1: "Add Iceberg dependencies to Spring Boot project",
                2: "Configure Iceberg catalog in application.properties",
                3: "Use Iceberg Catalog API for table operations",
                4: "Implement REST endpoints for data access",
                5: "Add transaction management and error handling"
            },
            11: {
                1: "Configure Trino to use Iceberg REST catalog",
                2: "Configure DuckDB to query Iceberg tables directly",
                3: "Test cross-engine queries and data consistency",
                4: "Optimize queries for each engine's strengths",
                5: "Implement workload isolation strategies"
            }
        }
        
        if self.lab_number in hints and step_number in hints[self.lab_number]:
            return hints[self.lab_number][step_number]
        else:
            return f"Hint not available for Lab {self.lab_number}, Step {step_number}"
    
    def get_solution_code(self, cell_index):
        """
        Get solution code for a specific cell.
        
        Args:
            cell_index: Index of the cell in the solution notebook
        """
        notebook = self.get_solution_notebook()
        
        # Find code cells
        code_cells = [cell for cell in notebook['cells'] if cell['cell_type'] == 'code']
        
        if cell_index < len(code_cells):
            return ''.join(code_cells[cell_index]['source'])
        else:
            return f"No solution code available for cell index {cell_index}"
    
    def check_solution(self, step_number):
        """
        Check if the solution for a step is available and provide guidance.
        
        Args:
            step_number: Step number to check
        """
        print(f"📋 Solution Check for Lab {self.lab_number}, Step {step_number}")
        print("=" * 60)
        print(f"\n💡 Hint: {self.get_hint(step_number)}")
        print(f"\n📁 Solution file: {self.solution_file}")
        print(f"\n💻 To view the full solution, open: solutions/lab-{self.lab_number:02d}-*-solution.ipynb")
        print(f"\n🔗 Conceptual Guide: docs/conceptual-guides/0{self.lab_number}-*.md")


def check_solution(lab_number, step_number=None):
    """
    Convenience function to check solution for a lab.
    
    Args:
        lab_number: Lab number (1-11)
        step_number: Optional step number for specific hint
    """
    helper = SolutionHelper(lab_number)
    
    if step_number:
        helper.check_solution(step_number)
    else:
        print(f"📋 Solution Helper for Lab {lab_number}")
        print("=" * 60)
        print(f"📁 Solution file: solutions/lab-{lab_number:02d}-*-solution.ipynb")
        print(f"🔗 Conceptual Guide: docs/conceptual-guides/0{lab_number}-*.md")
        print(f"\n💡 Use get_hint(step_number) for specific step hints")


def get_hint(lab_number, step_number):
    """
    Get a hint for a specific step in a lab.
    
    Args:
        lab_number: Lab number (1-11)
        step_number: Step number to get hint for
    """
    helper = SolutionHelper(lab_number)
    return helper.get_hint(step_number)


# Example usage (for documentation):
if __name__ == "__main__":
    print("Iceberg Practice Environment - Solution Helper")
    print("=" * 60)
    print("\nUsage in Jupyter notebooks:")
    print("  from solution_helper import check_solution, get_hint")
    print("  check_solution(1)  # Check solution for Lab 1")
    print("  get_hint(1, 1)     # Get hint for Lab 1, Step 1")
    print("\nAvailable labs: 1-11")
    print("Solution directory: solutions/")
