# Application Integration with Iceberg

## Overview

This conceptual guide explains how to integrate Apache Iceberg into application architectures, covering patterns for building data-driven applications that leverage Iceberg's capabilities. While the lab focuses on Spring Boot, the concepts apply to any application framework.

## Learning Objectives

By the end of this guide, you will understand:

1. Application integration patterns with Iceberg
2. Data access layer design
3. Transaction management patterns
4. Caching strategies
5. Performance optimization techniques
6. Security and access control
7. Monitoring and observability

## Part 1: Integration Patterns

### Pattern 1: Direct Catalog Access

```
Application → Iceberg Catalog → Iceberg Tables
```

**Architecture:**
- Application connects directly to Iceberg REST catalog
- Uses Iceberg Java/Python client libraries
- Direct table read/write operations

**Advantages:**
- Simple architecture
- Low latency
- Full Iceberg feature access

**Disadvantages:**
- Application must handle Iceberg complexity
- Limited to single engine operations

**Use Cases:**
- Simple CRUD applications
- Batch processing jobs
- Data migration scripts

### Pattern 2: Query Engine Integration

```
Application → Query Engine (Spark/Trino) → Iceberg Tables
```

**Architecture:**
- Application connects to query engine
- Query engine handles Iceberg operations
- Application uses SQL or engine-specific APIs

**Advantages:**
- Leverages query engine optimizations
- Supports complex queries
- Engine handles Iceberg complexity

**Disadvantages:**
- Additional infrastructure
- Higher latency
- Limited to engine capabilities

**Use Cases:**
- Analytics applications
- Reporting dashboards
- Data science workflows

### Pattern 3: Service Layer Abstraction

```
Application → Service Layer → Repository Layer → Iceberg
```

**Architecture:**
- Application calls service layer
- Service layer implements business logic
- Repository layer handles data access
- Iceberg operations abstracted

**Advantages:**
- Clean separation of concerns
- Testable architecture
- Reusable components

**Disadvantages:**
- More complex architecture
- Additional abstraction layer

**Use Cases:**
- Enterprise applications
- Microservices architectures
- Complex business logic

## Part 2: Data Access Layer Design

### Repository Pattern

The repository pattern provides an abstraction for data access:

```java
public interface IcebergRepository<T, ID> {
    T findById(ID id);
    List<T> findAll();
    T save(T entity);
    List<T> saveAll(List<T> entities);
    void deleteById(ID id);
    boolean existsById(ID id);
    long count();
}
```

**Benefits:**
- Consistent data access interface
- Easy to test and mock
- Centralized data access logic
- Supports different implementations

### Generic Repository Implementation

```java
public abstract class AbstractIcebergRepository<T, ID> 
    implements IcebergRepository<T, ID> {
    
    protected final Catalog catalog;
    protected final TableIdentifier tableIdentifier;
    protected final Schema schema;
    
    @Override
    public T findById(ID id) {
        Table table = catalog.loadTable(tableIdentifier);
        // Scan table for record with given ID
        return findRecordById(table, id);
    }
    
    @Override
    public List<T> findAll() {
        Table table = catalog.loadTable(tableIdentifier);
        // Scan entire table
        return scanTable(table);
    }
    
    @Override
    public T save(T entity) {
        Table table = catalog.loadTable(tableIdentifier);
        Record record = mapToRecord(entity, schema);
        // Append record to table
        table.newAppend().appendFile(record).commit();
        return entity;
    }
    
    protected abstract T mapFromRecord(Record record);
    protected abstract Record mapToRecord(T entity, Schema schema);
}
```

### Domain-Specific Repositories

```java
@Repository
public class CustomerRepository extends AbstractIcebergRepository<Customer, Integer> {
    
    public CustomerRepository(Catalog catalog) {
        super(catalog, 
              TableIdentifier.of("demo", "customers"),
              customerSchema());
    }
    
    @Override
    protected Customer mapFromRecord(Record record) {
        return Customer.builder()
            .id((Integer) record.get(0))
            .name((String) record.get(1))
            .email((String) record.get(2))
            .build();
    }
    
    @Override
    protected Record mapToRecord(Customer customer, Schema schema) {
        GenericRecord record = GenericRecord.create(schema);
        record.set(0, customer.getId());
        record.set(1, customer.getName());
        record.set(2, customer.getEmail());
        return record;
    }
    
    // Custom query methods
    public List<Customer> findByEmail(String email) {
        // Implement custom query logic
    }
    
    public List<Customer> findByNameContaining(String name) {
        // Implement custom query logic
    }
}
```

## Part 3: Transaction Management

### ACID Transactions with Iceberg

Iceberg provides ACID guarantees at the table level:

