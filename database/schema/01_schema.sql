-- ============================================================
-- SupplyChainIQ
-- Supply Chain & Inventory Analytics System
-- Database Schema
-- MySQL 8.0+
-- ============================================================

DROP DATABASE IF EXISTS supply_chain;

CREATE DATABASE supply_chain;

USE supply_chain;


-- ============================================================
-- 1. Categories
-- ============================================================

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);


-- ============================================================
-- 2. Suppliers
-- ============================================================

CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(150) NOT NULL,
    country VARCHAR(80),
    contact_email VARCHAR(150),
    contracted_lead_days INT NOT NULL DEFAULT 7,
    onboarded_date DATE NOT NULL
);


-- ============================================================
-- 3. Warehouses
-- ============================================================

CREATE TABLE warehouses (
    warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    capacity_units INT NOT NULL
);


-- ============================================================
-- 4. Products
-- ============================================================

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL,
    primary_supplier_id INT NOT NULL,
    is_component BOOLEAN NOT NULL DEFAULT FALSE,
    unit_cost DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (category_id)
        REFERENCES categories(category_id),

    FOREIGN KEY (primary_supplier_id)
        REFERENCES suppliers(supplier_id)
);


-- ============================================================
-- 5. Bill of Materials (BOM)
-- Self-referencing product hierarchy
-- ============================================================

CREATE TABLE product_components (
    bom_id INT AUTO_INCREMENT PRIMARY KEY,

    parent_product_id INT NOT NULL,
    component_product_id INT NOT NULL,

    quantity_required INT NOT NULL DEFAULT 1,

    FOREIGN KEY (parent_product_id)
        REFERENCES products(product_id),

    FOREIGN KEY (component_product_id)
        REFERENCES products(product_id),

    UNIQUE (parent_product_id, component_product_id)
);


-- ============================================================
-- 6. Inventory
-- Current stock for every product/warehouse combination
-- ============================================================

CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,

    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,

    quantity_on_hand INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL DEFAULT 10,
    reorder_quantity INT NOT NULL DEFAULT 50,

    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id),

    UNIQUE (product_id, warehouse_id)
);


-- ============================================================
-- 7. Inventory Snapshots
-- Historical inventory levels
-- ============================================================

CREATE TABLE inventory_snapshots (
    snapshot_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,

    snapshot_date DATE NOT NULL,
    quantity_on_hand INT NOT NULL,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id),

    UNIQUE (product_id, warehouse_id, snapshot_date)
);


-- ============================================================
-- 8. Purchase Orders
-- Orders placed with suppliers
-- ============================================================

CREATE TABLE purchase_orders (
    po_id INT AUTO_INCREMENT PRIMARY KEY,

    supplier_id INT NOT NULL,
    product_id INT NOT NULL,

    order_date DATE NOT NULL,
    expected_date DATE NOT NULL,
    received_date DATE,

    quantity_ordered INT NOT NULL,

    status ENUM(
        'PENDING',
        'RECEIVED',
        'CANCELLED'
    ) NOT NULL DEFAULT 'PENDING',

    FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);


-- ============================================================
-- 9. Customers
-- ============================================================

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,

    customer_name VARCHAR(150) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),

    customer_type ENUM(
        'RETAIL',
        'WHOLESALE'
    ) NOT NULL DEFAULT 'RETAIL'
);


-- ============================================================
-- 10. Customer Orders
-- ============================================================

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,

    customer_id INT NOT NULL,
    warehouse_id INT NOT NULL,

    order_date DATE NOT NULL,
    ship_date DATE,

    status ENUM(
        'PENDING',
        'SHIPPED',
        'CANCELLED'
    ) NOT NULL DEFAULT 'PENDING',

    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
);


-- ============================================================
-- 11. Order Items
-- Products contained in customer orders
-- ============================================================

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,

    order_id INT NOT NULL,
    product_id INT NOT NULL,

    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);


-- ============================================================
-- 12. Reorder Alerts
-- Automatically populated by inventory trigger
-- ============================================================

CREATE TABLE reorder_alerts (
    alert_id INT AUTO_INCREMENT PRIMARY KEY,

    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,

    quantity_on_hand INT NOT NULL,
    reorder_level INT NOT NULL,

    alert_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
);


-- ============================================================
-- Verify tables
-- ============================================================

SHOW TABLES;