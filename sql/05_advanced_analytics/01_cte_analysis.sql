USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
PHASE 3.1 - CTE & RANKING ANALYSIS
=========================================================

Purpose:
    Use Common Table Expressions (CTEs) and ranking
    functions to identify high-performing categories,
    sellers and products.
=========================================================
*/


/* =======================================================
   1. TOP 10 CATEGORIES USING RANK()
   ======================================================= */

WITH CategoryRevenue AS
(
    SELECT
        product_category,
        product_revenue
    FROM analytics.vw_CategorySales
),

RankedCategories AS
(
    SELECT
        product_category,
        product_revenue,

        RANK() OVER
        (
            ORDER BY product_revenue DESC
        ) AS RevenueRank

    FROM CategoryRevenue
)

SELECT
    RevenueRank,
    product_category,
    product_revenue

FROM RankedCategories

WHERE RevenueRank <= 10

ORDER BY
    RevenueRank;
GO


/* =======================================================
   2. TOP SELLERS USING DENSE_RANK()
   ======================================================= */

WITH SellerRevenue AS
(
    SELECT
        seller_id,
        product_revenue
    FROM analytics.vw_SellerPerformance
),

RankedSellers AS
(
    SELECT
        seller_id,
        product_revenue,

        DENSE_RANK() OVER
        (
            ORDER BY product_revenue DESC
        ) AS RevenueRank

    FROM SellerRevenue
)

SELECT
    RevenueRank,
    seller_id,
    product_revenue

FROM RankedSellers

WHERE RevenueRank <= 10

ORDER BY
    RevenueRank;
GO


/* =======================================================
   3. CATEGORY REVENUE SHARE
   ======================================================= */

WITH CategoryRevenue AS
(
    SELECT
        product_category,
        product_revenue
    FROM analytics.vw_CategorySales
)

SELECT
    product_category,
    product_revenue,

    CAST(
        100.0 * product_revenue /
        SUM(product_revenue) OVER ()
        AS DECIMAL(10,2)
    ) AS RevenueSharePercent

FROM CategoryRevenue

ORDER BY
    product_revenue DESC;
GO


/* =======================================================
   4. TOP CATEGORIES WITH ORDER EFFICIENCY
   ======================================================= */

WITH CategoryMetrics AS
(
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
)

SELECT TOP 10
    product_category,
    total_orders,
    product_revenue,
    RevenuePerOrder

FROM CategoryMetrics

ORDER BY
    RevenuePerOrder DESC;
GO