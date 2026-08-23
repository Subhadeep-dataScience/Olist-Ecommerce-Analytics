USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
04 - SELLER ANALYSIS
=========================================================

Purpose:
    Analyze seller revenue, order volume, item volume,
    pricing and freight performance.

Sources:
    analytics.vw_OrderSales
    core.Sellers
=========================================================
*/


/* =======================================================
   1. SELLER PERFORMANCE OVERVIEW
   ======================================================= */

SELECT
    COUNT(DISTINCT seller_id) AS ActiveSellers,

    COUNT(DISTINCT order_id) AS TotalOrders,

    COUNT(*) AS TotalItems,

    SUM(price) AS ProductRevenue,

    SUM(freight_value) AS FreightValue,

    SUM(price + freight_value) AS GrossOrderValue

FROM analytics.vw_OrderSales;
GO


/* =======================================================
   2. TOP 20 SELLERS BY PRODUCT REVENUE
   ======================================================= */

SELECT TOP 20
    s.seller_id,

    COUNT(DISTINCT s.order_id) AS TotalOrders,

    COUNT(*) AS TotalItems,

    SUM(s.price) AS ProductRevenue,

    SUM(s.freight_value) AS FreightValue,

    SUM(s.price + s.freight_value) AS GrossOrderValue

FROM analytics.vw_OrderSales AS s

GROUP BY
    s.seller_id

ORDER BY
    ProductRevenue DESC;
GO


/* =======================================================
   3. TOP 20 SELLERS BY ORDER VOLUME
   ======================================================= */

SELECT TOP 20
    seller_id,

    COUNT(DISTINCT order_id) AS TotalOrders,

    COUNT(*) AS TotalItems,

    SUM(price) AS ProductRevenue,

    AVG(price) AS AverageItemPrice

FROM analytics.vw_OrderSales

GROUP BY
    seller_id

ORDER BY
    TotalOrders DESC;
GO


/* =======================================================
   4. TOP 20 SELLERS BY ITEM VOLUME
   ======================================================= */

SELECT TOP 20
    seller_id,

    COUNT(*) AS TotalItems,

    COUNT(DISTINCT order_id) AS TotalOrders,

    SUM(price) AS ProductRevenue,

    AVG(price) AS AverageItemPrice

FROM analytics.vw_OrderSales

GROUP BY
    seller_id

ORDER BY
    TotalItems DESC;
GO


/* =======================================================
   5. SELLER REVENUE PER ORDER
   ======================================================= */

SELECT TOP 20
    seller_id,

    COUNT(DISTINCT order_id) AS TotalOrders,

    SUM(price) AS ProductRevenue,

    CAST(
        SUM(price) /
        NULLIF(COUNT(DISTINCT order_id), 0)
        AS DECIMAL(18,2)
    ) AS RevenuePerOrder

FROM analytics.vw_OrderSales

GROUP BY
    seller_id

ORDER BY
    RevenuePerOrder DESC;
GO


/* =======================================================
   6. SELLER FREIGHT BURDEN
   ======================================================= */

SELECT TOP 20
    seller_id,

    SUM(price) AS ProductRevenue,

    SUM(freight_value) AS FreightValue,

    CAST(
        100.0 * SUM(freight_value) /
        NULLIF(SUM(price), 0)
        AS DECIMAL(10,2)
    ) AS FreightToRevenuePercent

FROM analytics.vw_OrderSales

GROUP BY
    seller_id

ORDER BY
    FreightToRevenuePercent DESC;
GO


/* =======================================================
   7. SELLER LOCATION
   ======================================================= */

SELECT TOP 20
    s.seller_id,

    s.seller_city,

    s.seller_state,

    sp.TotalOrders,

    sp.ProductRevenue,

    sp.GrossOrderValue

FROM core.Sellers AS s

INNER JOIN
(
    SELECT
        seller_id,

        COUNT(DISTINCT order_id) AS TotalOrders,

        SUM(price) AS ProductRevenue,

        SUM(price + freight_value) AS GrossOrderValue

    FROM analytics.vw_OrderSales

    GROUP BY
        seller_id

) AS sp

    ON s.seller_id = sp.seller_id

ORDER BY
    sp.ProductRevenue DESC;
GO


/* =======================================================
   8. SELLER REVENUE BY STATE
   ======================================================= */

SELECT
    s.seller_state,

    COUNT(DISTINCT s.seller_id) AS SellerCount,

    COUNT(DISTINCT os.order_id) AS TotalOrders,

    SUM(os.price) AS ProductRevenue,

    SUM(os.freight_value) AS FreightValue

FROM core.Sellers AS s

INNER JOIN analytics.vw_OrderSales AS os
    ON s.seller_id = os.seller_id

GROUP BY
    s.seller_state

ORDER BY
    ProductRevenue DESC;
GO

/*One metric here needs special attention

We're calculating:

Freight-to-Revenue %
Freight Value
────────────── × 100
Product Revenue

This is not a profit margin.

It tells us how large freight costs are relative to product sales value.

We'll use it as an operational cost indicator, not profitability.*/