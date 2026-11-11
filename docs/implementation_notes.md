# Implementation Notes — SupplyChainIQ

## Project Timeline

| Phase | Description |
|---|---|
| Design | Schema design — 12 tables, relationships, constraints |
| Implementation | SQL scripts written and executed in MySQL Workbench |
| Data Population | Dataset seeded into the `supply_chain` database |
| Analytics | 12 business analysis queries implemented |
| Objects | Trigger, 2 views, 6 indexes created and tested |
| Documentation | Repository organised and documented |

---

## Implementation Decisions

### Why MySQL 8.0?
MySQL 8.0 introduced native window functions (`ROW_NUMBER`, `RANK`, `LAG`, `LEAD`, rolling frames) and full support for Recursive CTEs. These are required for Queries #3–#6 and #12. Earlier versions would require procedural workarounds.

### Why InnoDB?
InnoDB is required for:
- Foreign key enforcement
- Row-level locking (safe concurrent updates to inventory)
- ACID-compliant transactions
- Trigger execution with transactional context

### Trigger design — transition condition
The `trg_inventory_low_stock` trigger uses a crossing condition:
```sql
IF NEW.quantity_on_hand <= NEW.reorder_level
   AND OLD.quantity_on_hand > OLD.reorder_level
```
This fires only when stock *transitions* from above-threshold to at-or-below, not on every update while already low. This prevents flooding `reorder_alerts` with duplicate rows on repeated inventory deductions.

### Inventory snapshots — 90-day window
The `inventory_snapshots` table stores 90 days of daily history (21,600 rows = 40 products × 6 warehouses × 90 days). This window is sufficient to:
- Compute 7-day rolling averages (Query #6)
- Calculate meaningful stockout percentages (Query #7)
- Support seasonal trend observation

### unit_price stored on order_items
The `order_items` table stores `unit_price` at the time of sale. This is intentional — it allows accurate historical revenue reporting even after product price changes. Without this, retroactively updating prices would corrupt all historical revenue figures.

---

## Known Limitations

| Limitation | Impact | Potential Improvement |
|---|---|---|
| No multi-item purchase orders | Each PO covers one product | Add `purchase_order_items` table |
| No lot/batch tracking | Cannot trace a specific batch through the warehouse | Add batch_id to inventory_movements |
| No shipping carrier data | Cannot measure carrier-level performance | Add carrier lookup and tracking number |
| No returns/refunds | Revenue is gross only | Add `order_returns` table |
| No user authentication | No concept of who made inventory changes | Add `users` table with audit log |
| No real-time event streaming | Inventory is updated manually or via trigger | Could integrate with warehouse management system |

---

## Execution Order

The scripts must be run in this order to satisfy foreign key dependencies:

```
01_schema.sql        → Creates database and all 12 tables
02_seed_data.sql     → Populates all tables with data
03_triggers.sql      → Creates trg_inventory_low_stock
04_views.sql         → Creates product_sales_summary, warehouse_inventory_status
05_indexes.sql       → Creates 6 performance indexes
06_analysis.sql      → Business analysis queries (run individually)
07_query_optimization.sql  → EXPLAIN analysis (optional, informational)
08_validation_tests.sql    → Integrity checks (run after all above)
```

> ⚠️ `01_schema.sql` contains `DROP DATABASE IF EXISTS supply_chain` — running it on a populated database will erase all data. Use `02_seed_data.sql` alone to restore data without recreating the schema.

