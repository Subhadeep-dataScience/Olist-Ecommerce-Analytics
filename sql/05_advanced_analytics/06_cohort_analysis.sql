USE Olist_Ecommerce_Analytics;
GO

/*
=========================================================
OLIST E-COMMERCE ANALYTICS
PHASE 3.6 - COHORT RETENTION ANALYSIS
=========================================================

Purpose:
    Analyze customer retention based on the month of
    each customer's first delivered purchase.

Definitions:
    Cohort Month     = Month of first delivered purchase
    Cohort Index     = Number of months since first purchase

Customer Grain:
    customer_unique_id

Note:
    Uses delivered orders only.
=========================================================
*/


/* =======================================================
   1. CUSTOMER COHORT ASSIGNMENT
   ======================================================= */

WITH CustomerFirstPurchase AS
(
    SELECT
        c.customer_unique_id,

        MIN(
            DATEFROMPARTS(
                YEAR(o.order_purchase_timestamp),
                MONTH(o.order_purchase_timestamp),
                1
            )
        ) AS CohortMonth

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    CohortMonth,

    COUNT(*) AS CustomersAcquired

FROM CustomerFirstPurchase

GROUP BY
    CohortMonth

ORDER BY
    CohortMonth;
GO


/* =======================================================
   2. CUSTOMER ACTIVITY BY COHORT
   ======================================================= */

WITH CustomerFirstPurchase AS
(
    SELECT
        c.customer_unique_id,

        MIN(
            DATEFROMPARTS(
                YEAR(o.order_purchase_timestamp),
                MONTH(o.order_purchase_timestamp),
                1
            )
        ) AS CohortMonth

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

CustomerMonthlyActivity AS
(
    SELECT DISTINCT
        c.customer_unique_id,

        DATEFROMPARTS(
            YEAR(o.order_purchase_timestamp),
            MONTH(o.order_purchase_timestamp),
            1
        ) AS ActivityMonth

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

CohortActivity AS
(
    SELECT
        cfp.customer_unique_id,
        cfp.CohortMonth,
        cma.ActivityMonth,

        DATEDIFF(
            MONTH,
            cfp.CohortMonth,
            cma.ActivityMonth
        ) AS CohortIndex

    FROM CustomerFirstPurchase AS cfp

    INNER JOIN CustomerMonthlyActivity AS cma
        ON cfp.customer_unique_id = cma.customer_unique_id
)

SELECT
    CohortMonth,
    CohortIndex,

    COUNT(DISTINCT customer_unique_id) AS ActiveCustomers

FROM CohortActivity

GROUP BY
    CohortMonth,
    CohortIndex

ORDER BY
    CohortMonth,
    CohortIndex;
GO


/* =======================================================
   3. COHORT RETENTION RATE
   ======================================================= */

WITH CustomerFirstPurchase AS
(
    SELECT
        c.customer_unique_id,

        MIN(
            DATEFROMPARTS(
                YEAR(o.order_purchase_timestamp),
                MONTH(o.order_purchase_timestamp),
                1
            )
        ) AS CohortMonth

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

CustomerMonthlyActivity AS
(
    SELECT DISTINCT
        c.customer_unique_id,

        DATEFROMPARTS(
            YEAR(o.order_purchase_timestamp),
            MONTH(o.order_purchase_timestamp),
            1
        ) AS ActivityMonth

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

CohortActivity AS
(
    SELECT
        cfp.customer_unique_id,
        cfp.CohortMonth,
        cma.ActivityMonth,

        DATEDIFF(
            MONTH,
            cfp.CohortMonth,
            cma.ActivityMonth
        ) AS CohortIndex

    FROM CustomerFirstPurchase AS cfp

    INNER JOIN CustomerMonthlyActivity AS cma
        ON cfp.customer_unique_id = cma.customer_unique_id
),

CohortSize AS
(
    SELECT
        CohortMonth,

        COUNT(DISTINCT customer_unique_id) AS CohortCustomers

    FROM CohortActivity

    WHERE CohortIndex = 0

    GROUP BY
        CohortMonth
),

Retention AS
(
    SELECT
        ca.CohortMonth,
        ca.CohortIndex,

        COUNT(DISTINCT ca.customer_unique_id) AS ActiveCustomers,

        cs.CohortCustomers

    FROM CohortActivity AS ca

    INNER JOIN CohortSize AS cs
        ON ca.CohortMonth = cs.CohortMonth

    GROUP BY
        ca.CohortMonth,
        ca.CohortIndex,
        cs.CohortCustomers
)

SELECT
    CohortMonth,
    CohortIndex,
    CohortCustomers,
    ActiveCustomers,

    CAST(
        100.0 * ActiveCustomers /
        NULLIF(CohortCustomers, 0)
        AS DECIMAL(10,2)
    ) AS RetentionRatePercent

FROM Retention

ORDER BY
    CohortMonth,
    CohortIndex;
GO

/* =======================================================
   4. FINAL COHORT RETENTION ANALYSIS
   Olist E-Commerce Analytics Project

   Logic:
   - Cohort = customer's first delivered purchase month
   - Retention = customers who make another delivered purchase
   - 0% means the month was observed but no customers returned
   - Future/unobserved months are NOT displayed
   ======================================================= */

WITH CustomerFirstPurchase AS
(
    SELECT
        c.customer_unique_id,

        MIN(
            DATEFROMPARTS(
                YEAR(o.order_purchase_timestamp),
                MONTH(o.order_purchase_timestamp),
                1
            )
        ) AS CohortMonth

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

CustomerMonthlyActivity AS
(
    SELECT DISTINCT
        c.customer_unique_id,

        DATEFROMPARTS(
            YEAR(o.order_purchase_timestamp),
            MONTH(o.order_purchase_timestamp),
            1
        ) AS ActivityMonth

    FROM core.Customers AS c

    INNER JOIN core.Orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

AnalysisPeriod AS
(
    SELECT
        MAX(
            DATEFROMPARTS(
                YEAR(order_purchase_timestamp),
                MONTH(order_purchase_timestamp),
                1
            )
        ) AS MaxActivityMonth

    FROM core.Orders
    WHERE order_status = 'delivered'
),

CohortActivity AS
(
    SELECT
        cfp.customer_unique_id,
        cfp.CohortMonth,

        DATEDIFF(
            MONTH,
            cfp.CohortMonth,
            cma.ActivityMonth
        ) AS CohortIndex

    FROM CustomerFirstPurchase AS cfp

    INNER JOIN CustomerMonthlyActivity AS cma
        ON cfp.customer_unique_id = cma.customer_unique_id
),

CohortSize AS
(
    SELECT
        CohortMonth,
        COUNT(*) AS CohortCustomers

    FROM CustomerFirstPurchase

    GROUP BY CohortMonth
),

ActiveCustomers AS
(
    SELECT
        CohortMonth,
        CohortIndex,
        COUNT(DISTINCT customer_unique_id) AS ActiveCustomerCount

    FROM CohortActivity

    GROUP BY
        CohortMonth,
        CohortIndex
),

Numbers AS
(
    SELECT 0 AS CohortIndex

    UNION ALL

    SELECT CohortIndex + 1
    FROM Numbers
    WHERE CohortIndex < 24
),

CompleteCohortGrid AS
(
    SELECT
        cs.CohortMonth,
        n.CohortIndex,
        cs.CohortCustomers

    FROM CohortSize AS cs
    CROSS JOIN Numbers AS n
    CROSS JOIN AnalysisPeriod AS ap

    /* Only generate months that actually existed
       within our observation period */
    WHERE DATEADD(
              MONTH,
              n.CohortIndex,
              cs.CohortMonth
          ) <= ap.MaxActivityMonth
)

SELECT
    g.CohortMonth,
    g.CohortIndex,
    g.CohortCustomers,

    COALESCE(
        ac.ActiveCustomerCount,
        0
    ) AS ActiveCustomers,

    CAST(
        100.0 * COALESCE(
            ac.ActiveCustomerCount,
            0
        ) / NULLIF(g.CohortCustomers, 0)
        AS DECIMAL(10,2)
    ) AS RetentionRatePercent

FROM CompleteCohortGrid AS g

LEFT JOIN ActiveCustomers AS ac
    ON g.CohortMonth = ac.CohortMonth
    AND g.CohortIndex = ac.CohortIndex

ORDER BY
    g.CohortMonth,
    g.CohortIndex

OPTION (MAXRECURSION 100);
GO