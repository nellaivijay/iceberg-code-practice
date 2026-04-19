# Lab Guides

This page provides detailed guidance and tips for completing the hands-on labs in this repository. Each lab is designed to build upon previous knowledge, so we recommend following the suggested order.

## 🎯 How to Use These Guides

Each lab guide includes:
- **Learning Objectives**: What you'll achieve
- **Prerequisites**: What you need to know first
- **Estimated Time**: How long to expect
- **Step-by-Step Instructions**: Detailed guidance
- **Common Pitfalls**: Mistakes to avoid
- **Solutions**: Reference implementations
- **Further Learning**: Where to go next

## 📚 Lab Sequence

### Phase 1: Foundation (Labs 0-2)

#### Lab 0: Sample Database Setup
**Purpose**: Generate and load sample data for all subsequent labs

**Learning Objectives**:
- Generate realistic business data
- Understand the sample database schema
- Practice basic data loading operations
- Verify data integrity

**Prerequisites**: None
**Estimated Time**: 30-45 minutes

**Key Concepts**:
- Sample data generation
- Database schema relationships
- Data loading with Spark
- Data validation

**Common Pitfalls**:
- Not running the data generation script first
- Incorrect file paths in load scripts
- Skipping data validation steps

**Tips**:
- Take time to explore the sample data structure
- Understand the relationships between tables
- Save the generated data for reuse

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-00-sample-database.md)

---

#### Lab 1: Environment Setup
**Purpose**: Verify your environment is correctly configured

**Learning Objectives**:
- Verify all components are running
- Test catalog connectivity
- Validate storage access
- Run your first Iceberg query

**Prerequisites**: Lab 0 completed
**Estimated Time**: 30-45 minutes

**Key Concepts**:
- Environment verification
- Catalog configuration
- Storage connectivity
- Basic Iceberg operations

**Common Pitfalls**:
- Components not starting in correct order
- Incorrect catalog configuration
- Network connectivity issues
- Missing dependencies

**Tips**:
- Follow the startup order carefully
- Check logs if components fail to start
- Verify network connectivity between services
- Test each component individually

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-01-setup.md)

---

#### Lab 2: Basic Iceberg Operations
**Purpose**: Learn fundamental Iceberg table operations

**Learning Objectives**:
- Create Iceberg tables
- Insert and query data
- Understand schema evolution
- Perform basic table operations

**Prerequisites**: Lab 1 completed
**Estimated Time**: 45-60 minutes

**Key Concepts**:
- Table creation
- Data insertion
- Query execution
- Schema evolution
- Basic table operations

**Common Pitfalls**:
- Incorrect table configuration
- Schema evolution mistakes
- Query syntax errors
- Not understanding catalog behavior

**Tips**:
- Start with simple operations
- Practice each operation multiple times
- Use the solution helper when stuck
- Understand the "why" behind each operation

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-02-basic-operations.md)

---

### Phase 2: Intermediate Skills (Labs 3-5)

#### Lab 3: Advanced Features
**Purpose**: Explore advanced Iceberg capabilities

**Learning Objectives**:
- Implement partitioning strategies
- Use Z-ordering for optimization
- Perform file compaction
- Apply advanced table operations

**Prerequisites**: Lab 2 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- Partitioning strategies
- Z-ordering
- File compaction
- Advanced table operations
- Performance optimization

**Common Pitfalls**:
- Over-partitioning data
- Incorrect Z-ordering column selection
- Compaction timing issues
- Not understanding performance impact

**Tips**:
- Start with simple partitioning
- Test different partition strategies
- Measure performance impact
- Understand trade-offs

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-03-advanced-features.md)

---

#### Lab 4: Spark Optimizations
**Purpose**: Optimize Spark-Iceberg integration

**Learning Objectives**:
- Optimize file sizes and compaction
- Manage snapshots effectively
- Configure Spark for Iceberg
- Implement query planning optimizations

**Prerequisites**: Lab 3 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- File size optimization
- Snapshot management
- Spark configuration
- Query planning
- Performance tuning

