USE Olist_Ecommerce_Analytics;
GO

/* =========================================================
   OLIST E-COMMERCE ANALYTICS
   SQL SERVER INDEX DEFINITIONS
   ========================================================= */


/* Orders - customer analysis */
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
ON core.Orders(customer_id);
GO


/* Orders - time-based analysis */
CREATE NONCLUSTERED INDEX IX_Orders_PurchaseTimestamp
ON core.Orders(order_purchase_timestamp);
GO


/* Orders - status analysis */
CREATE NONCLUSTERED INDEX IX_Orders_OrderStatus_Covering
ON core.Orders(order_status)
INCLUDE
(
    customer_id,
    order_purchase_timestamp
);
GO


/* Order Items - product analysis */
CREATE NONCLUSTERED INDEX IX_OrderItems_ProductID
ON core.OrderItems(product_id);
GO


/* Order Items - seller analysis */
CREATE NONCLUSTERED INDEX IX_OrderItems_SellerID
ON core.OrderItems(seller_id);
GO


/* Reviews - order-level analysis */
CREATE NONCLUSTERED INDEX IX_OrderReviews_OrderID
ON core.OrderReviews(order_id);
GO


/* Customers - repeat customer analysis */
CREATE NONCLUSTERED INDEX IX_Customers_CustomerUniqueID
ON core.Customers(customer_unique_id);
GO