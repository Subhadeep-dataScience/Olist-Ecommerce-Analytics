--We'll create a reusable sales-level view.
USE Olist_Ecommerce_Analytics;
GO
CREATE OR ALTER VIEW analytics.vw_OrderSales
AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value AS gross_item_value
FROM core.Orders AS o
INNER JOIN core.OrderItems AS oi
    ON o.order_id = oi.order_id;
GO


SELECT TOP 20 *
FROM analytics.vw_OrderSales;
GO

--Create Customer Summary View
CREATE OR ALTER VIEW analytics.vw_CustomerSummary
AS
SELECT
    c.customer_unique_id,

    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(oi.price) AS total_spend,

    SUM(oi.freight_value) AS total_freight,

    SUM(oi.price + oi.freight_value) AS gross_order_value,

    MIN(o.order_purchase_timestamp) AS first_order_date,

    MAX(o.order_purchase_timestamp) AS last_order_date

FROM core.Customers AS c

INNER JOIN core.Orders AS o
    ON c.customer_id = o.customer_id

INNER JOIN core.OrderItems AS oi
    ON o.order_id = oi.order_id

GROUP BY
    c.customer_unique_id;
GO
--test the above view
SELECT TOP 20 *
FROM analytics.vw_CustomerSummary
ORDER BY total_spend DESC;

--Create Category Sales View
CREATE OR ALTER VIEW analytics.vw_CategorySales
AS
SELECT
    COALESCE(
        pct.product_category_name_english,
        'Unknown'
    ) AS product_category,

    COUNT(DISTINCT s.order_id) AS total_orders,

    COUNT(*) AS total_items,

    SUM(s.price) AS product_revenue,

    SUM(s.freight_value) AS freight_value,

    SUM(s.price + s.freight_value) AS gross_order_value

FROM analytics.vw_OrderSales AS s

LEFT JOIN core.Products AS p
    ON s.product_id = p.product_id

LEFT JOIN core.ProductCategoryTranslation AS pct
    ON p.product_category_name =
       pct.product_category_name

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        'Unknown'
    );
GO

--TEST
SELECT TOP 20 *
FROM analytics.vw_CategorySales
ORDER BY product_revenue DESC;
GO

--Create Seller Performance View
CREATE OR ALTER VIEW analytics.vw_SellerPerformance
AS
SELECT
    s.seller_id,

    COUNT(DISTINCT s.order_id) AS total_orders,

    COUNT(*) AS total_items,

    SUM(s.price) AS product_revenue,

    SUM(s.freight_value) AS freight_value,

    SUM(s.gross_item_value) AS gross_order_value,

    AVG(s.price) AS avg_item_price

FROM analytics.vw_OrderSales AS s

GROUP BY
    s.seller_id;
GO

SELECT TOP 20 *
FROM analytics.vw_SellerPerformance
ORDER BY product_revenue DESC;
GO

--Create Delivery Performance View
CREATE OR ALTER VIEW analytics.vw_DeliveryPerformance
AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,

    o.order_purchase_timestamp,

    o.order_estimated_delivery_date,

    o.order_delivered_customer_date,

    DATEDIFF(
        DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    ) AS actual_delivery_days,

    DATEDIFF(
        DAY,
        o.order_purchase_timestamp,
        o.order_estimated_delivery_date
    ) AS estimated_delivery_days,

    CASE
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
        THEN 'Late'

        WHEN o.order_delivered_customer_date IS NULL
        THEN 'Not Delivered'

        ELSE 'On Time'
    END AS delivery_status

FROM core.Orders AS o;
GO

--TEST
SELECT TOP 20 *
FROM analytics.vw_DeliveryPerformance;
GO

