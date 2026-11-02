USE Olist_Ecommerce_Analytics;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

/* Full staging-to-core refresh. Review data-quality outputs first.
   If an insert fails, the transaction rolls back the entire refresh. */
IF EXISTS (SELECT 1 FROM staging.olist_customers WHERE customer_id IS NULL OR customer_unique_id IS NULL OR customer_zip_code_prefix IS NULL OR customer_city IS NULL OR customer_state IS NULL)
    THROW 51000, 'Required customer fields are null.', 1;
IF EXISTS (SELECT 1 FROM staging.olist_orders WHERE order_id IS NULL OR customer_id IS NULL OR order_status IS NULL OR order_purchase_timestamp IS NULL OR order_estimated_delivery_date IS NULL)
    THROW 51001, 'Required order fields are null.', 1;
IF EXISTS (SELECT 1 FROM staging.olist_order_items WHERE order_id IS NULL OR order_item_id IS NULL OR product_id IS NULL OR seller_id IS NULL OR shipping_limit_date IS NULL OR price IS NULL OR freight_value IS NULL)
    THROW 51002, 'Required order-item fields are null.', 1;
IF EXISTS (SELECT 1 FROM staging.olist_order_payments WHERE order_id IS NULL OR payment_sequential IS NULL OR payment_type IS NULL OR payment_installments IS NULL OR payment_value IS NULL)
    THROW 51003, 'Required payment fields are null.', 1;
IF EXISTS (SELECT 1 FROM staging.olist_order_reviews WHERE review_id IS NULL OR order_id IS NULL OR review_score IS NULL OR review_score NOT BETWEEN 1 AND 5)
    THROW 51004, 'Review keys or scores are invalid.', 1;
IF EXISTS (SELECT customer_id FROM staging.olist_customers GROUP BY customer_id HAVING COUNT(*) > 1)
    THROW 51005, 'Duplicate customer_id values found.', 1;
IF EXISTS (SELECT order_id FROM staging.olist_orders GROUP BY order_id HAVING COUNT(*) > 1)
    THROW 51006, 'Duplicate order_id values found.', 1;
IF EXISTS (SELECT product_id FROM staging.olist_products GROUP BY product_id HAVING COUNT(*) > 1)
    THROW 51007, 'Duplicate product_id values found.', 1;
IF EXISTS (SELECT seller_id FROM staging.olist_sellers GROUP BY seller_id HAVING COUNT(*) > 1)
    THROW 51008, 'Duplicate seller_id values found.', 1;
IF EXISTS (SELECT order_id, order_item_id FROM staging.olist_order_items GROUP BY order_id, order_item_id HAVING COUNT(*) > 1)
    THROW 51009, 'Duplicate order/item keys found.', 1;
IF EXISTS (SELECT order_id, payment_sequential FROM staging.olist_order_payments GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1)
    THROW 51010, 'Duplicate order/payment keys found.', 1;
IF EXISTS (SELECT product_category_name FROM staging.product_category_translation GROUP BY product_category_name HAVING COUNT(*) > 1)
    THROW 51011, 'Duplicate category translation keys found.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM core.OrderReviews;
    DELETE FROM core.OrderPayments;
    DELETE FROM core.OrderItems;
    DELETE FROM core.Orders;
    DELETE FROM core.Products;
    DELETE FROM core.Sellers;
    DELETE FROM core.Customers;
    DELETE FROM core.ProductCategoryTranslation;
    DELETE FROM core.Geolocation;

    INSERT INTO core.Customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
    SELECT customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state FROM staging.olist_customers;
    INSERT INTO core.Products (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
    SELECT product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm FROM staging.olist_products;
    INSERT INTO core.Sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state)
    SELECT seller_id, seller_zip_code_prefix, seller_city, seller_state FROM staging.olist_sellers;
    INSERT INTO core.ProductCategoryTranslation (product_category_name, product_category_name_english)
    SELECT product_category_name, product_category_name_english FROM staging.product_category_translation;
    INSERT INTO core.Orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
    SELECT order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date FROM staging.olist_orders;
    INSERT INTO core.OrderItems (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
    SELECT order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value FROM staging.olist_order_items;
    INSERT INTO core.OrderPayments (order_id, payment_sequential, payment_type, payment_installments, payment_value)
    SELECT order_id, payment_sequential, payment_type, payment_installments, payment_value FROM staging.olist_order_payments;
    INSERT INTO core.OrderReviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
    SELECT review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp FROM staging.olist_order_reviews;
    INSERT INTO core.Geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
    SELECT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state FROM staging.olist_geolocation;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT 'customers' AS table_name, COUNT_BIG(*) AS row_count FROM core.Customers
UNION ALL SELECT 'orders', COUNT_BIG(*) FROM core.Orders
UNION ALL SELECT 'order_items', COUNT_BIG(*) FROM core.OrderItems
UNION ALL SELECT 'order_payments', COUNT_BIG(*) FROM core.OrderPayments
UNION ALL SELECT 'order_reviews', COUNT_BIG(*) FROM core.OrderReviews;
GO