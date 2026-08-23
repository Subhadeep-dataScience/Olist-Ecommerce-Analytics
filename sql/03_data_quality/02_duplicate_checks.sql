--Check duplicate business keys

--Check duplicates for customer_id from customer table
SELECT
    customer_id,
    COUNT(*) AS DuplicateCount
FROM staging.olist_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


--Check duplicates for order_id from order table
SELECT
    order_id,
    COUNT(*) AS DuplicateCount
FROM staging.olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1;


--Check duplicates for product_id from products table
SELECT
    product_id,
    COUNT(*) AS DuplicateCount
FROM staging.olist_products
GROUP BY product_id
HAVING COUNT(*) > 1;


--Check duplicates for seller_id from sellers table
SELECT
    seller_id,
    COUNT(*) AS DuplicateCount
FROM staging.olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


--Check duplicates for order_id and order_item_id from order_items table
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS DuplicateCount
FROM staging.olist_order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;


--Check duplicates for order_id and payment_sequential from order_payments table
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS DuplicateCount
FROM staging.olist_order_payments
GROUP BY
    order_id,
    payment_sequential
HAVING COUNT(*) > 1;


--Check duplicates for seller_id from sellers table
SELECT
    review_id,
    COUNT(*) AS DuplicateCount
FROM staging.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;
