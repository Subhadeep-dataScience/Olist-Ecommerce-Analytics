--core.Customers
 CONSTRAINT PK_Customers
        PRIMARY KEY (customer_id)

--core.Orders
 CONSTRAINT PK_Orders
        PRIMARY KEY (order_id)

--core.Products
 CONSTRAINT PK_Products
        PRIMARY KEY (product_id)

--core.Sellers
CONSTRAINT PK_Sellers
        PRIMARY KEY (seller_id)

--core.OrderItems
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

--core.OrderPayments
    CONSTRAINT PK_OrderPayments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT FK_OrderPayments_Orders
        FOREIGN KEY (order_id)
        REFERENCES core.Orders(order_id)

--core.OrderReviews
    CONSTRAINT PK_OrderReviews
        PRIMARY KEY (review_key),

    CONSTRAINT FK_OrderReviews_Orders
        FOREIGN KEY (order_id)
        REFERENCES core.Orders(order_id),

    CONSTRAINT CK_OrderReviews_Score
        CHECK (review_score BETWEEN 1 AND 5)

--core.ProductCategoryTranslation
    CONSTRAINT PK_ProductCategoryTranslation
        PRIMARY KEY (product_category_name)

--core.Geolocation
CONSTRAINT PK_Geolocation
        PRIMARY KEY (geolocation_key)