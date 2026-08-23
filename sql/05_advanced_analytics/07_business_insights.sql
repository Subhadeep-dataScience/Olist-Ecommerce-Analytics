USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
BUSINESS INSIGHTS & EXECUTIVE SUMMARY
=========================================================
Purpose:
Identify key business performance indicators and generate
actionable insights from the Olist E-Commerce dataset.
=========================================================
*/

SELECT
    COUNT(DISTINCT o.order_id) AS TotalOrders,
    
    COUNT(DISTINCT o.customer_id) AS TotalCustomers,
    
    CAST(SUM(oi.price) AS DECIMAL(18,2)) AS ProductRevenue,
    
    CAST(SUM(oi.freight_value) AS DECIMAL(18,2)) AS FreightRevenue,
    
    CAST(SUM(oi.price + oi.freight_value) AS DECIMAL(18,2)) AS TotalRevenue,
    
    CAST(
        SUM(oi.price + oi.freight_value) * 1.0 /
        NULLIF(COUNT(DISTINCT o.order_id), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM core.orders AS o
INNER JOIN core.OrderItems AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


/*
BUSINESS INSIGHT #1 – EXECUTIVE PERFORMANCE

• The platform successfully delivered 96,478 orders.
• Total transaction value reached approximately R$15.42 million.
• Products generated R$13.22 million, while freight contributed R$2.20 million.
• The average value generated per delivered order was R$159.83.

BUSINESS INTERPRETATION:
The business has a strong transaction volume, but increasing Average Order Value
through cross-selling, product bundles, and personalized recommendations could
create additional revenue without requiring the same proportional increase in
customer acquisition.
*/
/*Important observation: TotalCustomers = TotalOrders in this particular KPI query does not necessarily mean every customer only ordered once. 
We used customer_id from the orders table, and in the Olist dataset that identifier can represent a customer-order record rather than a unique real-world customer 
across purchases. 
We'll handle repeat customer analysis separately using the appropriate customer identifier logic, as we already explored in your customer analysis.*/


/*
=========================================================
SECTION 2: YEAR-OVER-YEAR BUSINESS PERFORMANCE
=========================================================
*/

SELECT
    YEAR(o.order_purchase_timestamp) AS OrderYear,

    COUNT(DISTINCT o.order_id) AS TotalOrders,

    CAST(SUM(oi.price + oi.freight_value) AS DECIMAL(18,2))
        AS TotalRevenue,

    CAST(
        SUM(oi.price + oi.freight_value) * 1.0 /
        NULLIF(COUNT(DISTINCT o.order_id), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM core.orders AS o
INNER JOIN core.OrderItems AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY YEAR(o.order_purchase_timestamp)
ORDER BY OrderYear;
GO

/*
BUSINESS INSIGHT #2 – BUSINESS GROWTH

• The business experienced strong growth from 2017 to 2018.
• Delivered orders increased from 43,428 in 2017 to 52,783 in 2018.
• Revenue increased from R$6.92 million to R$8.45 million.
• Average Order Value remained relatively stable at approximately R$160.

BUSINESS INTERPRETATION:
The increase in revenue was primarily driven by higher order volume rather than
a significant increase in spending per order. This suggests that customer
acquisition and transaction growth were major drivers of business expansion.

NOTE:
2018 represents a partial period in the dataset, so the growth comparison should
be interpreted with caution.
*/

/*"What was the major growth driver?"

"The revenue growth was mainly driven by increasing order volume rather than a significant increase in average order value. 
This indicates that business expansion was largely volume-driven."*/


/*
=========================================================
SECTION 3: CATEGORY PERFORMANCE & CUSTOMER SATISFACTION
=========================================================
*/

SELECT TOP 10
    COALESCE(
        ct.product_category_name_english,
        'Unknown'
    ) AS ProductCategory,

    COUNT(DISTINCT oi.order_id) AS TotalOrders,

    CAST(SUM(oi.price + oi.freight_value) AS DECIMAL(18,2))
        AS TotalRevenue,

    CAST(AVG(CAST(r.review_score AS DECIMAL(10,2))) AS DECIMAL(10,2))
        AS AverageReviewScore

FROM core.OrderItems AS oi

INNER JOIN core.orders AS o
    ON oi.order_id = o.order_id

LEFT JOIN core.Products AS p
    ON oi.product_id = p.product_id

LEFT JOIN core.ProductCategoryTranslation AS ct
    ON p.product_category_name = ct.product_category_name

LEFT JOIN core.OrderReviews AS r
    ON oi.order_id = r.order_id

WHERE o.order_status = 'delivered'

GROUP BY
    COALESCE(ct.product_category_name_english, 'Unknown')

ORDER BY TotalRevenue DESC;
GO


/*
BUSINESS INSIGHT #3 – CATEGORY PERFORMANCE

• Health & Beauty was the highest-revenue category, generating approximately
  R$1.42 million while maintaining a strong average review score of 4.19.

• Sports & Leisure and Cool Stuff also demonstrated a strong combination of
  revenue generation and customer satisfaction.

• Bed, Bath & Table generated high revenue but had the lowest customer
  satisfaction score among the top three revenue-generating categories (3.92).

• Furniture & Decor and Computers & Accessories also showed relatively lower
  review scores compared with other top-performing categories.

BUSINESS INTERPRETATION:
High-revenue categories should not be evaluated only by sales. Categories with
high sales but comparatively lower customer satisfaction should be investigated
for potential issues related to product quality, seller performance, delivery,
or customer expectations.
*/

--How did I generate actionable insights?
/*"Instead of analyzing revenue alone, I combined category revenue with customer review scores. 
This helped identify categories that were commercially successful but had comparatively lower customer satisfaction, highlighting areas 
where the business could investigate operational or product-related issues."*/


/*
=========================================================
SECTION 4: DELIVERY PERFORMANCE & CUSTOMER SATISFACTION
=========================================================
*/

SELECT
    CASE
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
        THEN 'Late Delivery'
        ELSE 'On-Time Delivery'
    END AS DeliveryStatus,

    COUNT(DISTINCT o.order_id) AS TotalOrders,

    CAST(
        AVG(CAST(r.review_score AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageReviewScore

FROM core.Orders AS o

LEFT JOIN core.OrderReviews AS r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY
    CASE
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
        THEN 'Late Delivery'
        ELSE 'On-Time Delivery'
    END;
GO

/*
BUSINESS INSIGHT #4 – DELIVERY PERFORMANCE

• Only around 8% of delivered orders were delivered late.
• However, late-delivery orders received an average review score of only 2.57.
• On-time deliveries received a much higher average review score of 4.29.

BUSINESS INTERPRETATION:
Delivery performance has a strong relationship with customer satisfaction.
Although late deliveries represent a relatively small proportion of orders,
they create a disproportionately negative customer experience.

RECOMMENDATION:
The business should investigate sellers, regions, and logistics processes
associated with late deliveries. Improving delivery reliability could
significantly improve customer satisfaction and potentially support
customer retention.
*/

/*"One of my strongest findings was that late delivery had a significant negative relationship with customer satisfaction. 
Late orders received an average review score of 2.57 compared with 4.29 for on-time deliveries. 
This showed that logistics performance was a critical driver of customer experience."*/



/*
=========================================================
SECTION 5: CUSTOMER RETENTION OPPORTUNITY
=========================================================
*/

WITH CustomerPurchaseSummary AS
(
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS TotalOrders,
        MAX(o.order_purchase_timestamp) AS LastPurchaseDate
    FROM core.Orders AS o
    INNER JOIN core.Customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
CustomerSegments AS
(
    SELECT
        customer_unique_id,
        TotalOrders,
        LastPurchaseDate,
        CASE
            WHEN TotalOrders = 1 THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS CustomerType
    FROM CustomerPurchaseSummary
)
SELECT
    CustomerType,
    COUNT(*) AS Customers,
    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS CustomerPercentage
FROM CustomerSegments
GROUP BY CustomerType
ORDER BY Customers DESC;
GO

/*
BUSINESS INSIGHT #5 – CUSTOMER RETENTION

• Approximately 97% of customers made only one delivered purchase.
• Only around 3% of customers returned for additional purchases.

BUSINESS INTERPRETATION:
The business appears to have a significant customer retention challenge.
While the platform successfully generates transactions and acquires customers,
very few customers return for repeat purchases.

RECOMMENDATION:
Olist could explore loyalty programs, personalized recommendations,
post-purchase engagement, targeted offers, and improved customer experience
to encourage repeat purchases and increase customer lifetime value.
*/

/*"Customer retention was one of the biggest opportunities I identified. After grouping purchases using customer_unique_id, 
I found that approximately 97% of customers made only one purchase, while only 3% became repeat customers. 
This suggested that improving retention could be a major growth opportunity."*/



/*
=========================================================
SECTION 6: GEOGRAPHIC BUSINESS PERFORMANCE
=========================================================
*/

SELECT TOP 10
    c.customer_state AS CustomerState,

    COUNT(DISTINCT o.order_id) AS TotalOrders,

    COUNT(DISTINCT c.customer_unique_id) AS UniqueCustomers,

    CAST(
        SUM(oi.price + oi.freight_value)
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

    CAST(
        AVG(oi.price + oi.freight_value)
        AS DECIMAL(18,2)
    ) AS AverageItemValue

FROM core.Orders AS o
INNER JOIN core.Customers AS c
    ON o.customer_id = c.customer_id
INNER JOIN core.OrderItems AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_state

ORDER BY TotalRevenue DESC;
GO

/*
BUSINESS INSIGHT #6 – GEOGRAPHIC PERFORMANCE

• São Paulo (SP) is the largest market, generating approximately R$5.77 million
  from more than 40,000 delivered orders.

• Rio de Janeiro (RJ) and Minas Gerais (MG) are the next largest markets,
  but there is a significant revenue gap compared with SP.

• São Paulo generates high transaction volume but has a comparatively lower
  average item value (R$124.22) than several other major states.

• Bahia (BA), despite lower order volume, has the highest average item value
  among the top-performing states shown in this analysis.

BUSINESS INTERPRETATION:
The business is heavily concentrated in São Paulo, making it the most important
market for maintaining revenue. However, states with higher average spending,
such as Bahia, may provide opportunities for targeted growth and premium
product strategies.
*/

/*"I found that revenue was geographically concentrated, with São Paulo being the dominant market. 
However, some smaller markets showed higher average spending per item, suggesting that growth opportunities may differ between high-volume and high-value regions."*/


/*
=========================================================
SECTION 7: PAYMENT METHOD PERFORMANCE
=========================================================
*/

WITH PaymentSummary AS
(
    SELECT
        payment_type,
        COUNT(DISTINCT order_id) AS TotalOrders,
        SUM(payment_value) AS TotalPaymentValue
    FROM core.OrderPayments
    GROUP BY payment_type
)
SELECT
    payment_type AS PaymentMethod,
    TotalOrders,

    CAST(TotalPaymentValue AS DECIMAL(18,2)) AS TotalPaymentValue,

    CAST(
        TotalPaymentValue * 100.0 /
        SUM(TotalPaymentValue) OVER ()
        AS DECIMAL(5,2)
    ) AS PaymentValuePercentage

FROM PaymentSummary
ORDER BY TotalPaymentValue DESC;
GO

/*
BUSINESS INSIGHT #7 – PAYMENT BEHAVIOUR

• Credit cards are the dominant payment method, contributing approximately
  78% of the total payment value.

• Boleto is the second most important payment method, contributing nearly
  18% of the total payment value.

• Other payment methods represent a relatively small share of transactions.

BUSINESS INTERPRETATION:
Payment behaviour is heavily concentrated around credit cards. Maintaining a
smooth and reliable credit card payment experience is therefore important for
protecting the majority of transaction value.

At the same time, supporting alternative payment methods such as Boleto helps
the platform serve customers with different payment preferences.
*/


/*
=========================================================
SECTION 8: EXECUTIVE RECOMMENDATIONS
=========================================================

RECOMMENDATION 1 – IMPROVE CUSTOMER RETENTION
Finding:
Approximately 97% of customers made only one purchase.

Action:
Develop loyalty programs, personalized offers, post-purchase engagement,
and recommendation strategies to encourage repeat purchases.

---------------------------------------------------------

RECOMMENDATION 2 – IMPROVE DELIVERY RELIABILITY
Finding:
Late deliveries received an average review score of 2.57 compared with
4.29 for on-time deliveries.

Action:
Identify sellers, logistics partners, and regions associated with late
deliveries and improve delivery performance.

---------------------------------------------------------

RECOMMENDATION 3 – INVESTIGATE HIGH-REVENUE, LOWER-SATISFACTION CATEGORIES
Finding:
Some high-revenue categories, such as Bed, Bath & Table, showed comparatively
lower customer review scores.

Action:
Investigate product quality, seller performance, customer expectations,
and delivery experience within these categories.

---------------------------------------------------------

RECOMMENDATION 4 – INCREASE AVERAGE ORDER VALUE
Finding:
Average Order Value remained relatively stable at around R$160.

Action:
Use cross-selling, product bundles, and personalized recommendations to
encourage customers to purchase additional products.

---------------------------------------------------------

RECOMMENDATION 5 – DEVELOP GEOGRAPHICALLY TARGETED STRATEGIES
Finding:
Revenue is heavily concentrated in São Paulo, while some smaller markets
demonstrate relatively higher average spending.

Action:
Protect performance in high-volume markets while using targeted campaigns
to expand high-value opportunities in other regions.

=========================================================
END OF BUSINESS INSIGHTS
=========================================================
*/