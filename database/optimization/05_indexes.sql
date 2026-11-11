-- ============================================================
-- SupplyChainIQ
-- Database Indexes
-- ============================================================

USE supply_chain;


-- Inventory lookups by product and warehouse
CREATE INDEX idx_inventory_product_warehouse
ON inventory(product_id, warehouse_id);


-- Historical inventory analysis
CREATE INDEX idx_inventory_snapshots_product_date
ON inventory_snapshots(product_id, snapshot_date);


-- Supplier purchase-order analysis
CREATE INDEX idx_purchase_orders_supplier_date
ON purchase_orders(supplier_id, order_date);


-- Customer order history
CREATE INDEX idx_orders_customer_date
ON orders(customer_id, order_date);


-- Warehouse order analysis
CREATE INDEX idx_orders_warehouse_date
ON orders(warehouse_id, order_date);


-- Product sales analysis
CREATE INDEX idx_order_items_product
ON order_items(product_id);