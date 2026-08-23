--Row-count validation
--instead of counting rows individually we can run one validation quarry that count rows from each table
SELECT 'customers' AS TableName, COUNT(*) AS Row_Count
FROM staging.olist_customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM staging.olist_orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM staging.olist_order_items

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM staging.olist_order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM staging.olist_order_reviews

UNION ALL

SELECT 'products', COUNT(*)
FROM staging.olist_products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM staging.olist_sellers

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM staging.olist_geolocation

UNION ALL

SELECT 'category_translation', COUNT(*)
FROM staging.product_category_translation;
