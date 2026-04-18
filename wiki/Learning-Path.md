# Learning Path - Recommended Order for Labs

This guide suggests a structured learning path through the Apache Iceberg Practice Environment labs. While you can skip around, following this path ensures you build skills progressively.

## Overview

The learning path is divided into three levels:
- **Beginner** (0-6 months experience): Foundation skills
- **Intermediate** (6-18 months experience): Production patterns
- **Advanced** (18+ months experience): System design and optimization

## Beginner Path

### Goal: Build foundation in Iceberg and basic data engineering

### Week 1: Environment Setup and Fundamentals

#### Lab 0: Sample Database Setup (30-45 min)
- Generate and load realistic business data
- Explore sample database schema and relationships
- Practice basic SQL queries
- Understand data distribution and patterns

**Why start here**: Provides realistic data for all subsequent labs. No Iceberg knowledge required.

#### Lab 1: Environment Setup (30-45 min)
- Verify all components are running
- Test catalog connectivity
- Validate storage access
- Perform first Iceberg operation

**Why it's important**: Ensures your environment works before diving into complex concepts.

#### Lab 2: Basic Iceberg Operations (30-45 min)
- Create Iceberg tables
- Insert and query data
- Understand schema evolution basics
- Practice CRUD operations

**Why it matters**: Core Iceberg concepts you'll use in every lab.

**Beginner Milestone**: Complete Labs 0-2 (approximately 2 hours)

## Intermediate Path

### Goal: Master production patterns and optimization

### Week 2: Advanced Iceberg Features

#### Lab 3: Advanced Features (45-60 min)
- Partitioning strategies
- Time travel queries
- Schema evolution with migrations
- Understanding snapshots and metadata

**Why it's important**: These features distinguish Iceberg from traditional data lakes.

#### Lab 4: Spark Optimizations (45-60 min)
- File compaction
- Snapshot management
- Query planning optimization
- Understanding metadata-only queries

**Why it matters**: Performance is critical in production environments.

### Week 3: Real-World Patterns

#### Lab 5: Real-World Patterns (45-60 min)
- Slowly Changing Dimensions (SCD)
- Upsert operations
- Batch and streaming patterns
- Star schema implementation

**Why it's important**: These patterns are used in real data engineering projects.

**Intermediate Milestone**: Complete Labs 3-5 (approximately 3 hours)

## Advanced Path

### Goal: System design, streaming, and multi-engine architecture

### Week 4: Performance and Operations

#### Lab 6: Performance & UI (60-90 min)
- Complex Iceberg join operations
- Spark History Server UI exploration
- DAG inspection and metadata-only filtering
- Performance analysis and optimization

**Why it's important**: Understanding query execution helps optimize production workloads.

#### Lab 7: Table Maintenance (60-90 min)
- File compaction and optimization strategies
- Snapshot management and expiration
- Orphan file cleanup and storage reclamation
- Table statistics collection and analysis
- Metadata optimization
- Monitoring and alerting setup

**Why it's important**: Maintenance is crucial for long-term production systems.

### Week 5: Streaming and CDC

#### Lab 8: Kafka Integration (60-90 min)
- Set up Apache Kafka for real-time data streaming
- Produce and consume events with Kafka
- Integrate Spark Structured Streaming with Iceberg
- Implement real-time analytics on streaming data
- Handle exactly-once processing semantics

**Why it's important**: Streaming is essential for modern data architectures.

#### Lab 9: Real CDC with Debezium (60-90 min)
- Configure Debezium for MySQL CDC
- Set up MySQL for change data capture
- Create and manage Debezium connectors
- Stream CDC events to Kafka topics
- Consume CDC events with Spark Structured Streaming
- Apply CDC changes to Iceberg tables

**Why it's important**: CDC enables real-time data synchronization across systems.

### Week 6: Application Integration and Multi-Engine

#### Lab 10: Spring Boot with Iceberg (60-90 min)
- Create Spring Boot applications with Iceberg integration
- Configure Iceberg catalog and table access
- Implement CRUD operations on Iceberg tables
- Build REST APIs for Iceberg data access
- Implement transaction handling and error management

**Why it's important**: Applications need to interact with data lakes efficiently.

#### Lab 11: Multi-Engine Lakehouse (60-90 min)
- Configure multiple query engines (Spark, Trino, DuckDB)
- Ensure schema consistency across engines
- Implement engine-specific optimizations
- Handle data type conversions between engines
- Monitor and optimize multi-engine workloads

**Why it's important**: Modern lakehouses use multiple engines for different use cases.

**Advanced Milestone**: Complete Labs 6-11 (approximately 8 hours)

## Alternative Learning Paths

### Fast Track for Experienced Engineers

If you have 2+ years of data engineering experience:

1. **Skip Labs 0-1**: Assume environment works
2. **Lab 2**: Quick refresher on Iceberg basics (30 min)
3. **Labs 3-5**: Focus on advanced features (2 hours)
4. **Labs 6-7**: Performance and operations (2 hours)
5. **Choose specialization**: Either streaming (8-9) or applications (10-11)

**Total time**: 5-6 hours

### Streaming Specialist Path

Focus on real-time data processing:

