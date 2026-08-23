USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
06 - DELIVERY ANALYSIS
=========================================================

Purpose:
    Analyze delivery speed, late deliveries,
    delivery performance by state and order status.

Source:
    analytics.vw_DeliveryPerformance
    core.Orders
    core.Customers
=========================================================
*/


/* =======================================================
   1. OVERALL DELIVERY KPIs
   ======================================================= */

SELECT
    COUNT(*) AS DeliveredOrders,

    AVG(actual_delivery_days * 1.0)
        AS AverageDeliveryDays,

    MIN(actual_delivery_days)
        AS MinimumDeliveryDays,

    MAX(actual_delivery_days)
        AS MaximumDeliveryDays

FROM analytics.vw_DeliveryPerformance

WHERE delivery_status <> 'Not Delivered';
GO


/* =======================================================
   2. DELIVERY STATUS DISTRIBUTION
   ======================================================= */

SELECT
    delivery_status,

    COUNT(*) AS OrderCount,

    CAST(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS OrderSharePercent

FROM analytics.vw_DeliveryPerformance

GROUP BY
    delivery_status

ORDER BY
    OrderCount DESC;
GO


/* =======================================================
   3. LATE DELIVERY KPI
   ======================================================= */

SELECT
    COUNT(*) AS DeliveredOrders,

    SUM(
        CASE
            WHEN delivery_status = 'Late'
            THEN 1
            ELSE 0
        END
    ) AS LateOrders,

    SUM(
        CASE
            WHEN delivery_status = 'On Time'
            THEN 1
            ELSE 0
        END
    ) AS OnTimeOrders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN delivery_status = 'Late'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS LateDeliveryRate

FROM analytics.vw_DeliveryPerformance

WHERE delivery_status <> 'Not Delivered';
GO


/* =======================================================
   4. AVERAGE DELIVERY TIME BY STATE
   ======================================================= */

SELECT
    c.customer_state,

    COUNT(*) AS DeliveredOrders,

    AVG(d.actual_delivery_days * 1.0)
        AS AverageDeliveryDays,

    SUM(
        CASE
            WHEN d.delivery_status = 'Late'
            THEN 1
            ELSE 0
        END
    ) AS LateOrders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN d.delivery_status = 'Late'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS LateDeliveryRate

FROM analytics.vw_DeliveryPerformance AS d

INNER JOIN core.Customers AS c
    ON d.customer_id = c.customer_id

WHERE d.delivery_status <> 'Not Delivered'

GROUP BY
    c.customer_state

ORDER BY
    AverageDeliveryDays DESC;
GO


/* =======================================================
   5. STATES WITH HIGHEST LATE DELIVERY RATE
   ======================================================= */

SELECT TOP 15
    c.customer_state,

    COUNT(*) AS DeliveredOrders,

    SUM(
        CASE
            WHEN d.delivery_status = 'Late'
            THEN 1
            ELSE 0
        END
    ) AS LateOrders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN d.delivery_status = 'Late'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS LateDeliveryRate

FROM analytics.vw_DeliveryPerformance AS d

INNER JOIN core.Customers AS c
    ON d.customer_id = c.customer_id

WHERE d.delivery_status <> 'Not Delivered'

GROUP BY
    c.customer_state

HAVING COUNT(*) >= 100

ORDER BY
    LateDeliveryRate DESC;
GO


/* =======================================================
   6. DELIVERY TIME VS ESTIMATED TIME
   ======================================================= */

SELECT
    AVG(actual_delivery_days * 1.0)
        AS AverageActualDeliveryDays,

    AVG(estimated_delivery_days * 1.0)
        AS AverageEstimatedDeliveryDays,

    AVG(
        (actual_delivery_days - estimated_delivery_days) * 1.0
    ) AS AverageDifferenceDays

FROM analytics.vw_DeliveryPerformance

WHERE delivery_status <> 'Not Delivered';
GO


/* =======================================================
   7. DELIVERY PERFORMANCE BY ORDER STATUS
   ======================================================= */

SELECT
    order_status,

    COUNT(*) AS OrderCount,

    AVG(actual_delivery_days * 1.0)
        AS AverageDeliveryDays

FROM analytics.vw_DeliveryPerformance

WHERE delivery_status <> 'Not Delivered'

GROUP BY
    order_status

ORDER BY
    OrderCount DESC;
GO


/*Why HAVING COUNT(*) >= 100?
This is important.
Suppose a state has:
10 delivered orders
8 late
It would show:
80% late
which looks terrible—but it's based on only 10 orders.
We're therefore saying:
Only rank states with at least 100 delivered orders.
That's a much more responsible analytical approach.*/