```java
@Service
@Transactional
public class OrderService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Autowired
    private ProductRepository productRepository;
    
    @Autowired
    private OrderRepository orderRepository;
    
    public Order createOrder(OrderRequest request) {
        // Transaction starts here
        
        // 1. Validate customer exists
        Customer customer = customerRepository.findById(request.getCustomerId());
        if (customer == null) {
            throw new CustomerNotFoundException();
        }
        
        // 2. Validate product exists and has stock
        Product product = productRepository.findById(request.getProductId());
        if (product == null || product.getStockQuantity() < request.getQuantity()) {
            throw new ProductNotAvailableException();
        }
        
        // 3. Create order
        Order order = Order.builder()
            .customerId(request.getCustomerId())
            .productId(request.getProductId())
            .quantity(request.getQuantity())
            .totalAmount(product.getPrice() * request.getQuantity())
            .build();
        
        orderRepository.save(order);
        
        // 4. Update product stock
        product.setStockQuantity(product.getStockQuantity() - request.getQuantity());
        productRepository.save(product);
        
        // Transaction commits here
        return order;
    }
}
```

### Optimistic Concurrency Control

```java
public class OptimisticLockingRepository<T, ID> extends AbstractIcebergRepository<T, ID> {
    
    @Override
    public T save(T entity) {
        Table table = catalog.loadTable(tableIdentifier);
        
        // Read current snapshot
        Snapshot currentSnapshot = table.currentSnapshot();
        
        // Check if entity was modified
        if (entity.getVersion() != getExpectedVersion(entity.getId())) {
            throw new OptimisticLockingFailureException();
        }
        
        // Update entity version
        entity.setVersion(entity.getVersion() + 1);
        
        // Write new snapshot
        Record record = mapToRecord(entity, schema);
        table.newAppend()
            .appendFile(record)
            .commit();
        
        return entity;
    }
}
```

### Distributed Transactions

For operations across multiple tables or systems:

```java
@Service
public class DistributedTransactionService {
    
    @Autowired
    private TransactionManager transactionManager;
    
    public void executeDistributedTransaction() {
        TransactionDefinition def = new DefaultTransactionDefinition();
        TransactionStatus status = transactionManager.getTransaction(def);
        
        try {
            // Operation 1: Write to table 1
            performOperation1();
            
            // Operation 2: Write to table 2
            performOperation2();
            
            // Operation 3: Write to table 3
            performOperation3();
            
            transactionManager.commit(status);
        } catch (Exception e) {
            transactionManager.rollback(status);
            throw e;
        }
    }
}
```

## Part 4: Caching Strategies

### Read-Through Caching

```java
@Service
public class CachedCustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Cacheable(value = "customers", key = "#id")
    public Customer findById(Integer id) {
        return customerRepository.findById(id);
    }
    
    @CacheEvict(value = "customers", key = "#id")
    public void updateCustomer(Integer id, Customer customer) {
        customerRepository.save(customer);
    }
    
    @CacheEvict(value = "customers", allEntries = true)
    public void refreshCache() {
        // Cache will be refreshed on next access
    }
}
```

### Write-Through Caching

```java
@Service
public class WriteThroughCustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Autowired
    private CacheManager cacheManager;
    
    @CachePut(value = "customers", key = "#result.id")
    public Customer save(Customer customer) {
        Customer saved = customerRepository.save(customer);
        return saved;
    }
}
```

### Cache Aside Pattern

```java
@Service
public class CacheAsideCustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Autowired
    private Cache cache;
    
    public Customer findById(Integer id) {
        // Try cache first
        Customer cached = cache.get(id, Customer.class);
        if (cached != null) {
            return cached;
        }
        
        // Cache miss - load from database
        Customer customer = customerRepository.findById(id);
        if (customer != null) {
            cache.put(id, customer);
        }
        
        return customer;
    }
}
```

## Part 5: Performance Optimization

### Connection Pooling

```java
@Configuration
public class IcebergConfig {
    
    @Bean
    public Catalog icebergCatalog() {
        Map<String, String> properties = new HashMap<>();
        properties.put("s3.endpoint", "http://localhost:9000");
        properties.put("s3.access-key-id", "minioadmin");
        properties.put("s3.secret-access-key", "minioadmin");
        
        RESTCatalog catalog = new RESTCatalog();
        catalog.setConf(properties);
        catalog.initialize("iceberg", Map.of(
            "uri", "http://localhost:8181/api/catalog",
            "warehouse", "s3a://iceberg-warehouse"
        ));
        
        return catalog;
    }
}
```

### Batch Operations

```java
@Service
public class BatchCustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Transactional
    public void importCustomers(List<Customer> customers) {
        // Process in batches
        int batchSize = 1000;
        for (int i = 0; i < customers.size(); i += batchSize) {
            int end = Math.min(i + batchSize, customers.size());
            List<Customer> batch = customers.subList(i, end);
            customerRepository.saveAll(batch);
        }
    }
}
```

### Query Optimization

```java
@Repository
public class OptimizedCustomerRepository extends AbstractIcebergRepository<Customer, Integer> {
    
    @Override
    public List<Customer> findAll() {
        Table table = catalog.loadTable(tableIdentifier);
        
        // Use table scan with pushdown predicates
        return table.newScan()
            .filter(Expressions.equal("active", true))
            .project(Schema.withIdentifierFields(
                table.schema().select("id", "name", "email")
            ))
            .planFiles()
            .stream()
            .flatMap(this::readFile)
            .collect(Collectors.toList());
    }
}
```

