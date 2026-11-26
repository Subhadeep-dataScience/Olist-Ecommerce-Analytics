USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
07 - REVIEW ANALYSIS
=========================================================

Purpose:
    Analyze review scores and investigate the relationship
    between delivery performance and customer satisfaction.

Grain:
    Review distribution uses physical review records.
    Delivery and customer comparisons average review rows to
    one score per order before joining to order-level dimensions.
=========================================================
*/

/* 1. Overall review KPIs: physical review-record grain */
SELECT
    COUNT(*) AS TotalReviewRecords,
    COUNT(DISTINCT order_id) AS OrdersWithReviews,
    AVG(review_score * 1.0) AS AverageReviewScorePerRecord,
    MIN(review_score) AS MinimumReviewScore,
    MAX(review_score) AS MaximumReviewScore
FROM core.OrderReviews;
GO

/* 2. Review score distribution: physical review-record grain */
SELECT
    review_score,
    COUNT(*) AS ReviewRecords,
    CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(10,2))
        AS ReviewRecordSharePercent
FROM core.OrderReviews
GROUP BY review_score
ORDER BY review_score;
GO

/* 3. Positive vs negative review records */
SELECT
    CASE
        WHEN review_score >= 4 THEN 'Positive (4-5)'
        WHEN review_score <= 2 THEN 'Negative (1-2)'
        ELSE 'Neutral (3)'
    END AS ReviewCategory,
    COUNT(*) AS ReviewRecords,
    CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(10,2))
        AS ReviewRecordSharePercent
FROM core.OrderReviews
GROUP BY CASE
    WHEN review_score >= 4 THEN 'Positive (4-5)'
    WHEN review_score <= 2 THEN 'Negative (1-2)'
    ELSE 'Neutral (3)'
END
ORDER BY ReviewRecords DESC;
GO

/* 4. Delivery status vs average order-level review score */
WITH ReviewByOrder AS
(
    SELECT order_id, AVG(review_score * 1.0) AS AverageOrderReviewScore
    FROM core.OrderReviews
    GROUP BY order_id
)
SELECT
    d.delivery_status,
    COUNT(*) AS ReviewedOrders,
    CAST(AVG(r.AverageOrderReviewScore) AS DECIMAL(10,2)) AS AverageReviewScorePerOrder
FROM analytics.vw_DeliveryPerformance AS d
INNER JOIN ReviewByOrder AS r ON r.order_id = d.order_id
WHERE d.delivery_status IN ('Late', 'On Time')
GROUP BY d.delivery_status
ORDER BY d.delivery_status;
GO

/* 5. Review-record distribution by delivery status */
SELECT
    d.delivery_status,
    r.review_score,
    COUNT(*) AS ReviewRecords
FROM analytics.vw_DeliveryPerformance AS d
INNER JOIN core.OrderReviews AS r ON r.order_id = d.order_id
WHERE d.delivery_status IN ('Late', 'On Time')
GROUP BY d.delivery_status, r.review_score
ORDER BY d.delivery_status, r.review_score;
GO

/* 6. Negative review rate by delivery status, at order grain.
   An order is classified as negative when its mean review score is <= 2. */
WITH ReviewByOrder AS
(
    SELECT order_id, AVG(review_score * 1.0) AS AverageOrderReviewScore
    FROM core.OrderReviews
    GROUP BY order_id
),
OrdersByDelivery AS
(
    SELECT d.delivery_status, r.AverageOrderReviewScore
    FROM analytics.vw_DeliveryPerformance AS d
    INNER JOIN ReviewByOrder AS r ON r.order_id = d.order_id
    WHERE d.delivery_status IN ('Late', 'On Time')
)
SELECT
    delivery_status,
    COUNT(*) AS ReviewedOrders,
    SUM(CASE WHEN AverageOrderReviewScore <= 2 THEN 1 ELSE 0 END) AS NegativeReviewOrders,
    CAST(100.0 * SUM(CASE WHEN AverageOrderReviewScore <= 2 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS NegativeReviewOrderRatePercent
FROM OrdersByDelivery
GROUP BY delivery_status
ORDER BY delivery_status;
GO

/* 7. Average order-level review score by customer state */
WITH ReviewByOrder AS
(
    SELECT order_id, AVG(review_score * 1.0) AS AverageOrderReviewScore
    FROM core.OrderReviews
    GROUP BY order_id
)
SELECT
    c.customer_state,
    COUNT(*) AS ReviewedOrders,
    CAST(AVG(r.AverageOrderReviewScore) AS DECIMAL(10,2)) AS AverageReviewScorePerOrder
FROM ReviewByOrder AS r
INNER JOIN core.Orders AS o ON o.order_id = r.order_id
INNER JOIN core.Customers AS c ON c.customer_id = o.customer_id
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY AverageReviewScorePerOrder;
GO

/* Recompute these descriptive results from the current dataset before
   publishing numeric claims. This analysis does not establish causation. */
