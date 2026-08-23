USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
PHASE 3.4 - RFM CUSTOMER SEGMENTATION
=========================================================

Purpose:
    Segment customers based on:

    R - Recency:
        Days since the customer's most recent purchase

    F - Frequency:
        Number of completed purchases

    M - Monetary:
        Total product value purchased

Customer Grain:
    customer_unique_id

Important:
    Uses customer_unique_id because one real customer may
    have multiple customer_id records in the Olist dataset.
=========================================================
*/


/* =======================================================
   1. DEFINE ANALYSIS DATE AND BUILD CUSTOMER RFM METRICS
   ======================================================= */

WITH AnalysisDate AS
(
    SELECT
        MAX(order_purchase_timestamp) AS MaxPurchaseDate
    FROM core.Orders
),

CustomerRFM AS
(
    SELECT
        c.customer_unique_id,

        MAX(o.order_purchase_timestamp) AS LastPurchaseDate,

        DATEDIFF(
            DAY,
            MAX(o.order_purchase_timestamp),
            (SELECT MaxPurchaseDate FROM AnalysisDate)
        ) AS RecencyDays,

        COUNT(DISTINCT o.order_id) AS Frequency,

        SUM(os.price) AS MonetaryValue

    FROM core.Customers AS c

        INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

        INNER JOIN analytics.vw_OrderSales AS os
        ON o.order_id = os.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    customer_unique_id,
    LastPurchaseDate,
    RecencyDays,
    Frequency,
    CAST(MonetaryValue AS DECIMAL(18,2)) AS MonetaryValue

FROM CustomerRFM

ORDER BY
    RecencyDays ASC,
    MonetaryValue DESC;
GO


/* =======================================================
   2. RFM SCORING USING NTILE()
   ======================================================= */

WITH AnalysisDate AS
(
    SELECT
        MAX(order_purchase_timestamp) AS MaxPurchaseDate
    FROM core.Orders
),

CustomerRFM AS
(
    SELECT
        c.customer_unique_id,

        DATEDIFF(
            DAY,
            MAX(o.order_purchase_timestamp),
            (SELECT MaxPurchaseDate FROM AnalysisDate)
        ) AS RecencyDays,

        COUNT(DISTINCT o.order_id) AS Frequency,

        SUM(os.price) AS MonetaryValue

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN analytics.vw_OrderSales AS os
        ON o.order_id = os.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

RFMScored AS
(
    SELECT
        customer_unique_id,
        RecencyDays,
        Frequency,
        MonetaryValue,

        NTILE(5) OVER
        (
            ORDER BY RecencyDays DESC
        ) AS RScore,

        NTILE(5) OVER
        (
            ORDER BY Frequency ASC
        ) AS FScore,

        NTILE(5) OVER
        (
            ORDER BY MonetaryValue ASC
        ) AS MScore

    FROM CustomerRFM
)

SELECT
    customer_unique_id,
    RecencyDays,
    Frequency,
    CAST(MonetaryValue AS DECIMAL(18,2)) AS MonetaryValue,
    RScore,
    FScore,
    MScore

FROM RFMScored

ORDER BY
    RScore DESC,
    FScore DESC,
    MScore DESC;
GO


--/* =======================================================
--   3. CUSTOMER SEGMENTATION
--   ======================================================= */

--WITH AnalysisDate AS
--(
--    SELECT
--        MAX(order_purchase_timestamp) AS MaxPurchaseDate
--    FROM core.Orders
--),

--CustomerRFM AS
--(
--    SELECT
--        c.customer_unique_id,

--        DATEDIFF(
--            DAY,
--            MAX(o.order_purchase_timestamp),
--            (SELECT MaxPurchaseDate FROM AnalysisDate)
--        ) AS RecencyDays,

--        COUNT(DISTINCT o.order_id) AS Frequency,

--        SUM(os.price) AS MonetaryValue

--    FROM core.Customers AS c

--    INNER JOIN core.Orders AS o
--        ON c.customer_id = o.customer_id

--    INNER JOIN analytics.vw_OrderSales AS os
--        ON o.order_id = os.order_id

--    WHERE o.order_status = 'delivered'

--    GROUP BY
--        c.customer_unique_id
--),

--RFMScored AS
--(
--    SELECT
--        customer_unique_id,
--        RecencyDays,
--        Frequency,
--        MonetaryValue,

--        NTILE(5) OVER
--        (
--            ORDER BY RecencyDays DESC
--        ) AS RScore,

--        NTILE(5) OVER
--        (
--            ORDER BY Frequency ASC
--        ) AS FScore,

--        NTILE(5) OVER
--        (
--            ORDER BY MonetaryValue ASC
--        ) AS MScore

--    FROM CustomerRFM
--),

--CustomerSegments AS
--(
--    SELECT
--        *,

--        CASE
--            WHEN RScore >= 4
--             AND FScore >= 4
--             AND MScore >= 4
--                THEN 'Champions'

--            WHEN RScore >= 3
--             AND FScore >= 4
--                THEN 'Loyal Customers'

--            WHEN RScore >= 4
--             AND FScore <= 2
--                THEN 'New Customers'

--            WHEN RScore <= 2
--             AND FScore >= 3
--                THEN 'At Risk'

--            WHEN RScore <= 2
--             AND FScore <= 2
--                THEN 'Lost Customers'

--            ELSE 'Potential Loyalists'
--        END AS CustomerSegment

--    FROM RFMScored
--)

--SELECT
--    CustomerSegment,

--    COUNT(*) AS CustomerCount,

--    CAST(
--        100.0 * COUNT(*) /
--        SUM(COUNT(*)) OVER ()
--        AS DECIMAL(10,2)
--    ) AS CustomerPercent,

--    CAST(
--        AVG(RecencyDays * 1.0)
--        AS DECIMAL(18,2)
--    ) AS AverageRecencyDays,

--    CAST(
--        AVG(Frequency * 1.0)
--        AS DECIMAL(18,2)
--    ) AS AverageFrequency,

--    CAST(
--        AVG(MonetaryValue)
--        AS DECIMAL(18,2)
--    ) AS AverageMonetaryValue

--FROM CustomerSegments

--GROUP BY
--    CustomerSegment

--ORDER BY
--    CustomerCount DESC;
--GO



--Notice something strange:

--Almost every segment has an Average Frequency close to 1.

--For example:

--Champions → 1.08 orders
--Loyal Customers → 1.04 orders
--Potential Loyalists → 1.00 order

--So calling someone a "Loyal Customer" when they have purchased only once on average is potentially misleading.

--This happens because the Olist dataset has very few repeat customers, which we already discovered earlier: the repeat customer rate is only about 3.12%.

--Also, NTILE(5) can split customers with the same Frequency value of 1 across different score buckets. 
--Therefore, a customer who ordered once may receive different Frequency scores simply because of how ties are distributed.


--The SQL runs correctly, but the business segmentation logic needs improvement.
--Business aspects:
--"I validated my RFM output instead of assuming that a statistically generated segment was automatically meaningful. 
--Because most Olist customers were one-time buyers, I adjusted the segmentation logic to account for the highly skewed purchase frequency."



/* =======================================================
   3. IMPROVED CUSTOMER SEGMENTATION
   ======================================================= */

--   New approach
--We'll separate one-time customers from repeat customers first.
--Then we'll use Recency and Monetary value to identify valuable customers.


WITH AnalysisDate AS
(
    SELECT MAX(order_purchase_timestamp) AS MaxPurchaseDate
    FROM core.Orders
),

CustomerRFM AS
(
    SELECT
        c.customer_unique_id,

        DATEDIFF(
            DAY,
            MAX(o.order_purchase_timestamp),
            (SELECT MaxPurchaseDate FROM AnalysisDate)
        ) AS RecencyDays,

        COUNT(DISTINCT o.order_id) AS Frequency,

        SUM(os.price) AS MonetaryValue

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN analytics.vw_OrderSales AS os
        ON o.order_id = os.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

CustomerSegments AS
(
    SELECT
        *,
        NTILE(5) OVER
        (
            ORDER BY RecencyDays DESC
        ) AS RScore,

        NTILE(5) OVER
        (
            ORDER BY MonetaryValue ASC
        ) AS MScore

    FROM CustomerRFM
),

FinalSegments AS
(
    SELECT
        *,

        CASE
            /* High-value repeat customers */
            WHEN Frequency >= 2
             AND RScore >= 4
             AND MScore >= 4
                THEN 'Champions'

            /* Repeat customers who haven't purchased recently */
            WHEN Frequency >= 2
             AND RScore <= 2
                THEN 'At Risk Repeat Customers'

            /* Other repeat customers */
            WHEN Frequency >= 2
                THEN 'Repeat Customers'

            /* Recent one-time customers */
            WHEN Frequency = 1
             AND RScore >= 4
                THEN 'Recent One-Time Customers'

            /* Older one-time customers */
            WHEN Frequency = 1
             AND RScore <= 2
                THEN 'Inactive One-Time Customers'

            /* Remaining one-time customers */
            ELSE 'One-Time Customers'
        END AS CustomerSegment

    FROM CustomerSegments
)

SELECT
    CustomerSegment,

    COUNT(*) AS CustomerCount,

    CAST(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS CustomerPercent,

    CAST(
        AVG(RecencyDays * 1.0)
        AS DECIMAL(18,2)
    ) AS AverageRecencyDays,

    CAST(
        AVG(Frequency * 1.0)
        AS DECIMAL(18,2)
    ) AS AverageFrequency,

    CAST(
        AVG(MonetaryValue)
        AS DECIMAL(18,2)
    ) AS AverageMonetaryValue

FROM FinalSegments

GROUP BY
    CustomerSegment

ORDER BY
    CustomerCount DESC;
GO