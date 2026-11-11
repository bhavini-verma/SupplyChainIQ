-- ============================================================
-- SupplyChainIQ
-- Key Business Analysis Queries
-- MySQL 8.0+
-- ============================================================

USE supply_chain;


-- ============================================================
-- 1. PRODUCT PROFITABILITY
-- Revenue, COGS, Gross Profit and Margin
-- ============================================================

SELECT
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
    ) AS gross_profit,

    ROUND(
        100 * (
            SUM(oi.quantity * oi.unit_price)
            -
            SUM(oi.quantity * p.unit_cost)
        )
        /
        NULLIF(
            SUM(oi.quantity * oi.unit_price),
            0
        ),
        2
    ) AS profit_margin

FROM order_items oi

JOIN orders o
    ON oi.order_id = o.order_id

JOIN products p
    ON oi.product_id = p.product_id

WHERE o.status = 'SHIPPED'

GROUP BY
    p.product_id,
    p.product_name

ORDER BY gross_profit DESC;


-- ============================================================
-- 2. SUPPLIER RELIABILITY
-- On-time delivery percentage
-- ============================================================

SELECT
    s.supplier_name,

    COUNT(po.po_id) AS total_orders,

    SUM(
        CASE
            WHEN po.received_date IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS received_orders,

    SUM(
        CASE
            WHEN po.received_date IS NOT NULL
             AND po.received_date <= po.expected_date
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,

    ROUND(
        100 *
        SUM(
            CASE
                WHEN po.received_date IS NOT NULL
                 AND po.received_date <= po.expected_date
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN po.received_date IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS on_time_percentage

FROM suppliers s

LEFT JOIN purchase_orders po
    ON s.supplier_id = po.supplier_id

GROUP BY
    s.supplier_id,
    s.supplier_name

ORDER BY on_time_percentage DESC;


-- ============================================================
-- 3. SUPPLIER RANKING
-- Window Function: RANK()
-- ============================================================

WITH supplier_performance AS (

    SELECT
        s.supplier_id,
        s.supplier_name,

        ROUND(
            100 *
            SUM(
                CASE
                    WHEN po.received_date IS NOT NULL
                     AND po.received_date <= po.expected_date
                    THEN 1
                    ELSE 0
                END
            )
            /
            NULLIF(
                SUM(
                    CASE
                        WHEN po.received_date IS NOT NULL
                        THEN 1
                        ELSE 0
                    END
                ),
                0
            ),
            2
        ) AS on_time_percentage

    FROM suppliers s

    LEFT JOIN purchase_orders po
        ON s.supplier_id = po.supplier_id

    GROUP BY
        s.supplier_id,
        s.supplier_name
)

SELECT
    supplier_name,
    on_time_percentage,

    RANK() OVER (
        ORDER BY on_time_percentage DESC
    ) AS supplier_rank

FROM supplier_performance

ORDER BY supplier_rank;


-- ============================================================
-- 4. MONTHLY REVENUE + RUNNING TOTAL
-- Window Function: SUM() OVER()
-- ============================================================

WITH monthly_sales AS (

    SELECT
        DATE_FORMAT(
            o.order_date,
            '%Y-%m'
        ) AS sales_month,

        SUM(
            oi.quantity * oi.unit_price
        ) AS monthly_revenue

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.status = 'SHIPPED'

    GROUP BY
        DATE_FORMAT(
            o.order_date,
            '%Y-%m'
        )
)

SELECT
    sales_month,

    ROUND(
        monthly_revenue,
        2
    ) AS monthly_revenue,

    ROUND(
        SUM(monthly_revenue) OVER (
            ORDER BY sales_month
        ),
        2
    ) AS running_revenue

FROM monthly_sales

ORDER BY sales_month;


-- ============================================================
-- 5. TOP PRODUCT PER MONTH
-- Window Function: ROW_NUMBER()
-- ============================================================

WITH monthly_product_sales AS (

    SELECT
        DATE_FORMAT(
            o.order_date,
            '%Y-%m'
        ) AS sales_month,

        p.product_id,
        p.product_name,

        SUM(
            oi.quantity * oi.unit_price
        ) AS revenue

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN products p
        ON oi.product_id = p.product_id

    WHERE o.status = 'SHIPPED'

    GROUP BY
        DATE_FORMAT(
            o.order_date,
            '%Y-%m'
        ),
        p.product_id,
        p.product_name
),

ranked_products AS (

    SELECT
        sales_month,
        product_name,
        revenue,

        ROW_NUMBER() OVER (
            PARTITION BY sales_month
            ORDER BY revenue DESC
        ) AS product_rank

    FROM monthly_product_sales
)

SELECT
    sales_month,
    product_name,
    ROUND(revenue, 2) AS revenue

FROM ranked_products

WHERE product_rank = 1

ORDER BY sales_month;


-- ============================================================
-- 6. 7-DAY ROLLING INVENTORY AVERAGE
-- Window Function: AVG() OVER()
-- ============================================================

WITH inventory_with_average AS (

    SELECT
        product_id,
        warehouse_id,
        snapshot_date,
        quantity_on_hand,

        AVG(quantity_on_hand) OVER (
            PARTITION BY
                product_id,
                warehouse_id

            ORDER BY snapshot_date

            ROWS BETWEEN
                6 PRECEDING
                AND CURRENT ROW
        ) AS seven_day_average

    FROM inventory_snapshots
)

SELECT
    p.product_name,
    w.warehouse_name,
    i.snapshot_date,
    i.quantity_on_hand,

    ROUND(
        i.seven_day_average,
        2
    ) AS seven_day_average

FROM inventory_with_average i

JOIN products p
    ON i.product_id = p.product_id

JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id

ORDER BY
    p.product_id,
    w.warehouse_id,
    i.snapshot_date

LIMIT 100;


-- ============================================================
-- 7. STOCKOUT ANALYSIS
-- ============================================================

SELECT
    p.product_name,
    w.warehouse_name,

    SUM(
        CASE
            WHEN i.quantity_on_hand = 0
            THEN 1
            ELSE 0
        END
    ) AS stockout_days,

    COUNT(*) AS total_snapshot_days,

    ROUND(
        100 *
        SUM(
            CASE
                WHEN i.quantity_on_hand = 0
                THEN 1
                ELSE 0
            END
        )
        /
        COUNT(*),
        2
    ) AS stockout_percentage

FROM inventory_snapshots i

JOIN products p
    ON i.product_id = p.product_id

JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id

GROUP BY
    p.product_id,
    w.warehouse_id

ORDER BY stockout_percentage DESC;


-- ============================================================
-- 8. WAREHOUSE FULFILLMENT PERFORMANCE
-- ============================================================

SELECT
    w.warehouse_name,

    COUNT(o.order_id) AS shipped_orders,

    ROUND(
        AVG(
            DATEDIFF(
                o.ship_date,
                o.order_date
            )
        ),
        2
    ) AS avg_fulfillment_days,

    MIN(
        DATEDIFF(
            o.ship_date,
            o.order_date
        )
    ) AS fastest_fulfillment_days,

    MAX(
        DATEDIFF(
            o.ship_date,
            o.order_date
        )
    ) AS slowest_fulfillment_days

FROM orders o

JOIN warehouses w
    ON o.warehouse_id = w.warehouse_id

WHERE o.status = 'SHIPPED'
  AND o.ship_date IS NOT NULL

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY avg_fulfillment_days;


-- ============================================================
-- 9. SLOW-MOVING INVENTORY
-- ============================================================

WITH sales AS (

    SELECT
        oi.product_id,
        SUM(oi.quantity) AS units_sold

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.status = 'SHIPPED'

    GROUP BY oi.product_id
),

inventory_average AS (

    SELECT
        product_id,
        AVG(quantity_on_hand) AS avg_inventory

    FROM inventory_snapshots

    GROUP BY product_id
)

SELECT
    p.product_name,

    ROUND(
        ia.avg_inventory,
        2
    ) AS avg_inventory,

    COALESCE(
        s.units_sold,
        0
    ) AS units_sold,

    ROUND(
        ia.avg_inventory /
        NULLIF(s.units_sold, 0),
        2
    ) AS inventory_to_sales_ratio

FROM products p

JOIN inventory_average ia
    ON p.product_id = ia.product_id

LEFT JOIN sales s
    ON p.product_id = s.product_id

ORDER BY inventory_to_sales_ratio DESC;


-- ============================================================
-- 10. REORDER REQUIREMENTS
-- ============================================================

SELECT
    p.product_name,
    w.warehouse_name,

    i.quantity_on_hand,
    i.reorder_level,
    i.reorder_quantity,

    (
        i.reorder_level
        - i.quantity_on_hand
    ) AS units_below_threshold

FROM inventory i

JOIN products p
    ON i.product_id = p.product_id

JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id

WHERE i.quantity_on_hand <= i.reorder_level

ORDER BY units_below_threshold DESC;


-- ============================================================
-- 11. CUSTOMER SEGMENTATION
-- ============================================================

SELECT
    c.customer_type,

    COUNT(DISTINCT c.customer_id)
        AS total_customers,

    COUNT(DISTINCT o.order_id)
        AS total_orders,

    SUM(oi.quantity)
        AS units_purchased,

    ROUND(
        SUM(
            oi.quantity * oi.unit_price
        ),
        2
    ) AS total_revenue,

    ROUND(
        SUM(
            oi.quantity * oi.unit_price
        )
        /
        NULLIF(
            COUNT(DISTINCT o.order_id),
            0
        ),
        2
    ) AS average_order_value

FROM customers c

JOIN orders o
    ON c.customer_id = o.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.status = 'SHIPPED'

GROUP BY c.customer_type

ORDER BY total_revenue DESC;


-- ============================================================
-- 12. BOM COST EXPLOSION
-- Recursive CTE
-- ============================================================

WITH RECURSIVE bom_tree AS (

    -- Anchor: direct components
    SELECT
        pc.parent_product_id,
        pc.component_product_id,
        pc.quantity_required,
        1 AS bom_level

    FROM product_components pc

    WHERE pc.parent_product_id = 1

    UNION ALL

    -- Recursive: lower-level components
    SELECT
        bt.parent_product_id,
        pc.component_product_id,

        bt.quantity_required
        * pc.quantity_required,

        bt.bom_level + 1

    FROM bom_tree bt

    JOIN product_components pc
        ON bt.component_product_id
        = pc.parent_product_id
)

SELECT
    parent.product_name AS finished_product,

    ROUND(
        SUM(
            bt.quantity_required
            * component.unit_cost
        ),
        2
    ) AS total_component_cost

FROM bom_tree bt

JOIN products component
    ON bt.component_product_id
    = component.product_id

JOIN products parent
    ON bt.parent_product_id
    = parent.product_id

GROUP BY
    parent.product_id,
    parent.product_name;