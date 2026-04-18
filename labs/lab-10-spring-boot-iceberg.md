# Lab 10: Spring Boot with Iceberg

## Overview

In this lab, you will learn how to build Spring Boot applications that integrate with Apache Iceberg. You will create a REST API that performs CRUD operations on Iceberg tables, implement data access patterns, and learn best practices for building production-ready applications with Iceberg.

## Prerequisites

- Complete Labs 0-7
- Java 11 or higher installed
- Maven or Gradle installed
- Spring Boot knowledge
- REST API development experience

## Learning Objectives

By the end of this lab, you will be able to:

1. Create a Spring Boot application with Iceberg integration
2. Configure Iceberg catalog and table access
3. Implement CRUD operations on Iceberg tables
4. Build REST APIs for Iceberg data access
5. Implement transaction handling and error management
6. Optimize performance with caching and connection pooling
7. Implement data validation and business logic
8. Add monitoring and logging to your application

## Lab Setup

### 1. Start the Infrastructure

Start the core infrastructure:

```bash
cd /home/ramdov/projects/iceberg-practice-env
docker-compose up -d minio polaris
```

Verify services are running:

```bash
docker-compose ps
```

### 2. Create Spring Boot Project

Create a new Spring Boot project:

```bash
# Using Spring Initializr (or manually create project structure)
mkdir -p iceberg-spring-boot/src/main/java/com/example/iceberg
mkdir -p iceberg-spring-boot/src/main/resources
mkdir -p iceberg-spring-boot/src/test/java/com/example/iceberg
```

## Part 1: Project Configuration

### Step 1.1: Create pom.xml

Create the Maven configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>iceberg-spring-boot</artifactId>
    <version>1.0.0</version>
    <name>Iceberg Spring Boot</name>
    <description>Spring Boot application with Iceberg integration</description>
    
    <properties>
        <java.version>17</java.version>
        <iceberg.version>1.4.0</iceberg.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <!-- Spring Boot Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <!-- Spring Boot Actuator -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        
        <!-- Apache Iceberg -->
        <dependency>
            <groupId>org.apache.iceberg</groupId>
            <artifactId>iceberg-core</artifactId>
            <version>${iceberg.version}</version>
        </dependency>
        
        <dependency>
            <groupId>org.apache.iceberg</groupId>
            <artifactId>iceberg-api</artifactId>
            <version>${iceberg.version}</version>
        </dependency>
        
        <dependency>
            <groupId>org.apache.iceberg</groupId>
            <artifactId>iceberg-rest</artifactId>
            <version>${iceberg.version}</version>
        </dependency>
        
        <dependency>
            <groupId>org.apache.iceberg</groupId>
            <artifactId>iceberg-aws</artifactId>
            <version>${iceberg.version}</version>
        </dependency>
        
        <!-- AWS SDK -->
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>s3</artifactId>
            <version>2.20.0</version>
        </dependency>
        
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- Test Dependencies -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### Step 1.2: Create application.yml

Create the application configuration:

```yaml
# iceberg-spring-boot/src/main/resources/application.yml
server:
  port: 8080

spring:
  application:
    name: iceberg-spring-boot

iceberg:
  catalog:
    type: rest
    uri: http://localhost:8181/api/catalog
    warehouse: s3a://iceberg-warehouse
  s3:
    endpoint: http://localhost:9000
    access-key: minioadmin
    secret-key: minioadmin
    path-style-access: true

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  metrics:
    export:
      prometheus:
        enabled: true

logging:
  level:
    com.example.iceberg: DEBUG
    org.apache.iceberg: INFO
```

## Part 2: Iceberg Configuration

### Step 2.1: Create Iceberg Configuration Class

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/config/IcebergConfig.java
package com.example.iceberg.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "iceberg")
public class IcebergConfig {
    private Catalog catalog = new Catalog();
    private S3 s3 = new S3();
    
    @Data
    public static class Catalog {
        private String type;
        private String uri;
        private String warehouse;
    }
    
