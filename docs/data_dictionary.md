# Data Dictionary — SupplyChainIQ

## Database: `supply_chain`
**Engine:** MySQL 8.0+ · InnoDB · utf8mb4

---

## Table: `categories`
Stores product category master data.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `category_id` | INT | PK, AUTO_INCREMENT | Unique category identifier |
| `category_name` | VARCHAR(100) | NOT NULL, UNIQUE | Category display name |

**Records:** 10 · **Example values:** Laptops, Monitors, Processors, Storage, Networking

---

## Table: `suppliers`
Stores supplier master data including contracted delivery lead times.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `supplier_id` | INT | PK, AUTO_INCREMENT | Unique supplier identifier |
| `supplier_name` | VARCHAR(150) | NOT NULL | Supplier company name |
| `country` | VARCHAR(80) | | Country of operation |
| `contact_email` | VARCHAR(150) | | Primary contact email |
| `contracted_lead_days` | INT | NOT NULL, DEFAULT 7 | Contracted delivery lead time in days |
| `onboarded_date` | DATE | NOT NULL | Date supplier was onboarded |

**Records:** 12

---

## Table: `warehouses`
Stores warehouse master data.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `warehouse_id` | INT | PK, AUTO_INCREMENT | Unique warehouse identifier |
| `warehouse_name` | VARCHAR(100) | NOT NULL | Warehouse display name |
| `city` | VARCHAR(100) | | City location |
| `state` | VARCHAR(100) | | State/region |
| `capacity_units` | INT | NOT NULL | Maximum storable units |

**Records:** 6

---

## Table: `products`
Stores product master data, including pricing and cost information.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `product_id` | INT | PK, AUTO_INCREMENT | Unique product identifier |
| `product_name` | VARCHAR(150) | NOT NULL | Product display name |
| `category_id` | INT | NOT NULL, FK → categories | Product category |
| `primary_supplier_id` | INT | NOT NULL, FK → suppliers | Default supplier for this product |
| `is_component` | BOOLEAN | NOT NULL, DEFAULT FALSE | TRUE if used as a BOM component |
| `unit_cost` | DECIMAL(10,2) | NOT NULL | Procurement cost per unit |
| `unit_price` | DECIMAL(10,2) | NOT NULL | Selling price per unit |

**Records:** 40 · **Note:** Products with `is_component = TRUE` appear in `product_components`

---

## Table: `product_components`
Bill of Materials (BOM) — self-referencing product hierarchy.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `bom_id` | INT | PK, AUTO_INCREMENT | Unique BOM entry |
| `parent_product_id` | INT | NOT NULL, FK → products | Finished product |
| `component_product_id` | INT | NOT NULL, FK → products | Component required |
| `quantity_required` | INT | NOT NULL, DEFAULT 1 | Units of component per parent unit |

**Records:** 31 · **Unique constraint:** (parent_product_id, component_product_id)

---

## Table: `inventory`
Current stock level for every product × warehouse combination.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `inventory_id` | INT | PK, AUTO_INCREMENT | Unique inventory record |
| `product_id` | INT | NOT NULL, FK → products | Product |
| `warehouse_id` | INT | NOT NULL, FK → warehouses | Warehouse |
| `quantity_on_hand` | INT | NOT NULL, DEFAULT 0 | Current stock level |
| `reorder_level` | INT | NOT NULL, DEFAULT 10 | Stock level that triggers reorder alert |
| `reorder_quantity` | INT | NOT NULL, DEFAULT 50 | Standard replenishment order quantity |
| `last_updated` | DATETIME | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Records:** 240 (40 products × 6 warehouses) · **Unique constraint:** (product_id, warehouse_id)

---

## Table: `inventory_snapshots`
Daily historical inventory levels — powers rolling average and stockout analysis.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `snapshot_id` | BIGINT | PK, AUTO_INCREMENT | Unique snapshot record |
| `product_id` | INT | NOT NULL, FK → products | Product |
| `warehouse_id` | INT | NOT NULL, FK → warehouses | Warehouse |
| `snapshot_date` | DATE | NOT NULL | Snapshot date |
| `quantity_on_hand` | INT | NOT NULL | Stock level on that date |

**Records:** 21,600 (40 × 6 × 90 days) · **Unique constraint:** (product_id, warehouse_id, snapshot_date)

