USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
PHASE 3.5 - CUSTOMER RETENTION ANALYSIS
=========================================================

Purpose:
    Analyze repeat purchasing and customer retention.

Key Questions:
    1. How many customers make repeat purchases?
    2. What is the overall repeat customer rate?
    3. How long does it take customers to purchase again?
    4. How does repeat purchasing vary over time?

Customer Grain:
    customer_unique_id
=========================================================
*/


/* =======================================================
   1. OVERALL CUSTOMER RETENTION KPIs
   ======================================================= */

WITH CustomerOrders AS
(
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS TotalOrders

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    COUNT(*) AS TotalCustomers,

    SUM(
        CASE
            WHEN TotalOrders >= 2 THEN 1
            ELSE 0
        END
    ) AS RepeatCustomers,

    SUM(
        CASE
            WHEN TotalOrders = 1 THEN 1
            ELSE 0
        END
    ) AS OneTimeCustomers,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN TotalOrders >= 2 THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS RepeatCustomerRate

FROM CustomerOrders;
GO


/* =======================================================
   2. CUSTOMER ORDER FREQUENCY DISTRIBUTION
   ======================================================= */

WITH CustomerOrders AS
(
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS TotalOrders

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    TotalOrders,

    COUNT(*) AS CustomerCount,

    CAST(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS CustomerPercent

FROM CustomerOrders

GROUP BY
    TotalOrders

ORDER BY
    TotalOrders;
GO


/* =======================================================
   3. TIME BETWEEN FIRST AND SECOND PURCHASE
   ======================================================= */

WITH CustomerOrderSequence AS
(
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,

        ROW_NUMBER() OVER
        (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS OrderNumber

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

CustomerFirstSecondPurchase AS
(
    SELECT
        customer_unique_id,

        MAX(
            CASE
                WHEN OrderNumber = 1
                THEN order_purchase_timestamp
            END
        ) AS FirstPurchaseDate,

        MAX(
            CASE
                WHEN OrderNumber = 2
                THEN order_purchase_timestamp
            END
        ) AS SecondPurchaseDate

    FROM CustomerOrderSequence

    WHERE OrderNumber <= 2

    GROUP BY
        customer_unique_id
)

SELECT
    COUNT(*) AS CustomersWithSecondPurchase,

    CAST(
        AVG(
            DATEDIFF(
                DAY,
                FirstPurchaseDate,
                SecondPurchaseDate
            ) * 1.0
        )
        AS DECIMAL(18,2)
    ) AS AverageDaysToSecondPurchase,

    MIN(
        DATEDIFF(
            DAY,
            FirstPurchaseDate,
            SecondPurchaseDate
        )
    ) AS MinimumDaysToSecondPurchase,

    MAX(
        DATEDIFF(
            DAY,
            FirstPurchaseDate,
            SecondPurchaseDate
        )
    ) AS MaximumDaysToSecondPurchase

FROM CustomerFirstSecondPurchase

WHERE SecondPurchaseDate IS NOT NULL;
GO


/* =======================================================
   4. REPEAT CUSTOMER ACQUISITION BY FIRST PURCHASE MONTH
   ======================================================= */

WITH CustomerOrders AS
(
    SELECT
        c.customer_unique_id,

        MIN(o.order_purchase_timestamp) AS FirstPurchaseDate,

        COUNT(DISTINCT o.order_id) AS TotalOrders

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    YEAR(FirstPurchaseDate) AS FirstPurchaseYear,

    MONTH(FirstPurchaseDate) AS FirstPurchaseMonth,

    COUNT(*) AS NewCustomers,

    SUM(
        CASE
            WHEN TotalOrders >= 2 THEN 1
            ELSE 0
        END
    ) AS CustomersWhoReturned,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN TotalOrders >= 2 THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS EventualRepeatRate           /*EventualRepeatRate means:

                                        Of customers whose first purchase occurred in a given month, what percentage made at least 
                                        one additional delivered purchase anywhere later in the dataset?

                                        This is not a fixed 30-day or 90-day retention rate. 
                                        Customers acquired near the end of the dataset have less time to return, so we'll interpret later cohorts carefully.*/

FROM CustomerOrders

GROUP BY
    YEAR(FirstPurchaseDate),
    MONTH(FirstPurchaseDate)

ORDER BY
    FirstPurchaseYear,
    FirstPurchaseMonth;
GO


/* =======================================================
   5. CUSTOMER RETENTION OPPORTUNITY SEGMENTS
   ======================================================= */

WITH AnalysisDate AS
(
    SELECT MAX(order_purchase_timestamp) AS MaxPurchaseDate
    FROM core.Orders
),

CustomerMetrics AS
(
    SELECT
        c.customer_unique_id,

        MAX(o.order_purchase_timestamp) AS LastPurchaseDate,

        COUNT(DISTINCT o.order_id) AS TotalOrders

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

CustomerSegments AS
(
    SELECT
        cm.customer_unique_id,
        cm.TotalOrders,

        DATEDIFF(
            DAY,
            cm.LastPurchaseDate,
            ad.MaxPurchaseDate
        ) AS RecencyDays,

        CASE
            WHEN cm.TotalOrders >= 2
                 AND DATEDIFF(
                        DAY,
                        cm.LastPurchaseDate,
                        ad.MaxPurchaseDate
                     ) <= 180
                THEN 'Active Repeat Customers'

            WHEN cm.TotalOrders >= 2
                THEN 'Inactive Repeat Customers'

            WHEN cm.TotalOrders = 1
                 AND DATEDIFF(
                        DAY,
                        cm.LastPurchaseDate,
                        ad.MaxPurchaseDate
                     ) <= 180
                THEN 'Recent One-Time Customers'

            ELSE 'Inactive One-Time Customers'
        END AS RetentionSegment

    FROM CustomerMetrics AS cm

    CROSS JOIN AnalysisDate AS ad
)

SELECT
    RetentionSegment,

    COUNT(*) AS CustomerCount,

    CAST(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS CustomerPercent

FROM CustomerSegments

GROUP BY
    RetentionSegment

ORDER BY
    CustomerCount DESC;
GO