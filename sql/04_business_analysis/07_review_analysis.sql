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

Sources:
    core.OrderReviews
    analytics.vw_DeliveryPerformance
=========================================================
*/


/* =======================================================
   1. OVERALL REVIEW KPIs
   ======================================================= */

SELECT
    COUNT(*) AS TotalReviewRecords,

    COUNT(DISTINCT order_id) AS OrdersWithReviews,

    AVG(review_score * 1.0) AS AverageReviewScore,

    MIN(review_score) AS MinimumReviewScore,

    MAX(review_score) AS MaximumReviewScore

FROM core.OrderReviews;
GO


/* =======================================================
   2. REVIEW SCORE DISTRIBUTION
   ======================================================= */

SELECT
    review_score,

    COUNT(*) AS ReviewCount,

    CAST(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS ReviewSharePercent

FROM core.OrderReviews

GROUP BY
    review_score

ORDER BY
    review_score;
GO


/* =======================================================
   3. POSITIVE VS NEGATIVE REVIEWS
   ======================================================= */

SELECT
    CASE
        WHEN review_score >= 4
            THEN 'Positive (4-5)'

        WHEN review_score <= 2
            THEN 'Negative (1-2)'

        ELSE 'Neutral (3)'
    END AS ReviewCategory,

    COUNT(*) AS ReviewCount,

    CAST(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS ReviewSharePercent

FROM core.OrderReviews

GROUP BY
    CASE
        WHEN review_score >= 4
            THEN 'Positive (4-5)'

        WHEN review_score <= 2
            THEN 'Negative (1-2)'

        ELSE 'Neutral (3)'
    END

ORDER BY
    ReviewCount DESC;
GO


/* =======================================================
   4. DELIVERY STATUS VS REVIEW SCORE
   ======================================================= */

SELECT
    d.delivery_status,

    COUNT(*) AS ReviewedOrders,

    CAST(
        AVG(r.review_score * 1.0)
        AS DECIMAL(10,2)
    ) AS AverageReviewScore

FROM analytics.vw_DeliveryPerformance AS d

INNER JOIN core.OrderReviews AS r
    ON d.order_id = r.order_id

WHERE d.delivery_status IN
(
    'Late',
    'On Time'
)

GROUP BY
    d.delivery_status

ORDER BY
    d.delivery_status;
GO


/* =======================================================
   5. REVIEW DISTRIBUTION BY DELIVERY STATUS
   ======================================================= */

SELECT
    d.delivery_status,

    r.review_score,

    COUNT(*) AS ReviewCount

FROM analytics.vw_DeliveryPerformance AS d

INNER JOIN core.OrderReviews AS r
    ON d.order_id = r.order_id

WHERE d.delivery_status IN
(
    'Late',
    'On Time'
)

GROUP BY
    d.delivery_status,
    r.review_score

ORDER BY
    d.delivery_status,
    r.review_score;
GO


/* =======================================================
   6. LATE DELIVERY + NEGATIVE REVIEW
   ======================================================= */

SELECT
    d.delivery_status,

    COUNT(*) AS ReviewedOrders,

    SUM(
        CASE
            WHEN r.review_score <= 2
            THEN 1
            ELSE 0
        END
    ) AS NegativeReviews,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN r.review_score <= 2
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS NegativeReviewRate

FROM analytics.vw_DeliveryPerformance AS d

INNER JOIN core.OrderReviews AS r
    ON d.order_id = r.order_id

WHERE d.delivery_status IN
(
    'Late',
    'On Time'
)

GROUP BY
    d.delivery_status;
GO


/* =======================================================
   7. REVIEW SCORE BY CUSTOMER STATE
   ======================================================= */

SELECT
    c.customer_state,

    COUNT(*) AS ReviewedOrders,

    CAST(
        AVG(r.review_score * 1.0)
        AS DECIMAL(10,2)
    ) AS AverageReviewScore

FROM core.OrderReviews AS r

INNER JOIN core.Orders AS o
    ON r.order_id = o.order_id

INNER JOIN core.Customers AS c
    ON o.customer_id = c.customer_id

GROUP BY
    c.customer_state

HAVING COUNT(*) >= 100

ORDER BY
    AverageReviewScore;
GO


/*Major business insight

Late delivery is strongly associated with poorer customer satisfaction in this dataset.
Compare:
Average rating

Late       → 2.57
On Time    → 4.29
Difference → 1.72 points

That's a substantial difference on a 5-point scale.
Even more striking:
Negative review rate
Late       → 54.02%
On Time    →  9.24%
So the negative-review rate among late-delivery orders is roughly 5.85× the rate among on-time orders.
Portfolio-ready insight
Late deliveries were associated with a 1.72-point lower average review score (2.57 vs 4.29), 
while negative-review incidence was 54.02% for late orders compared with 9.24% for on-time orders.