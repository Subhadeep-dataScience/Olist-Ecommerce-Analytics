USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
05 - PAYMENT ANALYSIS
=========================================================

Scope:
    Delivered orders only, consistent with the sales analyses.
    One order may have multiple payment records and payment types.
    Method order shares are therefore non-exclusive and may sum
    to more than 100 percent.
=========================================================
*/

/* 1. Delivered-order payment KPIs */
WITH DeliveredPayments AS
(
    SELECT p.*
    FROM core.OrderPayments AS p
    INNER JOIN core.Orders AS o ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    COUNT(*) AS TotalPaymentRecords,
    COUNT(DISTINCT order_id) AS DeliveredOrdersWithPayments,
    SUM(payment_value) AS TotalPaymentValue,
    AVG(payment_value) AS AveragePaymentRecordValue,
    MAX(payment_value) AS MaximumPaymentRecordValue
FROM DeliveredPayments;
GO

/* 2. Payment method distribution */
WITH DeliveredPayments AS
(
    SELECT p.*
    FROM core.OrderPayments AS p
    INNER JOIN core.Orders AS o ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    payment_type,
    COUNT(*) AS PaymentRecords,
    COUNT(DISTINCT order_id) AS DeliveredOrdersUsingMethod,
    SUM(payment_value) AS TotalPaymentValue,
    AVG(payment_value) AS AveragePaymentRecordValue
FROM DeliveredPayments
GROUP BY payment_type
ORDER BY TotalPaymentValue DESC;
GO

/* 3. Non-exclusive share of delivered orders using each method */
WITH DeliveredPayments AS
(
    SELECT p.*
    FROM core.OrderPayments AS p
    INNER JOIN core.Orders AS o ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
),
PaymentOrders AS
(
    SELECT payment_type, COUNT(DISTINCT order_id) AS OrdersUsingMethod
    FROM DeliveredPayments
    GROUP BY payment_type
),
TotalOrders AS
(
    SELECT COUNT(DISTINCT order_id) AS OrdersWithPayments
    FROM DeliveredPayments
)
SELECT
    po.payment_type,
    po.OrdersUsingMethod,
    CAST(100.0 * po.OrdersUsingMethod / NULLIF(t.OrdersWithPayments, 0) AS DECIMAL(10,2))
        AS ShareOfDeliveredOrdersPercent
FROM PaymentOrders AS po
CROSS JOIN TotalOrders AS t
ORDER BY po.OrdersUsingMethod DESC;
GO

/* 4. Delivered-order payment value contribution */
WITH DeliveredPayments AS
(
    SELECT p.*
    FROM core.OrderPayments AS p
    INNER JOIN core.Orders AS o ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    payment_type,
    SUM(payment_value) AS TotalPaymentValue,
    CAST(100.0 * SUM(payment_value) / NULLIF(SUM(SUM(payment_value)) OVER (), 0) AS DECIMAL(10,2))
        AS PaymentValueSharePercent
FROM DeliveredPayments
GROUP BY payment_type
ORDER BY TotalPaymentValue DESC;
GO

/* 5. Installment analysis */
WITH DeliveredPayments AS
(
    SELECT p.*
    FROM core.OrderPayments AS p
    INNER JOIN core.Orders AS o ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    payment_installments,
    COUNT(*) AS PaymentRecords,
    COUNT(DISTINCT order_id) AS DeliveredOrders,
    SUM(payment_value) AS TotalPaymentValue,
    AVG(payment_value) AS AveragePaymentRecordValue
FROM DeliveredPayments
GROUP BY payment_installments
ORDER BY payment_installments;
GO

/* 6. Installment distribution */
WITH DeliveredPayments AS
(
    SELECT p.*
    FROM core.OrderPayments AS p
    INNER JOIN core.Orders AS o ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
),
GroupedPayments AS
(
    SELECT
        CASE
            WHEN payment_installments = 1 THEN 'Single Payment'
            WHEN payment_installments BETWEEN 2 AND 3 THEN '2-3 Installments'
            WHEN payment_installments BETWEEN 4 AND 6 THEN '4-6 Installments'
            WHEN payment_installments BETWEEN 7 AND 12 THEN '7-12 Installments'
            ELSE '13+ Installments'
        END AS InstallmentGroup,
        order_id,
        payment_value
    FROM DeliveredPayments
)
SELECT
    InstallmentGroup,
    COUNT(DISTINCT order_id) AS DeliveredOrders,
    SUM(payment_value) AS TotalPaymentValue,
    AVG(payment_value) AS AveragePaymentRecordValue
FROM GroupedPayments
GROUP BY InstallmentGroup
ORDER BY TotalPaymentValue DESC;
GO

/* 7. Payment type and installment behavior */
WITH DeliveredPayments AS
(
    SELECT p.*
    FROM core.OrderPayments AS p
    INNER JOIN core.Orders AS o ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    payment_type,
    AVG(payment_installments * 1.0) AS AverageInstallmentsPerPaymentRecord,
    MAX(payment_installments) AS MaximumInstallments,
    SUM(payment_value) AS TotalPaymentValue
FROM DeliveredPayments
GROUP BY payment_type
ORDER BY TotalPaymentValue DESC;
GO
