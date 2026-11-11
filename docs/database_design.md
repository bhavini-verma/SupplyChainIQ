# Database Design — SupplyChainIQ

## Design Principles

The `supply_chain` database is designed around **third normal form (3NF)** to minimise data redundancy while maintaining query performance through targeted indexing.

### Key Design Decisions

**1. Separated inventory current state from history**
`inventory` holds the live stock level (one row per product × warehouse). `inventory_snapshots` captures daily point-in-time levels for trend analysis. This separation allows fast current-stock lookups without loading historical data.

**2. Bill of Materials via self-referencing table**
`product_components` uses two foreign keys both pointing to `products`, enabling a recursive multi-level BOM. The Recursive CTE in `06_analysis.sql` traverses this hierarchy to calculate total component cost for any finished product.

**3. ENUM for status fields**
`purchase_orders.status` and `orders.status` use ENUMs (`PENDING`, `RECEIVED`/`SHIPPED`, `CANCELLED`) rather than a lookup table. This keeps queries readable and enforces valid values at the database level without an extra join.

**4. Trigger-driven reorder alerts**
Rather than querying inventory on every dashboard refresh, the `trg_inventory_low_stock` trigger writes an alert row to `reorder_alerts` only at the moment stock crosses below threshold. The transition condition (`OLD.quantity_on_hand > OLD.reorder_level` AND `NEW.quantity_on_hand <= NEW.reorder_level`) prevents duplicate alerts on repeated updates below threshold.

**5. unit_price captured in order_items**
Storing `unit_price` on each `order_item` (not just on `products`) is intentional — it records the price at the time of sale, allowing accurate historical revenue calculation even after a price change.

---

## Entity Relationship Summary

```
categories ──< products >── suppliers
                  │
         ┌────────┼────────┐
         │        │        │
   product_   inventory  order_
   components  (current)  items >── orders >── customers
         │        │                      │
         │   inventory_               warehouses
         │   snapshots
         │
   purchase_orders >── suppliers
         │
   reorder_alerts (auto-populated by trigger)
```

---

## Normalisation Notes

| Table | Normal Form | Notes |
|---|---|---|
| categories | 3NF | Simple lookup table |
| suppliers | 3NF | No transitive dependencies |
| warehouses | 3NF | City/state depend only on warehouse_id |
| products | 3NF | unit_cost and unit_price are product attributes |
| product_components | 3NF | Only quantity_required as a non-key attribute |
| inventory | 3NF | Quantities are warehouse+product specific |
| inventory_snapshots | 3NF | Snapshot_date creates a unique time dimension |
| purchase_orders | 3NF | received_date is nullable (optional event) |
| customers | 3NF | customer_type is a customer attribute |
| orders | 3NF | ship_date is nullable (event not yet occurred) |
| order_items | 3NF | unit_price is intentionally denormalised (historical price) |
| reorder_alerts | 3NF | Snapshot of inventory state at alert time |

---

## Index Strategy

| Index Name | Table | Columns | Purpose |
|---|---|---|---|
| PRIMARY | All tables | PK column | Row lookups |
| `idx_inventory_product_warehouse` | inventory | product_id, warehouse_id | Fast stock lookups |
| `idx_inventory_snapshots_product_date` | inventory_snapshots | product_id, snapshot_date | Rolling average queries |
| `idx_purchase_orders_supplier_date` | purchase_orders | supplier_id, order_date | Supplier performance analysis |
| `idx_orders_customer_date` | orders | customer_id, order_date | Customer history queries |
| `idx_orders_warehouse_date` | orders | warehouse_id, order_date | Warehouse fulfilment analysis |
| `idx_order_items_product` | order_items | product_id | Product sales aggregation |

---

## Referential Integrity Map

| Child Table | Column | References |
|---|---|---|
| products | category_id | categories.category_id |
| products | primary_supplier_id | suppliers.supplier_id |
| product_components | parent_product_id | products.product_id |
| product_components | component_product_id | products.product_id |
| inventory | product_id | products.product_id |
| inventory | warehouse_id | warehouses.warehouse_id |
| inventory_snapshots | product_id | products.product_id |
| inventory_snapshots | warehouse_id | warehouses.warehouse_id |
| purchase_orders | supplier_id | suppliers.supplier_id |
| purchase_orders | product_id | products.product_id |
| orders | customer_id | customers.customer_id |
| orders | warehouse_id | warehouses.warehouse_id |
| order_items | order_id | orders.order_id |
| order_items | product_id | products.product_id |
| reorder_alerts | product_id | products.product_id |
| reorder_alerts | warehouse_id | warehouses.warehouse_id |