    @Data
    public static class S3 {
        private String endpoint;
        private String accessKey;
        private String secretKey;
        private Boolean pathStyleAccess;
    }
}
```

### Step 2.2: Create Iceberg Catalog Bean

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/config/IcebergCatalogConfig.java
package com.example.iceberg.config;

import org.apache.iceberg.Catalog;
import org.apache.iceberg.catalog.CatalogUtil;
import org.apache.iceberg.catalog.TableIdentifier;
import org.apache.iceberg.hadoop.HadoopCatalog;
import org.apache.iceberg.rest.RESTCatalog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class IcebergCatalogConfig {
    
    @Autowired
    private IcebergConfig icebergConfig;
    
    @Bean
    public Catalog icebergCatalog() {
        Map<String, String> properties = new HashMap<>();
        
        // S3 configuration
        properties.put("s3.endpoint", icebergConfig.getS3().getEndpoint());
        properties.put("s3.access-key-id", icebergConfig.getS3().getAccessKey());
        properties.put("s3.secret-access-key", icebergConfig.getS3().getSecretKey());
        properties.put("s3.path-style-access", 
                      icebergConfig.getS3().getPathStyleAccess().toString());
        
        // Catalog configuration
        if ("rest".equalsIgnoreCase(icebergConfig.getCatalog().getType())) {
            RESTCatalog catalog = new RESTCatalog();
            catalog.setConf(properties);
            catalog.initialize("iceberg", Map.of(
                "uri", icebergConfig.getCatalog().getUri(),
                "warehouse", icebergConfig.getCatalog().getWarehouse()
            ));
            return catalog;
        } else {
            HadoopCatalog catalog = new HadoopCatalog();
            catalog.setConf(properties);
            catalog.initialize("iceberg", Map.of(
                "warehouse", icebergConfig.getCatalog().getWarehouse()
            ));
            return catalog;
        }
    }
}
```

## Part 3: Domain Models

### Step 3.1: Create Customer Model

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/model/Customer.java
package com.example.iceberg.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Customer {
    
    @NotNull
    private Integer id;
    
    @NotBlank
    private String name;
    
    @NotBlank
    @Email
    private String email;
    
    private String phone;
    
    private String address;
    
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;
}
```

### Step 3.2: Create Product Model

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/model/Product.java
package com.example.iceberg.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Product {
    
    @NotNull
    private Integer id;
    
    @NotBlank
    private String name;
    
    private String description;
    
    @NotNull
    @DecimalMin("0.01")
    private BigDecimal price;
    
    private String category;
    
    private Integer stockQuantity;
    
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;
}
```

