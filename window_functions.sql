SELECT 
    customer_id,
    sale_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id 
        ORDER BY sale_date
    ) AS running_total
FROM sales;
