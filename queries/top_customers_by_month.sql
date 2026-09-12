-- Redshift analytics pattern: top customers by monthly revenue.
-- Uses a two-step aggregation + window function approach so the ranking
-- operates on monthly customer totals instead of raw transaction rows.

WITH monthly_customer_sales AS (
    SELECT
        DATE_TRUNC('month', sale_date) AS sales_month,
        customer_id,
        SUM(sales_amount) AS monthly_revenue
    FROM sales
    GROUP BY 1, 2
),
ranked_customers AS (
    SELECT
        sales_month,
        customer_id,
        monthly_revenue,
        DENSE_RANK() OVER (
            PARTITION BY sales_month
            ORDER BY monthly_revenue DESC
        ) AS revenue_rank
    FROM monthly_customer_sales
)
SELECT
    sales_month,
    customer_id,
    monthly_revenue,
    revenue_rank
FROM ranked_customers
WHERE revenue_rank <= 5
ORDER BY sales_month, revenue_rank, customer_id;