## Part 6: Security and Access Control

### Authentication

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/api/customers/**").hasRole("USER")
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtDecoder(jwtDecoder()))
            );
        
        return http.build();
    }
}
```

### Row-Level Security

```java
@Service
public class SecureCustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Autowired
    private SecurityContext securityContext;
    
    public List<Customer> findAccessibleCustomers() {
        String userId = securityContext.getUserPrincipal().getName();
        
        // Filter based on user permissions
        return customerRepository.findAll()
            .stream()
            .filter(customer -> hasAccessToCustomer(userId, customer))
            .collect(Collectors.toList());
    }
    
    private boolean hasAccessToCustomer(String userId, Customer customer) {
        // Implement access control logic
        return true;
    }
}
```

### Audit Logging

```java
@Aspect
@Component
public class AuditAspect {
    
    @Autowired
    private AuditLogRepository auditLogRepository;
    
    @Around("@annotation(Auditable)")
    public Object auditOperation(ProceedingJoinPoint joinPoint) throws Throwable {
        String operation = joinPoint.getSignature().getName();
        Object[] args = joinPoint.getArgs();
        
        long startTime = System.currentTimeMillis();
        
        try {
            Object result = joinPoint.proceed();
            
            long duration = System.currentTimeMillis() - startTime;
            
            // Log successful operation
            AuditLog log = AuditLog.builder()
                .operation(operation)
                .parameters(Arrays.toString(args))
                .result(result.toString())
                .duration(duration)
                .status("SUCCESS")
                .timestamp(Instant.now())
                .build();
            
            auditLogRepository.save(log);
            
            return result;
        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            
            // Log failed operation
            AuditLog log = AuditLog.builder()
                .operation(operation)
                .parameters(Arrays.toString(args))
                .error(e.getMessage())
                .duration(duration)
                .status("FAILED")
                .timestamp(Instant.now())
                .build();
            
            auditLogRepository.save(log);
            
            throw e;
        }
    }
}
```

## Part 7: Monitoring and Observability

### Metrics Collection

```java
@Component
public class IcebergMetrics {
    
    private final MeterRegistry meterRegistry;
    
    @Autowired
    public IcebergMetrics(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }
    
    public void recordQuery(String tableName, long duration) {
        Timer.builder("iceberg.query.duration")
            .tag("table", tableName)
            .register(meterRegistry)
            .record(duration, TimeUnit.MILLISECONDS);
    }
    
    public void recordWrite(String tableName, int recordCount) {
        Counter.builder("iceberg.write.records")
            .tag("table", tableName)
            .register(meterRegistry)
            .increment(recordCount);
    }
}
```

### Health Checks

```java
@Component
public class IcebergHealthIndicator implements HealthIndicator {
    
    @Autowired
    private Catalog icebergCatalog;
    
    @Override
    public Health health() {
        try {
            // Check catalog connectivity
            icebergCatalog.listNamespaces();
            
            return Health.up()
                .withDetail("catalog", "iceberg")
                .withDetail("status", "connected")
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

### Distributed Tracing

```java
@Service
public class TracedCustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @NewSpan("customer-service.find-by-id")
    public Customer findById(@SpanTag("customerId") Integer id) {
        return customerRepository.findById(id);
    }
}
```

## Part 8: Error Handling

### Global Exception Handler

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(IcebergException.class)
    public ResponseEntity<ErrorResponse> handleIcebergException(IcebergException ex) {
        ErrorResponse error = ErrorResponse.builder()
            .timestamp(Instant.now())
            .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
            .error("Iceberg Error")
            .message(ex.getMessage())
            .build();
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
    
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(ValidationException ex) {
        ErrorResponse error = ErrorResponse.builder()
            .timestamp(Instant.now())
            .status(HttpStatus.BAD_REQUEST.value())
            .error("Validation Error")
            .message(ex.getMessage())
            .build();
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }
}
```

### Retry Logic

```java
@Service
public class RetryableCustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    @Retryable(
        value = {TransientDataAccessException.class},
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2)
    )
    public Customer saveWithRetry(Customer customer) {
        return customerRepository.save(customer);
    }
}
```

## Summary

This guide covered:

1. **Integration Patterns**: Different approaches to integrating Iceberg into applications
2. **Data Access Layer**: Repository pattern and implementation strategies
3. **Transaction Management**: ACID transactions and concurrency control
4. **Caching Strategies**: Various caching patterns for performance optimization
5. **Performance Optimization**: Connection pooling, batch operations, and query optimization
6. **Security**: Authentication, authorization, and audit logging
7. **Monitoring**: Metrics, health checks, and distributed tracing
8. **Error Handling**: Global exception handling and retry logic

By following these patterns and best practices, you can build robust, scalable applications that effectively leverage Apache Iceberg's capabilities.

## Related Labs

- Lab 10: Spring Boot with Iceberg
- Lab 11: Multi-Engine Lakehouse