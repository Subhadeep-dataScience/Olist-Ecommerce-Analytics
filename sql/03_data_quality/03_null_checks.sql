--NULL analysis for orders
SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS Missing_Order_ID,

    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS Missing_Customer_ID,

    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS Missing_Order_Status,

    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS Missing_Purchase_Date,

    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS Missing_Approval_Date,

    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS Missing_Carrier_Date,

    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS Missing_Delivery_Date,

    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS Missing_Estimated_Date

FROM staging.olist_orders;


--null analysis for Customers
SELECT
    COUNT(*) AS TotalRows,

    COUNT(customer_id) AS customer_id_NonNull,
    COUNT(*) - COUNT(customer_id) AS customer_id_Null,

    COUNT(customer_unique_id) AS customer_unique_id_NonNull,
    COUNT(*) - COUNT(customer_unique_id) AS customer_unique_id_Null,

    COUNT(customer_zip_code_prefix) AS customer_zip_code_prefix_NonNull,
    COUNT(*) - COUNT(customer_zip_code_prefix) AS customer_zip_code_prefix_Null,

    COUNT(customer_city) AS customer_city_NonNull,
    COUNT(*) - COUNT(customer_city) AS customer_city_Null,

    COUNT(customer_state) AS customer_state_NonNull,
    COUNT(*) - COUNT(customer_state) AS customer_state_Null

FROM staging.olist_customers;

--null analysis for Order Items
SELECT
    COUNT(*) AS TotalRows,

    COUNT(order_id) AS order_id_NonNull,
    COUNT(*) - COUNT(order_id) AS order_id_Null,

    COUNT(order_item_id) AS order_item_id_NonNull,
    COUNT(*) - COUNT(order_item_id) AS order_item_id_Null,

    COUNT(product_id) AS product_id_NonNull,
    COUNT(*) - COUNT(product_id) AS product_id_Null,

    COUNT(seller_id) AS seller_id_NonNull,
    COUNT(*) - COUNT(seller_id) AS seller_id_Null,

    COUNT(shipping_limit_date) AS shipping_limit_date_NonNull,
    COUNT(*) - COUNT(shipping_limit_date) AS shipping_limit_date_Null,

    COUNT(price) AS price_NonNull,
    COUNT(*) - COUNT(price) AS price_Null,

    COUNT(freight_value) AS freight_value_NonNull,
    COUNT(*) - COUNT(freight_value) AS freight_value_Null

FROM staging.olist_order_items;


--null analysis for Order Payments
SELECT
    COUNT(*) AS TotalRows,

    COUNT(order_id) AS order_id_NonNull,
    COUNT(*) - COUNT(order_id) AS order_id_Null,

    COUNT(payment_sequential) AS payment_sequential_NonNull,
    COUNT(*) - COUNT(payment_sequential) AS payment_sequential_Null,

    COUNT(payment_type) AS payment_type_NonNull,
    COUNT(*) - COUNT(payment_type) AS payment_type_Null,

    COUNT(payment_installments) AS payment_installments_NonNull,
    COUNT(*) - COUNT(payment_installments) AS payment_installments_Null,

    COUNT(payment_value) AS payment_value_NonNull,
    COUNT(*) - COUNT(payment_value) AS payment_value_Null

FROM staging.olist_order_payments;

--null analysis for Order Reviews
SELECT
    COUNT(*) AS TotalRows,

    COUNT(review_id) AS review_id_NonNull,
    COUNT(*) - COUNT(review_id) AS review_id_Null,

    COUNT(order_id) AS order_id_NonNull,
    COUNT(*) - COUNT(order_id) AS order_id_Null,

    COUNT(review_score) AS review_score_NonNull,
    COUNT(*) - COUNT(review_score) AS review_score_Null,

    COUNT(review_comment_title) AS review_comment_title_NonNull,
    COUNT(*) - COUNT(review_comment_title) AS review_comment_title_Null,

    COUNT(review_comment_message) AS review_comment_message_NonNull,
    COUNT(*) - COUNT(review_comment_message) AS review_comment_message_Null,

    COUNT(review_creation_date) AS review_creation_date_NonNull,
    COUNT(*) - COUNT(review_creation_date) AS review_creation_date_Null,

    COUNT(review_answer_timestamp) AS review_answer_timestamp_NonNull,
    COUNT(*) - COUNT(review_answer_timestamp) AS review_answer_timestamp_Null

