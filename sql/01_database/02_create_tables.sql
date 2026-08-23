--use staging schema area which is a temporary landing zone used to safely store, clean, and transform raw data before moving it to production tables.
USE Olist_Ecommerce_Analytics;
GO
CREATE SCHEMA staging;
GO

--create 9 tables exactly with the column present within the Olist dataset
CREATE TABLE staging.olist_customers
(
    customer_id              VARCHAR(50),
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(10)
);
GO
CREATE TABLE staging.olist_orders
(
    order_id                       VARCHAR(50),
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(30),
    order_purchase_timestamp       DATETIME2,
    order_approved_at              DATETIME2,
    order_delivered_carrier_date   DATETIME2,
    order_delivered_customer_date  DATETIME2,
    order_estimated_delivery_date  DATETIME2
);
GO


CREATE TABLE staging.olist_order_items
(
    order_id             VARCHAR(50),
    order_item_id        INT,
    product_id           VARCHAR(50),
    seller_id            VARCHAR(50),
    shipping_limit_date  DATETIME2,
    price                DECIMAL(18,2),
    freight_value        DECIMAL(18,2)
);
GO


CREATE TABLE staging.olist_order_payments
(
    order_id             VARCHAR(50),
    payment_sequential   INT,
    payment_type         VARCHAR(30),
    payment_installments INT,
    payment_value        DECIMAL(18,2)
);
GO


CREATE TABLE staging.olist_order_reviews
(
    review_id                VARCHAR(50),
    order_id                 VARCHAR(50),
    review_score             INT,
    review_comment_title     NVARCHAR(500),
    review_comment_message   NVARCHAR(MAX),
    review_creation_date     DATETIME2,
    review_answer_timestamp  DATETIME2
);
GO


CREATE TABLE staging.olist_products
(
    product_id                    VARCHAR(50),
    product_category_name         VARCHAR(100),
    product_name_lenght           INT,
    product_description_lenght    INT,
    product_photos_qty             INT,
    product_weight_g               DECIMAL(18,2),
    product_length_cm              DECIMAL(18,2),
    product_height_cm              DECIMAL(18,2),
    product_width_cm               DECIMAL(18,2)
);
GO


CREATE TABLE staging.olist_sellers
(
    seller_id             VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city            VARCHAR(100),
    seller_state           VARCHAR(10)
);
GO


CREATE TABLE staging.olist_geolocation
(
    geolocation_zip_code_prefix INT,
    geolocation_lat             DECIMAL(10,7),
    geolocation_lng             DECIMAL(10,7),
    geolocation_city            VARCHAR(100),
    geolocation_state           VARCHAR(10)
);
GO


CREATE TABLE staging.product_category_translation
(
    product_category_name          VARCHAR(100),
    product_category_name_english  VARCHAR(100)
);
GO

--Check that all 9 tables exist
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'staging'
ORDER BY TABLE_NAME;


--create the production/core layer
USE Olist_Ecommerce_Analytics;
GO

CREATE SCHEMA core;
GO

--Check:
SELECT
    NAME AS SchemaName
FROM sys.schemas
--WHERE NAME IN ('staging', 'core', 'analytics');

--Create core.Customers
CREATE TABLE core.Customers
(
    customer_id              VARCHAR(50) NOT NULL,
    customer_unique_id       VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT NOT NULL,
    customer_city            VARCHAR(100) NOT NULL,
    customer_state           CHAR(2) NOT NULL,

    CONSTRAINT PK_Customers
        PRIMARY KEY (customer_id)
);
GO

--Create core.Orders
CREATE TABLE core.Orders
(
    order_id                       VARCHAR(50) NOT NULL,
    customer_id                    VARCHAR(50) NOT NULL,
    order_status                   VARCHAR(30) NOT NULL,
    order_purchase_timestamp       DATETIME2 NOT NULL,
    order_approved_at              DATETIME2 NULL,
    order_delivered_carrier_date   DATETIME2 NULL,
    order_delivered_customer_date  DATETIME2 NULL,
    order_estimated_delivery_date  DATETIME2 NOT NULL,

    CONSTRAINT PK_Orders
        PRIMARY KEY (order_id),

    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (customer_id)
        REFERENCES core.Customers(customer_id)
);
GO

