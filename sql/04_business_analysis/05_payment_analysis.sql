/*Now we'll analyze how customers pay.

We'll answer:

Which payment methods are most popular?
How much value flows through each payment method?
What's the average payment value?
How common are installments?
Which payment methods have the highest installment usage?
How much of total payment value comes from each method?*/

USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
05 - PAYMENT ANALYSIS
=========================================================

Purpose:
    Analyze payment methods, payment value,
    installments and payment behavior.

Source:
    core.OrderPayments
=========================================================
*/


/* =======================================================
   1. OVERALL PAYMENT KPIs
   ======================================================= */

SELECT
    COUNT(*) AS TotalPaymentRecords,

    COUNT(DISTINCT order_id) AS OrdersWithPayments,

    SUM(payment_value) AS TotalPaymentValue,

    AVG(payment_value) AS AveragePaymentValue,

    MAX(payment_value) AS MaximumPaymentValue

FROM core.OrderPayments;
GO


/* =======================================================
   2. PAYMENT METHOD DISTRIBUTION
   ======================================================= */

SELECT
    payment_type,

    COUNT(*) AS PaymentRecords,

    COUNT(DISTINCT order_id) AS Orders,

    SUM(payment_value) AS TotalPaymentValue,

    AVG(payment_value) AS AveragePaymentValue

FROM core.OrderPayments

GROUP BY
    payment_type

ORDER BY
    TotalPaymentValue DESC;
GO


/* =======================================================
   3. PAYMENT METHOD — ORDER SHARE
   ======================================================= */

WITH PaymentOrders AS
(
    SELECT
        payment_type,

        COUNT(DISTINCT order_id) AS Orders

    FROM core.OrderPayments

    GROUP BY
        payment_type
)

SELECT
    payment_type,

    Orders,

    CAST(
        100.0 * Orders /
        SUM(Orders) OVER ()
        AS DECIMAL(10,2)
    ) AS OrderSharePercent

FROM PaymentOrders

ORDER BY
    Orders DESC;
GO


/* =======================================================
   4. PAYMENT VALUE CONTRIBUTION
   ======================================================= */

SELECT
    payment_type,

    SUM(payment_value) AS TotalPaymentValue,

    CAST(
        100.0 * SUM(payment_value) /
        SUM(SUM(payment_value)) OVER ()
        AS DECIMAL(10,2)
    ) AS PaymentValueSharePercent

FROM core.OrderPayments

GROUP BY
    payment_type

ORDER BY
    TotalPaymentValue DESC;
GO


/* =======================================================
   5. INSTALLMENT ANALYSIS
   ======================================================= */

SELECT
    payment_installments,

    COUNT(*) AS PaymentRecords,

    COUNT(DISTINCT order_id) AS Orders,

    SUM(payment_value) AS TotalPaymentValue,

    AVG(payment_value) AS AveragePaymentValue

FROM core.OrderPayments

GROUP BY
    payment_installments

ORDER BY
    payment_installments;
GO


/* =======================================================
   6. INSTALLMENT DISTRIBUTION
   ======================================================= */

SELECT
    CASE
        WHEN payment_installments = 1
            THEN 'Single Payment'

        WHEN payment_installments BETWEEN 2 AND 3
            THEN '2-3 Installments'

        WHEN payment_installments BETWEEN 4 AND 6
            THEN '4-6 Installments'

        WHEN payment_installments BETWEEN 7 AND 12
            THEN '7-12 Installments'

        ELSE '13+ Installments'
    END AS InstallmentGroup,

    COUNT(DISTINCT order_id) AS Orders,

    SUM(payment_value) AS TotalPaymentValue,

    AVG(payment_value) AS AveragePaymentValue

FROM core.OrderPayments

GROUP BY
    CASE
        WHEN payment_installments = 1
            THEN 'Single Payment'

        WHEN payment_installments BETWEEN 2 AND 3
            THEN '2-3 Installments'

        WHEN payment_installments BETWEEN 4 AND 6
            THEN '4-6 Installments'

        WHEN payment_installments BETWEEN 7 AND 12
            THEN '7-12 Installments'

        ELSE '13+ Installments'
    END

ORDER BY
    TotalPaymentValue DESC;
GO


/* =======================================================
   7. PAYMENT TYPE + INSTALLMENTS
   ======================================================= */

SELECT
    payment_type,

    AVG(payment_installments * 1.0)
        AS AverageInstallments,

    MAX(payment_installments)
        AS MaximumInstallments,

    SUM(payment_value)
        AS TotalPaymentValue

FROM core.OrderPayments

GROUP BY
    payment_type

ORDER BY
    TotalPaymentValue DESC;
GO