# Olist E-Commerce Analytics

An end-to-end SQL Server analytics project using the Brazilian E-Commerce Public Dataset by Olist. The workflow loads CSVs into staging, validates source quality, promotes data into a relational core, then builds reusable views and business analyses.

> **Current scope:** the repository contains SQL Server analytics and a standard-library Python CSV preparation and validation tool. Raw CSV files and dashboards are not tracked.

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
- **Reviews:** record-level distributions are labeled as records. Delivery and state comparisons first average multiple review rows to one order-level score.
- **Payments:** payment analysis includes delivered orders only. A delivered order may use multiple payment records or methods, so method order shares are non-exclusive.

Re-run the SQL against the local dataset before publishing figures. Narrative values in old script comments are not a substitute for reproducible output.

## Layout

```text
sql/
python/
  prepare_olist.py    CSV validation, normalization, and manifest generation
  tests/              standard-library unit tests
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

Prerequisites: Python 3.10+, SQL Server 2017 or later, SSMS, the nine Olist CSV files, and SQL Server service-account read access to the prepared CSV folder (BULK INSERT reads server-side).

1. Run `sql/01_database/01_create_database.sql` once, then `02_create_tables.sql`.
2. Download and extract the nine original CSVs into `data/raw/` (the script does not download data).
3. Run `python python/prepare_olist.py --input data/raw --output data/processed/sql_server`. It checks required columns and values, duplicate primary/composite keys, review-score bounds, and key relationships. It preserves source rows and writes normalized UTF-8/LF CSVs plus `manifest.json` with row counts and SHA-256 hashes only when validation passes.
4. In `sql/02_data_loading/01_bulk_insert.sql`, replace the `C:\\path\\to\\Olist-Ecommerce-Analytics` placeholder with the absolute local repository path. Confirm the SQL Server service account can read `data/processed/sql_server/`, then load staging tables.
5. Run `sql/03_data_quality/` scripts and review the results.
6. Run `sql/02_data_loading/02_load_core_from_staging.sql`. This transactionally replaces core rows from validated staging data.
7. Run `sql/01_database/03_constraints.sql` to inspect inline constraints, then `04_indexes.sql`.
8. Run `sql/06_views/view_creation_for_business_analysis.sql`.
9. Run the scripts in `sql/04_business_analysis/` and `sql/05_advanced_analytics/`.

The database and table-creation scripts target a clean database; they are not migrations.

## Limitations

- The dataset covers a historical period (2016–2018); findings describe that sample and window.
- Delivery and review comparisons are descriptive associations, not causal estimates.
- Customer and review identifiers require explicit grain handling.
- Dataset download, orchestration, dashboards, and SQL Server integration tests are not included. Python validation runs in GitHub Actions; T-SQL still needs a local SQL Server run against the source CSVs.

## Author

**Subhadeep Panda** · Data Analytics portfolio · SQL Server / T-SQL