--Create core.products
CREATE TABLE core.Products
(
    product_id                    VARCHAR(50) NOT NULL,
    product_category_name         VARCHAR(100) NULL,
    product_name_lenght           INT NULL,
    product_description_lenght    INT NULL,
    product_photos_qty             INT NULL,
    product_weight_g              DECIMAL(18,2) NULL,
    product_length_cm             DECIMAL(18,2) NULL,
    product_height_cm             DECIMAL(18,2) NULL,
    product_width_cm              DECIMAL(18,2) NULL,

    CONSTRAINT PK_Products
        PRIMARY KEY (product_id)
);
GO

--Create core.Sellers
CREATE TABLE core.Sellers
(
    seller_id              VARCHAR(50) NOT NULL,
    seller_zip_code_prefix INT NOT NULL,
    seller_city             VARCHAR(100) NOT NULL,
    seller_state            CHAR(2) NOT NULL,

    CONSTRAINT PK_Sellers
        PRIMARY KEY (seller_id)
);
GO

--Create core.OrderItems (here we will use both order_id and order_item_id as the primary key this called "composite key". As order_id itself is not unique)
CREATE TABLE core.OrderItems
(
    order_id             VARCHAR(50) NOT NULL,
    order_item_id        INT NOT NULL,
    product_id           VARCHAR(50) NOT NULL,
    seller_id            VARCHAR(50) NOT NULL,
    shipping_limit_date  DATETIME2 NOT NULL,
    price                DECIMAL(18,2) NOT NULL,
    freight_value        DECIMAL(18,2) NOT NULL,

    CONSTRAINT PK_OrderItems
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT FK_OrderItems_Orders
        FOREIGN KEY (order_id)
        REFERENCES core.Orders(order_id),

    CONSTRAINT FK_OrderItems_Products
        FOREIGN KEY (product_id)
        REFERENCES core.Products(product_id),

    CONSTRAINT FK_OrderItems_Sellers
        FOREIGN KEY (seller_id)
        REFERENCES core.Sellers(seller_id)
);
GO

--Create core.OrderPayments ( we will use order_id + payment_sequential as our natural primary key. an order can have multiple payment records.)
CREATE TABLE core.OrderPayments
(
    order_id             VARCHAR(50) NOT NULL,
    payment_sequential   INT NOT NULL,
    payment_type         VARCHAR(30) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value        DECIMAL(18,2) NOT NULL,

    CONSTRAINT PK_OrderPayments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT FK_OrderPayments_Orders
        FOREIGN KEY (order_id)
        REFERENCES core.Orders(order_id)
);
GO

--Create core.OrderReviews     (Our earlier validation showed:  99,224 review row   98,410 unique review_id Therefore:  We cannot use review_id as the primary key. But we also know: 98,673 unique order_id So order_id isn't unique either. We therefore need a surrogate key for the core table.)
CREATE TABLE core.OrderReviews
(
    review_key               BIGINT IDENTITY(1,1) NOT NULL,       --This allows every physical review record to be uniquely identified without altering the source data.
    review_id                VARCHAR(50) NOT NULL,
    order_id                 VARCHAR(50) NOT NULL,
    review_score             INT NOT NULL,
    review_comment_title     NVARCHAR(500) NULL,
    review_comment_message   NVARCHAR(MAX) NULL,
    review_creation_date     DATETIME2 NULL,
    review_answer_timestamp  DATETIME2 NULL,

    CONSTRAINT PK_OrderReviews
        PRIMARY KEY (review_key),

    CONSTRAINT FK_OrderReviews_Orders
        FOREIGN KEY (order_id)
        REFERENCES core.Orders(order_id),

    CONSTRAINT CK_OrderReviews_Score
        CHECK (review_score BETWEEN 1 AND 5)
);
GO

--Create core.ProductCategoryTranslation
CREATE TABLE core.ProductCategoryTranslation
(
    product_category_name          VARCHAR(100) NOT NULL,
    product_category_name_english  VARCHAR(100) NOT NULL,

    CONSTRAINT PK_ProductCategoryTranslation
        PRIMARY KEY (product_category_name)
);
GO

--create core.Geolocation
CREATE TABLE core.Geolocation
(
    geolocation_key            BIGINT IDENTITY(1,1) NOT NULL,
    geolocation_zip_code_prefix INT NOT NULL,
    geolocation_lat             DECIMAL(10,7) NULL,
    geolocation_lng             DECIMAL(10,7) NULL,
    geolocation_city            VARCHAR(100) NULL,
    geolocation_state           CHAR(2) NULL,

    CONSTRAINT PK_Geolocation
        PRIMARY KEY (geolocation_key)
);
GO

