SELECT c.customer_name, SUM(s.amount)
FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
WHERE s.sale_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.customer_name;