1. **Labs 0-2**: Foundation (2 hours)
2. **Lab 5**: Real-world patterns (1 hour)
3. **Lab 8**: Kafka integration (1.5 hours)
4. **Lab 9**: CDC with Debezium (1.5 hours)
5. **Lab 11**: Multi-engine considerations (1.5 hours)

**Total time**: 7.5 hours

### Performance Engineer Path

Focus on optimization and operations:

1. **Labs 0-2**: Foundation (2 hours)
2. **Lab 3**: Advanced features (1 hour)
3. **Lab 4**: Spark optimizations (1 hour)
4. **Lab 6**: Performance & UI (1.5 hours)
5. **Lab 7**: Table maintenance (1.5 hours)
6. **Lab 11**: Multi-engine optimization (1.5 hours)

**Total time**: 8.5 hours

### Application Developer Path

Focus on building applications with Iceberg:

1. **Labs 0-2**: Foundation (2 hours)
2. **Lab 5**: Real-world patterns (1 hour)
3. **Lab 10**: Spring Boot integration (1.5 hours)
4. **Lab 11**: Multi-engine considerations (1.5 hours)

**Total time**: 6 hours

## Progress Tracking

Use this checklist to track your progress:

### Beginner
- [ ] Lab 0: Sample Database Setup
- [ ] Lab 1: Environment Setup
- [ ] Lab 2: Basic Iceberg Operations

### Intermediate
- [ ] Lab 3: Advanced Features
- [ ] Lab 4: Spark Optimizations
- [ ] Lab 5: Real-World Patterns

### Advanced
- [ ] Lab 6: Performance & UI
- [ ] Lab 7: Table Maintenance
- [ ] Lab 8: Kafka Integration
- [ ] Lab 9: CDC with Debezium
- [ ] Lab 10: Spring Boot with Iceberg
- [ ] Lab 11: Multi-Engine Lakehouse

## Time Estimates

- **Beginner Path**: 2 hours
- **Intermediate Path**: 3 hours
- **Advanced Path**: 8 hours
- **Complete Learning Path**: 13 hours

## Tips for Following the Path

### 1. Don't Rush
- Understanding is more important than speed
- Take time to read the conceptual guides
- Review solutions even when you succeed

### 2. Practice Regularly
- 30-60 minutes daily is better than 4 hours weekly
- Consistency builds muscle memory
- Revisit labs after breaks

### 3. Use Multiple Engines
- Try the same operations in Spark, Trino, and DuckDB
- Understand engine-specific behaviors
- Learn which engine is best for which task

### 4. Learn from Mistakes
- Understand why your solution failed
- Read error messages carefully
- Check the solution notebooks for patterns

### 5. Build on Previous Knowledge
- Each lab builds on earlier concepts
- Don't skip foundational labs
- Reference completed labs when stuck

### 6. Apply to Real Work
- Try patterns in your actual projects
- Adapt labs to your use cases
- Share learnings with your team

## Before Starting Each Lab

1. **Review Prerequisites**: Ensure you've completed required previous labs
2. **Read the Lab Guide**: Understand objectives and requirements
3. **Check Environment**: Verify all services are running
4. **Allocate Time**: Ensure you have the estimated time available
5. **Have Resources Ready**: Keep documentation and solution notebooks accessible

## After Completing Each Lab

1. **Review Solutions**: Compare with solution notebooks
2. **Document Learnings**: Note key concepts and patterns
3. **Practice Again**: Try variations of the exercises
4. **Teach Someone**: Explain concepts to reinforce learning
5. **Apply to Projects**: Use patterns in real scenarios

## Customizing Your Path

Feel free to customize based on your needs:

### Focus on Specific Topics
- **Iceberg Deep Dive**: Labs 2-4, 6-7
- **Streaming Focus**: Labs 5, 8-9
- **Multi-Engine Focus**: Labs 4, 6, 11
- **Application Development**: Labs 2, 5, 10

### Time Constraints
- **1 Hour**: Lab 2 only
- **Half Day**: Labs 0-5
- **Full Day**: Labs 0-9
- **Two Days**: Complete all labs

### Skill Level Adjustment
- **Beginner**: Complete all beginner labs, skip advanced
- **Intermediate**: Complete beginner and intermediate, sample advanced
- **Advanced**: Skip beginner, focus on intermediate and advanced

## Next Steps

After completing the learning path:

1. **Build a Project**: Apply patterns to a real project
2. **Contribute**: Add new labs or improve existing ones
3. **Specialize**: Deep dive into specific areas (streaming, performance, etc.)
4. **Teach**: Share knowledge with your team or community
5. **Certify**: Pursue Apache Iceberg or related certifications

## Additional Resources

- [Getting Started Guide](Getting-Started.md)
- [Best Practices](Best-Practices.md)
- [Troubleshooting](Troubleshooting.md)
- [Iceberg Fundamentals](Iceberg-Fundamentals.md)
- [Main Repository](https://github.com/yourusername/iceberg-code-practice)
- Contact: nellaivijay@gmail.com

---

**Ready to start?** Begin with [Lab 0: Sample Database Setup](https://github.com/yourusername/iceberg-code-practice/blob/main/labs/lab-00-sample-database.md) 🚀