# Contributing to Iceberg Code Practice

Thank you for your interest in contributing to this educational repository! This project is designed to help data engineers and developers practice and improve their Apache Iceberg skills through hands-on coding labs and exercises.

## Educational Purpose

This repository is an independent educational resource created to help data professionals:
- Practice Apache Iceberg and data lakehouse concepts
- Learn vendor-independent data engineering patterns
- Understand modern table formats and lakehouse architecture
- Build hands-on experience with Spark, Trino, DuckDB, and streaming technologies
- Prepare for real-world data engineering challenges

## How to Contribute

### Adding New Labs

1. **Choose a topic**: Pick a new area of Iceberg or data lakehouse technology
2. **Follow the structure**: Each lab should follow the established pattern:
   - Clear learning objectives
   - Prerequisites and requirements
   - Step-by-step instructions
   - Hands-on exercises with validation
   - Expected outcomes and verification steps

3. **Lab guidelines**:
   - Make labs independent where possible (or clearly state dependencies)
   - Include both conceptual explanations and practical exercises
   - Provide realistic sample data when needed
   - Add troubleshooting sections for common issues
   - Include solution notebooks in the `solutions/` folder

### Improving Existing Labs

- **Bug fixes**: If you find an error in a lab or solution, please open an issue or submit a PR
- **Clarifications**: Improve explanations to make concepts clearer
- **Additional exercises**: Add more hands-on exercises to existing labs
- **Documentation**: Improve lab documentation and add more context
- **Performance**: Optimize setup scripts and improve environment performance

### Suggesting New Topics

We're always looking to expand the lab coverage. Suggested topics include:
- Additional query engines (Presto, Hive, etc.)
- Advanced partitioning strategies
- Machine learning with Iceberg
- Cloud-specific deployments (AWS, Azure, GCP)
- Security and governance patterns
- Monitoring and observability
- Cost optimization strategies

If you'd like to contribute a new lab, please:
1. Open an issue to discuss the lab scope and objectives
2. Create a lab markdown file following the existing structure
3. Create a corresponding student notebook in `notebooks/`
4. Provide a solution notebook in `solutions/`
5. Update the README with the new lab information
6. Test thoroughly in both K8s and Docker Compose setups

## Lab Structure Guidelines

### Lab Markdown Files
Each lab should include:
- **Title and learning objectives**: Clear goals for the lab
- **Prerequisites**: What students need to know before starting
- **Estimated time**: Realistic time estimates
- **Conceptual background**: Brief explanation of concepts covered
- **Step-by-step instructions**: Clear, numbered steps
- **Hands-on exercises**: Practical exercises with validation
- **Expected results**: What students should see/achieve
- **Troubleshooting**: Common issues and solutions

### Student Notebooks
Student notebooks in `notebooks/` should:
- Follow the lab markdown structure
- Include TODO cells for exercises
- Provide clear instructions in markdown cells
- Include validation cells where appropriate
- Be runnable independently after setup

### Solution Notebooks
Solution notebooks in `solutions/` should:
- Provide complete, working solutions
- Include explanations for key concepts
- Show expected outputs
- Highlight common mistakes and how to avoid them
- Be clearly marked as solutions (use `-solution` suffix)

## Code Style Guidelines

- Use Python 3.8+ for Python scripts
- Follow PEP 8 for Python code
- Use descriptive variable names
- Add comments for complex logic
- Ensure solutions follow best practices
- Use type hints where appropriate

## Testing Your Contributions

Before submitting a PR:
1. Test the lab in both K8s and Docker Compose setups
2. Verify all setup scripts run successfully
3. Run the student notebook and verify exercises work
4. Test the solution notebook for completeness
5. Check that all links and references work
6. Verify documentation is clear and complete

## Setup Scripts

If your contribution requires setup scripts:
- Place scripts in the `scripts/` directory
- Make scripts executable (`chmod +x`)
- Include error handling and validation
- Add comments explaining what each script does
- Test scripts in both K8s and Docker environments
- Update setup documentation as needed

## Documentation Standards

- Use clear, concise language
- Explain the "why" behind the "how"
- Include code examples with explanations
- Add diagrams for complex concepts
- Keep documentation up to date with code changes
- Use consistent formatting and structure

## Submitting Changes

1. Fork the repository
2. Create a new branch for your feature/fix
3. Make your changes following the guidelines above
4. Test thoroughly in both environments
5. Update documentation as needed
6. Submit a pull request with a clear description of your changes
7. Link to related issues if applicable

## Educational Resources

If you're contributing to help others learn, consider:
- Adding explanations of *why* a solution works
- Including common mistakes and how to avoid them
- Providing alternative approaches when relevant
- Linking to official Apache Iceberg documentation
- Adding real-world context and use cases
- Including performance considerations

## Environment-Specific Guidelines

### Kubernetes (k3s) Setup
- Test with k3s version compatibility
- Verify resource requirements are reasonable
- Check pod startup and health checks
- Test service discovery and networking
- Verify storage provisioning and access

### Docker Compose Setup
- Test with Docker Compose version compatibility
- Verify container startup order
- Check volume mounting and permissions
- Test network connectivity between services
- Verify resource limits and constraints

## Code of Conduct

Be respectful and constructive in all interactions. This is an educational space where we're all learning together. Welcome newcomers and help them get started.

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0, consistent with the repository.

## Questions?

If you have questions about contributing, please:
- Open an issue on GitHub with your question
- Check existing issues and discussions for similar topics
- Review the wiki for additional guidance

## Recognition

Contributors will be recognized in:
- Release notes for significant contributions
- Lab documentation for substantial additions
- The project's contributor list

---

**Happy learning and contributing!** 🚀

## Additional Resources

- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Trino Documentation](https://trino.io/docs/current/)
- [DuckDB Documentation](https://duckdb.org/docs/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)