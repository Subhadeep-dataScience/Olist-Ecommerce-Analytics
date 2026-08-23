USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
02 - CUSTOMER ANALYSIS
=========================================================

Purpose:
    Analyze customer base, purchasing frequency,
    customer spending, repeat customers and
    customer concentration.

Source:
    core.Customers
    core.Orders
    core.OrderItems
    analytics.vw_CustomerSummary
=========================================================
*/


/* =======================================================
   1. CUSTOMER BASE OVERVIEW
   ======================================================= */

SELECT
    COUNT(*) AS TotalUniqueCustomers,

    SUM(
        CASE
            WHEN total_orders = 1 THEN 1
            ELSE 0
        END
    ) AS OneTimeCustomers,

    SUM(
        CASE
            WHEN total_orders > 1 THEN 1
            ELSE 0
        END
    ) AS RepeatCustomers

FROM analytics.vw_CustomerSummary;
GO


/* =======================================================
   2. REPEAT CUSTOMER RATE
   ======================================================= */

SELECT
    COUNT(*) AS TotalCustomers,

    SUM(
        CASE
            WHEN total_orders > 1 THEN 1
            ELSE 0
        END
    ) AS RepeatCustomers,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN total_orders > 1 THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(10,2)
    ) AS RepeatCustomerRate

FROM analytics.vw_CustomerSummary;
GO


/* =======================================================
   3. CUSTOMER ORDER FREQUENCY
   ======================================================= */

SELECT
    total_orders AS OrderFrequency,
    COUNT(*) AS CustomerCount

FROM analytics.vw_CustomerSummary

GROUP BY
    total_orders

ORDER BY
    total_orders;
GO


/* =======================================================
   4. CUSTOMER SPENDING DISTRIBUTION
   ======================================================= */

SELECT
    MIN(total_spend) AS MinimumSpend,

    MAX(total_spend) AS MaximumSpend,

    AVG(total_spend) AS AverageSpend,

    SUM(total_spend) AS TotalCustomerSpend

FROM analytics.vw_CustomerSummary;
GO


/* =======================================================
   5. TOP 20 CUSTOMERS BY TOTAL SPEND
   ======================================================= */

SELECT TOP 20
    customer_unique_id,

    total_orders,

    total_spend,

    total_freight,

    gross_order_value,

    first_order_date,

    last_order_date

FROM analytics.vw_CustomerSummary

ORDER BY
    total_spend DESC;
GO


/* =======================================================
   6. TOP 20 CUSTOMERS BY ORDER FREQUENCY
   ======================================================= */

SELECT TOP 20
    customer_unique_id,

    total_orders,

    total_spend,

    gross_order_value,

    first_order_date,

    last_order_date

FROM analytics.vw_CustomerSummary

ORDER BY
    total_orders DESC,
    total_spend DESC;
GO


/* =======================================================
   7. CUSTOMER REVENUE CONTRIBUTION
   ======================================================= */

SELECT TOP 20
    customer_unique_id,

    total_orders,

    total_spend,

    CAST(
        100.0 * total_spend /
        SUM(total_spend) OVER ()
        AS DECIMAL(10,2)
    ) AS RevenueContributionPercent

FROM analytics.vw_CustomerSummary

ORDER BY
    total_spend DESC;
GO


/* =======================================================
   8. REPEAT VS ONE-TIME CUSTOMER VALUE
   ======================================================= */

SELECT
    CASE
        WHEN total_orders = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS CustomerType,

    COUNT(*) AS CustomerCount,

    SUM(total_spend) AS TotalSpend,

    AVG(total_spend) AS AverageSpend

FROM analytics.vw_CustomerSummary

GROUP BY
    CASE
        WHEN total_orders = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END;
GO

/*We're now answering:

Customer acquisition

How large is our customer base?

Customer retention

How many customers came back?

Purchase frequency

How many orders does a typical customer make?

Customer value

How much does each customer spend?

High-value customers

Who generates the most revenue?

Customer concentration

How much revenue comes from our highest-spending customers?

One-time vs repeat

Do repeat customers actually spend more?*/
