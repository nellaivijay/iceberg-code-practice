-- CDC Source Database Initialization Script
-- This script creates sample tables for CDC demonstrations

-- Enable binary logging for CDC
SET GLOBAL binlog_format = 'ROW';
SET GLOBAL binlog_row_image = 'FULL';

-- Create customers table
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(100),
    stock_quantity INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_price (price)
) ENGINE=InnoDB;

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    shipping_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_customer_id (customer_id),
    INDEX idx_order_date (order_date),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB;

-- Create inventory_events table (for tracking inventory changes)
CREATE TABLE IF NOT EXISTS inventory_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    quantity_change INT NOT NULL,
    previous_quantity INT,
    new_quantity INT,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_event_timestamp (event_timestamp)
) ENGINE=InnoDB;

-- Create customer_reviews table
CREATE TABLE IF NOT EXISTS customer_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_purchase BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_rating (rating),
    INDEX idx_review_date (review_date)
) ENGINE=InnoDB;

-- Insert sample data for CDC demonstrations
INSERT INTO customers (name, email, phone, address) VALUES
('John Doe', 'john.doe@example.com', '+1-555-0101', '123 Main St, New York, NY 10001'),
('Jane Smith', 'jane.smith@example.com', '+1-555-0102', '456 Oak Ave, Los Angeles, CA 90001'),
('Bob Johnson', 'bob.johnson@example.com', '+1-555-0103', '789 Pine Rd, Chicago, IL 60601'),
('Alice Williams', 'alice.williams@example.com', '+1-555-0104', '321 Elm St, Houston, TX 77001'),
('Charlie Brown', 'charlie.brown@example.com', '+1-555-0105', '654 Maple Dr, Phoenix, AZ 85001');

INSERT INTO products (name, description, price, category, stock_quantity) VALUES
('Laptop Pro 15"', 'High-performance laptop with 16GB RAM and 512GB SSD', 1299.99, 'Electronics', 50),
('Wireless Mouse', 'Ergonomic wireless mouse with precision tracking', 29.99, 'Electronics', 200),
('Mechanical Keyboard', 'RGB mechanical keyboard with Cherry MX switches', 149.99, 'Electronics', 100),
('USB-C Hub', '7-in-1 USB-C hub with HDMI, USB 3.0, and SD card reader', 49.99, 'Electronics', 150),
('Monitor 27" 4K', 'Ultra HD monitor with HDR support', 399.99, 'Electronics', 75);

INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_address) VALUES
(1, NOW() - INTERVAL 1 DAY, 'completed', 1329.98, '123 Main St, New York, NY 10001'),
(2, NOW() - INTERVAL 2 DAY, 'processing', 179.98, '456 Oak Ave, Los Angeles, CA 90001'),
(3, NOW() - INTERVAL 3 DAY, 'shipped', 549.97, '789 Pine Rd, Chicago, IL 60601'),
(4, NOW() - INTERVAL 4 DAY, 'delivered', 449.98, '321 Elm St, Houston, TX 77001'),
(5, NOW() - INTERVAL 5 DAY, 'pending', 1299.99, '654 Maple Dr, Phoenix, AZ 85001');

INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES
(1, 1, 1, 1299.99, 1299.99),
(1, 2, 1, 29.99, 29.99),
(2, 3, 1, 149.99, 149.99),
(2, 2, 1, 29.99, 29.99),
(3, 1, 1, 1299.99, 1299.99),
(3, 5, 1, 399.99, 399.99),
(3, 3, 1, 149.99, 149.99),
(4, 5, 1, 399.99, 399.99),
(4, 4, 1, 49.99, 49.99),
(5, 1, 1, 1299.99, 1299.99);

INSERT INTO inventory_events (product_id, event_type, quantity_change, previous_quantity, new_quantity, reason) VALUES
(1, 'restock', 50, 0, 50, 'Initial stock'),
(2, 'restock', 200, 0, 200, 'Initial stock'),
(3, 'restock', 100, 0, 100, 'Initial stock'),
(4, 'restock', 150, 0, 150, 'Initial stock'),
(5, 'restock', 75, 0, 75, 'Initial stock'),
(1, 'sale', -1, 50, 49, 'Order #1'),
(2, 'sale', -1, 200, 199, 'Order #1'),
(3, 'sale', -1, 100, 99, 'Order #2'),
(2, 'sale', -1, 199, 198, 'Order #2'),
(1, 'sale', -1, 49, 48, 'Order #3');

INSERT INTO customer_reviews (customer_id, product_id, rating, review_text, verified_purchase) VALUES
(1, 1, 5, 'Excellent laptop! Fast and reliable.', TRUE),
(2, 3, 4, 'Great keyboard, but the RGB could be brighter.', TRUE),
(3, 1, 5, 'Best laptop I have ever owned.', TRUE),
(4, 5, 4, 'Beautiful display, good color accuracy.', TRUE),
(5, 2, 5, 'Perfect mouse for productivity.', FALSE);

-- Create a Debezium user for CDC (optional, if using specific authentication)
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'dbz';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

-- Display summary
SELECT 'CDC Source Database Initialization Complete' AS status;
SELECT COUNT(*) AS customer_count FROM customers;
SELECT COUNT(*) AS product_count FROM products;
SELECT COUNT(*) AS order_count FROM orders;
SELECT COUNT(*) AS order_item_count FROM order_items;
SELECT COUNT(*) AS inventory_event_count FROM inventory_events;
SELECT COUNT(*) AS review_count FROM customer_reviews;