#!/usr/bin/env python3
"""
Generate sample business data for the Iceberg practice environment.
Creates realistic e-commerce data including customers, products, orders, and transactions.
"""

import csv
import random
import os
from datetime import datetime, timedelta
from pathlib import Path

# Configuration
PROJECT_DIR = Path(__file__).parent.parent.absolute()
SAMPLE_DIR = PROJECT_DIR / "data" / "sample"
NUM_CUSTOMERS = 1000
NUM_PRODUCTS = 200
NUM_ORDERS = 5000
NUM_TRANSACTIONS = 10000
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2024, 12, 31)

# Sample data
FIRST_NAMES = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", 
               "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
               "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa"]
LAST_NAMES = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
              "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
              "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White"]
REGIONS = ["north", "south", "east", "west"]
CITIES = {
    "north": ["Seattle", "Portland", "Minneapolis", "Chicago"],
    "south": ["Austin", "Dallas", "Houston", "Atlanta"],
    "east": ["New York", "Boston", "Philadelphia", "Washington DC"],
    "west": ["San Francisco", "Los Angeles", "San Diego", "Phoenix"]
}
SEGMENTS = ["premium", "standard", "bronze"]

PRODUCT_CATEGORIES = ["Electronics", "Clothing", "Home", "Sports", "Books", "Beauty"]
PRODUCT_BRANDS = ["TechBrand", "ComfortBrand", "HomeStyle", "SportPro", "BookWorld", "BeautyPlus"]
TRANSACTION_TYPES = ["purchase", "refund", "exchange"]
PAYMENT_METHODS = ["credit_card", "debit_card", "paypal", "apple_pay", "google_pay"]

def random_date(start, end):
    """Generate a random date between start and end."""
    return start + timedelta(days=random.randint(0, (end - start).days))

def generate_customers():
    """Generate customer data."""
    customers = []
    for i in range(1, NUM_CUSTOMERS + 1):
        customer = {
            "customer_id": i,
            "customer_name": f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
            "customer_email": f"customer{i}@example.com",
            "region": random.choice(REGIONS),
            "city": random.choice(CITIES[random.choice(REGIONS)]),
            "segment": random.choice(SEGMENTS),
            "signup_date": random_date(START_DATE, END_DATE - timedelta(days=365)).strftime("%Y-%m-%d"),
            "total_purchases": random.randint(1, 100),
            "total_spent": round(random.uniform(100.0, 10000.0), 2)
        }
        customers.append(customer)
    return customers

def generate_products():
    """Generate product data."""
    products = []
    for i in range(1, NUM_PRODUCTS + 1):
        category = random.choice(PRODUCT_CATEGORIES)
        products.append({
            "product_id": i,
            "product_name": f"{category} Product {i}",
            "category": category,
            "subcategory": f"{category} Subcategory {random.randint(1, 5)}",
            "brand": random.choice(PRODUCT_BRANDS),
            "unit_price": round(random.uniform(10.0, 500.0), 2),
            "weight": round(random.uniform(0.5, 10.0), 2),
            "dimensions": f"{random.randint(5, 50)}x{random.randint(5, 50)}x{random.randint(5, 50)}"
        })
    return products

def generate_orders(customers, products):
    """Generate order data."""
    orders = []
    for i in range(1, NUM_ORDERS + 1):
        customer = random.choice(customers)
        product = random.choice(products)
        order_date = random_date(START_DATE, END_DATE)
        quantity = random.randint(1, 10)
        
        orders.append({
            "order_id": i,
            "customer_id": customer["customer_id"],
            "product_id": product["product_id"],
            "order_date": order_date.strftime("%Y-%m-%d"),
            "quantity": quantity,
            "unit_price": product["unit_price"],
            "total_amount": round(product["unit_price"] * quantity, 2),
            "status": random.choice(["pending", "shipped", "delivered", "cancelled", "returned"]),
            "region": customer["region"],
            "salesperson_id": random.randint(1, 20)
        })
    return orders

def generate_transactions(orders):
    """Generate transaction data."""
    transactions = []
    for i in range(1, NUM_TRANSACTIONS + 1):
        order = random.choice(orders)
        transaction_date = random_date(
            datetime.strptime(order["order_date"], "%Y-%m-%d"),
            END_DATE
        )
        
        transactions.append({
            "transaction_id": f"txn{i:06d}",
            "order_id": order["order_id"],
            "customer_id": order["customer_id"],
            "transaction_date": transaction_date.strftime("%Y-%m-%d %H:%M:%S"),
            "transaction_type": random.choice(TRANSACTION_TYPES),
            "amount": round(order["total_amount"] * random.uniform(0.8, 1.2), 2),
            "payment_method": random.choice(PAYMENT_METHODS),
            "merchant": random.choice(["Amazon", "eBay", "Walmart", "Target", "Best Buy"])
        })
    return transactions

def generate_events(customers):
    """Generate web event data."""
    events = []
    event_types = ["pageview", "click", "login", "purchase", "add_to_cart", "search"]
    
    for i in range(1, 20000):
        customer = random.choice(customers)
        event_date = random_date(START_DATE, END_DATE)
        
        events.append({
            "event_id": f"evt{i:06d}",
            "user_id": customer["customer_id"],
            "event_timestamp": event_date.strftime("%Y-%m-%d %H:%M:%S"),
            "event_type": random.choice(event_types),
            "page_url": f"/{random.choice(['home', 'products', 'cart', 'checkout', 'profile'])}",
            "session_id": f"session_{random.randint(1, 5000)}",
            "region": customer["region"]
        })
    return events

def write_csv(data, filename):
    """Write data to CSV file."""
    filepath = SAMPLE_DIR / filename
    with open(filepath, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)
    print(f"Created {filename} with {len(data)} records")

def main():
    """Generate all sample data files."""
    SAMPLE_DIR.mkdir(parents=True, exist_ok=True)
    
    print("Generating sample data...")
    
    # Generate customers
    customers = generate_customers()
    write_csv(customers, "customers.csv")
    
    # Generate products
    products = generate_products()
    write_csv(products, "products.csv")
    
    # Generate orders
    orders = generate_orders(customers, products)
    write_csv(orders, "orders.csv")
    
    # Generate transactions
    transactions = generate_transactions(orders)
    write_csv(transactions, "transactions.csv")
    
    # Generate events
    events = generate_events(customers)
    write_csv(events, "events.csv")
    
    print(f"\nSample data generation complete!")
    print(f"Data directory: {SAMPLE_DIR}")
    print(f"Files created: {len(list(SAMPLE_DIR.glob('*.csv')))}")

if __name__ == "__main__":
    main()