### Step 3.3: Create Order Model

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/model/Order.java
package com.example.iceberg.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Order {
    
    @NotNull
    private Integer id;
    
    @NotNull
    private Integer customerId;
    
    @NotNull
    private LocalDateTime orderDate;
    
    @NotBlank
    private String status;
    
    @NotNull
    @DecimalMin("0.01")
    private BigDecimal totalAmount;
    
    private String shippingAddress;
    
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;
}
```

## Part 4: Repository Layer

### Step 4.1: Create Iceberg Repository Base

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/repository/IcebergRepository.java
package com.example.iceberg.repository;

import org.apache.iceberg.Catalog;
import org.apache.iceberg.Table;
import org.apache.iceberg.TableIdentifier;
import org.apache.iceberg.data.Record;
import org.apache.iceberg.data.GenericRecord;
import org.apache.iceberg.Schema;
import org.apache.iceberg.types.Type;
import org.apache.iceberg.types.Types;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;

public abstract class IcebergRepository<T> {
    
    @Autowired
    protected Catalog catalog;
    
    protected abstract String getTableName();
    
    protected abstract T mapRecordToEntity(Record record);
    
    protected abstract Record mapEntityToRecord(T entity, Schema schema);
    
    protected Table getTable() {
        TableIdentifier identifier = TableIdentifier.of("demo", getTableName());
        return catalog.loadTable(identifier);
    }
    
    protected Table getOrCreateTable(Schema schema) {
        TableIdentifier identifier = TableIdentifier.of("demo", getTableName());
        if (catalog.tableExists(identifier)) {
            return catalog.loadTable(identifier);
        } else {
            return catalog.buildTable(identifier, schema)
                .withPartitionSpec(null)
                .create();
        }
    }
    
    public List<T> findAll() {
        Table table = getTable();
        Schema schema = table.schema();
        
        return table.newScan()
            .planFiles()
            .stream()
            .flatMap(fileScanTask -> {
                try (org.apache.iceberg.io.CloseableIterable<Record> records = 
                     table.newRowReader().createReader(fileScanTask)) {
                    return records.stream()
                        .map(this::mapRecordToEntity)
                        .toList()
                        .stream();
                } catch (Exception e) {
                    throw new RuntimeException("Error reading records", e);
                }
            })
            .toList();
    }
    
    public T findById(Object id) {
        Table table = getTable();
        Schema schema = table.schema();
        
        return table.newScan()
            .planFiles()
            .stream()
            .flatMap(fileScanTask -> {
                try (org.apache.iceberg.io.CloseableIterable<Record> records = 
                     table.newRowReader().createReader(fileScanTask)) {
                    return records.stream()
                        .filter(record -> record.get(0).equals(id))
                        .map(this::mapRecordToEntity)
                        .toList()
                        .stream();
                } catch (Exception e) {
                    throw new RuntimeException("Error reading records", e);
                }
            })
            .findFirst()
            .orElse(null);
    }
    
    public void save(T entity) {
        Table table = getTable();
        Schema schema = table.schema();
        Record record = mapEntityToRecord(entity, schema);
        
        try {
            table.newAppend()
                .appendFile(org.apache.iceberg.data.AppenderFactory.create(table)
                    .createAppender()
                    .append(record))
                .commit();
        } catch (Exception e) {
            throw new RuntimeException("Error saving entity", e);
        }
    }
    
    public void saveAll(List<T> entities) {
        Table table = getTable();
        Schema schema = table.schema();
        
        try {
            org.apache.iceberg.data.Appender<Record> appender = 
                org.apache.iceberg.data.AppenderFactory.create(table).createAppender();
            
            for (T entity : entities) {
                Record record = mapEntityToRecord(entity, schema);
                appender.append(record);
            }
            
            table.newAppend()
                .appendFile(appender)
                .commit();
        } catch (Exception e) {
            throw new RuntimeException("Error saving entities", e);
        }
    }
    
    public void delete(Object id) {
        Table table = getTable();
        
        try {
            table.newDelete()
                .deleteFromRowFilter(org.apache.iceberg.expressions.Expressions.equal(
                    table.schema().findField("id").name(), id))
                .commit();
        } catch (Exception e) {
            throw new RuntimeException("Error deleting entity", e);
        }
    }
}
```

### Step 4.2: Create Customer Repository

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/repository/CustomerRepository.java
package com.example.iceberg.repository;

import com.example.iceberg.model.Customer;
import org.apache.iceberg.Schema;
import org.apache.iceberg.data.GenericRecord;
import org.apache.iceberg.data.Record;
import org.apache.iceberg.types.Types;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Repository
public class CustomerRepository extends IcebergRepository<Customer> {
    
    @Override
    protected String getTableName() {
        return "customers";
    }
    
    @Override
    protected Schema getSchema() {
        return new Schema(
            Types.NestedField.required(0, "id", Types.IntegerType.get()),
            Types.NestedField.required(1, "name", Types.StringType.get()),
            Types.NestedField.required(2, "email", Types.StringType.get()),
            Types.NestedField.optional(3, "phone", Types.StringType.get()),
            Types.NestedField.optional(4, "address", Types.StringType.get()),
            Types.NestedField.optional(5, "created_at", Types.TimestampType.withoutZone()),
            Types.NestedField.optional(6, "updated_at", Types.TimestampType.withoutZone())
        );
    }
    
    @Override
    protected Customer mapRecordToEntity(Record record) {
        return Customer.builder()
            .id((Integer) record.get(0))
            .name((String) record.get(1))
            .email((String) record.get(2))
            .phone((String) record.get(3))
            .address((String) record.get(4))
            .createdAt(record.get(5) != null ? 
                LocalDateTime.ofEpochSecond((Long) record.get(5) / 1000, 0, ZoneOffset.UTC) : null)
            .updatedAt(record.get(6) != null ? 
                LocalDateTime.ofEpochSecond((Long) record.get(6) / 1000, 0, ZoneOffset.UTC) : null)
            .build();
    }
    
