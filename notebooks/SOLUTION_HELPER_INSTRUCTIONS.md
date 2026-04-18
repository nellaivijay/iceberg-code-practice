# Solution Helper

If you get stuck during this lab, you can use the solution helper to get hints and view the solution code.

```python
# Import the solution helper
import sys
sys.path.append('/home/ramdov/projects/iceberg-practice-env/scripts')
from solution_helper import check_solution, get_hint

# Get general solution information
check_solution(1)

# Get a hint for a specific step
get_hint(1, 1)  # Lab 1, Step 1
```

## Available Help

- **`check_solution(lab_number)`**: Shows solution file location and conceptual guide link
- **`get_hint(lab_number, step_number)`**: Gets a specific hint for a step
- **Solution Notebooks**: Full solutions available in `/solutions/` directory
- **Conceptual Guides**: Deep-dive explanations in `/docs/conceptual-guides/`

## Conceptual Guide

For this lab, see: [Conceptual Guide](../docs/conceptual-guides/01-environment-architecture.md)

The conceptual guide explains:
- Why Iceberg uses a separate catalog and storage
- How Apache Polaris works as a REST catalog
- Why S3-compatible storage is used
- How the Spark History Server provides observability
- The architecture decisions behind the environment

---

**Remember**: The goal is to learn! Try to solve the problems yourself first, then use the helper if you get stuck.