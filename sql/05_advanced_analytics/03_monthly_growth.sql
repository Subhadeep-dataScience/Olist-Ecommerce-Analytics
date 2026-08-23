USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
PHASE 3.3 - MONTHLY GROWTH ANALYSIS
=========================================================

Purpose:
    Create a continuous monthly timeline and analyze:
    - Monthly revenue
    - Month-over-month growth
    - Year-over-year comparison

Important:
    Months with no sales are retained and shown as zero.
=========================================================
*/


/* =======================================================
   1. CREATE CONTINUOUS MONTHLY CALENDAR
   ======================================================= */

WITH MonthCalendar AS
(
    SELECT
        CAST('2016-09-01' AS DATE) AS MonthStart

    UNION ALL

    SELECT
        DATEADD(MONTH, 1, MonthStart)

    FROM MonthCalendar

    WHERE MonthStart < '2018-09-01'
),

MonthlySales AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(order_purchase_timestamp),
            MONTH(order_purchase_timestamp),
            1
        ) AS MonthStart,

        SUM(price) AS ProductRevenue,

        COUNT(DISTINCT order_id) AS TotalOrders

    FROM analytics.vw_OrderSales

    GROUP BY
        DATEFROMPARTS(
            YEAR(order_purchase_timestamp),
            MONTH(order_purchase_timestamp),
            1
        )
)

SELECT
    c.MonthStart,

    YEAR(c.MonthStart) AS OrderYear,

    MONTH(c.MonthStart) AS OrderMonth,

    COALESCE(s.TotalOrders, 0) AS TotalOrders,

    COALESCE(s.ProductRevenue, 0) AS ProductRevenue

FROM MonthCalendar AS c

LEFT JOIN MonthlySales AS s
    ON c.MonthStart = s.MonthStart

ORDER BY
    c.MonthStart
OPTION (MAXRECURSION 100);
GO


/* =======================================================
   2. MONTH-OVER-MONTH GROWTH
   ======================================================= */

WITH MonthCalendar AS
(
    SELECT CAST('2016-09-01' AS DATE) AS MonthStart

    UNION ALL

    SELECT DATEADD(MONTH, 1, MonthStart)

    FROM MonthCalendar

    WHERE MonthStart < '2018-09-01'
),

MonthlySales AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(order_purchase_timestamp),
            MONTH(order_purchase_timestamp),
            1
        ) AS MonthStart,

        SUM(price) AS ProductRevenue

    FROM analytics.vw_OrderSales

    GROUP BY
        DATEFROMPARTS(
            YEAR(order_purchase_timestamp),
            MONTH(order_purchase_timestamp),
            1
        )
),

ContinuousSales AS
(
    SELECT
        c.MonthStart,
        COALESCE(s.ProductRevenue, 0) AS ProductRevenue

    FROM MonthCalendar AS c

    LEFT JOIN MonthlySales AS s
        ON c.MonthStart = s.MonthStart
),

GrowthCalculation AS
(
    SELECT
        MonthStart,
        ProductRevenue,

        LAG(ProductRevenue) OVER
        (
            ORDER BY MonthStart
        ) AS PreviousMonthRevenue

    FROM ContinuousSales
)

SELECT
    MonthStart,

    ProductRevenue,

    PreviousMonthRevenue,

    CASE
        WHEN PreviousMonthRevenue IS NULL
            THEN NULL

        WHEN PreviousMonthRevenue = 0
            THEN NULL

        ELSE CAST(
            100.0 *
            (ProductRevenue - PreviousMonthRevenue)
            / PreviousMonthRevenue
            AS DECIMAL(10,2)
        )
    END AS MoMGrowthPercent

FROM GrowthCalculation

ORDER BY
    MonthStart
OPTION (MAXRECURSION 100);
GO


/* =======================================================
   3. YEAR-OVER-YEAR MONTHLY COMPARISON
      USING CONTINUOUS CALENDAR
   ======================================================= */

WITH MonthCalendar AS
(
    SELECT CAST('2016-09-01' AS DATE) AS MonthStart

    UNION ALL

    SELECT DATEADD(MONTH, 1, MonthStart)

    FROM MonthCalendar

    WHERE MonthStart < '2018-09-01'
),

MonthlySales AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(order_purchase_timestamp),
            MONTH(order_purchase_timestamp),
            1
        ) AS MonthStart,

        SUM(price) AS ProductRevenue

    FROM analytics.vw_OrderSales

    GROUP BY
        DATEFROMPARTS(
            YEAR(order_purchase_timestamp),
            MONTH(order_purchase_timestamp),
            1
        )
),

ContinuousSales AS
(
    SELECT
        c.MonthStart,

        COALESCE(s.ProductRevenue, 0) AS ProductRevenue

    FROM MonthCalendar AS c

    LEFT JOIN MonthlySales AS s
        ON c.MonthStart = s.MonthStart
)

SELECT
    MonthStart,

    ProductRevenue,

    LAG(ProductRevenue, 12) OVER
    (
        ORDER BY MonthStart
    ) AS SameMonthPreviousYearRevenue,

    CASE
        WHEN LAG(ProductRevenue, 12) OVER
             (ORDER BY MonthStart) IS NULL
            THEN NULL

        WHEN LAG(ProductRevenue, 12) OVER
             (ORDER BY MonthStart) = 0
            THEN NULL

        ELSE CAST(
            100.0 *
            (
                ProductRevenue
                - LAG(ProductRevenue, 12) OVER
                  (ORDER BY MonthStart)
            )
            /
            NULLIF(
                LAG(ProductRevenue, 12) OVER
                (ORDER BY MonthStart),
                0
            )
            AS DECIMAL(10,2)
        )
    END AS YoYGrowthPercent

FROM ContinuousSales

ORDER BY
    MonthStart
OPTION (MAXRECURSION 100);
GO