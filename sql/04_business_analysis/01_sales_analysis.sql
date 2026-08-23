--Business Analytics Layer
/*The project should answer business questions, not just demonstrate SQL syntax.
This single file answers six business questions:

Total business performance
        ↓
Monthly trend
        ↓
Category performance
        ↓
Top categories by revenue
        ↓
Top categories by orders
        ↓
Revenue contribution*/


--Create an Analytics schema
USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
01 - SALES ANALYSIS
=========================================================

Purpose:
    Analyze revenue, orders, average order value,
    monthly sales trends, and category performance.

Source:
    analytics.vw_OrderSales
    analytics.vw_CategorySales
=========================================================
*/


/* =======================================================
   1. OVERALL SALES KPIs
   ======================================================= */

SELECT
    COUNT(DISTINCT order_id) AS TotalOrders,

    COUNT(*) AS TotalItems,

    SUM(price) AS ProductRevenue,

    SUM(freight_value) AS FreightValue,

    SUM(price + freight_value) AS GrossOrderValue,

    CAST(
        SUM(price) / COUNT(DISTINCT order_id)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM analytics.vw_OrderSales;
GO


/* =======================================================
   2. MONTHLY SALES TREND
   ======================================================= */

SELECT
    YEAR(order_purchase_timestamp) AS OrderYear,

    MONTH(order_purchase_timestamp) AS OrderMonth,

    COUNT(DISTINCT order_id) AS TotalOrders,

    SUM(price) AS ProductRevenue,

    SUM(freight_value) AS FreightValue,

    SUM(price + freight_value) AS GrossOrderValue

FROM analytics.vw_OrderSales

GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)

ORDER BY
    OrderYear,
    OrderMonth;
GO


/* =======================================================
   3. CATEGORY PERFORMANCE
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
   4. TOP 10 CATEGORIES BY PRODUCT REVENUE
   ======================================================= */

SELECT TOP 10
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
   5. TOP 10 CATEGORIES BY ORDER VOLUME
   ======================================================= */

SELECT TOP 10
    product_category,

    total_orders,

    total_items,

    product_revenue,

    gross_order_value

FROM analytics.vw_CategorySales

ORDER BY
    total_orders DESC;
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