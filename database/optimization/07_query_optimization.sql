-- ============================================================
-- SupplyChainIQ
-- Query Optimisation Analysis
-- MySQL 8.0+
-- ============================================================

USE supply_chain;


-- ============================================================
-- INDEX STRATEGY OVERVIEW
-- ============================================================
-- The following indexes are defined in 05_indexes.sql.
-- This file documents the rationale and verifies them
-- using EXPLAIN.
-- ============================================================


-- ============================================================
-- OPT-1: Inventory Lookup Without Index vs With Index
-- Table: inventory
-- Index: idx_inventory_product_warehouse (product_id, warehouse_id)
-- ============================================================

-- Without the composite index, a full table scan (type=ALL)
-- would be required for every product+warehouse lookup.
-- The composite UNIQUE key doubles as a covering index here.

EXPLAIN
SELECT quantity_on_hand, reorder_level
FROM inventory
WHERE product_id = 5
  AND warehouse_id = 3;

-- Expected: type=const or ref, key=inventory.product_id (UNIQUE)
-- Rows examined: 1 (index seek, not table scan)


-- ============================================================
-- OPT-2: Supplier Purchase Order Analysis
-- Table: purchase_orders
-- Index: idx_purchase_orders_supplier_date (supplier_id, order_date)
-- ============================================================

EXPLAIN
SELECT
    supplier_id,
    COUNT(*)               AS total_orders,
    MIN(order_date)        AS first_order,
    MAX(order_date)        AS last_order
FROM purchase_orders
WHERE supplier_id = 3
  AND order_date >= '2026-06-01'
GROUP BY supplier_id;

-- Without index: full scan of 536 rows every time.
-- With composite index: range scan on (supplier_id, order_date) —
-- MySQL reads only the matching supplier's date range.


-- ============================================================
-- OPT-3: Customer Order History
-- Table: orders
-- Index: idx_orders_customer_date (customer_id, order_date)
-- ============================================================

EXPLAIN
SELECT order_id, order_date, status
FROM orders
WHERE customer_id = 42
ORDER BY order_date DESC;

-- Index allows both the WHERE filter and the ORDER BY
-- to be resolved using a single index scan (no filesort).


-- ============================================================
-- OPT-4: Snapshot Rolling Average
-- Table: inventory_snapshots
-- Index: idx_inventory_snapshots_product_date (product_id, snapshot_date)
-- ============================================================

-- This query drives Analysis #6 (7-day rolling average).
-- 21,600 snapshot rows; without an index, every execution
-- requires a full table scan for each partition window.

EXPLAIN
SELECT product_id, warehouse_id, snapshot_date, quantity_on_hand
FROM inventory_snapshots
WHERE product_id = 1
ORDER BY snapshot_date;

-- With the composite index, MySQL uses a range scan on
-- product_id=1, then reads snapshot_date in order — no sort.


-- ============================================================
-- OPT-5: Product Sales Join
-- Table: order_items
-- Index: idx_order_items_product (product_id)
-- ============================================================

EXPLAIN
SELECT
    oi.product_id,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'SHIPPED'
GROUP BY oi.product_id;

-- The index on order_items(product_id) supports both
-- the GROUP BY and the join lookup.


-- ============================================================
-- OPT-6: Show All Indexes on Key Tables
-- ============================================================

SHOW INDEX FROM inventory;
SHOW INDEX FROM inventory_snapshots;
SHOW INDEX FROM purchase_orders;
SHOW INDEX FROM orders;
SHOW INDEX FROM order_items;

