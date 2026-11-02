--Raw Data Loading

--load csv data of olist_customers from olist csv file
USE Olist_Ecommerce_Analytics;
GO
BULK INSERT staging.olist_customers
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\olist_customers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO

--verify the loaading by counting no. of rows loaded
SELECT COUNT(*) AS CustomerRows
FROM staging.olist_customers;

--view top 10 rows from the table
SELECT TOP 10 *
FROM staging.olist_customers;

--Load orders
USE Olist_Ecommerce_Analytics;
GO

BULK INSERT staging.olist_orders
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\olist_orders_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO

--check rows count and top 5 rows of staging.olist_orders table
SELECT COUNT(*) AS OrderRows
FROM staging.olist_orders;
SELECT TOP 5 *
FROM staging.olist_orders;

--Load order_items
BULK INSERT staging.olist_order_items
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\olist_order_items_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO

--Check:
SELECT COUNT(*) AS OrderItemRows
FROM staging.olist_order_items;

--Load order_payments
BULK INSERT staging.olist_order_payments
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\olist_order_payments_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO

--Check:
SELECT COUNT(*) AS PaymentRows
FROM staging.olist_order_payments;


--Load order_reviews  note: FIELDTERMINATOR = ','  and  ROWTERMINATOR = '0x0a', should be excluded if you need to load large character data
BULK INSERT staging.olist_order_reviews
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\olist_order_reviews_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    TABLOCK
);
GO

--see details about the table like its structure
sp_help 'staging.olist_order_reviews';

--check if order_reviews loaded or not
SELECT COUNT(*) AS Row_count
FROM staging.olist_order_reviews;

--Load products
BULK INSERT staging.olist_products
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\olist_products_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO

--Check:
SELECT COUNT(*) AS ProductRows
FROM staging.olist_products;

--Load sellers
BULK INSERT staging.olist_sellers
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\olist_sellers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO

--Check:
SELECT COUNT(*) AS SellerRows
FROM staging.olist_sellers;

--load geolocation
BULK INSERT staging.olist_geolocation
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\olist_geolocation_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO

--Check:
SELECT COUNT(*) AS GeolocationRows
FROM staging.olist_geolocation;

--load product_category_translation
BULK INSERT staging.product_category_translation
FROM 'C:\path\to\Olist-Ecommerce-Analytics\data\raw\product_category_name_translation.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
GO

--Check:
SELECT COUNT(*) AS CategoryRows
FROM staging.product_category_translation;
