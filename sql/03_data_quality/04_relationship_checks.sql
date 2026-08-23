--Check relationships

    --Orders without customers
    SELECT COUNT(*) AS OrdersWithoutCustomer
FROM staging.olist_orders o
LEFT JOIN staging.olist_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

    --Order items without orders
    SELECT COUNT(*) AS ItemsWithoutOrder
FROM staging.olist_order_items oi
LEFT JOIN staging.olist_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

    --Order items without products
    SELECT COUNT(*) AS ItemsWithoutProduct
FROM staging.olist_order_items oi
LEFT JOIN staging.olist_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

    --Order items without sellers
    SELECT COUNT(*) AS ItemsWithoutSeller
FROM staging.olist_order_items oi
LEFT JOIN staging.olist_sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

--customer_id , customer_unique_id segmentation
SELECT
    COUNT(*) AS TotalCustomerRows,
    COUNT(DISTINCT customer_id) AS UniqueCustomerIDs,
    COUNT(DISTINCT customer_unique_id) AS UniqueCustomerUniqueIDs
FROM staging.olist_customers;

--Check unique_customer_id count
SELECT
    COUNT(*) AS TotalCustomerRows,
    COUNT(DISTINCT customer_id) AS UniqueCustomerIDs,
    COUNT(DISTINCT customer_unique_id) AS UniqueCustomerUniqueIDs
FROM staging.olist_customers;

--Check wheather all reviews given by customer has ordered any item or not
SELECT
    COUNT(*) AS TotalReviewRows,
    COUNT(DISTINCT review_id) AS UniqueReviewIDs,
    COUNT(DISTINCT order_id) AS OrdersWithReviews
FROM staging.olist_order_reviews;
