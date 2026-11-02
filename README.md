# Olist E-Commerce Analytics

An end-to-end SQL Server analytics project using the Brazilian E-Commerce Public Dataset by Olist. The workflow loads CSVs into staging, validates source quality, promotes data into a relational core, then builds reusable views and business analyses.

> **Current scope:** the repository contains T-SQL scripts and documentation. Python preparation, dashboards, and raw CSV files are not currently tracked.

## Questions explored

- What are delivered-order sales, product revenue, freight, and monthly trends?
- Which product categories and sellers contribute most to marketplace revenue?
- How often do customers return, measured at `customer_unique_id` grain?
- How does retention change across first-purchase-month cohorts?
- How do delivery timing and customer review scores vary together?

## Metric rules

- **Customer identity:** `customer_unique_id` represents the customer across order-level `customer_id` records.
- **Product revenue:** item price only; freight is separate.
- **Gross order value:** item price plus freight.
- **AOV:** product-only AOV and gross AOV are separate; divide each by distinct delivered orders.
- **Sales scope:** sales and customer views use delivered orders. The delivery view retains other statuses to show unfulfilled orders.
- **Cohort:** first delivered purchase month, based on purchase timestamp. Retention counts customers with a delivered purchase in each observed month.
- **Reviews:** average duplicate review rows to order grain before joining them to item- or category-grain metrics.

Re-run the SQL against the local dataset before publishing figures. Narrative values in old script comments are not a substitute for reproducible output.

## Layout

```text
sql/
  01_database/       database, staging/core tables, constraint audit, indexes
  02_data_loading/   CSV bulk load and staging-to-core refresh
  03_data_quality/   row counts, duplicates, nulls, relationships
  04_business_analysis/
  05_advanced_analytics/
  06_views/
```

Raw CSVs are downloaded separately and are excluded from Git.

## Run locally

Prerequisites: SQL Server 2017 or later, SSMS, the Olist CSV files, and SQL Server service-account read access to the CSV folder (BULK INSERT reads server-side).

1. Run `sql/01_database/01_create_database.sql` once.
2. Run `sql/01_database/02_create_tables.sql`.
3. Set the local CSV paths in `sql/02_data_loading/01_bulk_insert.sql` and load the staging tables.
4. Run `sql/03_data_quality/` scripts and review the results.
5. Run `sql/02_data_loading/02_load_core_from_staging.sql`. This transactionally replaces core rows from validated staging data.
6. Run `sql/01_database/03_constraints.sql` to inspect inline constraints, then `04_indexes.sql`.
7. Run `sql/06_views/view_creation_for_business_analysis.sql`.
8. Run the scripts in `sql/04_business_analysis/` and `sql/05_advanced_analytics/`.

The database and table-creation scripts target a clean database; they are not migrations.

## Limitations

- The dataset covers a historical period (2016–2018); findings describe that sample and window.
- Delivery and review comparisons are descriptive associations, not causal estimates.
- Customer and review identifiers require explicit grain handling.
- Downloading, Python preparation, orchestration, and automated SQL validation are not yet included.

## Author

**Subhadeep Panda** · Data Analytics portfolio · SQL Server / T-SQL