    @Override
    protected Record mapEntityToRecord(Customer entity, Schema schema) {
        GenericRecord record = GenericRecord.create(schema);
        record.set(0, entity.getId());
        record.set(1, entity.getName());
        record.set(2, entity.getEmail());
        record.set(3, entity.getPhone());
        record.set(4, entity.getAddress());
        record.set(5, entity.getCreatedAt() != null ? 
            entity.getCreatedAt().toEpochSecond(ZoneOffset.UTC) * 1000 : null);
        record.set(6, entity.getUpdatedAt() != null ? 
            entity.getUpdatedAt().toEpochSecond(ZoneOffset.UTC) * 1000 : null);
        return record;
    }
    
    public void initializeTable() {
        getOrCreateTable(getSchema());
    }
}
```

### Step 4.3: Create Product Repository

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/repository/ProductRepository.java
package com.example.iceberg.repository;

import com.example.iceberg.model.Product;
import org.apache.iceberg.Schema;
import org.apache.iceberg.data.GenericRecord;
import org.apache.iceberg.data.Record;
import org.apache.iceberg.types.Types;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Repository
public class ProductRepository extends IcebergRepository<Product> {
    
    @Override
    protected String getTableName() {
        return "products";
    }
    
    @Override
    protected Schema getSchema() {
        return new Schema(
            Types.NestedField.required(0, "id", Types.IntegerType.get()),
            Types.NestedField.required(1, "name", Types.StringType.get()),
            Types.NestedField.optional(2, "description", Types.StringType.get()),
            Types.NestedField.required(3, "price", Types.DecimalType.of(10, 2)),
            Types.NestedField.optional(4, "category", Types.StringType.get()),
            Types.NestedField.optional(5, "stock_quantity", Types.IntegerType.get()),
            Types.NestedField.optional(6, "created_at", Types.TimestampType.withoutZone()),
            Types.NestedField.optional(7, "updated_at", Types.TimestampType.withoutZone())
        );
    }
    
    @Override
    protected Product mapRecordToEntity(Record record) {
        return Product.builder()
            .id((Integer) record.get(0))
            .name((String) record.get(1))
            .description((String) record.get(2))
            .price(record.get(3) != null ? new BigDecimal(record.get(3).toString()) : null)
            .category((String) record.get(4))
            .stockQuantity((Integer) record.get(5))
            .createdAt(record.get(6) != null ? 
                LocalDateTime.ofEpochSecond((Long) record.get(6) / 1000, 0, ZoneOffset.UTC) : null)
            .updatedAt(record.get(7) != null ? 
                LocalDateTime.ofEpochSecond((Long) record.get(7) / 1000, 0, ZoneOffset.UTC) : null)
            .build();
    }
    
    @Override
    protected Record mapEntityToRecord(Product entity, Schema schema) {
        GenericRecord record = GenericRecord.create(schema);
        record.set(0, entity.getId());
        record.set(1, entity.getName());
        record.set(2, entity.getDescription());
        record.set(3, entity.getPrice() != null ? entity.getPrice().doubleValue() : null);
        record.set(4, entity.getCategory());
        record.set(5, entity.getStockQuantity());
        record.set(6, entity.getCreatedAt() != null ? 
            entity.getCreatedAt().toEpochSecond(ZoneOffset.UTC) * 1000 : null);
        record.set(7, entity.getUpdatedAt() != null ? 
            entity.getUpdatedAt().toEpochSecond(ZoneOffset.UTC) * 1000 : null);
        return record;
    }
    
    public void initializeTable() {
        getOrCreateTable(getSchema());
    }
}
```

## Part 5: Service Layer

### Step 5.1: Create Customer Service

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/service/CustomerService.java
package com.example.iceberg.service;

