USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
03 - PRODUCT ANALYSIS
=========================================================

Purpose:
    Analyze product/category performance, sales volume,
    revenue contribution and product attributes.

Sources:
    analytics.vw_OrderSales
    core.Products
    core.ProductCategoryTranslation
=========================================================
*/


/* =======================================================
   1. PRODUCT PERFORMANCE OVERVIEW
   ======================================================= */

SELECT
    COUNT(DISTINCT product_id) AS ProductsSold,

    COUNT(*) AS TotalItemsSold,

    SUM(price) AS ProductRevenue,

    SUM(freight_value) AS FreightValue,

    SUM(price + freight_value) AS GrossOrderValue

FROM analytics.vw_OrderSales;
GO


/* =======================================================
   2. TOP 20 PRODUCTS BY PRODUCT REVENUE
   ======================================================= */

SELECT TOP 20
    s.product_id,

    COUNT(DISTINCT s.order_id) AS TotalOrders,

    COUNT(*) AS TotalItemsSold,

    SUM(s.price) AS ProductRevenue,

    SUM(s.freight_value) AS FreightValue,

    SUM(s.price + s.freight_value) AS GrossOrderValue

FROM analytics.vw_OrderSales AS s

GROUP BY
    s.product_id

ORDER BY
    ProductRevenue DESC;
GO


/* =======================================================
   3. TOP 20 PRODUCTS BY NUMBER OF ITEMS SOLD
   ======================================================= */

SELECT TOP 20
    s.product_id,

    COUNT(DISTINCT s.order_id) AS TotalOrders,

    COUNT(*) AS TotalItemsSold,

    SUM(s.price) AS ProductRevenue,

    AVG(s.price) AS AverageItemPrice

FROM analytics.vw_OrderSales AS s

GROUP BY
    s.product_id

ORDER BY
    TotalItemsSold DESC;
GO


/* =======================================================
   4. CATEGORY PERFORMANCE
   ======================================================= */

SELECT
    product_category,

    total_orders,

    total_items,

    product_revenue,

    freight_value,

    gross_order_value

FROM analytics.vw_CategorySales

ORDER BY
    product_revenue DESC;
GO


/* =======================================================
   5. TOP 10 CATEGORIES BY PRODUCT REVENUE
   ======================================================= */

SELECT TOP 10
    product_category,

    total_orders,

    total_items,

    product_revenue,

    gross_order_value

FROM analytics.vw_CategorySales

ORDER BY
    product_revenue DESC;
GO


/* =======================================================
   6. CATEGORY REVENUE CONTRIBUTION
   ======================================================= */

SELECT
    product_category,

    product_revenue,

    CAST(
        100.0 * product_revenue /
        SUM(product_revenue) OVER ()
        AS DECIMAL(10,2)
    ) AS RevenueContributionPercent

FROM analytics.vw_CategorySales

ORDER BY
    product_revenue DESC;
GO


/* =======================================================
   7. CATEGORY AVERAGE ORDER VALUE
   ======================================================= */

SELECT
    product_category,

    total_orders,

    product_revenue,

    CAST(
        product_revenue /
        NULLIF(total_orders, 0)
        AS DECIMAL(18,2)
    ) AS RevenuePerOrder

FROM analytics.vw_CategorySales

ORDER BY
    RevenuePerOrder DESC;
GO


/* =======================================================
   8. PRODUCTS WITH MISSING CATEGORY
   ======================================================= */

SELECT
    COUNT(*) AS ProductsWithoutCategory

FROM core.Products

WHERE product_category_name IS NULL;
GO


/* =======================================================
   9. PRODUCT ATTRIBUTE COMPLETENESS
   ======================================================= */

SELECT
    COUNT(*) AS TotalProducts,

    SUM(
        CASE
            WHEN product_weight_g IS NULL
            THEN 1 ELSE 0
        END
    ) AS MissingWeight,

    SUM(
        CASE
            WHEN product_length_cm IS NULL
            THEN 1 ELSE 0
        END
    ) AS MissingLength,

    SUM(
        CASE
            WHEN product_height_cm IS NULL
            THEN 1 ELSE 0
        END
    ) AS MissingHeight,

    SUM(
        CASE
            WHEN product_width_cm IS NULL
            THEN 1 ELSE 0
        END
    ) AS MissingWidth,

    SUM(
        CASE
            WHEN product_photos_qty IS NULL
            THEN 1 ELSE 0
        END
    ) AS MissingPhotoCount

FROM core.Products;
GO

/*This file answers several important questions.

Product performance

Which individual products generate the most sales?

Product popularity

Which products sell the most units?

Category performance

Which categories generate the most revenue?

Revenue concentration

What percentage of revenue comes from each category?

Category economics

Which categories have the highest revenue per order?

Data quality

How complete are our product attributes?*/