---

## Table: `purchase_orders`
Orders placed with suppliers to replenish inventory.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `po_id` | INT | PK, AUTO_INCREMENT | Unique purchase order identifier |
| `supplier_id` | INT | NOT NULL, FK → suppliers | Supplying vendor |
| `product_id` | INT | NOT NULL, FK → products | Product ordered |
| `order_date` | DATE | NOT NULL | Date order was placed |
| `expected_date` | DATE | NOT NULL | Contracted delivery date |
| `received_date` | DATE | | Actual delivery date (NULL if not yet received) |
| `quantity_ordered` | INT | NOT NULL | Units ordered |
| `status` | ENUM | NOT NULL, DEFAULT 'PENDING' | PENDING / RECEIVED / CANCELLED |

**Records:** 536

---

## Table: `customers`
Customer master data with segmentation.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `customer_id` | INT | PK, AUTO_INCREMENT | Unique customer identifier |
| `customer_name` | VARCHAR(150) | NOT NULL | Customer display name |
| `city` | VARCHAR(100) | | City |
| `state` | VARCHAR(100) | | State/region |
| `customer_type` | ENUM | NOT NULL, DEFAULT 'RETAIL' | RETAIL / WHOLESALE |

**Records:** 1,000 · **Cities covered:** Bangalore, Delhi, Mumbai, Hyderabad, Pune, Kolkata, Ahmedabad, Jaipur, Lucknow, Chennai

---

## Table: `orders`
Customer sales orders.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `order_id` | INT | PK, AUTO_INCREMENT | Unique order identifier |
| `customer_id` | INT | NOT NULL, FK → customers | Customer who placed order |
| `warehouse_id` | INT | NOT NULL, FK → warehouses | Fulfilling warehouse |
| `order_date` | DATE | NOT NULL | Date order was placed |
| `ship_date` | DATE | | Date order was shipped (NULL if pending) |
| `status` | ENUM | NOT NULL, DEFAULT 'PENDING' | PENDING / SHIPPED / CANCELLED |

**Records:** 3,000

---

## Table: `order_items`
Individual line items within customer orders.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `order_item_id` | INT | PK, AUTO_INCREMENT | Unique line item identifier |
| `order_id` | INT | NOT NULL, FK → orders | Parent order |
| `product_id` | INT | NOT NULL, FK → products | Product sold |
| `quantity` | INT | NOT NULL | Units sold |
| `unit_price` | DECIMAL(10,2) | NOT NULL | Selling price at time of order |

**Records:** 5,100

---

## Table: `reorder_alerts`
Automatically populated by the `trg_inventory_low_stock` trigger when stock falls to or below reorder level.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `alert_id` | INT | PK, AUTO_INCREMENT | Unique alert identifier |
| `product_id` | INT | NOT NULL, FK → products | Product requiring reorder |
| `warehouse_id` | INT | NOT NULL, FK → warehouses | Affected warehouse |
| `quantity_on_hand` | INT | NOT NULL | Stock level when alert triggered |
| `reorder_level` | INT | NOT NULL | Reorder threshold at time of alert |
| `alert_date` | DATETIME | NOT NULL, DEFAULT NOW() | Timestamp when alert was generated |

**Records:** 2 (populated automatically; grows as inventory is updated)

---

## Views

### `product_sales_summary`
Aggregates revenue, COGS, and gross profit per product across all SHIPPED orders.

| Column | Description |
|---|---|
| `product_id` | Product identifier |
| `product_name` | Product name |
| `units_sold` | Total units sold (SHIPPED orders only) |
| `revenue` | Total revenue (quantity × unit_price) |
| `cogs` | Cost of goods sold (quantity × unit_cost) |
| `gross_profit` | Revenue minus COGS |

### `warehouse_inventory_status`
Shows current stock levels across all product × warehouse combinations with a REORDER / SUFFICIENT status flag.

| Column | Description |
|---|---|
| `product_id` | Product identifier |
| `product_name` | Product name |
| `warehouse_id` | Warehouse identifier |
| `warehouse_name` | Warehouse name |
| `quantity_on_hand` | Current stock level |
| `reorder_level` | Configured reorder threshold |
| `reorder_quantity` | Standard replenishment quantity |
| `inventory_status` | REORDER (at or below threshold) / SUFFICIENT |

