# Business Questions & Analytical Queries — SupplyChainIQ

All queries are located in [`database/analytics/06_analysis.sql`](../database/analytics/06_analysis.sql).

---

## Product & Sales Analytics

### Q1 — Which products generate the highest revenue and gross profit?
**Query #1 — Product Profitability**
Calculates revenue, COGS, gross profit, and profit margin per product across all SHIPPED orders.
- **SQL techniques:** Multi-table JOIN, GROUP BY, ROUND(), NULLIF() for safe division
- **Business value:** Identifies which products to prioritise and which may need price review

### Q2 — What are the monthly revenue trends, and what is the cumulative revenue to date?
**Query #4 — Monthly Revenue + Running Total**
Groups revenue by calendar month and computes a running cumulative total.
- **SQL techniques:** `DATE_FORMAT()`, CTE, `SUM() OVER (ORDER BY sales_month)` window function
- **Business value:** Reveals growth trends and seasonal patterns; running total shows trajectory toward annual targets

### Q3 — Which product is the top seller each month?
**Query #5 — Top Product Per Month**
Identifies the single highest-revenue product for each month.
- **SQL techniques:** Multi-level CTE, `ROW_NUMBER() OVER (PARTITION BY sales_month ORDER BY revenue DESC)` window function
- **Business value:** Tracks changing demand patterns and informs promotional planning

---

## Inventory Analytics

### Q4 — Which products are below their reorder threshold right now?
**Query #10 — Reorder Requirements**
Filters the inventory table for all product × warehouse combinations at or below `reorder_level`.
- **SQL techniques:** Filtered JOIN, computed column (`reorder_level - quantity_on_hand`)
- **Business value:** Directly actionable — procurement team can place orders immediately

### Q5 — What is the 7-day rolling average inventory level per product and warehouse?
**Query #6 — 7-Day Rolling Inventory Average**
Uses the `inventory_snapshots` table to compute a 7-day moving average of stock levels.
- **SQL techniques:** `AVG() OVER (PARTITION BY product_id, warehouse_id ORDER BY snapshot_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` window function
- **Business value:** Smooths out daily volatility to reveal underlying inventory trends

### Q6 — Which products experience stockouts, and how often?
**Query #7 — Stockout Analysis**
Counts snapshot days where `quantity_on_hand = 0` and calculates a stockout percentage.
- **SQL techniques:** Conditional aggregation with `CASE/WHEN`, percentage calculation
- **Business value:** Highlights chronic stockout risks that cause lost sales

### Q7 — Which products are slow-moving relative to their inventory level?
**Query #9 — Slow-Moving Inventory**
Computes an inventory-to-sales ratio (average inventory ÷ units sold). High ratios indicate slow movers.
- **SQL techniques:** Multi-CTE, `COALESCE()` to handle zero-sales products, `NULLIF()` for safe division
- **Business value:** Identifies overstock situations and candidates for clearance or discontinuation

---

## Supplier Analytics

### Q8 — Which suppliers have the best on-time delivery performance?
**Query #2 — Supplier Reliability**
Computes on-time delivery percentage using `received_date` vs `expected_date`.
- **SQL techniques:** LEFT JOIN, `CASE/WHEN` conditional aggregation, NULLIF()
- **Business value:** Quantifies supplier reliability — critical for SLA reviews and supplier renegotiation

### Q9 — How do suppliers rank overall?
**Query #3 — Supplier Ranking**
Ranks all suppliers by on-time delivery percentage.
- **SQL techniques:** CTE + `RANK() OVER (ORDER BY on_time_percentage DESC)` window function
- **Business value:** Single-view supplier scorecard for procurement leadership

---

## Warehouse Analytics

### Q10 — How does each warehouse perform on order fulfilment speed?
**Query #8 — Warehouse Fulfillment Performance**
Calculates average, fastest, and slowest fulfilment times (days from order_date to ship_date) per warehouse.
- **SQL techniques:** `DATEDIFF()`, MIN/MAX/AVG aggregation, filtered JOIN
- **Business value:** Highlights operational differences between warehouses; identifies bottlenecks

---

## Customer Analytics

### Q11 — How do RETAIL and WHOLESALE customers differ in purchasing behaviour?
**Query #11 — Customer Segmentation**
Groups orders by `customer_type`, showing total customers, orders, units, revenue, and average order value.
- **SQL techniques:** Three-table JOIN, multi-dimension GROUP BY, `COUNT(DISTINCT)`, average order value calculation
- **Business value:** Guides pricing strategy and account management focus

---

## Bill of Materials

### Q12 — What is the total component cost for a finished product?
**Query #12 — BOM Cost Explosion**
Traverses the product component hierarchy recursively to sum up all component costs.
- **SQL techniques:** `WITH RECURSIVE` CTE — the most advanced query in the project
- **Business value:** Determines true manufacturing cost by rolling up multi-level component prices; essential for accurate margin calculation on assembled products