import com.example.iceberg.model.Customer;
import com.example.iceberg.repository.CustomerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class CustomerService {
    
    @Autowired
    private CustomerRepository customerRepository;
    
    public void initializeTable() {
        customerRepository.initializeTable();
    }
    
    public List<Customer> findAll() {
        return customerRepository.findAll();
    }
    
    public Customer findById(Integer id) {
        return customerRepository.findById(id);
    }
    
    public Customer create(Customer customer) {
        customer.setCreatedAt(LocalDateTime.now());
        customer.setUpdatedAt(LocalDateTime.now());
        customerRepository.save(customer);
        return customer;
    }
    
    public Customer update(Integer id, Customer customer) {
        Customer existing = customerRepository.findById(id);
        if (existing == null) {
            throw new RuntimeException("Customer not found with id: " + id);
        }
        
        existing.setName(customer.getName());
        existing.setEmail(customer.getEmail());
        existing.setPhone(customer.getPhone());
        existing.setAddress(customer.getAddress());
        existing.setUpdatedAt(LocalDateTime.now());
        
        customerRepository.save(existing);
        return existing;
    }
    
    public void delete(Integer id) {
        customerRepository.delete(id);
    }
}
```

### Step 5.2: Create Product Service

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/service/ProductService.java
package com.example.iceberg.service;

import com.example.iceberg.model.Product;
import com.example.iceberg.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class ProductService {
    
    @Autowired
    private ProductRepository productRepository;
    
    public void initializeTable() {
        productRepository.initializeTable();
    }
    
    public List<Product> findAll() {
        return productRepository.findAll();
    }
    
    public Product findById(Integer id) {
        return productRepository.findById(id);
    }
    
    public Product create(Product product) {
        product.setCreatedAt(LocalDateTime.now());
        product.setUpdatedAt(LocalDateTime.now());
        productRepository.save(product);
        return product;
    }
    
    public Product update(Integer id, Product product) {
        Product existing = productRepository.findById(id);
        if (existing == null) {
            throw new RuntimeException("Product not found with id: " + id);
        }
        
        existing.setName(product.getName());
        existing.setDescription(product.getDescription());
        existing.setPrice(product.getPrice());
        existing.setCategory(product.getCategory());
        existing.setStockQuantity(product.getStockQuantity());
        existing.setUpdatedAt(LocalDateTime.now());
        
        productRepository.save(existing);
        return existing;
    }
    
    public void delete(Integer id) {
        productRepository.delete(id);
    }
}
```

## Part 6: REST API Controllers

### Step 6.1: Create Customer Controller

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/controller/CustomerController.java
package com.example.iceberg.controller;

