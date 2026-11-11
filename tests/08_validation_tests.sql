-- ============================================================
-- SupplyChainIQ
-- Validation and Integrity Tests
-- MySQL 8.0+
-- Run after all scripts to verify correctness.
-- ============================================================

USE supply_chain;


-- ============================================================
-- TEST 1: Row Counts (Baseline Verification)
-- ============================================================

SELECT 'categories'          AS tbl, COUNT(*) AS row_count FROM categories
UNION ALL SELECT 'suppliers',          COUNT(*) FROM suppliers
UNION ALL SELECT 'warehouses',         COUNT(*) FROM warehouses
UNION ALL SELECT 'products',           COUNT(*) FROM products
UNION ALL SELECT 'product_components', COUNT(*) FROM product_components
UNION ALL SELECT 'inventory',          COUNT(*) FROM inventory
UNION ALL SELECT 'inventory_snapshots',COUNT(*) FROM inventory_snapshots
UNION ALL SELECT 'purchase_orders',    COUNT(*) FROM purchase_orders
UNION ALL SELECT 'customers',          COUNT(*) FROM customers
UNION ALL SELECT 'orders',             COUNT(*) FROM orders
UNION ALL SELECT 'order_items',        COUNT(*) FROM order_items
UNION ALL SELECT 'reorder_alerts',     COUNT(*) FROM reorder_alerts;

-- Expected: matches documented record counts


-- ============================================================
-- TEST 2: Referential Integrity — No Orphaned Order Items
-- ============================================================

SELECT COUNT(*) AS orphaned_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Expected: 0


-- ============================================================
-- TEST 3: Referential Integrity — No Orphaned Inventory
-- ============================================================

SELECT COUNT(*) AS orphaned_inventory_rows
FROM inventory i
LEFT JOIN products p ON i.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Expected: 0


-- ============================================================
-- TEST 4: Business Rule — unit_price >= unit_cost
-- ============================================================

SELECT
    product_id,
    product_name,
    unit_cost,
    unit_price
FROM products
WHERE unit_price < unit_cost;

-- Expected: 0 rows (no product sold below cost)


-- ============================================================
-- TEST 5: Inventory Coverage
-- Every product should have inventory in every warehouse
-- (product_count * warehouse_count rows expected = 40 * 6 = 240)
-- ============================================================

SELECT
    COUNT(*)                                       AS total_inventory_rows,
    (SELECT COUNT(*) FROM products)
    * (SELECT COUNT(*) FROM warehouses)            AS expected_rows,
    COUNT(*) = (SELECT COUNT(*) FROM products)
              * (SELECT COUNT(*) FROM warehouses)  AS is_complete
FROM inventory;

-- Expected: total_inventory_rows = 240, is_complete = 1


-- ============================================================
-- TEST 6: Trigger Verification
-- Reorder alerts should exist for products at or below reorder level
-- ============================================================

SELECT COUNT(*) AS alert_count FROM reorder_alerts;

-- Expected: > 0 (trigger has fired)


-- ============================================================
-- TEST 7: Snapshot Completeness
-- 21,600 snapshots = 40 products * 6 warehouses * 90 days
-- ============================================================

SELECT
    COUNT(*)                             AS total_snapshots,
    COUNT(DISTINCT product_id)           AS distinct_products,
    COUNT(DISTINCT warehouse_id)         AS distinct_warehouses,
    COUNT(DISTINCT snapshot_date)        AS distinct_dates,
    MIN(snapshot_date)                   AS earliest_date,
    MAX(snapshot_date)                   AS latest_date
FROM inventory_snapshots;

-- Expected: 21600 total, 40 products, 6 warehouses, 90 dates


-- ============================================================
-- TEST 8: View Accessibility
-- ============================================================

SELECT COUNT(*) AS product_sales_summary_rows  FROM product_sales_summary;
SELECT COUNT(*) AS warehouse_inventory_rows     FROM warehouse_inventory_status;

-- Expected: > 0 rows in both views


-- ============================================================
-- TEST 9: BOM Integrity — No Self-Reference
-- ============================================================

SELECT COUNT(*) AS self_referencing_bom
FROM product_components
WHERE parent_product_id = component_product_id;

-- Expected: 0


-- ============================================================
-- TEST 10: Purchase Order Status Distribution
-- ============================================================

SELECT
    status,
    COUNT(*) AS order_count
FROM purchase_orders
GROUP BY status
ORDER BY order_count DESC;

-- Expected: Shows PENDING, RECEIVED, CANCELLED with valid counts

