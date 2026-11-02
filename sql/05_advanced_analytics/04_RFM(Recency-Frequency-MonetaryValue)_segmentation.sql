USE Olist_Ecommerce_Analytics;
GO

IF OBJECT_ID('tempdb..#CustomerRFM') IS NOT NULL
    DROP TABLE #CustomerRFM;

/* Delivered orders only; customer_unique_id is the customer grain.
   PERCENT_RANK gives tied metric values the same score band. */
WITH AnalysisDate AS
(
    SELECT MAX(order_purchase_timestamp) AS max_purchase_date
    FROM core.Orders
    WHERE order_status = 'delivered'
),
CustomerMetrics AS
(
    SELECT
        c.customer_unique_id,
        DATEDIFF(DAY, MAX(o.order_purchase_timestamp), ad.max_purchase_date) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary_product_revenue
    FROM core.Customers AS c
    INNER JOIN core.Orders AS o ON o.customer_id = c.customer_id
    INNER JOIN core.OrderItems AS oi ON oi.order_id = o.order_id
    CROSS JOIN AnalysisDate AS ad
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, ad.max_purchase_date
),
Percentiles AS
(
    SELECT
        *,
        PERCENT_RANK() OVER (ORDER BY recency_days ASC) AS recency_percentile,
        PERCENT_RANK() OVER (ORDER BY frequency ASC) AS frequency_percentile,
        PERCENT_RANK() OVER (ORDER BY monetary_product_revenue ASC) AS monetary_percentile
    FROM CustomerMetrics
),
Scores AS
(
    SELECT
        *,
        CASE WHEN recency_percentile < 0.20 THEN 5 WHEN recency_percentile < 0.40 THEN 4 WHEN recency_percentile < 0.60 THEN 3 WHEN recency_percentile < 0.80 THEN 2 ELSE 1 END AS r_score,
        CASE WHEN frequency_percentile < 0.20 THEN 1 WHEN frequency_percentile < 0.40 THEN 2 WHEN frequency_percentile < 0.60 THEN 3 WHEN frequency_percentile < 0.80 THEN 4 ELSE 5 END AS f_score,
        CASE WHEN monetary_percentile < 0.20 THEN 1 WHEN monetary_percentile < 0.40 THEN 2 WHEN monetary_percentile < 0.60 THEN 3 WHEN monetary_percentile < 0.80 THEN 4 ELSE 5 END AS m_score
    FROM Percentiles
),
Segmented AS
(
    SELECT
        *,
        CASE
            WHEN frequency = 1 AND r_score >= 4 THEN 'Recent One-Time'
            WHEN frequency = 1 THEN 'One-Time, Lapsed'
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4 THEN 'Loyal Repeat'
            WHEN r_score >= 4 AND f_score >= 2 THEN 'Potential Loyalist'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 THEN 'Lapsed Repeat'
            ELSE 'Develop Repeat Behavior'
        END AS customer_segment
    FROM Scores
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary_product_revenue,
    r_score,
    f_score,
    m_score,
    customer_segment
INTO #CustomerRFM
FROM Segmented;

/* Segment distribution */
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(6,2)) AS customer_percent,
    CAST(AVG(recency_days * 1.0) AS DECIMAL(10,2)) AS average_recency_days,
    CAST(AVG(frequency * 1.0) AS DECIMAL(10,2)) AS average_delivered_orders,
    CAST(AVG(monetary_product_revenue) AS DECIMAL(18,2)) AS average_product_revenue
FROM #CustomerRFM
GROUP BY customer_segment
ORDER BY customer_count DESC;

/* Customer-level scores and segment membership for follow-up analysis */
SELECT
    customer_unique_id, recency_days, frequency, monetary_product_revenue,
    r_score, f_score, m_score, customer_segment
FROM #CustomerRFM
ORDER BY r_score DESC, f_score DESC, m_score DESC, customer_unique_id;

DROP TABLE #CustomerRFM;
GO