**Common Pitfalls**:
- Incorrect file size targets
- Snapshot management issues
- Spark misconfiguration
- Not measuring performance

**Tips**:
- Monitor file sizes regularly
- Use Spark UI for performance analysis
- Test different configurations
- Document optimal settings

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-04-optimizations.md)

---

#### Lab 5: Real-World Patterns
**Purpose**: Implement common data engineering patterns

**Learning Objectives**:
- Implement Slowly Changing Dimensions (SCD)
- Use upsert operations effectively
- Handle batch and streaming patterns
- Design star schemas

**Prerequisites**: Lab 4 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- SCD patterns
- Upsert operations
- Batch vs streaming
- Star schema design
- Real-world data patterns

**Common Pitfalls**:
- Incorrect SCD implementation
- Upsert logic errors
- Confusing batch/stream patterns
- Poor schema design

**Tips**:
- Understand business requirements first
- Start with simple patterns
- Test edge cases thoroughly
- Document pattern decisions

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-05-real-world-patterns.md)

---

### Phase 3: Advanced Topics (Labs 6-11)

#### Lab 6: Performance & UI
**Purpose**: Analyze performance and use monitoring tools

**Learning Objectives**:
- Use Spark History Server UI
- Analyze query execution plans
- Implement metadata-only filtering
- Optimize complex queries

**Prerequisites**: Lab 5 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- Spark History Server
- Query execution analysis
- DAG inspection
- Metadata-only filtering
- Performance optimization

**Common Pitfalls**:
- Not using monitoring tools
- Misinterpreting execution plans
- Inefficient query patterns
- Ignoring performance metrics

**Tips**:
- Use monitoring tools regularly
- Learn to read execution plans
- Test optimization strategies
- Document performance findings

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-06-performance-ui.md)

---

#### Lab 7: Table Maintenance
**Purpose**: Implement automated table maintenance

**Learning Objectives**:
- Perform file compaction
- Manage snapshot expiration
- Clean up orphan files
- Implement automated maintenance

**Prerequisites**: Lab 6 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- File compaction strategies
- Snapshot management
- Orphan file cleanup
- Maintenance automation
- Storage optimization

**Common Pitfalls**:
- Over-aggressive compaction
- Incorrect snapshot retention
- Missing orphan file cleanup
- Not automating maintenance

**Tips**:
- Establish maintenance schedules
- Monitor storage usage
- Test maintenance procedures
- Automate where possible

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-07-table-maintenance.md)

---

#### Lab 8: Kafka Integration
**Purpose**: Implement real-time streaming with Kafka

**Learning Objectives**:
- Set up Kafka for streaming
- Produce and consume events
- Integrate Spark Structured Streaming
- Implement real-time analytics

**Prerequisites**: Lab 7 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- Kafka fundamentals
- Event streaming
- Structured Streaming
- Real-time analytics
- Exactly-once semantics

**Common Pitfalls**:
- Kafka configuration errors
- Streaming logic mistakes
- Not handling backpressure
- Incorrect checkpointing

**Tips**:
- Start with simple streaming
- Monitor streaming metrics
- Handle failures gracefully
- Test streaming thoroughly

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-08-kafka-integration.md)

---

#### Lab 9: CDC with Debezium
**Purpose**: Implement change data capture with Debezium

**Learning Objectives**:
- Configure Debezium for CDC
- Set up MySQL for CDC
- Stream CDC events to Kafka
- Apply CDC changes to Iceberg

**Prerequisites**: Lab 8 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- Change Data Capture
- Debezium configuration
- MySQL binlog
- CDC event streaming
- Real-time data synchronization

**Common Pitfalls**:
- Incorrect Debezium configuration
- MySQL binlog issues
- CDC event handling errors
- Schema evolution challenges

**Tips**:
- Understand CDC concepts first
- Test Debezium configuration
- Monitor CDC pipeline
- Plan for schema evolution

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-09-cdc-debezium.md)

---