import com.example.iceberg.model.Customer;
import com.example.iceberg.service.CustomerService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {
    
    @Autowired
    private CustomerService customerService;
    
    @PostMapping("/initialize")
    public ResponseEntity<String> initializeTable() {
        customerService.initializeTable();
        return ResponseEntity.ok("Customer table initialized successfully");
    }
    
    @GetMapping
    public ResponseEntity<List<Customer>> findAll() {
        return ResponseEntity.ok(customerService.findAll());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Customer> findById(@PathVariable Integer id) {
        Customer customer = customerService.findById(id);
        if (customer == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(customer);
    }
    
    @PostMapping
    public ResponseEntity<Customer> create(@Valid @RequestBody Customer customer) {
        Customer created = customerService.create(customer);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Customer> update(@PathVariable Integer id, 
                                          @Valid @RequestBody Customer customer) {
        try {
            Customer updated = customerService.update(id, customer);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        customerService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

### Step 6.2: Create Product Controller

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/controller/ProductController.java
package com.example.iceberg.controller;

import com.example.iceberg.model.Product;
import com.example.iceberg.service.ProductService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    
    @Autowired
    private ProductService productService;
    
    @PostMapping("/initialize")
    public ResponseEntity<String> initializeTable() {
        productService.initializeTable();
        return ResponseEntity.ok("Product table initialized successfully");
    }
    
    @GetMapping
    public ResponseEntity<List<Product>> findAll() {
        return ResponseEntity.ok(productService.findAll());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Product> findById(@PathVariable Integer id) {
        Product product = productService.findById(id);
        if (product == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(product);
    }
    
    @PostMapping
    public ResponseEntity<Product> create(@Valid @RequestBody Product product) {
        Product created = productService.create(product);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Product> update(@PathVariable Integer id, 
                                         @Valid @RequestBody Product product) {
        try {
            Product updated = productService.update(id, product);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        productService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

## Part 7: Main Application

### Step 7.1: Create Main Application Class

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/IcebergSpringBootApplication.java
package com.example.iceberg;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class IcebergSpringBootApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(IcebergSpringBootApplication.class, args);
    }
}
```

## Part 8: Testing the Application

### Step 8.1: Build and Run the Application

```bash
cd iceberg-spring-boot
mvn clean install
mvn spring-boot:run
```

### Step 8.2: Test the API

Initialize tables:

```bash
curl -X POST http://localhost:8080/api/customers/initialize
curl -X POST http://localhost:8080/api/products/initialize
```

Create a customer:

```bash
curl -X POST http://localhost:8080/api/customers \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+1-555-0101",
    "address": "123 Main St, New York, NY 10001"
  }'
```

Create a product:

```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "name": "Laptop Pro 15\"",
    "description": "High-performance laptop with 16GB RAM and 512GB SSD",
    "price": 1299.99,
    "category": "Electronics",
    "stockQuantity": 50
  }'
```

Get all customers:

```bash
curl http://localhost:8080/api/customers
```

Get a specific customer:

```bash
curl http://localhost:8080/api/customers/1
```

Update a customer:

```bash
curl -X PUT http://localhost:8080/api/customers/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith",
    "email": "john.smith@example.com",
    "phone": "+1-555-0102",
    "address": "456 Oak Ave, Los Angeles, CA 90001"
  }'
```

Delete a customer:

```bash
curl -X DELETE http://localhost:8080/api/customers/1
```

## Part 9: Advanced Features

### Step 9.1: Add Caching

Add caching to improve performance:

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/config/CacheConfig.java
package com.example.iceberg.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableCaching
public class CacheConfig {
}
```

Update services with caching annotations:

```java
// In CustomerService.java
@Cacheable(value = "customers", key = "#id")
public Customer findById(Integer id) {
    return customerRepository.findById(id);
}

@CacheEvict(value = "customers", key = "#id")
public void delete(Integer id) {
    customerRepository.delete(id);
}

@CachePut(value = "customers", key = "#result.id")
public Customer update(Integer id, Customer customer) {
    // existing update logic
}
```

### Step 9.2: Add Exception Handling

Create global exception handler:

```java
// iceberg-spring-boot/src/main/java/com/example/iceberg/exception/GlobalExceptionHandler.java
package com.example.iceberg.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ErrorResponse> handleRuntimeException(RuntimeException ex) {
        ErrorResponse error = new ErrorResponse(
            LocalDateTime.now(),
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            "Internal Server Error",
            ex.getMessage()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ValidationErrorResponse> handleValidationException(
        MethodArgumentNotValidException ex) {
        
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        
        ValidationErrorResponse response = new ValidationErrorResponse(
            LocalDateTime.now(),
            HttpStatus.BAD_REQUEST.value(),
            "Validation Error",
            errors
        );
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }
    
    record ErrorResponse(
        LocalDateTime timestamp,
        int status,
        String error,
        String message
    ) {}
    
    record ValidationErrorResponse(
        LocalDateTime timestamp,
        int status,
        String error,
        Map<String, String> errors
    ) {}
}
```

## Cleanup

### Stop the Infrastructure

```bash
cd /home/ramdov/projects/iceberg-practice-env
docker-compose down
```

### Clean up the Spring Boot Application

```bash
cd iceberg-spring-boot
mvn clean
```

## Challenges

### Challenge 1: Add Order Management

Extend the application to include order management with order items, implementing relationships between customers, products, and orders.

### Challenge 2: Add Pagination and Filtering

Implement pagination and filtering for the list endpoints to handle large datasets efficiently.

### Challenge 3: Add Authentication and Authorization

Add Spring Security to implement authentication and authorization for the API endpoints.

### Challenge 4: Add Data Export

Add endpoints to export data in different formats (CSV, JSON, Parquet) directly from Iceberg tables.

## Verification

Verify your implementation:

1. Check that the Spring Boot application starts successfully
2. Verify that table initialization works correctly
3. Test CRUD operations through the REST API
4. Validate that data validation is working
5. Verify that error handling works correctly
6. Test caching performance improvements
7. Monitor application metrics through Actuator

## Next Steps

- Lab 11: Multi-Engine Lakehouse