FROM staging.olist_order_reviews;

--null analysis for Products
SELECT
    COUNT(*) AS TotalRows,

    COUNT(product_id) AS product_id_NonNull,
    COUNT(*) - COUNT(product_id) AS product_id_Null,

    COUNT(product_category_name) AS product_category_name_NonNull,
    COUNT(*) - COUNT(product_category_name) AS product_category_name_Null,

    COUNT(product_name_lenght) AS product_name_lenght_NonNull,
    COUNT(*) - COUNT(product_name_lenght) AS product_name_lenght_Null,

    COUNT(product_description_lenght) AS product_description_lenght_NonNull,
    COUNT(*) - COUNT(product_description_lenght) AS product_description_lenght_Null,

    COUNT(product_photos_qty) AS product_photos_qty_NonNull,
    COUNT(*) - COUNT(product_photos_qty) AS product_photos_qty_Null,

    COUNT(product_weight_g) AS product_weight_g_NonNull,
    COUNT(*) - COUNT(product_weight_g) AS product_weight_g_Null,

    COUNT(product_length_cm) AS product_length_cm_NonNull,
    COUNT(*) - COUNT(product_length_cm) AS product_length_cm_Null,

    COUNT(product_height_cm) AS product_height_cm_NonNull,
    COUNT(*) - COUNT(product_height_cm) AS product_height_cm_Null,

    COUNT(product_width_cm) AS product_width_cm_NonNull,
    COUNT(*) - COUNT(product_width_cm) AS product_width_cm_Null

FROM staging.olist_products;

--null analysis for Sellers
SELECT
    COUNT(*) AS TotalRows,

    COUNT(seller_id) AS seller_id_NonNull,
    COUNT(*) - COUNT(seller_id) AS seller_id_Null,

    COUNT(seller_zip_code_prefix) AS seller_zip_code_prefix_NonNull,
    COUNT(*) - COUNT(seller_zip_code_prefix) AS seller_zip_code_prefix_Null,

    COUNT(seller_city) AS seller_city_NonNull,
    COUNT(*) - COUNT(seller_city) AS seller_city_Null,

    COUNT(seller_state) AS seller_state_NonNull,
    COUNT(*) - COUNT(seller_state) AS seller_state_Null

FROM staging.olist_sellers;

--null analysis for Geolocation
SELECT
    COUNT(*) AS TotalRows,

    COUNT(geolocation_zip_code_prefix) AS geolocation_zip_code_prefix_NonNull,
    COUNT(*) - COUNT(geolocation_zip_code_prefix) AS geolocation_zip_code_prefix_Null,

    COUNT(geolocation_lat) AS geolocation_lat_NonNull,
    COUNT(*) - COUNT(geolocation_lat) AS geolocation_lat_Null,

    COUNT(geolocation_lng) AS geolocation_lng_NonNull,
    COUNT(*) - COUNT(geolocation_lng) AS geolocation_lng_Null,

    COUNT(geolocation_city) AS geolocation_city_NonNull,
    COUNT(*) - COUNT(geolocation_city) AS geolocation_city_Null,

    COUNT(geolocation_state) AS geolocation_state_NonNull,
    COUNT(*) - COUNT(geolocation_state) AS geolocation_state_Null

FROM staging.olist_geolocation;


--null analysis for Product Category Translation
SELECT
    COUNT(*) AS TotalRows,

    COUNT(product_category_name) AS product_category_name_NonNull,
    COUNT(*) - COUNT(product_category_name) AS product_category_name_Null,

    COUNT(product_category_name_english) AS product_category_name_english_NonNull,
    COUNT(*) - COUNT(product_category_name_english) AS product_category_name_english_Null

FROM staging.product_category_translation;