#### Lab 10: Spring Boot with Iceberg
**Purpose**: Build applications with Iceberg integration

**Learning Objectives**:
- Create Spring Boot applications
- Configure Iceberg access
- Implement CRUD operations
- Build REST APIs for Iceberg

**Prerequisites**: Lab 9 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- Spring Boot integration
- Iceberg catalog access
- Application patterns
- REST API design
- Transaction management

**Common Pitfalls**:
- Incorrect Iceberg configuration
- Transaction handling errors
- Poor API design
- Not handling exceptions

**Tips**:
- Follow Spring best practices
- Test Iceberg operations thoroughly
- Design APIs carefully
- Handle errors gracefully

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-10-spring-boot-iceberg.md)

---

#### Lab 11: Multi-Engine Lakehouse
**Purpose**: Work with multiple query engines

**Learning Objectives**:
- Configure multiple query engines
- Ensure cross-engine consistency
- Implement engine-specific optimizations
- Build multi-engine pipelines

**Prerequisites**: Lab 10 completed
**Estimated Time**: 60-90 minutes

**Key Concepts**:
- Multi-engine architecture
- Cross-engine queries
- Engine-specific optimizations
- Data type conversions
- Workload isolation

**Common Pitfalls**:
- Inconsistent configurations
- Data type conversion issues
- Poor engine selection
- Not optimizing per engine

**Tips**:
- Understand each engine's strengths
- Test cross-engine operations
- Optimize for each engine
- Monitor performance

[📖 Full Lab Guide](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-11-multi-engine-lakehouse.md)

---

## 💡 General Lab Tips

### Preparation

1. **Read the Lab First**: Understand objectives before starting
2. **Check Prerequisites**: Ensure previous labs are completed
3. **Set Aside Time**: Don't rush through labs
4. **Take Notes**: Document what you learn

### During Labs

1. **Follow Instructions Step-by-Step**: Don't skip steps
2. **Test Each Step**: Verify each operation works
3. **Use Solution Helper**: When stuck, check for hints
4. **Ask Questions**: Use community resources when needed

### After Labs

1. **Review Solutions**: Compare with provided solutions
2. **Experiment Further**: Try variations on exercises
3. **Document Learnings**: Write down key takeaways
4. **Share Insights**: Help others learn from your experience

## 🆘 Getting Help

### Solution Helper

Use the built-in solution helper when stuck:
```python
from solution_helper import check_solution, get_hint

check_solution(1)  # Get help for Lab 1
get_hint(1, 1)     # Get hint for Lab 1, Step 1
```

### Community Resources

- **GitHub Issues**: Report bugs and ask questions
- **GitHub Discussions**: Start discussions about topics
- **Wiki**: Check for additional guidance
- **Documentation**: Review official Iceberg docs

### Troubleshooting

1. **Check Logs**: Review component logs for errors
2. **Verify Configuration**: Ensure settings are correct
3. **Test Components**: Check each component individually
4. **Review Documentation**: Check relevant docs and guides

## 📈 Tracking Progress

### Progress Checklist

Use this checklist to track your progress:

- [ ] Lab 0: Sample Database Setup
- [ ] Lab 1: Environment Setup
- [ ] Lab 2: Basic Iceberg Operations
- [ ] Lab 3: Advanced Features
- [ ] Lab 4: Spark Optimizations
- [ ] Lab 5: Real-World Patterns
- [ ] Lab 6: Performance & UI
- [ ] Lab 7: Table Maintenance
- [ ] Lab 8: Kafka Integration
- [ ] Lab 9: CDC with Debezium
- [ ] Lab 10: Spring Boot with Iceberg
- [ ] Lab 11: Multi-Engine Lakehouse

### Skill Assessment

After completing labs, assess your skills:
- **Beginner**: Labs 0-2 completed
- **Intermediate**: Labs 3-5 completed
- **Advanced**: Labs 6-11 completed

---

**Ready to start?** Begin with [Lab 0: Sample Database Setup](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-00-sample-database.md) 🚀
