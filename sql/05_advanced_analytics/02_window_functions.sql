USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
PHASE 3.2 - WINDOW FUNCTIONS
=========================================================

Purpose:
    Use SQL Server window functions for:
    - Monthly revenue growth
    - Running revenue
    - Previous-month comparison
    - Rolling 3-month revenue
    - Category ranking
=========================================================
*/


/* =======================================================
   1. MONTHLY REVENUE WITH PREVIOUS MONTH
   ======================================================= */

WITH MonthlySales AS
(
    SELECT
        YEAR(order_purchase_timestamp) AS OrderYear,

        MONTH(order_purchase_timestamp) AS OrderMonth,

        SUM(price) AS ProductRevenue

    FROM analytics.vw_OrderSales

    GROUP BY
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp)
)

SELECT
    OrderYear,
    OrderMonth,
    ProductRevenue,

    LAG(ProductRevenue) OVER
    (
        ORDER BY
            OrderYear,
            OrderMonth
    ) AS PreviousMonthRevenue

FROM MonthlySales

ORDER BY
    OrderYear,
    OrderMonth;
GO


/* =======================================================
   2. MONTH-OVER-MONTH REVENUE GROWTH
   ======================================================= */

WITH MonthlySales AS
(
    SELECT
        YEAR(order_purchase_timestamp) AS OrderYear,

        MONTH(order_purchase_timestamp) AS OrderMonth,

        SUM(price) AS ProductRevenue

    FROM analytics.vw_OrderSales

    GROUP BY
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp)
),

MonthlyComparison AS
(
    SELECT
        OrderYear,
        OrderMonth,
        ProductRevenue,

        LAG(ProductRevenue) OVER
        (
            ORDER BY
                OrderYear,
                OrderMonth
        ) AS PreviousMonthRevenue

    FROM MonthlySales
)

SELECT
    OrderYear,
    OrderMonth,
    ProductRevenue,
    PreviousMonthRevenue,

    CAST(
        100.0 *
        (ProductRevenue - PreviousMonthRevenue)
        / NULLIF(PreviousMonthRevenue, 0)
        AS DECIMAL(10,2)
    ) AS MoMGrowthPercent

FROM MonthlyComparison

ORDER BY
    OrderYear,
    OrderMonth;
GO


/* =======================================================
   3. RUNNING / CUMULATIVE REVENUE
   ======================================================= */

WITH MonthlySales AS
(
    SELECT
        YEAR(order_purchase_timestamp) AS OrderYear,

        MONTH(order_purchase_timestamp) AS OrderMonth,

        SUM(price) AS ProductRevenue

    FROM analytics.vw_OrderSales

    GROUP BY
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp)
)

SELECT
    OrderYear,
    OrderMonth,
    ProductRevenue,

    SUM(ProductRevenue) OVER
    (
        ORDER BY
            OrderYear,
            OrderMonth

        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS CumulativeRevenue

FROM MonthlySales

ORDER BY
    OrderYear,
    OrderMonth;
GO


/* =======================================================
   4. ROLLING 3-MONTH REVENUE
   ======================================================= */

WITH MonthlySales AS
(
    SELECT
        YEAR(order_purchase_timestamp) AS OrderYear,

        MONTH(order_purchase_timestamp) AS OrderMonth,

        SUM(price) AS ProductRevenue

    FROM analytics.vw_OrderSales

    GROUP BY
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp)
)

SELECT
    OrderYear,
    OrderMonth,
    ProductRevenue,

    SUM(ProductRevenue) OVER
    (
        ORDER BY
            OrderYear,
            OrderMonth

        ROWS BETWEEN 2 PRECEDING
        AND CURRENT ROW
    ) AS Rolling3MonthRevenue

FROM MonthlySales

ORDER BY
    OrderYear,
    OrderMonth;
GO


/* =======================================================
   5. CATEGORY RANKING
   ======================================================= */

SELECT
    product_category,

    product_revenue,

    RANK() OVER
    (
        ORDER BY product_revenue DESC
    ) AS RevenueRank,

    DENSE_RANK() OVER
    (
        ORDER BY product_revenue DESC
    ) AS DenseRevenueRank

FROM analytics.vw_CategorySales

ORDER BY
    RevenueRank;
GO


/* =======================================================
   6. CATEGORY REVENUE SHARE
   ======================================================= */

SELECT
    product_category,

    product_revenue,

    CAST(
        100.0 * product_revenue /
        SUM(product_revenue) OVER ()
        AS DECIMAL(10,2)
    ) AS RevenueSharePercent

FROM analytics.vw_CategorySales

ORDER BY
    product_revenue DESC;
GO