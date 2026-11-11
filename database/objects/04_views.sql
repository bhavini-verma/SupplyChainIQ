-- ============================================================
-- SupplyChainIQ
-- Reusable Analytical Views
-- ============================================================

USE supply_chain;


-- ============================================================
-- View 1: Product Sales & Profitability
-- ============================================================

CREATE OR REPLACE VIEW product_sales_summary AS

SELECT
    p.product_id,
    p.product_name,

    SUM(oi.quantity) AS units_sold,

    ROUND(
        SUM(oi.quantity * oi.unit_price),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.quantity * p.unit_cost),
        2
    ) AS cogs,

    ROUND(
        SUM(oi.quantity * oi.unit_price)
        -
        SUM(oi.quantity * p.unit_cost),
        2
    ) AS gross_profit

FROM products p

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.status = 'SHIPPED'

GROUP BY
    p.product_id,
    p.product_name;


-- ============================================================
-- View 2: Warehouse Inventory Status
-- ============================================================

CREATE OR REPLACE VIEW warehouse_inventory_status AS

SELECT
    p.product_id,
    p.product_name,

    w.warehouse_id,
    w.warehouse_name,

    i.quantity_on_hand,
    i.reorder_level,
    i.reorder_quantity,

    CASE
        WHEN i.quantity_on_hand <= i.reorder_level
            THEN 'REORDER'
        ELSE 'SUFFICIENT'
    END AS inventory_status

FROM inventory i

JOIN products p
    ON i.product_id = p.product_id

JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id;