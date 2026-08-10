# SupplyChainIQ

SupplyChainIQ is a MySQL-based supply chain and inventory analytics project.  
It models products, suppliers, warehouses, inventory, purchase orders, customers, and sales orders, and uses SQL to analyze the data and generate useful business insights.

## What this project does

The project focuses on questions such as:

- Which products generate the most revenue and profit?
- Which suppliers are reliable and deliver orders on time?
- Which products are running low on stock?
- Which warehouses perform better in order fulfillment?
- Which products are slow-moving?
- Which customer segment generates more revenue?
- How does revenue change over time?
- What is the component cost of a product?

## Tech Stack

- MySQL 8.0+
- MySQL Workbench
- SQL

## Database

The database contains tables for:

- Categories
- Suppliers
- Products
- Product Components
- Warehouses
- Inventory
- Inventory Snapshots
- Purchase Orders
- Customers
- Orders
- Order Items
- Reorder Alerts

The main relationships connect suppliers and categories to products, products to inventory and warehouses, and customers to orders and order items.

## SQL Concepts Used

This project uses:

- Joins
- Aggregations
- `GROUP BY`
- `CASE`
- CTEs
- Recursive CTEs
- Window functions
- `RANK()`
- `ROW_NUMBER()`
- Date functions
- Views
- Indexes
- Triggers
- Conditional aggregation

## Automation

A trigger is used to detect low inventory.

When the quantity of a product falls to or below its reorder level, a record is automatically added to the `reorder_alerts` table.

## Project Files

| File | Description |
|---|---|
| `01_schema.sql` | Creates the database and tables |
| `02_data.sql` | Data-loading script |
| `03_triggers.sql` | Inventory reorder trigger |
| `04_views.sql` | Analytical views |
| `05_indexes.sql` | Database indexes |
| `06_analysis.sql` | Business analysis queries |

## Analysis Included

The analysis covers:

- Product profitability
- Supplier performance
- Monthly revenue
- Product rankings
- Inventory and stockouts
- Warehouse fulfillment
- Slow-moving inventory
- Reorder requirements
- Customer segmentation
- BOM cost analysis

## Future Improvements

Some possible extensions are:

- Power BI dashboard
- Demand forecasting
- Safety-stock optimization
- Automated inventory reports
- Supplier performance dashboard
- Email alerts for critical inventory



B.Tech, Electronics & Communication Engineering  
VIT Vellore
